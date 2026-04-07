use zed_extension_api as zed;

struct DotPromptExtension {
    cached_binary_path: Option<String>,
}

impl DotPromptExtension {
    fn new() -> Self {
        Self {
            cached_binary_path: None,
        }
    }

    fn platform_string(os: zed::Os, arch: zed::Architecture) -> String {
        match (os, arch) {
            (zed::Os::Linux, zed::Architecture::X8664) => "x86_64-unknown-linux-gnu",
            (zed::Os::Linux, zed::Architecture::Aarch64) => "aarch64-unknown-linux-gnu",
            (zed::Os::Mac, zed::Architecture::X8664) => "x86_64-apple-darwin",
            (zed::Os::Mac, zed::Architecture::Aarch64) => "aarch64-apple-darwin",
            (zed::Os::Windows, zed::Architecture::X8664) => "x86_64-pc-windows-msvc",
            _ => "x86_64-unknown-linux-gnu",
        }.to_string()
    }

    fn language_server_binary_path(
        &mut self,
        language_server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> zed::Result<String> {
        if let Some(path) = worktree.which("dot-prompt-lsp") {
            return Ok(path);
        }

        if let Some(path) = &self.cached_binary_path {
            if std::fs::metadata(path).map_or(false, |stat| stat.is_file()) {
                return Ok(path.clone());
            }
        }

        let server_root_path = worktree.root_path();
        let binary_path = format!("{}/bin/dot-prompt-lsp", server_root_path);

        if !std::fs::metadata(&binary_path).map_or(false, |stat| stat.is_file()) {
            zed::set_language_server_installation_status(
                language_server_id,
                &zed::LanguageServerInstallationStatus::CheckingForUpdate,
            );

            zed::set_language_server_installation_status(
                language_server_id,
                &zed::LanguageServerInstallationStatus::Downloading,
            );

            let (os, arch) = zed::current_platform();
            let platform = Self::platform_string(os, arch);
            let asset_name = format!("dot-prompt-lsp-{}.tar.gz", platform);

            let url = format!(
                "https://github.com/dot-prompt/dotprompt/releases/latest/{}",
                asset_name
            );

            zed::download_file(
                &url,
                &binary_path,
                zed::DownloadedFileType::GzipTar,
            )
            .map_err(|e| format!("failed to download {}: {}", asset_name, e))?;
        }

        self.cached_binary_path = Some(binary_path.clone());

        if !std::fs::metadata(&binary_path).map_or(false, |stat| stat.is_file()) {
            return Err(format!(
                "downloaded binary was expected at '{}', but it was not found",
                binary_path
            ));
        }

        Ok(binary_path)
    }
}

impl zed::Extension for DotPromptExtension {
    fn new() -> Self {
        DotPromptExtension::new()
    }

    fn language_server_command(
        &mut self,
        language_server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> zed::Result<zed::Command> {
        let binary_path = self.language_server_binary_path(language_server_id, worktree)?;

        let server_url = std::env::var("DOT_PROMPT_SERVER_URL")
            .unwrap_or_else(|_| "http://localhost:4000".to_string());

        Ok(zed::Command {
            command: binary_path,
            args: vec![],
            env: vec![("DOT_PROMPT_SERVER_URL".to_string(), server_url)],
        })
    }

    fn language_server_workspace_configuration(
        &mut self,
        server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> zed::Result<Option<zed::serde_json::Value>> {
        let _ = (server_id, worktree);
        Ok(Some(zed::serde_json::json!({
            "dotPrompt": {
                "serverUrl": "http://localhost:4000"
            }
        })))
    }
}

zed::register_extension!(DotPromptExtension);
