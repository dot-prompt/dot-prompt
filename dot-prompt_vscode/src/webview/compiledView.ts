/**
 * Compiled View Webview Panel - displays compiled .prompt output
 */

import * as vscode from 'vscode';
import * as path from 'path';
import { CompileResponse, CompileError } from '../api/types';
import * as api from '../api/client';

export class CompiledViewPanel {
  public static currentPanel: CompiledViewPanel | undefined;
  public static readonly viewType = 'dotPromptCompiled';

  private readonly panel: vscode.WebviewPanel;
  private readonly extensionUri: vscode.Uri;
  private currentDocument: vscode.TextDocument | undefined;
  private currentParams: Record<string, any> = {};

  /**
   * Create or show the compiled view panel
   */
  public static createOrShow(extensionUri: vscode.Uri): CompiledViewPanel {
    const column = vscode.ViewColumn.Two;

    // If we already have a panel, show it
    if (CompiledViewPanel.currentPanel) {
      CompiledViewPanel.currentPanel.panel.reveal(column, true);
      return CompiledViewPanel.currentPanel;
    }

    // Create a new panel
    const panel = vscode.window.createWebviewPanel(
      CompiledViewPanel.viewType,
      'Compiled View',
      column,
      {
        enableScripts: true,
        retainContextWhenHidden: true,
        localResourceRoots: [
          vscode.Uri.file(path.join(extensionUri.fsPath, 'webviews', 'compiled'))
        ]
      }
    );

    CompiledViewPanel.currentPanel = new CompiledViewPanel(panel, extensionUri);
    return CompiledViewPanel.currentPanel;
  }

  private constructor(panel: vscode.WebviewPanel, extensionUri: vscode.Uri) {
    this.panel = panel;
    this.extensionUri = extensionUri;

    // Set up the webview content
    this.panel.webview.html = this.getHtmlForWebview();
    this.panel.webview.onDidReceiveMessage(this.handleMessage.bind(this));

    // Handle panel disposal
    this.panel.onDidDispose(() => {
      CompiledViewPanel.currentPanel = undefined;
    });
  }

  /**
   * Set the current document being viewed
   */
  public setDocument(document: vscode.TextDocument, params: Record<string, any> = {}): void {
    this.currentDocument = document;
    this.currentParams = params;
  }

  /**
   * Compile and display the current document
   */
  public async compileAndDisplay(): Promise<void> {
    if (!this.currentDocument) {
      this.showError('No document open');
      return;
    }

    const prompt = this.currentDocument.getText();
    
    try {
      this.showLoading();
      
      const result = await api.compile(prompt, this.currentParams);
      this.displayCompileResult(result);
    } catch (error) {
      const compileError = error as CompileError;
      this.showError(compileError.message || 'Compilation failed');
    }
  }

  /**
   * Display the compile result in the webview
   */
  private displayCompileResult(result: CompileResponse): void {
    const message = {
      type: 'display',
      data: result
    };
    this.panel.webview.postMessage(message);
  }

  /**
   * Show loading state
   */
  private showLoading(): void {
    this.panel.webview.postMessage({ type: 'loading' });
  }

  /**
   * Show error message
   */
  private showError(message: string): void {
    this.panel.webview.postMessage({
      type: 'error',
      data: { message }
    });
  }

  /**
   * Handle messages from the webview
   */
  private async handleMessage(message: any): Promise<void> {
    switch (message.type) {
      case 'compile':
        await this.compileAndDisplay();
        break;
      case 'copy':
        await vscode.env.clipboard.writeText(message.data.text);
        vscode.window.showInformationMessage('Copied to clipboard');
        break;
      case 'openInEditor':
        // Could implement navigating to specific sections
        break;
      case 'refresh':
        await this.compileAndDisplay();
        break;
    }
  }

