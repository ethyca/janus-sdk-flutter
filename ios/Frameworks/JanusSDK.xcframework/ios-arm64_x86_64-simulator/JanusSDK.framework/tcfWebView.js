// TCF WebView JavaScript Code
// This file contains JavaScript functionality for the TCF WebView experience

// Initialize Janus namespace if it doesn't exist
if (!window.Janus) {
  window.Janus = {};
}

// Inject custom CSS styles for TCF content
window.Janus.injectTCFStyles = function() {
  // Create style element
  var style = document.createElement('style');
  style.type = 'text/css';
  style.id = 'janus-tcf-styles';
  
  // TCF content styling for full-screen display
  var css = `
    div#fides-consent-content, div.fides-modal-content {
      height: 100%!important;
      max-height: 100%!important;
      padding-top: 6%;
      padding-bottom: 6%;
    }
    
    .fides-close-button {
      color: #007AFF !important; /* iOS blue */
      font-weight: 600 !important;
      padding-right: 24px !important;
      font-size: 17px !important; /* Increase font size to match iOS standard */
    }
    
    .fides-close-button::before {
      content: "Close" !important;
      display: inline !important;
    }
    
    .fides-close-button svg, .fides-close-button img {
      display: none !important; /* Hide any existing icon */
    }
  `;
  
  // Add the CSS to the style element
  if (style.styleSheet) {
    // For old IE
    style.styleSheet.cssText = css;
  } else {
    // For modern browsers
    style.appendChild(document.createTextNode(css));
  }
  
  // Inject style into document
  document.head.appendChild(style);
  window.webkit.messageHandlers.fidesModalDebug.postMessage('TCF styles injected');
};

// Create a global callback function for modal ready notification
window.Janus.onFidesModalReady = function() {
  // Inject custom styles when modal is ready
  window.Janus.injectTCFStyles();
  
  // Let iOS know the modal is ready
  window.webkit.messageHandlers.fidesModalReady.postMessage('ready');
  console.log('Fides modal fully loaded and ready');
};

// Create a global callback function for TCF flow completion
window.Janus.onFidesModalCompleted = function() {
  // Notify iOS to hide the WebView immediately
  window.webkit.messageHandlers.fidesModalHide.postMessage('hide');
  console.log('TCF flow completed - WebView hidden');
};

// Setup event listeners for TCF flow completion
window.Janus.setupTCFCompletionListeners = function() {
  window.webkit.messageHandlers.fidesModalDebug.postMessage('Setting up TCF completion listeners');
  
  // Add a global document click handler for all button interactions
  if (!document.body._janusGlobalListenerAdded) {
    document.body._janusGlobalListenerAdded = true;
    document.body.addEventListener('click', function(e) {
      // Target only specific button classes
      if (e.target && 
          (e.target.classList.contains('fides-close-button') || 
           e.target.classList.contains('fides-save-button') ||
           e.target.classList.contains('fides-reject-all-button') ||
           e.target.classList.contains('fides-accept-all-button'))) {
        
        window.webkit.messageHandlers.fidesModalDebug.postMessage('Button click detected via global handler: ' + e.target.outerHTML);
        window.Janus.onFidesModalCompleted();
      }
    }, true); // true for useCapture
    
    window.webkit.messageHandlers.fidesModalDebug.postMessage('Attached global document click listener with capture');
  }
  
  window.webkit.messageHandlers.fidesModalDebug.postMessage('TCF completion listeners set up with capture phase');
};

