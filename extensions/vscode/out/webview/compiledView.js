"use strict";
/**
 * Compiled View Webview Panel - displays compiled .prompt output
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.CompiledViewPanel = void 0;
const vscode = __importStar(require("vscode"));
const path = __importStar(require("path"));
const api = __importStar(require("../api/client"));
const extension_1 = require("../extension");
class CompiledViewPanel {
    /**
     * Create or show the compiled view panel
     */
    static createOrShow(extensionUri) {
        if (CompiledViewPanel.currentPanel) {
            (0, extension_1.log)('[CompiledView] Existing panel revealed');
            CompiledViewPanel.currentPanel.panel.reveal(vscode.ViewColumn.Two);
            return CompiledViewPanel.currentPanel;
        }
        (0, extension_1.log)('[CompiledView] Creating new panel');
        const panel = vscode.window.createWebviewPanel(CompiledViewPanel.viewType, 'Compiled View', vscode.ViewColumn.Two, {
            enableScripts: true,
            retainContextWhenHidden: true,
            localResourceRoots: [extensionUri]
        });
        CompiledViewPanel.currentPanel = new CompiledViewPanel(panel, extensionUri);
        return CompiledViewPanel.currentPanel;
    }
    /**
     * Update the current panel if it exists
     */
    static updateActivePanel(document) {
        if (CompiledViewPanel.currentPanel && document.languageId === 'dot-prompt') {
            (0, extension_1.log)(`[CompiledView] Updating for: ${path.basename(document.fileName)}`);
            if (CompiledViewPanel.currentPanel.currentDocument?.uri.toString() !== document.uri.toString()) {
                CompiledViewPanel.currentPanel.currentParams = {};
                CompiledViewPanel.currentPanel.currentSeed = undefined;
            }
            CompiledViewPanel.currentPanel.setDocument(document);
            CompiledViewPanel.currentPanel.compileAndDisplay();
        }
    }
    constructor(panel, extensionUri) {
        this.currentParams = {};
        this.panel = panel;
        this.extensionUri = extensionUri;
        this.panel.webview.html = this.getHtmlForWebview();
        this.panel.webview.onDidReceiveMessage(this.handleMessage.bind(this));
        this.panel.onDidDispose(() => {
            (0, extension_1.log)('[CompiledView] Panel disposed');
            CompiledViewPanel.currentPanel = undefined;
        });
        this.panel.onDidChangeViewState((e) => {
            if (e.webviewPanel.visible) {
                (0, extension_1.log)('[CompiledView] Panel became visible');
                const activeEditor = vscode.window.activeTextEditor;
                if (activeEditor && activeEditor.document.languageId === 'dot-prompt') {
                    this.setDocument(activeEditor.document);
                    this.compileAndDisplay();
                }
            }
        });
    }
    setDocument(document) {
        this.currentDocument = document;
        if (this.panel) {
            this.panel.title = `Compiled: ${path.basename(document.fileName)}`;
        }
    }
    async compileAndDisplay() {
        if (!this.currentDocument)
            return;
        const prompt = this.currentDocument.getText();
        const fileName = path.basename(this.currentDocument.fileName);
        (0, extension_1.log)(`[CompiledView] Fetching compilation for: ${fileName}`);
        try {
            this.showLoading();
            const result = await api.compile(prompt, this.currentParams, {
                seed: this.currentSeed,
                annotated: true
            });
            (0, extension_1.log)(`[CompiledView] API success: ${fileName}`);
            this.displayCompileResult(result);
        }
        catch (error) {
            const message = error.apiError?.message || error.message || 'Compilation failed';
            (0, extension_1.log)(`[CompiledView] API failure: ${message}`);
            this.showError(message);
        }
    }
    displayCompileResult(result) {
        if (!this.panel)
            return;
        // Create a clean copy to avoid circular reference issues
        const cleanData = JSON.parse(JSON.stringify({
            template: result.template,
            cache_hit: result.cache_hit,
            compiled_tokens: result.compiled_tokens,
            vary_selections: result.vary_selections,
            response_contract: result.response_contract,
            warnings: result.warnings,
            params: result.params,
            major: result.major,
            version: result.version,
            used_vars: result.used_vars
        }));
        this.panel.webview.postMessage({
            type: 'display',
            data: cleanData,
            currentParams: this.currentParams,
            currentSeed: this.currentSeed
        });
    }
    showLoading() {
        if (!this.panel)
            return;
        this.panel.webview.postMessage({ type: 'loading' });
    }
    showError(message) {
        if (!this.panel)
            return;
        this.panel.webview.postMessage({
            type: 'error',
            data: { message }
        });
    }
    async handleMessage(message) {
        (0, extension_1.log)(`[CompiledView] Received message: ${message.type}`);
        switch (message.type) {
            case 'ready':
                if (this.currentDocument)
                    await this.compileAndDisplay();
                break;
            case 'refresh':
                await this.compileAndDisplay();
                break;
            case 'updateParam':
                this.currentParams[message.key] = message.value;
                await this.compileAndDisplay();
                break;
            case 'updateListParam':
                {
                    const current = Array.isArray(this.currentParams[message.key]) ? [...this.currentParams[message.key]] : [];
                    if (message.checked) {
                        if (!current.includes(message.val))
                            current.push(message.val);
                    }
                    else {
                        const idx = current.indexOf(message.val);
                        if (idx !== -1)
                            current.splice(idx, 1);
                    }
                    this.currentParams[message.key] = current;
                    await this.compileAndDisplay();
                }
                break;
            case 'updateSeed':
                this.currentSeed = message.value;
                await this.compileAndDisplay();
                break;
            case 'resetParams':
                this.currentParams = {};
                this.currentSeed = undefined;
                await this.compileAndDisplay();
                break;
            case 'copy':
                await vscode.env.clipboard.writeText(message.data.text);
                vscode.window.showInformationMessage('Copied to clipboard');
                break;
        }
    }
    getHtmlForWebview() {
        return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Compiled View</title>
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <style>
    body { margin: 0; padding: 0; background: #1e1e1e; color: #d4d4d4; font-family: -apple-system, sans-serif; font-size: 13px; display: flex; flex-direction: column; height: 100vh; overflow: hidden; }
    .toolbar { display: flex; align-items: center; gap: 12px; padding: 8px 16px; background: #252526; border-bottom: 1px solid #3c3c3c; flex-shrink: 0; }
    .toolbar button { background: #0e639c; color: #fff; border: none; padding: 4px 12px; border-radius: 2px; cursor: pointer; font-size: 12px; }
    .toolbar button:hover { background: #1177bb; }
    .toolbar button.secondary { background: #3c3c3c; color: #ccc; }
    .status { margin-left: auto; display: flex; align-items: center; gap: 12px; font-size: 11px; }
    .token-count { color: #9cdcfe; font-weight: bold; }
    .cache-status { padding: 2px 6px; border-radius: 2px; }
    .cache-hit { background: rgba(78, 201, 176, 0.2); color: #4ec9b0; }
    .cache-miss { background: rgba(220, 220, 170, 0.2); color: #dcdcaa; }
    
    .main-container { display: flex; flex: 1; overflow: hidden; }
    .sidebar { width: 300px; background: #252526; border-right: 1px solid #3c3c3c; overflow-y: auto; padding: 16px; flex-shrink: 0; }
    .sidebar-section { margin-bottom: 24px; }
    .sidebar-header { font-weight: bold; margin-bottom: 12px; color: #ccc; text-transform: uppercase; font-size: 11px; border-bottom: 1px solid #333; padding-bottom: 4px; display: flex; justify-content: space-between; }
    
    .param-item { margin-bottom: 16px; }
    .param-item.vary-param { background: rgba(180, 120, 255, 0.08); padding: 8px; border-radius: 4px; border-left: 3px solid #c586c0; }
    .param-label { display: block; margin-bottom: 6px; font-weight: 500; color: #9cdcfe; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .param-doc { font-size: 11px; color: #858585; margin-top: 6px; display: block; line-height: 1.3; }
    .param-input { width: 100%; background: #3c3c3c; color: #ccc; border: 1px solid #3c3c3c; padding: 6px 10px; border-radius: 2px; box-sizing: border-box; font-size: 12px; font-family: inherit; }
    .param-input:focus { border-color: #0e639c; outline: none; }
    
    .range-container { display: flex; align-items: center; gap: 10px; }
    .range-value { min-width: 24px; text-align: right; color: #ce9178; font-family: monospace; }
    
    .content { flex: 1; padding: 16px; overflow-y: auto; background: #1e1e1e; }
    .section { margin-bottom: 16px; border: 1px solid #3c3c3c; border-radius: 4px; overflow: hidden; }
    .section-header { background: #252526; padding: 8px 12px; border-bottom: 1px solid #3c3c3c; font-weight: bold; display: flex; justify-content: space-between; align-items: center; }
    .section-header button { background: transparent; border: 1px solid #3c3c3c; color: #ccc; padding: 2px 8px; font-size: 10px; cursor: pointer; }
    .section-content { padding: 12px; font-size: 12px; line-height: 1.5; }
    .section-content pre { background: #0d1117; padding: 12px; border-radius: 4px; overflow-x: auto; border: 1px solid #30363d; margin: 8px 0; }
    .section-content code { font-family: 'Consolas', monospace; color: #ce9178; background: rgba(255,255,255,0.05); padding: 2px 4px; border-radius: 3px; }
    
    .param-item.inactive { opacity: 0.4; filter: grayscale(100%); pointer-events: none; }
    .param-item.inactive label { color: #858585; }
    
    .loading-spinner { display: none; width: 14px; height: 14px; border: 2px solid rgba(255,255,255,0.1); border-top-color: #0e639c; border-radius: 50%; animation: spin 0.8s linear infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }
    
    .error { padding: 16px; color: #f14c4c; background: rgba(241, 76, 76, 0.1); border: 1px solid #f14c4c; border-radius: 4px; }
    .contract pre { margin: 0; color: #9cdcfe; font-size: 11px; }
    
    .badge { padding: 2px 6px; border-radius: 10px; background: #333; color: #aaa; font-size: 10px; font-weight: normal; }
    .badge.vary { background: rgba(180, 120, 255, 0.25); color: #c586c0; font-weight: bold; border: 1px solid rgba(180, 120, 255, 0.4); }
    .vary-value { font-size: 10px; color: #c586c0; margin-top: 4px; display: block; font-style: italic; }

    /* Highlighted Sections */
    .msec { border: 1px solid #333; border-radius: 4px; margin: 8px 0; background: rgba(255,255,255,0.02); overflow: hidden; }
    .msec-label { background: #252526; padding: 4px 10px; font-size: 10px; color: #858585; border-bottom: 1px solid #333; cursor: pointer; display: flex; justify-content: space-between; align-items: center; font-weight: bold; text-transform: uppercase; letter-spacing: 0.5px; }
    .msec-label:hover { background: #2d2d2d; color: #ccc; }
    .msec-content { padding: 10px; }
    .msec-content.collapsed { display: none; }
    .msec-chev { transition: transform 0.2s; font-size: 12px; }
    .msec-chev.open { transform: rotate(90deg); }
    
    .ab-gr { border-color: rgba(78, 201, 176, 0.3); }
    .ab-gr > .msec-label { color: #4ec9b0; border-bottom-color: rgba(78, 201, 176, 0.3); }
    .ab-bl { border-color: rgba(156, 220, 254, 0.3); }
    .ab-bl > .msec-label { color: #9cdcfe; border-bottom-color: rgba(156, 220, 254, 0.3); }
    .ab-pu { border-color: rgba(197, 134, 192, 0.3); }
    .ab-pu > .msec-label { color: #c586c0; border-bottom-color: rgba(197, 134, 192, 0.3); }
    .ab-mu { border-color: rgba(133, 133, 133, 0.3); }
    .ab-mu > .msec-label { color: #858585; border-bottom-color: rgba(133, 133, 133, 0.3); }

    .pv { color: #4ec9b0; font-weight: bold; border-bottom: 1px dashed rgba(78, 201, 176, 0.4); cursor: help; }
    .rtv { color: #ce9178; font-weight: bold; }
    .va { color: #c586c0; font-style: italic; border-bottom: 1px dashed rgba(197, 134, 192, 0.4); cursor: help; }
    
    ::-webkit-scrollbar { width: 10px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: #3c3c3c; }
    ::-webkit-scrollbar-thumb:hover { background: #454545; }
  </style>
</head>
<body>
  <div class="toolbar">
    <button id="refresh-btn">↻ Refresh</button>
    <button id="reset-btn" class="secondary">Reset All</button>
    <div class="loading-spinner" id="loader"></div>
    <div class="status">
      <span class="token-count" id="tokens"></span>
      <span id="cache"></span>
    </div>
  </div>
  
  <div class="main-container">
    <div class="sidebar">
      <div class="sidebar-section">
        <div class="sidebar-header">Prompt Info</div>
        <div style="display: flex; flex-direction: column; gap: 8px;">
          <div style="display: flex; justify-content: space-between; font-size: 12px;">
            <span style="color: #858585;">Major Version:</span>
            <span id="info-major" style="color: #9cdcfe; font-weight: bold;">-</span>
          </div>
          <div style="display: flex; justify-content: space-between; font-size: 12px;">
            <span style="color: #858585;">Revision:</span>
            <span id="info-version" style="color: #9cdcfe;">-</span>
          </div>
          <div class="param-item" style="margin-top: 4px; padding-top: 8px; border-top: 1px solid #333;">
            <label class="param-label" style="font-size: 11px; color: #858585;">Global Seed</label>
            <input type="number" class="param-input" id="seed-input" placeholder="Random" style="padding: 4px 8px; height: 24px;" onchange="vscode.postMessage({type:'updateSeed', value: this.value ? parseInt(this.value, 10) : undefined})">
          </div>
        </div>
      </div>
      
      <div class="sidebar-section">
        <div class="sidebar-header">Parameters</div>
        <div id="params-list"></div>
      </div>
    </div>
    
    <div class="content" id="main">
      <div class="empty-state">Select a .prompt file to see the compiled output</div>
    </div>
  </div>

  <script>
    (function() {
      const vscode = acquireVsCodeApi();
      const main = document.getElementById('main');
      const loader = document.getElementById('loader');
      const paramsList = document.getElementById('params-list');
      
      document.getElementById('refresh-btn').onclick = () => vscode.postMessage({ type: 'refresh' });
      document.getElementById('reset-btn').onclick = () => {
        document.getElementById('seed-input').value = '';
        vscode.postMessage({ type: 'resetParams' });
      };

      window.addEventListener('message', event => {
        const msg = event.data;
        if (msg.type === 'loading') loader.style.display = 'inline-block';
        else if (msg.type === 'error') {
          loader.style.display = 'none';
          main.innerHTML = '<div class="error"><b>Error:</b><br>' + escapeHtml(msg.data.message) + '</div>';
        } else if (msg.type === 'display') {
          loader.style.display = 'none';
          document.getElementById('seed-input').value = msg.currentSeed || '';
          document.getElementById('info-major').textContent = msg.data.major || '1';
          document.getElementById('info-version').textContent = msg.data.version || '1';
          
          const usedVars = msg.data.used_vars || [];
          renderParams(msg.data.params, msg.data.vary_selections, msg.currentParams, usedVars);
          renderContent(msg.data);
        }
      });

      function renderParams(params, varySelections, current, usedVars) {
        if (!params || Object.keys(params).length === 0) {
          paramsList.innerHTML = '<div style="color:#666; font-size:11px; font-style:italic;">No parameters defined</div>';
          return;
        }
        let html = '';
        const varyNames = varySelections ? Object.keys(varySelections) : [];

        for (const [key, meta] of Object.entries(params)) {
          const cleanKey = key.startsWith('@') ? key.substring(1) : key;
          const isVary = varyNames.includes(cleanKey) || varyNames.includes(key);
          const varyData = isVary ? (varySelections[cleanKey] || varySelections[key]) : null;
          const selectedId = varyData ? (typeof varyData === 'object' ? varyData.id : varyData) : null;
          // For vary params, use the selectedId as the value if no explicit current value
          const value = current[key] !== undefined ? current[key] : (selectedId !== null ? selectedId : (meta.default !== undefined ? meta.default : ''));
          
          const isUsed = usedVars.length === 0 || usedVars.includes(cleanKey) || usedVars.includes(key);
          const isInactive = usedVars.length > 0 && !isUsed;
          const inactiveClass = isInactive ? ' inactive' : '';
          
          html += '<div class="param-item' + (isVary ? ' vary-param' : '') + inactiveClass + '"><label class="param-label">';
          if (isInactive) {
            html += '👻 ';
          }
          html += key;
          if (isVary) {
             html += ' <span class="badge vary" title="Vary selection: ' + selectedId + '">vary</span>';
             if (selectedId) {
               html += '<span class="vary-value">→ ' + selectedId + '</span>';
             }
          }
          html += '</label>';
          
          if (meta.type === 'enum' && meta.values) {
            html += '<select class="param-input" onchange="up(\\''+key+'\\',this.value,\\'str\\')">';
            html += '<option value="">Select...</option>';
            meta.values.forEach(v => html += '<option value="'+v+'" '+(String(v)===String(value)?'selected':'')+'>'+v+'</option>');
            html += '</select>';
          } else if (meta.type === 'bool') {
            html += '<select class="param-input" onchange="up(\\''+key+'\\',this.value === \\'true\\',\\'bool\\')">';
            html += '<option value="true" '+(String(value)==='true'?'selected':'')+'>True</option>';
            html += '<option value="false" '+(String(value)==='false'?'selected':'')+'>False</option>';
            html += '</select>';
          } else if (meta.type === 'list' && meta.values) {
            const selectedValues = Array.isArray(value) ? value.map(String) : [];
            html += '<div class="list-multi-select" style="background:#3c3c3c; padding:4px; border-radius:2px; max-height: 120px; overflow-y: auto; border: 1px solid #3c3c3c;">';
            meta.values.forEach(v => {
              const isChecked = selectedValues.includes(String(v));
              html += '<label style="display:flex; align-items:center; gap:6px; padding:2px 4px; cursor:pointer; font-size:11px;">';
              html += '<input type="checkbox" '+(isChecked?'checked':'')+' onchange="upList(\\''+key+'\\',\\''+v+'\\',this.checked)">';
              html += '<span>'+v+'</span></label>';
            });
            html += '</div>';
          } else if (meta.type === 'int' && meta.range) {
            const min = meta.range[0];
            const max = meta.range[1];
            // If the range is small (<= 20), use a dropdown, otherwise use a slider
            if (max - min <= 20) {
              html += '<select class="param-input" onchange="up(\\''+key+'\\',this.value,\\'int\\')">';
              for (let i = min; i <= max; i++) {
                html += '<option value="'+i+'" '+(parseInt(value, 10)===i?'selected':'')+'>'+i+'</option>';
              }
              html += '</select>';
            } else {
              html += '<div class="range-container"><input type="range" class="param-input" min="'+min+'" max="'+max+'" value="'+value+'" oninput="this.nextElementSibling.innerText=this.value" onchange="up(\\''+key+'\\',this.value,\\'int\\')"><span class="range-value">'+value+'</span></div>';
            }
          } else if (meta.type === 'int') {
            html += '<input type="number" class="param-input" value="'+value+'" onchange="up(\\''+key+'\\',this.value,\\'int\\')">';
          } else {
            const displayValue = Array.isArray(value) ? value.join(', ') : value;
            html += '<input type="text" class="param-input" value="'+displayValue+'" onchange="up(\\''+key+'\\',this.value,\\''+(meta.type==='list'?'list':'str')+'\\')">';
          }
          if (meta.doc) html += '<span class="param-doc">' + meta.doc + '</span>';
          html += '</div>';
        }
        paramsList.innerHTML = html;
      }

      window.upList = (key, val, checked) => {
        vscode.postMessage({ type: 'updateListParam', key, val, checked });
      };

      window.up = (key, val, type) => {
        let v = val;
        if (type === 'int') v = parseInt(val, 10);
        if (type === 'list') v = val.split(',').map(x => x.trim()).filter(x => x);
        vscode.postMessage({ type: 'updateParam', key, value: v });
      };

      function renderContent(data) {
        document.getElementById('tokens').textContent = (data.compiled_tokens || 0) + ' tokens';
        const cs = document.getElementById('cache');
        cs.textContent = data.cache_hit ? '✓ Cached' : '✗ Miss';
        cs.className = 'cache-status ' + (data.cache_hit ? 'cache-hit' : 'cache-miss');

        const template = data.template || '';
        const highlighted = parseAndRenderSections(template, data.vary_selections || {});
        
        let html = '<div class="section"><div class="section-header">Compiled Prompt <button onclick="copy(this)">Copy</button></div><div class="section-content" id="prompt-content">' + highlighted + '</div></div>';
        
        if (data.response_contract) {
          html += '<div class="section"><div class="section-header">Response Contract <button onclick="copy(this)">Copy</button></div><div class="section-content"><pre>' + escapeHtml(JSON.stringify(data.response_contract, null, 2)) + '</pre></div></div>';
        }
        main.innerHTML = html;
      }

      function parseAndRenderSections(text, varySelections) {
        const lines = text.split('\\n');
        return splitIntoSections(lines, varySelections);
      }

      function splitIntoSections(lines, varySelections) {
        let result = '';
        let i = 0;
        
        while (i < lines.length) {
          const line = lines[i];
          if (line.trim().startsWith('[[section:')) {
            const header = parseSectionHeader(line);
            const { content, nextIdx } = extractSectionContent(lines, i + 1);
            result += renderSection(header, content, varySelections);
            i = nextIdx;
          } else {
            let textBlock = '';
            while (i < lines.length && !lines[i].trim().startsWith('[[section:')) {
              textBlock += lines[i] + '\\n';
              i++;
            }
            result += renderMarkdown(textBlock, varySelections);
          }
        }
        return result;
      }

      function extractSectionContent(lines, startIdx) {
        const content = [];
        let depth = 0;
        let i = startIdx;
        
        while (i < lines.length) {
          const line = lines[i].trim();
          if (line.startsWith('[[section:')) {
            depth++;
          } else if (line === '[[/section]]') {
            if (depth === 0) {
              return { content, nextIdx: i + 1 };
            }
            depth--;
          }
          content.push(lines[i]);
          i++;
        }
        return { content, nextIdx: i };
      }

      function parseSectionHeader(line) {
        const match = line.match(/\\[\\[section:([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^\\]]*)\\]\\]/);
        if (match) {
          return {
            type: match[1],
            indent: parseInt(match[2], 10),
            id: match[3],
            varName: match[4],
            optionsStr: match[5],
            label: match[6].replace(']]', '')
          };
        }
        return null;
      }

      function renderSection(header, contentLines, varySelections) {
        if (!header) return '';
        
        const isCollapsed = false; // We can add state for this later
        const indentPx = header.indent * 20;
        
        let colorClass = 'ab-mu';
        switch (header.type) {
          case 'branch': case 'case': colorClass = 'ab-gr'; break;
          case 'frag': colorClass = 'ab-bl'; break;
          case 'vary': colorClass = 'ab-pu'; break;
        }
        
        let label = header.label;
        if (header.type === 'vary') {
          const selection = varySelections[label];
          const selectionId = selection ? (typeof selection === 'object' ? selection.id : selection) : '?';
          label = label + ' → ' + selectionId;
        }
        
        const content = splitIntoSections(contentLines, varySelections);
        
        return \`
          <div class="msec \${colorClass}" style="margin-left: \${indentPx}px;">
            <div class="msec-label" onclick="this.nextElementSibling.classList.toggle('collapsed'); this.querySelector('.msec-chev').classList.toggle('open')">
              <span>\${label}</span>
              <span class="msec-chev open">›</span>
            </div>
            <div class="msec-content \${isCollapsed ? 'collapsed' : ''}">
              \${content}
            </div>
          </div>
        \`;
      }

      function renderMarkdown(text, varySelections) {
        if (!text.trim()) return '';
        
        // Handle vary tags [[vary:"name"]]
        let processed = text.replace(/\\[\\[vary:(?:"|&quot;|”|“)(.*?)(?:"|&quot;|”|“)\\]\\]/g, (match, name) => {
          const selection = varySelections[name];
          if (selection && typeof selection === 'object') {
            return \`<span class="va" title="Variant: \${selection.id}">\${selection.text}</span>\`;
          }
          return \`<span class="va">[\${selection || 'slot'}]</span>\`;
        });
        
        // Use marked for MD rendering
        return marked.parse(processed);
      }

      window.copy = (btn) => {
        const text = btn.parentElement.nextElementSibling.innerText;
        vscode.postMessage({ type: 'copy', data: { text } });
      };

      function escapeHtml(t) {
        return t ? t.toString().replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;") : '';
      }
      vscode.postMessage({ type: 'ready' });
    })();
  </script>
</body>
</html>`;
    }
}
exports.CompiledViewPanel = CompiledViewPanel;
CompiledViewPanel.viewType = 'dotPromptCompiled';
//# sourceMappingURL=compiledView.js.map