// ComfyUI Model Downloader Extension
// Only log initialization message in non-production environments
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    console.log("[MODEL_DOWNLOADER] Loading model downloader extension...");
}

// Forward a progress event to the core module, if it has loaded.
function forwardProgress(event) {
    if (window.modelDownloader && typeof window.modelDownloader.handleMessageEvent === 'function') {
        window.modelDownloader.handleMessageEvent(event);
    }
}

// Resolve ComfyUI's API client. Current frontends expose it as
// window.comfyAPI.api.api (and app.api); window.api is legacy.
function getComfyApi() {
    return window.comfyAPI?.api?.api || window.app?.api || window.api || null;
}

// Register message handler as early as possible
function registerMessageHandler() {
    try {
        // Preferred: subscribe through the API client. This delivers each
        // model_download_progress message as a CustomEvent and registers the
        // type, so the frontend no longer logs "Unknown message type".
        const comfyApi = getComfyApi();
        if (comfyApi && typeof comfyApi.addEventListener === 'function') {
            comfyApi.addEventListener('model_download_progress', forwardProgress);
            return;
        }

        // Fallback: patch the WebSocket directly when no API client is found
        function patchWebSocket() {
            // Find the WebSocket object to patch
            let socket = null;
            let socketParent = null;
            
            if (window.app && window.app.socket && window.app.socket instanceof WebSocket) {
                socket = window.app.socket;
                socketParent = window.app;
            } else if (window.app && window.app.api && window.app.api.socket && window.app.api.socket instanceof WebSocket) {
                socket = window.app.api.socket;
                socketParent = window.app.api;
            }
            
            // If we found a socket, patch its onmessage handler
            if (socket) {
                const originalOnMessage = socket.onmessage;
                socket.onmessage = function(event) {
                    // Call original handler first
                    if (originalOnMessage) {
                        originalOnMessage.call(this, event);
                    }
                    
                    // Then handle for our own messages
                    try {
                        const message = JSON.parse(event.data);
                        if (message.type === 'model_download_progress') {
                            forwardProgress(message);
                        }
                    } catch (e) {
                        // Ignore JSON parse errors
                    }
                };
                console.log("[MODEL_DOWNLOADER] Successfully patched WebSocket handler");
            } else {
                // Try again later when app is fully loaded
                setTimeout(patchWebSocket, 500);
            }
        }
        
        // Start WebSocket patching process
        patchWebSocket();
        
    } catch (error) {
        console.error('[MODEL_DOWNLOADER] Error registering message handler:', error);
    }
}

// Create and load the main downloader script using a script tag
function loadMainScript() {
    // Get the current script path to determine the base path
    const scripts = document.getElementsByTagName('script');
    let basePath = '';
    
    // Find the current script
    for (const script of scripts) {
        if (script.src && script.src.includes('model_downloader.js')) {
            basePath = script.src.substring(0, script.src.lastIndexOf('/') + 1);
            console.log('[MODEL_DOWNLOADER] Found script path:', script.src);
            break;
        }
    }
    
    // If path not found, use relative path
    if (!basePath) {
        // Try to derive it from the current page URL
        const currentUrl = window.location.href;
        const urlObj = new URL(currentUrl);
        
        // First try with /extensions/ path which is how ComfyUI serves custom node files
        basePath = `${urlObj.protocol}//${urlObj.host}/extensions/model_downloader/`;
        console.log('[MODEL_DOWNLOADER] Using extensions path:', basePath);
    }
    
    // Create a script element for the main downloader script
    const script = document.createElement('script');
    script.type = 'text/javascript';
    script.src = basePath + 'backend_download.js';
    script.onload = function() {
        console.log('[MODEL_DOWNLOADER] Main downloader script loaded');
    };
    script.onerror = function(error) {
        console.error('[MODEL_DOWNLOADER] Error loading main script:', error);
    };
    
    // Append the script to the document head
    document.head.appendChild(script);
}

// Initialize the extension
function registerModelDownloader() {
    // Register message handler first
    registerMessageHandler();
    
    // Then load the main script
    loadMainScript();
}

// Wait for DOMContentLoaded to ensure the document is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', registerModelDownloader);
} else {
    registerModelDownloader();
}