  /**
   * Get the HTML for the webview
   */
  private getHtmlForWebview(): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';">
  <title>Compiled View</title>
  <style>
    * {
      box-sizing: border-box;
    }
    body {
      margin: 0;
      padding: 0;
      background: #1e1e1e;
      color: #d4d4d4;
      font-family: 'Consolas', 'Courier New', monospace;
      font-size: 13px;
      line-height: 1.5;
    }
    .toolbar {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 8px 16px;
      background: #252526;
      border-bottom: 1px solid #3c3c3c;
    }
    .toolbar button {
      background: #0e639c;
      color: #fff;
      border: none;
      padding: 6px 12px;
      border-radius: 2px;
      cursor: pointer;
      font-size: 12px;
    }
    .toolbar button:hover {
      background: #1177bb;
    }
    .status {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-left: auto;
    }
    .token-count {
      color: #9cdcfe;
    }
    .cache-status {
      padding: 2px 8px;
      border-radius: 2px;
      font-size: 11px;
    }
    .cache-hit {
      background: rgba(78, 201, 176, 0.2);
      color: #4ec9b0;
    }
    .cache-miss {
      background: rgba(220, 220, 170, 0.2);
      color: #dcdcaa;
    }
    .content {
      padding: 16px;
      overflow: auto;
      height: calc(100vh - 50px);
    }
    .section {
      margin-bottom: 16px;
      border: 1px solid #3c3c3c;
      border-radius: 4px;
      overflow: hidden;
    }
    .section-header {
      background: #252526;
      padding: 8px 12px;
      font-weight: 600;
      border-bottom: 1px solid #3c3c3c;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .section-header button {
      background: transparent;
      border: 1px solid #3c3c3c;
      color: #d4d4d4;
      padding: 2px 8px;
      border-radius: 2px;
      cursor: pointer;
      font-size: 11px;
    }
    .section-header button:hover {
      background: #3c3c3c;
    }
    .section-content {
      padding: 12px;
      white-space: pre-wrap;
      word-break: break-word;
      max-height: 300px;
      overflow: auto;
    }
    .system { border-left: 3px solid #dcdcaa; }
    .user { border-left: 3px solid #9cdcfe; }
    .assistant { border-left: 3px solid #ce9178; }
    .vary { border-left: 3px solid #c586c0; }
    .contract { border-left: 3px solid #4ec9b0; }
    
    .vary-selections {
      background: #1e1e1e;
    }
    .vary-selections ul {
      margin: 0;
      padding: 12px;
      list-style: none;
    }
    .vary-selections li {
      padding: 4px 0;
    }
    .vary-key {
      color: #c586c0;
    }
    .vary-value {
      color: #ce9178;
    }
    
    .warnings {
      background: rgba(220, 170, 170, 0.1);
      border-left: 3px solid #f14c4c;
    }
    .warnings ul {
      margin: 0;
      padding: 12px;
      list-style: none;
    }
    .warnings li {
      color: #f14c4c;
      padding: 4px 0;
    }
    
    .contract pre {
      margin: 0;
      padding: 12px;
      white-space: pre-wrap;
      word-break: break-word;
      font-size: 12px;
      color: #9cdcfe;
    }
    
    .loading {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100%;
      color: #858585;
    }
    .loading::after {
      content: '';
      width: 20px;
      height: 20px;
      border: 2px solid #3c3c3c;
      border-top-color: #0e639c;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin-left: 10px;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
    
    .error {
      padding: 16px;
      background: rgba(244, 76, 76, 0.1);
      border: 1px solid #f14c4c;
      border-radius: 4px;
      color: #f14c4c;
    }
    
    .empty-state {
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      height: 100%;
      color: #858585;
    }
  </style>
</head>
<body>
  <div class="toolbar">
    <button id="compile-btn">▶ Compile</button>
    <span class="status">
      <span class="token-count" id="token-count"></span>
      <span class="cache-status" id="cache-status"></span>
    </span>
  </div>
  <div class="content" id="content">
    <div class="empty-state">
      <p>Open a .prompt file and click Compile to see the results</p>
    </div>
  </div>

  <script>
    const vscode = acquireVsCodeApi();
    const compileBtn = document.getElementById('compile-btn');
    const contentDiv = document.getElementById('content');
    const tokenCountSpan = document.getElementById('token-count');
    const cacheStatusSpan = document.getElementById('cache-status');

    compileBtn.addEventListener('click', () => {
      vscode.postMessage({ type: 'compile' });
    });

    window.addEventListener('message', (event) => {
      const message = event.data;
      
      if (message.type === 'loading') {
        contentDiv.innerHTML = '<div class="loading">Compiling...</div>';
        return;
      }
      
      if (message.type === 'error') {
        contentDiv.innerHTML = '<div class="error">' + message.data.message + '</div>';
        return;
      }
      
      if (message.type === 'display') {
        displayResult(message.data);
      }
    });

    function displayResult(data) {
      const template = data.template || '';
      const cacheHit = data.cache_hit;
      const varySelections = data.vary_selections || {};
      const contract = data.response_contract;
      const warnings = data.warnings || [];
      
      // Update toolbar
      tokenCountSpan.textContent = '~' + (data.compiled_tokens || 0) + ' tokens';
      cacheStatusSpan.textContent = cacheHit ? '✓ Cache Hit' : '✗ Cache Miss';
      cacheStatusSpan.className = 'cache-status ' + (cacheHit ? 'cache-hit' : 'cache-miss');
      
      // Build sections HTML
      let sectionsHtml = '';
      
      // If template contains section markers, try to split them
      // Otherwise show raw template
      sectionsHtml += '<div class="section system">';
      sectionsHtml += '<div class="section-header">System<div><button onclick="copySection(\'system\')">Copy</button></div></div>';
      sectionsHtml += '<div class="section-content" id="section-system">' + escapeHtml(template) + '</div>';
      sectionsHtml += '</div>';
      
      // Vary selections
      if (Object.keys(varySelections).length > 0) {
        let varyHtml = '<ul>';
        for (const [key, value] of Object.entries(varySelections)) {
          varyHtml += '<li><span class="vary-key">' + key + '</span>: <span class="vary-value">' + value + '</span></li>';
        }
        varyHtml += '</ul>';
        
        sectionsHtml += '<div class="section vary-selections">';
        sectionsHtml += '<div class="section-header">Vary Selections</div>';
        sectionsHtml += varyHtml;
        sectionsHtml += '</div>';
      }
      
      // Warnings
      if (warnings.length > 0) {
        let warningsHtml = '<ul>';
        for (const warning of warnings) {
          warningsHtml += '<li>' + escapeHtml(warning) + '</li>';
        }
        warningsHtml += '</ul>';
        
        sectionsHtml += '<div class="section warnings">';
        sectionsHtml += '<div class="section-header">⚠ Warnings</div>';
        sectionsHtml += warningsHtml;
        sectionsHtml += '</div>';
      }
      
      // Response contract
      if (contract) {
        let contractJson = JSON.stringify(contract, null, 2);
        sectionsHtml += '<div class="section contract">';
        sectionsHtml += '<div class="section-header">Response Contract<div><button onclick="copySection(\'contract\')">Copy</button></div></div>';
        sectionsHtml += '<pre id="section-contract">' + escapeHtml(contractJson) + '</pre>';
        sectionsHtml += '</div>';
      }
      
      contentDiv.innerHTML = sectionsHtml;
    }

    function escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    function copySection(sectionId) {
      const element = document.getElementById('section-' + sectionId);
      if (element) {
        vscode.postMessage({
          type: 'copy',
          data: { text: element.textContent }
        });
      }
    }
  </script>
</body>
</html>`;
  }
}
