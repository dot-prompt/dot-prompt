use lsp_server::{Connection, Message, Notification, Request, Response};
use lsp_types::{
    Diagnostic, DiagnosticSeverity, DidChangeTextDocumentParams,
    DidOpenTextDocumentParams, FullDocumentDiagnosticReport, Hover, HoverContents, HoverParams,
    InitializeParams, MarkupContent, MarkupKind, Position, PublishDiagnosticsParams, Range,
    RelatedFullDocumentDiagnosticReport, ServerCapabilities, TextDocumentSyncKind, Uri,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

const DEFAULT_SERVER_URL: &str = "http://localhost:4000";

fn get_server_url() -> String {
    std::env::var("DOT_PROMPT_SERVER_URL").unwrap_or_else(|_| DEFAULT_SERVER_URL.to_string())
}

#[derive(Debug, Serialize, Deserialize)]
struct CompileRequest {
    prompt: String,
    params: HashMap<String, serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    seed: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    major: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    annotated: Option<bool>,
}

#[derive(Debug, Serialize, Deserialize)]
struct CompileResponse {
    template: String,
    cache_hit: bool,
    compiled_tokens: u64,
    #[serde(default)]
    vary_selections: HashMap<String, serde_json::Value>,
    #[serde(default)]
    response_contract: Option<serde_json::Value>,
    #[serde(default)]
    warnings: Vec<String>,
    #[serde(default)]
    params: Option<HashMap<String, ParamMeta>>,
    #[serde(default)]
    major: Option<u64>,
    #[serde(default)]
    version: Option<serde_json::Value>,
    #[serde(default)]
    used_vars: Option<Vec<String>>,
}

#[derive(Debug, Serialize, Deserialize)]
struct ParamMeta {
    #[serde(rename = "type")]
    param_type: String,
    #[serde(default)]
    default: Option<serde_json::Value>,
    #[serde(default)]
    values: Option<Vec<String>>,
    #[serde(default)]
    range: Option<Vec<i64>>,
    #[serde(default)]
    doc: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct CompileError {
    error: String,
    message: String,
    #[serde(default)]
    line: Option<u64>,
    #[serde(default)]
    column: Option<u64>,
}

fn compile(prompt: &str) -> Result<CompileResponse, String> {
    let server_url = get_server_url();
    let request = CompileRequest {
        prompt: prompt.to_string(),
        params: HashMap::new(),
        seed: None,
        major: None,
        annotated: Some(true),
    };

    let response = ureq::post(&format!("{}/api/compile", server_url))
        .set("Content-Type", "application/json")
        .send_json(serde_json::to_value(&request).map_err(|e| e.to_string())?)
        .map_err(|e| e.to_string())?;

    let status = response.status();
    let body: serde_json::Value = response.into_json().map_err(|e| e.to_string())?;

    if status != 200 {
        let error: CompileError = serde_json::from_value(body).unwrap_or(CompileError {
            error: "unknown".to_string(),
            message: format!("Server returned {}", status),
            line: None,
            column: None,
        });
        return Err(error.message);
    }

    serde_json::from_value(body).map_err(|e| e.to_string())
}

fn parse_line_from_message(msg: &str) -> Option<u64> {
    let mut chars = msg.chars().peekable();
    loop {
        let c = match chars.next() {
            Some(c) => c,
            None => break,
        };
        if c == 'l' {
            let peeked: String = chars.clone().take(3).collect();
            if peeked == "ine" {
                chars.next();
                chars.next();
                chars.next();
                let num_str: String = chars.by_ref().take_while(|c| c.is_ascii_digit()).collect();
                if let Ok(n) = num_str.parse::<u64>() {
                    return Some(n);
                }
            }
        }
    }
    None
}

fn uri_to_path(uri: &Uri) -> Option<std::path::PathBuf> {
    let path_str = uri.as_str();
    if path_str.starts_with("file://") {
        let path = &path_str[7..];
        Some(std::path::PathBuf::from(path))
    } else {
        None
    }
}

fn main() -> Result<(), Box<dyn std::error::Error + Sync + Send>> {
    eprintln!("dot-prompt-lsp starting...");

    let (connection, io_threads) = Connection::stdio();

    let server_capabilities = serde_json::to_value(&ServerCapabilities {
        text_document_sync: Some(lsp_types::TextDocumentSyncCapability::Kind(
            TextDocumentSyncKind::INCREMENTAL,
        )),
        hover_provider: Some(lsp_types::HoverProviderCapability::Simple(true)),
        diagnostic_provider: Some(lsp_types::DiagnosticServerCapabilities::Options(
            lsp_types::DiagnosticOptions {
                identifier: Some("dot-prompt".to_string()),
                inter_file_dependencies: false,
                workspace_diagnostics: false,
                work_done_progress_options: lsp_types::WorkDoneProgressOptions {
                    work_done_progress: Some(false),
                },
            },
        )),
        ..Default::default()
    })
    .unwrap();

    let initialization_params = connection.initialize(server_capabilities)?;
    let _init_params: InitializeParams = serde_json::from_value(initialization_params)?;

    eprintln!("dot-prompt-lsp initialized");

    main_loop(&connection)?;

    io_threads.join()?;
    eprintln!("dot-prompt-lsp shutting down");

    Ok(())
}

fn main_loop(connection: &Connection) -> Result<(), Box<dyn std::error::Error + Sync + Send>> {
    for msg in &connection.receiver {
        match msg {
            Message::Request(req) => {
                if connection.handle_shutdown(&req)? {
                    return Ok(());
                }
                handle_request(connection, req)?;
            }
            Message::Notification(not) => {
                handle_notification(connection, not)?;
            }
            Message::Response(_) => {}
        }
    }
    Ok(())
}

fn handle_request(connection: &Connection, req: Request) -> Result<(), Box<dyn std::error::Error + Sync + Send>> {
    match req.method.as_str() {
        "textDocument/hover" => {
            let params: HoverParams = serde_json::from_value(req.params)?;
            let uri = params.text_document_position_params.text_document.uri;
            let result = handle_hover(&uri);
            let result = serde_json::to_value(result)?;
            let resp = Response {
                id: req.id,
                result: Some(result),
                error: None,
            };
            connection.sender.send(Message::Response(resp))?;
        }
        "textDocument/diagnostic" => {
            let params: lsp_types::DocumentDiagnosticParams = serde_json::from_value(req.params)?;
            let uri = params.text_document.uri;
            let diagnostics = handle_diagnostics(&uri);
            let report = RelatedFullDocumentDiagnosticReport {
                related_documents: None,
                full_document_diagnostic_report: FullDocumentDiagnosticReport {
                    result_id: None,
                    items: diagnostics,
                },
            };
            let result = lsp_types::DocumentDiagnosticReport::Full(report);
            let result = serde_json::to_value(result)?;
            let resp = Response {
                id: req.id,
                result: Some(result),
                error: None,
            };
            connection.sender.send(Message::Response(resp))?;
        }
        _ => {
            let resp = Response {
                id: req.id,
                result: None,
                error: Some(lsp_server::ResponseError {
                    code: lsp_server::ErrorCode::MethodNotFound as i32,
                    message: format!("Method not found: {}", req.method),
                    data: None,
                }),
            };
            connection.sender.send(Message::Response(resp))?;
        }
    }
    Ok(())
}

fn handle_notification(connection: &Connection, not: Notification) -> Result<(), Box<dyn std::error::Error + Sync + Send>> {
    match not.method.as_str() {
        "textDocument/didOpen" => {
            let params: DidOpenTextDocumentParams = serde_json::from_value(not.params)?;
            publish_diagnostics(connection, &params.text_document.uri, &params.text_document.text)?;
        }
        "textDocument/didChange" => {
            let params: DidChangeTextDocumentParams = serde_json::from_value(not.params)?;
            if let Some(change) = params.content_changes.first() {
                publish_diagnostics(connection, &params.text_document.uri, &change.text)?;
            }
        }
        _ => {}
    }
    Ok(())
}

fn publish_diagnostics(
    connection: &Connection,
    uri: &Uri,
    text: &str,
) -> Result<(), Box<dyn std::error::Error + Sync + Send>> {
    let diagnostics = compute_diagnostics(text);
    let params = PublishDiagnosticsParams {
        uri: uri.clone(),
        diagnostics,
        version: None,
    };
    let result = serde_json::to_value(&params)?;
    connection.sender.send(Message::Notification(Notification {
        method: "textDocument/publishDiagnostics".to_string(),
        params: result,
    }))?;
    Ok(())
}

fn compute_diagnostics(text: &str) -> Vec<Diagnostic> {
    match compile(text) {
        Ok(result) => {
            let mut diagnostics = Vec::new();
            for warning in &result.warnings {
                let line = parse_line_from_message(warning).unwrap_or(0);
                let line = if line > 0 { line - 1 } else { 0 };
                diagnostics.push(Diagnostic {
                    range: Range {
                        start: Position {
                            line: line as u32,
                            character: 0,
                        },
                        end: Position {
                            line: line as u32,
                            character: 1000,
                        },
                    },
                    severity: Some(DiagnosticSeverity::WARNING),
                    code: None,
                    code_description: None,
                    source: Some("dot-prompt".to_string()),
                    message: warning.clone(),
                    related_information: None,
                    tags: None,
                    data: None,
                });
            }
            diagnostics
        }
        Err(message) => {
            let line = parse_line_from_message(&message).unwrap_or(0);
            let line = if line > 0 { line - 1 } else { 0 };
            vec![Diagnostic {
                range: Range {
                    start: Position {
                        line: line as u32,
                        character: 0,
                    },
                    end: Position {
                        line: line as u32,
                        character: 1000,
                    },
                },
                severity: Some(DiagnosticSeverity::ERROR),
                code: None,
                code_description: None,
                source: Some("dot-prompt".to_string()),
                message,
                related_information: None,
                tags: None,
                data: None,
            }]
        }
    }
}

fn handle_hover(uri: &Uri) -> Option<Hover> {
    let text = std::fs::read_to_string(uri_to_path(uri)?).ok()?;

    match compile(&text) {
        Ok(result) => {
            let mut content = String::new();
            content.push_str(&format!("**Tokens:** ~{}", result.compiled_tokens));
            if result.cache_hit {
                content.push_str("\n\n**Cache:** ✓ Hit");
            }
            if !result.vary_selections.is_empty() {
                content.push_str("\n\n**Vary Selections:**");
                for (key, value) in &result.vary_selections {
                    content.push_str(&format!("\n- {}: {}", key, value));
                }
            }
            if let Some(contract) = &result.response_contract {
                if let Some(type_val) = contract.get("type") {
                    content.push_str(&format!("\n\n**Response Type:** {}", type_val));
                }
            }
            if !result.warnings.is_empty() {
                content.push_str(&format!("\n\n**Warnings:** {}", result.warnings.len()));
            }

            let preview = if result.template.len() > 500 {
                format!("{}...", &result.template[..500])
            } else {
                result.template.clone()
            };
            content.push_str(&format!("\n\n---\n\n**Compiled Template:**\n```\n{}\n```", preview));

            Some(Hover {
                contents: HoverContents::Markup(MarkupContent {
                    kind: MarkupKind::Markdown,
                    value: content,
                }),
                range: None,
            })
        }
        Err(_) => None,
    }
}

fn handle_diagnostics(uri: &Uri) -> Vec<Diagnostic> {
    let text = std::fs::read_to_string(uri_to_path(uri).unwrap_or_default()).unwrap_or_default();
    compute_diagnostics(&text)
}
