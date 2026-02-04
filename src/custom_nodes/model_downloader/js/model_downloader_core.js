// Model Downloader Core Functionality
// This file contains the core functionality for downloading models

(function() {
  // Check if this module is already loaded, but don't skip core functionality
  // We need the patching to work even with duplicates
  if (window.modelDownloaderCoreLoaded) {
    // If the core is already loaded, just make sure the button patching function is still executed
    if (typeof window.modelDownloader?.patchMissingModelButtons === 'function') {
      console.log('[MODEL_DOWNLOADER] Core already loaded, re-running button patching');
      window.modelDownloader.patchMissingModelButtons();
      return;
    }
  }
  window.modelDownloaderCoreLoaded = true;
  console.log('[MODEL_DOWNLOADER] Loading core functionality');

  // Map to store active downloads
  const activeDownloads = {};
  
  // List of trusted domains for model downloads
  const trustedDomains = [
    'huggingface.co',
    'civitai.com',
    'github.com',
    'cdn.discordapp.com',
    'pixeldrain.com',
    'replicate.delivery'
  ];
  
  // Check if a URL is from a trusted domain
  function isTrustedDomain(url) {
    try {
      const urlObj = new URL(url);
      return trustedDomains.some(domain => urlObj.hostname === domain || urlObj.hostname.endsWith('.' + domain));
    } catch (e) {
      console.error('[MODEL_DOWNLOADER] Error parsing URL:', e);
      return false;
    }
  }
  
  // Handle incoming WebSocket messages for our download progress
  function handleMessageEvent(event) {
    try {
      // Extract data from the event (different ComfyUI versions may structure this differently)
      let messageData = event.data || event;
      
      // If this is a wrapper message with a type and data property (standard format)
      if (messageData && messageData.type === 'model_download_progress' && messageData.data) {
        messageData = messageData.data;
      }
      
      // Handle CustomEvent format used by addEventListener
      if (messageData && messageData.detail) {
        if (messageData.detail.data) {
          // Event comes as {detail: {type: 'model_download_progress', data: {...}}}
          messageData = messageData.detail.data;
        } else {
          // Event comes as {detail: {download_id: '...', status: '...'}}
          messageData = messageData.detail;
        }
      }
      
      if (messageData && messageData.download_id && window.modelDownloader) {
        // Process download update
        
        // Create array to store all matched buttons
        let matchedButtons = [];
        let downloadData = null;
        
        // Only search active downloads if they exist
        if (window.modelDownloader.activeDownloads) {
          // Look for the download by server download ID
          downloadData = window.modelDownloader.activeDownloads[messageData.download_id];
          
          // If not found directly, check all active downloads for a matching server_download_id
          if (!downloadData) {
            Object.values(window.modelDownloader.activeDownloads).forEach(download => {
              if (download.server_download_id === messageData.download_id) {
                downloadData = download;
              }
            });
          }
          
          // If we found download data with a button, add it to matches
          if (downloadData && downloadData.button) {
            matchedButtons.push(downloadData.button);
          }
        }
        
        // Search for button by data attribute as a backup
        if (document.querySelector) {
          const buttonByAttribute = document.querySelector(`button[data-download-id="${messageData.download_id}"]`);
          if (buttonByAttribute) {
            matchedButtons.push(buttonByAttribute);
          }
        }
        
        // Search through all buttons for any with metadata that might match
        if (document.querySelectorAll) {
          const allButtons = document.querySelectorAll('button[data-model-downloader-patched="true"]');
          for (const btn of allButtons) {
            const folder = btn.getAttribute('data-folder-name');
            const filename = btn.getAttribute('data-file-name');
            
            if (folder && filename && messageData.folder && messageData.filename) {
              // Check if this button's metadata matches the download metadata
              if (folder === messageData.folder && filename === messageData.filename) {
                matchedButtons.push(btn);
              }
            }
          }
        }
        
        // Update all matched buttons
        if (matchedButtons.length > 0) {
          matchedButtons.forEach(button => {
            // If message contains total_size, store it on the button for later
            if (messageData.total_size) {
              button.setAttribute('data-total-size', messageData.total_size);
            }
            
            // Update our tracking object with all message data
            if (downloadData) {
              // Copy all properties from the message to our tracking object
              Object.assign(downloadData, {
                percent: messageData.percent || 0,
                downloaded: messageData.downloaded || 0,
                total_size: messageData.total_size || 0,
                speed: messageData.speed || 0,
                eta: messageData.eta || 0,
                status: messageData.status || 'downloading',
                error: messageData.error || null
              });
            }
            
            if (messageData.status === 'completed') {
              updateButtonStatus(button, 'completed');
              // Update status in activeDownloads tracking
              if (downloadData) {
                downloadData.status = 'completed';
              }
              // Check if all downloads are complete to close the dialog
              checkAndCloseDialog();
            } else if (messageData.status === 'error') {
              updateButtonStatus(button, 'error', messageData.error);
              // Update status in activeDownloads tracking
              if (downloadData) {
                downloadData.status = 'error';
              }
              // Check if all downloads are complete to close the dialog
              checkAndCloseDialog();
            } else {
              // For in-progress downloads, update button with downloading status and information
              updateButtonStatus(button, 'downloading');
            }
          });
        } else {
          // Store status for later if no button found
          if (messageData.status === 'completed' || messageData.status === 'error') {
            // Store in cache for later use
            if (!window.modelDownloader.completedDownloads) {
              window.modelDownloader.completedDownloads = {};
            }
            window.modelDownloader.completedDownloads[messageData.download_id] = messageData;
            
            // Update status in activeDownloads if we can find it
            if (window.modelDownloader.activeDownloads && 
                window.modelDownloader.activeDownloads[messageData.download_id]) {
              window.modelDownloader.activeDownloads[messageData.download_id].status = messageData.status;
              // Check if all downloads are complete to close the dialog
              checkAndCloseDialog();
            }
          }
        }
      }
    } catch (error) {
      console.error('[MODEL_DOWNLOADER] Error handling message event:', error);
    }
  }
  
  // Check if all active downloads are complete and close the dialog if appropriate
  function checkAndCloseDialog() {
    // Don't do anything if there are no active downloads
    if (!window.modelDownloader || !window.modelDownloader.activeDownloads) {
      return;
    }
    
    // First, check if there are any active downloads still in progress
    const activeDownloads = window.modelDownloader.activeDownloads;
    const activeDownloadIds = Object.keys(activeDownloads);
    
    // If no active downloads, nothing to check
    if (activeDownloadIds.length === 0) {
      return;
    }
    
    // Check if all downloads are either completed or failed
    const allComplete = activeDownloadIds.every(id => {
      const download = activeDownloads[id];
      return download.status === 'completed' || download.status === 'error';
    });
    
    if (allComplete) {
      console.log('[MODEL_DOWNLOADER] All downloads complete, attempting to close dialog');
      
      try {
        // Find and access the Pinia dialog store which is where ComfyUI manages dialogs
        let dialogStore = null;
        
        // Method 1: Try to find the dialog store in the Pinia instance
        if (window?.$pinia?.state?.value?.dialog) {
          console.log('[MODEL_DOWNLOADER] Found dialog store in Pinia state');
          dialogStore = window?.$pinia?._s?.get('dialog');
        }
        
        // Method 2: Check if app has store with direct dialog store reference
        if (!dialogStore && window.app?.store?.dialog) {
          console.log('[MODEL_DOWNLOADER] Found dialog store in app.store');
          dialogStore = window.app.store.dialog;
        }
        
        // Method 3: Check for a direct dialogStore property on app
        if (!dialogStore && window.app?.dialogStore) {
          console.log('[MODEL_DOWNLOADER] Found dialogStore in app');
          dialogStore = window.app.dialogStore;
        }
        
        // If we found a dialog store, try to close the dialog
        if (dialogStore && typeof dialogStore.closeDialog === 'function') {
          console.log('[MODEL_DOWNLOADER] Calling closeDialog on dialog store');
          dialogStore.closeDialog({ key: 'global-missing-models-warning' });
          
          // Show a toast notification if available
          if (window.app && typeof window.app.ui?.showToast === 'function') {
            window.app.ui.showToast('All model downloads completed!', 3000, 0);
          }
          return;
        }
        
        // Method 3: Look for PrimeVue dialog in the DOM
        const primeVueDialog = document.querySelector('.p-dialog.global-dialog');
        if (primeVueDialog && primeVueDialog.textContent.includes('Missing Models')) {
          console.log('[MODEL_DOWNLOADER] Found PrimeVue dialog, attempting to close it');
          
          // Try to find and click the close button
          const closeButton = primeVueDialog.querySelector('.p-dialog-header-close, .p-dialog-close-button');
          if (closeButton) {
            console.log('[MODEL_DOWNLOADER] Clicking close button on PrimeVue dialog');
            closeButton.click();
            
            // Show a toast notification if available
            if (window.app && typeof window.app.ui?.showToast === 'function') {
              window.app.ui.showToast('All model downloads completed!', 3000, 0);
            }
            return;
          }
          
          // If no close button found, try to hide the dialog
          primeVueDialog.style.display = 'none';
          return;
        }
        
        // Method 4: Try to find the dialog in DOM and close it manually (fallback)
        const dialogSelectors = [
          '.comfy-modal.open',
          '.sp-container dialog[open]',
          '.comfy-menu dialog[open]', 
          'div[id^="dialog"] dialog[open]',
          'div.dialog dialog[open]',
          'dialog[open]'
        ];
        
        // Find the missing models dialog
        for (const selector of dialogSelectors) {
          const dialogs = document.querySelectorAll(selector);
          for (const dialog of dialogs) {
            if (dialog.textContent && dialog.textContent.includes('Missing Models')) {
              // Close the dialog
              console.log('[MODEL_DOWNLOADER] Closing dialog via DOM as all downloads are complete');
              if (typeof dialog.close === 'function') {
                dialog.close();
              } else if (dialog.style) {
                dialog.style.display = 'none';
              }
              
              // Show a toast notification if available
              if (window.app && typeof window.app.ui?.showToast === 'function') {
                window.app.ui.showToast('All model downloads completed!', 3000, 0);
              } else if (typeof window.toastr?.success === 'function') {
                window.toastr.success('All model downloads completed!');
              }
              
              return;
            }
          }
        }
        
        // Method 5: Last resort - try to programmatically trigger Escape key to close modal
        console.log('[MODEL_DOWNLOADER] Attempting to use Escape key to close dialog');
        const escapeEvent = new KeyboardEvent('keydown', {
          key: 'Escape',
          code: 'Escape',
          keyCode: 27,
          which: 27,
          bubbles: true,
          cancelable: true
        });
        document.dispatchEvent(escapeEvent);
        
      } catch (error) {
        console.error('[MODEL_DOWNLOADER] Error trying to close dialog:', error);
      }
    }
  }

  // Function to download model using backend API
  async function downloadModelWithBackend(url, folder, filename, button) {
    // Start download process
    
    // Message handlers are registered in model_downloader.js
    
    // Create a unique client ID for tracking
    const clientDownloadId = `${folder}_${filename}_${Date.now()}`;
    
    // Add a data attribute to the button for easy lookup
    if (button) {
      button.setAttribute('data-download-id', clientDownloadId);
    }
    
    // Disable button and show spinner
    if (button) {
      button.disabled = true;
      button.innerHTML = '<span class="spinner"></span> Downloading...';
      button.style.cursor = 'not-allowed';

      // Improve contrast for disabled button styling in newer ComfyUI/PrimeVue themes
      button.style.opacity = '1';
      button.style.color = '#fff';
      button.style.backgroundColor = 'rgba(0, 0, 0, 0.35)';
      button.style.borderColor = 'rgba(255, 255, 255, 0.18)';
      button.style.textShadow = '0 1px 1px rgba(0, 0, 0, 0.5)';
      
      // Store original button text in case we need to revert
      button.setAttribute('data-original-text', button.textContent || 'Download with Model Downloader');
      
      // Add spinner CSS if not already added
      if (!document.getElementById('model-downloader-spinner-style')) {
        const style = document.createElement('style');
        style.id = 'model-downloader-spinner-style';
        style.textContent = `
          .spinner {
            display: inline-block;
            width: 12px;
            height: 12px;
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top-color: white;
            animation: spin 1s ease-in-out infinite;
            margin-right: 8px;
          }
          @keyframes spin {
            to {
              transform: rotate(360deg);
            }
          }
        `;
        document.head.appendChild(style);
      }

      // Improve contrast for the progress pill/button in the PrimeVue/ComfyUI theme.
      // Some themes apply opacity + dimmed colors to disabled buttons and make the
      // progress text nearly invisible. Override with !important.
      if (!document.getElementById('model-downloader-contrast-style')) {
        const style = document.createElement('style');
        style.id = 'model-downloader-contrast-style';
        style.textContent = `
          button.model-downloader-patched:disabled,
          .model-downloader-patched[disabled] {
            opacity: 1 !important;
            filter: none !important;
            color: #fff !important;
            background-color: rgba(0, 0, 0, 0.45) !important;
            border-color: rgba(255, 255, 255, 0.22) !important;
            text-shadow: 0 1px 1px rgba(0, 0, 0, 0.55) !important;
          }
        `;
        document.head.appendChild(style);
      }
    }
    
    // Store in the global object for tracking
    if (!window.modelDownloader) {
      window.modelDownloader = {};
    }
    if (!window.modelDownloader.activeDownloads) {
      window.modelDownloader.activeDownloads = {};
    }
    window.modelDownloader.activeDownloads[clientDownloadId] = {
      button: button,
      url: url,
      folder: folder,
      filename: filename,
      status: 'downloading'
    };
    
    // Initialize completedDownloads cache if needed
    if (!window.modelDownloader.completedDownloads) {
      window.modelDownloader.completedDownloads = {};
    }
    
    try {
      // Prepare request data as JSON instead of FormData for better compatibility
      const jsonData = {
        url: url,
        folder: folder,
        filename: filename
      };
      
      console.log('[MODEL_DOWNLOADER] Sending download request with data:', jsonData);
      
      // Server request that returns immediately while download continues in background
      const response = await fetch('/api/download-model', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(jsonData)
      });
      
      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Server responded with ${response.status}: ${errorText}`);
      }
      
      const result = await response.json();
      
      if (result.success) {
        // Download successfully initiated
        
        // Store the server-assigned download ID for future reference
        if (window.modelDownloader.activeDownloads[clientDownloadId]) {
          window.modelDownloader.activeDownloads[clientDownloadId].server_download_id = result.download_id;
        }
        
        // Also store with the server's download ID for easier lookup
        window.modelDownloader.activeDownloads[result.download_id] = {
          button: button,
          url: url,
          folder: folder,
          filename: filename,
          status: 'downloading',
          client_id: clientDownloadId
        };
        
        // Update button with server download ID for direct matching
        if (button) {
          button.setAttribute('data-download-id', result.download_id);
          button.setAttribute('data-server-download-id', result.download_id);
          button.setAttribute('data-client-download-id', clientDownloadId);
        }
        
        // Check if we already have a completed status for this download in our cache
        if (window.modelDownloader.completedDownloads && 
            window.modelDownloader.completedDownloads[result.download_id]) {
            
          const cachedResult = window.modelDownloader.completedDownloads[result.download_id];
          console.log('[MODEL_DOWNLOADER] Found cached completion status:', cachedResult.status);
          
          // Apply the cached status
          if (cachedResult.status === 'completed') {
            console.log('[MODEL_DOWNLOADER] Applying cached completed status');
            updateButtonStatus(button, 'completed');
          } else if (cachedResult.status === 'error') {
            console.log('[MODEL_DOWNLOADER] Applying cached error status');
            updateButtonStatus(button, 'error', cachedResult.error);
          }
        }
        
        return result;
      } else if (result.error) {
        throw new Error(result.error);
      }
      
      return result;
    } catch (error) {
      console.error('[MODEL_DOWNLOADER] Download request failed:', error.message);
      
      // Update button with error
      updateButtonStatus(button, 'error', error.message);
      
      throw error;
    }
  }

// Update the button status based on download status
function updateButtonStatus(button, status, errorMessage) {
  if (!button) return;
  
  if (status === 'completed') {
    button.disabled = true;

    // Just show "Downloaded" when complete, no file size
    button.innerHTML = 'Downloaded';

    // Keep original styling - don't change color
    button.style.cursor = 'default';
    button.setAttribute('data-download-status', 'completed');
    // Show a toast notification for download completion if possible
    if (window.app && typeof window.app.ui?.showToast === 'function') {
      window.app.ui.showToast('Model download completed!', 3000, 0);
    } else if (typeof window.toastr?.success === 'function') {
      window.toastr.success('Model download completed!');
    } else {
      console.log('[MODEL_DOWNLOADER] Download completed');
    }
  } else if (status === 'downloading') {
    // For downloading status, get the download info from our tracking object
    const downloadId = button.getAttribute('data-download-id');
    if (downloadId && downloadId in window.modelDownloader.activeDownloads) {
      const downloadInfo = window.modelDownloader.activeDownloads[downloadId];

      // Display percentage
      let statusText = `${downloadInfo.percent || 0}%`;

      // Add speed if available
      if (downloadInfo.speed) {
        statusText += ` (${downloadInfo.speed} MB/s)`;
      }

      // Add ETA if available
      if (downloadInfo.eta) {
        const etaMinutes = Math.floor(downloadInfo.eta / 60);
        const etaSeconds = downloadInfo.eta % 60;
        statusText += ` - ${etaMinutes}m ${etaSeconds}s remaining`;
      }

      button.innerHTML = statusText;
    } else {
      // Fallback if we don't have detailed info
      button.innerHTML = errorMessage || 'Downloading...';
    }

    button.disabled = true;
    button.style.cursor = 'default';

    // Improve contrast for disabled button styling in newer ComfyUI/PrimeVue themes
    // (keep it inline too, in case the CSS injection above loads late)
    button.style.setProperty('opacity', '1', 'important');
    button.style.setProperty('filter', 'none', 'important');
    button.style.setProperty('color', '#fff', 'important');
    button.style.setProperty('background-color', 'rgba(0, 0, 0, 0.45)', 'important');
    button.style.setProperty('border-color', 'rgba(255, 255, 255, 0.22)', 'important');
    button.style.setProperty('text-shadow', '0 1px 1px rgba(0, 0, 0, 0.55)', 'important');

    button.setAttribute('data-download-status', 'downloading');
  } else if (status === 'error') {
    button.disabled = false;
    button.innerHTML = '❌ Failed - Try Again';
    button.style.backgroundColor = '#F44336';
    button.style.cursor = 'pointer';
    button.title = errorMessage || 'Download failed';
    button.setAttribute('data-download-status', 'error');
    // Show error notification if possible
    if (window.app && typeof window.app.ui?.showToast === 'function') {
      window.app.ui.showToast('Download failed: ' + (errorMessage || 'Unknown error'), 5000, 2);
    } else if (typeof window.toastr?.error === 'function') {
      window.toastr.error('Download failed: ' + (errorMessage || 'Unknown error'));
    } else {
      console.error('[MODEL_DOWNLOADER] Download failed:', errorMessage || 'Unknown error');
    }
  } 
}

// Patch the download buttons in the missing models dialog
function patchMissingModelButtons() {
  // Set up missing model button patching
  
  // ... rest of the code remains the same ...
    // Selectors for finding dialogs and buttons
    const dialogSelectors = [
      '.p-dialog.global-dialog',  // ComfyUI missing models dialog
      '.p-dialog',                // Any PrimeVue dialog
      '#nodes-modal',            // Old-style ComfyUI modal
      'div[role="dialog"]',      // Generic dialog role
      '.p-dialog-content',       // PrimeVue dialog content
      '.dialog'                  // Generic dialog class
    ];
    
    const buttonSelectors = [
      '.p-button[title*="http"]',                 // PrimeVue buttons with URL in title
      'button[title*="http"]',                    // Regular buttons with URL in title
      '.comfy-missing-models button',             // Buttons in missing models list
      '.p-listbox.comfy-missing-models .p-button', // ListBox buttons
      'button:not([data-model-downloader-patched])', // Any button not already patched
      '.p-button',                                // Any PrimeVue button
      'a.p-button',                              // PrimeVue button links
      '.p-dialog button'                         // Any button in a dialog
    ];
    
    // Combined selectors
    const dialogSelector = dialogSelectors.join(', ');
    const buttonSelector = buttonSelectors.join(', ');
    
    // Function to find and patch all download buttons
    function patchAllButtons() {
      let patchedCount = 0;
      
      // Find all dialogs that could be missing models dialogs
      document.querySelectorAll(dialogSelector).forEach(dialog => {
        // Check if this looks like a missing models dialog
        if (dialog.textContent && dialog.textContent.includes('Missing Models')) {
          
          // Find all potential download buttons in this dialog
          const buttons = dialog.querySelectorAll(buttonSelector);
          
          // Process each button
          buttons.forEach(button => {
            // Skip already patched buttons
            if (button.hasAttribute('data-model-downloader-patched')) {
              return;
            }
            
            // Check if this looks like a download button
            const buttonText = button.textContent || '';
            const buttonTitle = button.getAttribute('title') || '';
            
            if ((buttonText.includes('Download') || 
                (button.tagName === 'BUTTON' && dialog.textContent.includes('Missing Models'))) &&
                (buttonTitle.includes('http') || button.getAttribute('href')?.includes('http'))) {
              
              // Mark button as patched
              button.setAttribute('data-model-downloader-patched', 'true');
              
              // Extract information from the dialog
              let modelUrl = buttonTitle;
              let folderName = '';
              let fileName = '';
              
              // Try multiple sources to find the URL
              if (!modelUrl.includes('http')) {
                // Look for href attributes that might contain the URL
                const closestLink = button.closest('a[href]');
                if (closestLink && closestLink.href.includes('http')) {
                  modelUrl = closestLink.href;
                } else {
                  // Look for text that resembles a URL in the dialog
                  const dialogText = dialog.textContent;
                  const urlMatch = dialogText.match(/(https?:\/\/[^\s]+)/);
                  if (urlMatch) {
                    modelUrl = urlMatch[0];
                  }
                }
              }
              
              // Try to find the folder/filename information
              const listItem = button.closest('li');
              if (listItem) {
                // Look for a span with title that might contain path info
                const pathSpan = listItem.querySelector('span[title]');
                if (pathSpan) {
                  const pathText = pathSpan.textContent;
                  if (pathText && pathText.includes('/')) {
                    const parts = pathText.split('/');
                    folderName = parts[0].trim();
                    fileName = parts.slice(1).join('/').trim();
                  }
                }
              }
              
              // If we still don't have a filename, extract from URL
              if (!fileName && modelUrl && modelUrl.includes('http')) {
                try {
                  const urlObj = new URL(modelUrl);
                  const pathParts = urlObj.pathname.split('/');
                  fileName = pathParts[pathParts.length - 1] || 'downloaded_model';
                } catch (e) {
                  console.error('[MODEL_DOWNLOADER] Error parsing URL:', e);
                }
              }
              
              // Fallback for folder name
              if (!folderName) {
                // Look for common model folder names in the dialog text
                const dialogText = dialog.textContent.toLowerCase();
                const folderHints = ['checkpoints', 'loras', 'vae', 'upscale', 'controlnet', 'embedding', 'clip'];
                
                for (const hint of folderHints) {
                  if (dialogText.includes(hint)) {
                    folderName = hint;
                    break;
                  }
                }
              }
              
              // Create a new button
              const newButton = document.createElement('button');
              
              // Copy all the important attributes
              newButton.className = button.className;
              newButton.style.cssText = button.style.cssText;
              newButton.type = 'button';
              newButton.title = button.title;
              // Try to get the model size from various places
              let sizeText = '';
              const parent = button.parentElement;
              const modelListItem = button.closest('li');
              
              // First check the button's own text or title
              const buttonTextMatch = (button.textContent || '').match(/(\d+(?:\.\d+)?)\s*(MB|GB)/i);
              const buttonTitleMatch = (button.title || '').match(/(\d+(?:\.\d+)?)\s*(MB|GB)/i);
              
              // Then check parent element
              const parentMatch = parent && parent.textContent ? 
                parent.textContent.match(/(\d+(?:\.\d+)?)\s*(MB|GB)/i) : null;
                
              // Check list item if available
              const listItemMatch = modelListItem && modelListItem.textContent ? 
                modelListItem.textContent.match(/(\d+(?:\.\d+)?)\s*(MB|GB)/i) : null;
                
              // Check dialog text
              const dialogTextMatch = dialog.textContent ? 
                dialog.textContent.match(/(\d+(?:\.\d+)?)\s*(MB|GB)/i) : null;
              
              // Use the first match found
              const match = buttonTextMatch || buttonTitleMatch || parentMatch || listItemMatch || dialogTextMatch;
              if (match) {
                sizeText = ` (${match[0]})`;
              } else {
                // If no size found, try to fetch size from the URL
                console.log('[MODEL_DOWNLOADER] No size found, will display size after fetching metadata');
              }
              
              newButton.textContent = `Download with Model Downloader${sizeText}`;
              
              // Mark as patched
              newButton.setAttribute('data-model-downloader-patched', 'true');
              newButton.classList.add('model-downloader-patched');
              
              // Store the URL
              newButton.setAttribute('data-model-url', modelUrl);
              newButton.setAttribute('data-folder-name', folderName);
              newButton.setAttribute('data-file-name', fileName);
              
              // Create download handler function
              const downloadHandler = function(e) {
                // Prevent default browser download behavior
                if (e) {
                  e.preventDefault();
                  e.stopPropagation();
                }
                
                // Get the URL directly from the button attributes
                const url = newButton.getAttribute('data-model-url') || newButton.getAttribute('title') || '';
                let folder = newButton.getAttribute('data-folder-name') || '';
                let filename = newButton.getAttribute('data-file-name') || '';
                
                // Prompt for missing info if needed
                if (!url || !url.includes('http')) {
                  alert('Could not determine download URL. Please download manually.');
                  return;
                }
                
                if (!folder) {
                  folder = prompt('Please specify the model folder type:', 'checkpoints');
                  if (!folder) {
                    return;
                  }
                }
                
                // Extract filename from URL if not already set
                if (!filename && url) {
                  try {
                    const urlObj = new URL(url);
                    const pathParts = urlObj.pathname.split('/');
                    filename = pathParts[pathParts.length - 1] || 'downloaded_model';
                  } catch (e) {
                    filename = 'downloaded_model';
                  }
                }
                
                // Call our backend download API with the button instance so it can be updated
                downloadModelWithBackend(url, folder, filename, newButton)
                  .catch(error => {
                    console.error('[MODEL_DOWNLOADER] Download error:', error);
                  });
              };
              
              // Set click handler
              newButton.addEventListener('click', downloadHandler);
              
              // Replace the old button with our new one
              if (button.parentNode) {
                button.parentNode.replaceChild(newButton, button);
              }
              
              // Count patched buttons
              patchedCount++;
            }
          });
        }
      });
    }
    
    // Patch immediately once
    patchAllButtons();
    
    // Set up mutation observer to catch dynamically created dialogs
    const observer = new MutationObserver(function(mutations) {
      for (const mutation of mutations) {
        if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
          for (const node of mutation.addedNodes) {
            if (node.nodeType === Node.ELEMENT_NODE) {
              // Check if this node or any of its children match our dialog selectors
              const isDialog = (node.matches && node.matches(dialogSelector)) || 
                  (node.querySelector && node.querySelector(dialogSelector));
                  
              // Or if it has "Missing Models" in its text content
              const hasMissingModels = node.textContent && node.textContent.includes('Missing Models');
              
              if (isDialog || hasMissingModels) {
                patchAllButtons();
                return;
              }
            }
          }
        }
      }
    });
    
    // Observe the entire document body for changes
    observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['style', 'class']
    });
    
    // Also poll occasionally for dialogs that might have been missed
    const pollInterval = setInterval(function() {
      const dialogs = document.querySelectorAll(dialogSelector);
      for (const dialog of dialogs) {
        if (dialog.textContent && dialog.textContent.includes('Missing Models')) {
          // We found a dialog to patch
          patchAllButtons();
          return;
        }
      }
    }, 1000); // Poll every second
  }
  
  // Define initialize function
  function initialize() {
    // Initialize core module
    
    // Message handlers are now registered in model_downloader.js
    // registerMessageHandlers() call removed
    
    // Patch the missing model buttons
    patchMissingModelButtons();
    
    // Check if DOM is already loaded
    if (document.readyState === 'loading') {
      // If not, wait for it to load
      document.addEventListener('DOMContentLoaded', () => {
        patchMissingModelButtons();
      });
    } else {
      // Run the patching immediately, but also run it again after a short delay
      // This helps catch dialogs that might be created by scripts after page load
      setTimeout(() => {
        patchMissingModelButtons();
      }, 1000);
    }
    
    return true;
  }

  // Expose functions and data to global scope
  // First, create the core object
  window.modelDownloaderCore = {
    isTrustedDomain: isTrustedDomain,
    downloadModelWithBackend: downloadModelWithBackend,
    patchMissingModelButtons: patchMissingModelButtons,
    initialize: initialize,
    updateButtonStatus: updateButtonStatus,
    // registerMessageHandlers removed - now in model_downloader.js
    handleMessageEvent: handleMessageEvent,
    checkAndCloseDialog: checkAndCloseDialog
  };
  
  // Make sure modelDownloader exists before assigning to it
  if (!window.modelDownloader) {
    window.modelDownloader = {
      activeDownloads: {}
    };
  }
  
  // Add core functions to the main modelDownloader object
  Object.assign(window.modelDownloader, window.modelDownloaderCore);
  
  // Message handlers are registered in model_downloader.js
  
  // Do NOT call initialize automatically - let backend_download.js call it
})();