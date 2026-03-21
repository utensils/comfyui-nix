// ComfyUI Model Downloader Frontend Patch
// This script initializes the model downloader core module

(function() {
  // Initialize the global modelDownloader object if it doesn't exist
  if (!window.modelDownloader) {
    window.modelDownloader = {
      activeDownloads: {}
    };
  }

  // Initialize if core is already loaded (ComfyUI loads all js/ files)
  if (window.modelDownloaderCoreLoaded && window.modelDownloader &&
      typeof window.modelDownloader.initialize === 'function') {
    console.log('[MODEL_DOWNLOADER] Core already loaded, initializing...');
    window.modelDownloader.initialize();
    return;
  }

  // Fallback: dynamically load core module if not already available
  function getBasePath() {
    const scripts = document.getElementsByTagName('script');
    for (const script of scripts) {
      if (script.src && script.src.includes('backend_download.js')) {
        return script.src.substring(0, script.src.lastIndexOf('/') + 1);
      }
    }
    for (const script of scripts) {
      if (script.src && script.src.includes('model_downloader')) {
        return script.src.substring(0, script.src.lastIndexOf('/') + 1);
      }
    }
    const urlObj = new URL(window.location.href);
    return `${urlObj.protocol}//${urlObj.host}/extensions/model_downloader/`;
  }

  const basePath = getBasePath();
  const script = document.createElement('script');
  script.type = 'text/javascript';
  script.src = basePath + 'model_downloader_core.js';
  script.onload = function() {
    if (window.modelDownloader && typeof window.modelDownloader.initialize === 'function') {
      console.log('[MODEL_DOWNLOADER] Initializing model downloader...');
      window.modelDownloader.initialize();
    } else {
      console.error('[MODEL_DOWNLOADER] Failed to initialize - core module not properly loaded');
    }
  };
  script.onerror = function(error) {
    console.error('[MODEL_DOWNLOADER] Error loading core script:', error);
  };
  document.head.appendChild(script);
})();