// Modal detection and retry mechanism
(function() {
  // Counter for retry attempts
  var retryCount = 0;
  var maxRetries = 120;
  var checkInterval = 500; // ms
  var modalCheckInterval = null;
  
  // Function to check if the modal is visible
  function isModalVisible() {
    var modal = document.getElementById('fides-modal');
    if (modal) {
      var style = window.getComputedStyle(modal);
      return style.display !== 'none' && style.visibility !== 'hidden';
    }
    return false;
  }
  
  // Function to check modal status
  function checkModalStatus() {
    if (isModalVisible()) {
      // Modal is visible, success!
      clearInterval(modalCheckInterval);
      window.webkit.messageHandlers.fidesModalDebug.postMessage('Modal found and visible');
      window.Janus.onFidesModalReady();
      // Set up TCF completion listeners
      window.Janus.setupTCFCompletionListeners();
      return true;
    }
    
    // Modal not found or not visible yet
    retryCount++;
    window.webkit.messageHandlers.fidesModalDebug.postMessage('Attempt ' + retryCount + ': Modal not ready yet');
    
    if (retryCount >= maxRetries) {
      // Give up after max retries
      clearInterval(modalCheckInterval);
      window.webkit.messageHandlers.fidesModalFailed.postMessage('Failed after ' + maxRetries + ' attempts to detect modal');
      return false;
    }
    
    // Try showing the modal again
    tryShowModal();
    return false;
  }
  
  // Function to attempt showing the modal
  function tryShowModal() {
    if (window.Fides) {
      try {
        window.webkit.messageHandlers.fidesModalDebug.postMessage('Calling Fides.showModal()');
        window.Fides.showModal();
      } catch (error) {
        window.webkit.messageHandlers.fidesModalDebug.postMessage('Error calling showModal: ' + error.toString());
      }
    } else {
      window.webkit.messageHandlers.fidesModalDebug.postMessage('Fides not available yet');
    }
  }
  
  // Start the process - exposed via Janus namespace
  window.Janus.startModalDetection = function() {
    window.webkit.messageHandlers.fidesModalDebug.postMessage('Starting modal detection');
    // Make first attempt
    tryShowModal();
    
    // Set up interval to check for modal
    modalCheckInterval = setInterval(checkModalStatus, checkInterval);
  };
})();

/**
 * Loads the Fides script with parameters
 * @param {string} apiHost - The API host URL
 * @param {string} region - Optional region code
 * @param {string} propertyId - Optional property ID
 */
window.Janus.loadFidesScript = function(apiHost, region, propertyId) {
  console.log('Initializing Fides script loader');
  
  // Build the script URL with query parameters
  var scriptURLString = apiHost + "/fides.js";
  var queryParams = [];
  
  // Add geolocation parameter if region is available
  if (region && region.length > 0) {
    queryParams.push("geolocation=" + encodeURIComponent(region));
  }
  
  // Add property_id parameter if available
  if (propertyId && propertyId.length > 0) {
    queryParams.push("property_id=" + encodeURIComponent(propertyId));
  }
  
  // Add query parameters to URL if any exist
  if (queryParams.length > 0) {
    scriptURLString += "?" + queryParams.join("&");
  }
  
  // Reset any existing Fides instance
  window.Fides = null;
  
  // Create a new script element
  var script = document.createElement('script');
  script.type = 'text/javascript';
  script.src = scriptURLString;
  script.async = true;
  script.id = 'fides-script';
  
  // Log when the script starts loading
  script.onload = function() {
    console.log('Fides script loaded successfully');
    window.webkit.messageHandlers.fidesModalDebug.postMessage('Fides script loaded from: ' + scriptURLString);
  };
  
  script.onerror = function() {
    console.error('Failed to load Fides script');
    window.webkit.messageHandlers.fidesModalFailed.postMessage('Failed to load Fides script from: ' + scriptURLString);
  };
  
  // Remove any existing Fides script
  var existingScript = document.getElementById('fides-script');
  if (existingScript) {
    existingScript.parentNode.removeChild(existingScript);
  }
  
  // Add the script to the document
  document.head.appendChild(script);
  
  console.log('Fides script element added to page');
  window.webkit.messageHandlers.fidesModalDebug.postMessage('Attempting to load Fides from: ' + scriptURLString);
}; 