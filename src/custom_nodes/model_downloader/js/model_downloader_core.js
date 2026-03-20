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
      row.innerHTML = `
        <div class="mdl-row-name" title="${filename}">${filename}</div>
        <div class="mdl-row-bar-bg"><div class="mdl-row-bar" style="width:0%"></div></div>
        <div class="mdl-row-info"><span class="mdl-pct">0%</span><span class="mdl-speed"></span></div>`;
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

  function checkAllDone() {
    if (!window.modelDownloader?.activeDownloads) return;
    const all = Object.values(window.modelDownloader.activeDownloads);
    if (all.length === 0) return;
    const done = all.every(d => d.status === 'completed' || d.status === 'error');
    if (done) {
      // Auto-hide panel after 8 seconds when all downloads finish
      setTimeout(() => {
        if (panelEl) panelEl.style.display = 'none';
      }, 8000);
    }
  }

  // ── Directory guessing from DOM ──────────────────────────────────────
  function guessDirectoryFromDom(filename) {
    const candidates = document.querySelectorAll('p[title]');
    for (const el of candidates) {
      if (el.title !== filename && !el.textContent.trim().startsWith(filename)) continue;
      let node = el.parentElement;
      for (let i = 0; i < 10 && node; i++) {
        const header = node.querySelector('.text-destructive-background-hover');
        if (header) {
          const match = header.textContent.trim().match(/^(\S+)/);
          if (match) return match[1];
        }
        node = node.parentElement;
      }
    }
    const headers = document.querySelectorAll('.text-destructive-background-hover');
    if (headers.length === 1) {
      const match = headers[0].textContent.trim().match(/^(\S+)/);
      if (match) return match[1];
    }
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

      if (messageData.status === 'completed' || messageData.status === 'error') {
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
        // Map server download ID to our tracking
        if (window.modelDownloader.activeDownloads[clientDownloadId]) {
          window.modelDownloader.activeDownloads[clientDownloadId].server_download_id = result.download_id;
        }
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
      if (window.modelDownloader.activeDownloads[clientDownloadId]) {
        window.modelDownloader.activeDownloads[clientDownloadId].status = 'error';
      }
      throw error;
    }
  }

  // ── Intercept browser-initiated model downloads ──────────────────────
  function interceptBrowserDownloads() {
    const originalClick = HTMLAnchorElement.prototype.click;

    HTMLAnchorElement.prototype.click = function() {
      if (this.download && this.href && !this.isConnected && isTrustedDomain(this.href)) {
        const url = this.href;
        const filename = this.download || url.split('/').pop() || 'model';
        const folder = guessDirectoryFromDom(filename);

        console.log('[MODEL_DOWNLOADER] Intercepted browser download:', { url, filename, folder });

        downloadModelWithBackend(url, folder, filename, null)
          .then(() => {
            console.log('[MODEL_DOWNLOADER] Backend download started for:', filename);
          })
          .catch(err => {
            console.error('[MODEL_DOWNLOADER] Backend download failed, falling back to browser:', err);
            originalClick.call(this);
          });
        return;
      }
      return originalClick.call(this);
    };

    console.log('[MODEL_DOWNLOADER] Browser download interception active');
  }

  function initialize() {
    interceptBrowserDownloads();
    return true;
  }

  // Expose to global scope
  window.modelDownloaderCore = {
    isTrustedDomain, downloadModelWithBackend, interceptBrowserDownloads,
    initialize, handleMessageEvent, getOrCreateRow, updateRow
  };

  if (!window.modelDownloader) {
    window.modelDownloader = { activeDownloads: {} };
  }
  Object.assign(window.modelDownloader, window.modelDownloaderCore);
})();
