// Model Downloader Core Functionality
// This file contains the core functionality for downloading models

(function() {
  // Check if this module is already loaded
  if (window.modelDownloaderCoreLoaded) {
    if (typeof window.modelDownloader?.interceptBrowserDownloads === 'function') {
      console.log('[MODEL_DOWNLOADER] Core already loaded');
      return;
    }
  }
  window.modelDownloaderCoreLoaded = true;
  console.log('[MODEL_DOWNLOADER] Loading core functionality');

  // List of trusted domains for model downloads
  const trustedDomains = [
    'huggingface.co',
    'civitai.com',
    'github.com',
    'cdn.discordapp.com',
    'pixeldrain.com',
    'replicate.delivery'
  ];

  function isTrustedDomain(url) {
    try {
      const urlObj = new URL(url);
      return trustedDomains.some(domain => urlObj.hostname === domain || urlObj.hostname.endsWith('.' + domain));
    } catch (e) {
      return false;
    }
  }

  // ── Floating progress panel ──────────────────────────────────────────
  let panelEl = null;
  let panelBodyEl = null;

  function ensurePanel() {
    if (panelEl) return;

    // Inject CSS once
    if (!document.getElementById('mdl-panel-style')) {
      const css = document.createElement('style');
      css.id = 'mdl-panel-style';
      css.textContent = `
        #mdl-panel {
          position: fixed; bottom: 16px; right: 16px; z-index: 99999;
          width: 380px; max-height: 50vh; overflow: hidden;
          background: #1e1e2e; border: 1px solid #444; border-radius: 10px;
          box-shadow: 0 8px 32px rgba(0,0,0,.5); font-family: system-ui, sans-serif;
          display: flex; flex-direction: column; color: #cdd6f4;
        }
        #mdl-panel-header {
          display: flex; align-items: center; justify-content: space-between;
          padding: 10px 14px; border-bottom: 1px solid #333; flex-shrink: 0;
        }
        #mdl-panel-header span { font-size: 13px; font-weight: 600; }
        #mdl-panel-close {
          background: none; border: none; color: #888; cursor: pointer;
          font-size: 18px; line-height: 1; padding: 0 4px;
        }
        #mdl-panel-close:hover { color: #cdd6f4; }
        #mdl-panel-body {
          overflow-y: auto; padding: 8px 14px 12px; flex: 1;
        }
        .mdl-row {
          display: flex; flex-direction: column; gap: 4px;
          padding: 8px 0; border-bottom: 1px solid #333;
        }
        .mdl-row:last-child { border-bottom: none; }
        .mdl-row-name {
          font-size: 12px; font-weight: 500; white-space: nowrap;
          overflow: hidden; text-overflow: ellipsis; color: #cdd6f4;
        }
        .mdl-row-bar-bg {
          height: 6px; border-radius: 3px; background: #313244; overflow: hidden;
        }
        .mdl-row-bar {
          height: 100%; border-radius: 3px; background: #89b4fa;
          transition: width .3s ease;
        }
        .mdl-row-bar.done { background: #a6e3a1; }
        .mdl-row-bar.fail { background: #f38ba8; }
        .mdl-row-info {
          display: flex; justify-content: space-between;
          font-size: 11px; color: #888;
        }
      `;
      document.head.appendChild(css);
    }

    panelEl = document.createElement('div');
    panelEl.id = 'mdl-panel';
    panelEl.innerHTML = `
      <div id="mdl-panel-header">
        <span>Model Downloads</span>
        <button id="mdl-panel-close" title="Minimize">&minus;</button>
      </div>
      <div id="mdl-panel-body"></div>`;
    document.body.appendChild(panelEl);
    panelBodyEl = panelEl.querySelector('#mdl-panel-body');
    panelEl.querySelector('#mdl-panel-close').addEventListener('click', () => {
      panelEl.style.display = 'none';
    });
  }

  function getOrCreateRow(downloadId, filename) {
    ensurePanel();
    panelEl.style.display = '';
    let row = panelBodyEl.querySelector(`[data-dl-id="${downloadId}"]`);
    if (!row) {
      row = document.createElement('div');
      row.className = 'mdl-row';
      row.setAttribute('data-dl-id', downloadId);
      const nameEl = document.createElement('div');
      nameEl.className = 'mdl-row-name';
      nameEl.setAttribute('title', filename);
      nameEl.textContent = filename;
      row.appendChild(nameEl);
      row.insertAdjacentHTML('beforeend',
        '<div class="mdl-row-bar-bg"><div class="mdl-row-bar" style="width:0%"></div></div>' +
        '<div class="mdl-row-info"><span class="mdl-pct">0%</span><span class="mdl-speed"></span></div>');
      panelBodyEl.appendChild(row);
    }
    return row;
  }

  function updateRow(downloadId, data) {
    const row = panelBodyEl?.querySelector(`[data-dl-id="${downloadId}"]`);
    if (!row) return;
    const bar = row.querySelector('.mdl-row-bar');
    const pctEl = row.querySelector('.mdl-pct');
    const speedEl = row.querySelector('.mdl-speed');

    if (data.status === 'completed') {
      bar.style.width = '100%';
      bar.classList.add('done');
      pctEl.textContent = 'Complete';
      speedEl.textContent = '';
    } else if (data.status === 'skipped') {
      bar.style.width = '100%';
      bar.classList.add('done');
      pctEl.textContent = 'Already exists';
      speedEl.textContent = 'Skipped';
    } else if (data.status === 'error') {
      bar.classList.add('fail');
      pctEl.textContent = 'Failed';
      speedEl.textContent = data.error || '';
    } else {
      const pct = Math.round(data.percent || 0);
      bar.style.width = pct + '%';
      pctEl.textContent = pct + '%';
      speedEl.textContent = data.speed ? (data.speed + ' MB/s') : '';
    }
  }

  let autoHideTimer = null;

  function checkAllDone() {
    if (!window.modelDownloader?.activeDownloads) return;
    const all = Object.values(window.modelDownloader.activeDownloads);
    if (all.length === 0) return;
    const done = all.every(d => d.status === 'completed' || d.status === 'skipped' || d.status === 'error');
    if (done && !autoHideTimer) {
      autoHideTimer = setTimeout(() => {
        if (panelEl) panelEl.style.display = 'none';
        autoHideTimer = null;
      }, 8000);
    }
  }

  // ── Directory detection ───────────────────────────────────────────────
  // ComfyUI folder_paths directory names that map to model types
  const KNOWN_DIRS = new Set([
    'checkpoints', 'classifiers', 'clip', 'clip_vision', 'configs',
    'controlnet', 'diffusers', 'diffusion_models', 'embeddings', 'gligen',
    'hypernetworks', 'loras', 'mmdets', 'photomaker', 'style_models',
    't2i_adapter', 'text_encoders', 'unet', 'upscale_models', 'vae',
    'vae_approx'
  ]);

  // Proactive cache: filename → directory, populated by observing the Missing Models panel
  const dirCache = {};

  // Scan the DOM for the Missing Models panel and build filename → directory mappings.
  // The panel groups models under category headers like "loras (1)".
  // Each model row has a <p title="filename.safetensors"> element.
  function scanMissingModelsPanel() {
    // Find all elements whose direct text matches "dirname (N)" pattern
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    let textNode;
    let currentDir = '';
    const headerElements = [];

    // First pass: find all category headers
    while ((textNode = walker.nextNode())) {
      const text = textNode.textContent.trim();
      const match = text.match(/^(\w+)\s*\(\d+\)$/);
      if (match && KNOWN_DIRS.has(match[1])) {
        headerElements.push({ dir: match[1], element: textNode.parentElement });
      }
    }

    // Second pass: for each header, find model names in its section
    for (const header of headerElements) {
      // Walk up until we find a container that holds model name elements
      let container = header.element.parentElement;
      while (container && container !== document.body) {
        if (container.querySelectorAll('p[title]').length > 0) break;
        container = container.parentElement;
      }
      if (!container || container === document.body) continue;

      // Find all p[title] elements within this container - these have model filenames
      const modelNames = container.querySelectorAll('p[title]');
      for (const p of modelNames) {
        const name = p.getAttribute('title');
        if (name && name.includes('.')) {
          dirCache[name] = header.dir;
        }
      }

      // Also check text content for filenames (backup)
      const allText = container.textContent;
      // Look for .safetensors, .ckpt, .pt, .bin filenames
      const fileMatches = allText.match(/[\w\-\.]+\.(?:safetensors|ckpt|pt|bin|pth|onnx)/g);
      if (fileMatches) {
        for (const fname of fileMatches) {
          if (!dirCache[fname]) {
            dirCache[fname] = header.dir;
          }
        }
      }
    }

    if (Object.keys(dirCache).length > 0) {
      console.log('[MODEL_DOWNLOADER] Cached directory map:', { ...dirCache });
    }
  }

  // Set up a MutationObserver to detect the Missing Models panel appearing
  function observeMissingModelsPanel() {
    let scanned = false;
    const observer = new MutationObserver(() => {
      // Look for "Missing Models" text appearing in the DOM
      if (!scanned && document.body.textContent.includes('Missing Models')) {
        scanMissingModelsPanel();
        scanned = true;
        observer.disconnect();
      }
    });
    observer.observe(document.body, { childList: true, subtree: true });

    // Also scan periodically as fallback
    const interval = setInterval(() => {
      if (document.body.textContent.includes('Missing Models')) {
        scanMissingModelsPanel();
        if (Object.keys(dirCache).length > 0) {
          clearInterval(interval);
        }
      }
    }, 2000);

    // Stop polling after 60 seconds
    setTimeout(() => clearInterval(interval), 60000);
  }

  // Guess the ComfyUI model directory from the download URL path segments
  function guessDirectoryFromUrl(url) {
    try {
      const segments = new URL(url).pathname.toLowerCase().split('/');
      for (const seg of segments) {
        if (KNOWN_DIRS.has(seg)) return seg;
      }
      // Common aliases
      for (const seg of segments) {
        if (seg === 'lora') return 'loras';
        if (seg === 'embedding') return 'embeddings';
        if (seg === 'checkpoint') return 'checkpoints';
      }
    } catch (e) { /* ignore */ }
    return '';
  }

  // Ask the backend to resolve which folder a filename belongs to
  async function resolveDirectoryFromBackend(filename) {
    try {
      const resp = await fetch(`/model-downloader/resolve-folder/${encodeURIComponent(filename)}`);
      if (resp.ok) {
        const data = await resp.json();
        if (data.success && data.folder) {
          console.log('[MODEL_DOWNLOADER] Backend resolved folder:', data.folder, 'for', filename);
          dirCache[filename] = data.folder;
          return data.folder;
        }
      }
    } catch (e) {
      console.warn('[MODEL_DOWNLOADER] Backend resolve-folder failed:', e);
    }
    return '';
  }

  // Combined directory detection: backend API first, cache second, URL third, default last
  async function detectDirectory(url, filename) {
    // 1. Check proactive cache (built from Missing Models panel or previous API calls)
    if (dirCache[filename]) return dirCache[filename];
    // 2. Ask the backend (searches all folder_paths for existing files)
    const fromBackend = await resolveDirectoryFromBackend(filename);
    if (fromBackend) return fromBackend;
    // 3. Parse URL path for known directory names
    const fromUrl = guessDirectoryFromUrl(url);
    if (fromUrl) return fromUrl;
    // 4. Try rescanning the DOM (legacy fallback)
    scanMissingModelsPanel();
    if (dirCache[filename]) return dirCache[filename];
    // 5. Default
    return 'checkpoints';
  }

  // ── WebSocket message handler ────────────────────────────────────────
  function handleMessageEvent(event) {
    try {
      let messageData = event.data || event;
      if (messageData && messageData.type === 'model_download_progress' && messageData.data) {
        messageData = messageData.data;
      }
      if (messageData && messageData.detail) {
        messageData = messageData.detail.data || messageData.detail;
      }

      if (!messageData || !messageData.download_id || !window.modelDownloader) return;

      const downloads = window.modelDownloader.activeDownloads || {};
      let downloadData = downloads[messageData.download_id];
      if (!downloadData) {
        Object.values(downloads).forEach(d => {
          if (d.server_download_id === messageData.download_id) downloadData = d;
        });
      }

      if (downloadData) {
        Object.assign(downloadData, {
          percent: messageData.percent || 0,
          speed: messageData.speed || 0,
          status: messageData.status || 'downloading',
          error: messageData.error || null
        });
      }

      // Update the progress panel row
      updateRow(messageData.download_id, messageData);

      if (messageData.status === 'completed' || messageData.status === 'skipped' || messageData.status === 'error') {
        if (downloadData) downloadData.status = messageData.status;
        if (!window.modelDownloader.completedDownloads) {
          window.modelDownloader.completedDownloads = {};
        }
        window.modelDownloader.completedDownloads[messageData.download_id] = messageData;
        checkAllDone();
      }
    } catch (error) {
      console.error('[MODEL_DOWNLOADER] Error handling message event:', error);
    }
  }

  // ── Backend download API ─────────────────────────────────────────────
  async function downloadModelWithBackend(url, folder, filename, button) {
    const clientDownloadId = `${folder}_${filename}_${Date.now()}`;

    // Create the progress panel row immediately
    getOrCreateRow(clientDownloadId, filename);

    if (!window.modelDownloader) window.modelDownloader = {};
    if (!window.modelDownloader.activeDownloads) window.modelDownloader.activeDownloads = {};
    if (!window.modelDownloader.completedDownloads) window.modelDownloader.completedDownloads = {};

    window.modelDownloader.activeDownloads[clientDownloadId] = {
      button: button,
      url: url,
      folder: folder,
      filename: filename,
      status: 'downloading'
    };

    try {
      const jsonData = { url, folder, filename };
      console.log('[MODEL_DOWNLOADER] Sending download request:', jsonData);

      const response = await fetch('/model-downloader/download', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(jsonData)
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Server responded with ${response.status}: ${errorText}`);
      }

      const result = await response.json();

      if (result.success) {
        // Replace client ID entry with server ID entry to avoid stale duplicates
        // that prevent checkAllDone() from detecting completion
        delete window.modelDownloader.activeDownloads[clientDownloadId];
        window.modelDownloader.activeDownloads[result.download_id] = {
          button: button, url, folder, filename,
          status: 'downloading',
          client_id: clientDownloadId
        };

        // Also update the panel row's data-dl-id to match the server ID
        // so WebSocket updates find it
        const row = panelBodyEl?.querySelector(`[data-dl-id="${clientDownloadId}"]`);
        if (row) row.setAttribute('data-dl-id', result.download_id);

        return result;
      } else if (result.error) {
        throw new Error(result.error);
      }
      return result;
    } catch (error) {
      console.error('[MODEL_DOWNLOADER] Download request failed:', error.message);
      updateRow(clientDownloadId, { status: 'error', error: error.message });
      // Entry may have been deleted after server ID mapping; update whichever exists
      const entry = window.modelDownloader.activeDownloads[clientDownloadId] ||
        Object.values(window.modelDownloader.activeDownloads).find(d => d.client_id === clientDownloadId);
      if (entry) {
        entry.status = 'error';
      }
      throw error;
    }
  }

  // ── Intercept browser-initiated model downloads ──────────────────────
  function interceptBrowserDownloads() {
    if (HTMLAnchorElement.prototype.click._mdlPatched) return;
    const originalClick = HTMLAnchorElement.prototype.click;

    HTMLAnchorElement.prototype.click = function() {
      if (this.download && this.href && !this.isConnected && isTrustedDomain(this.href)) {
        const url = this.href;
        const filename = this.download || url.split('/').pop() || 'model';
        const self = this;

        detectDirectory(url, filename)
          .then(folder => {
            console.log('[MODEL_DOWNLOADER] Intercepted browser download:', { url, filename, folder });
            return downloadModelWithBackend(url, folder, filename, null);
          })
          .then(() => {
            console.log('[MODEL_DOWNLOADER] Backend download started for:', filename);
          })
          .catch(err => {
            console.error('[MODEL_DOWNLOADER] Backend download failed, falling back to browser:', err);
            originalClick.call(self);
          });
        return;
      }
      return originalClick.call(this);
    };
    HTMLAnchorElement.prototype.click._mdlPatched = true;

    console.log('[MODEL_DOWNLOADER] Browser download interception active');
  }

  function initialize() {
    interceptBrowserDownloads();
    observeMissingModelsPanel();
    return true;
  }

  // Expose to global scope
  window.modelDownloaderCore = {
    isTrustedDomain, downloadModelWithBackend, interceptBrowserDownloads,
    initialize, handleMessageEvent, getOrCreateRow, updateRow,
    scanMissingModelsPanel, detectDirectory, resolveDirectoryFromBackend, dirCache
  };

  if (!window.modelDownloader) {
    window.modelDownloader = { activeDownloads: {} };
  }
  Object.assign(window.modelDownloader, window.modelDownloaderCore);
})();
