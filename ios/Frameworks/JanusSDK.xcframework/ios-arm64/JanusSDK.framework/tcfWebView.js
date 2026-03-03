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

    /* ============================================
     * TEMPORARY: UNTIL 2.81 is released and deployed
     * TCF Overlay fixes for embedded mobile SDK
     * ============================================ */

    body {
      margin: 0 !important;
    }

    .fides-banner.fides-embedded {
      height: 100vh !important;
      display: flex !important;
    }

    .fides-banner.fides-embedded #fides-banner .fides-close-button {
      display: none !important;
    }

    #fides-banner {
      --fides-overlay-padding: 24px !important;
      flex-direction: column !important;
    }

    #fides-banner-inner {
      flex: 1 !important;
      display: flex !important;
      flex-direction: column !important;
      min-height: 0 !important;
    }

    #fides-banner-inner-container {
      flex: 1 !important;
      overflow-y: auto !important;
      min-height: 0 !important;
      max-height: none !important;
    }

    #fides-button-group {
      flex-shrink: 0 !important;
    }

    @media (min-width: 768px) {
      #fides-banner {
        padding: 48px !important;
      }

      .fides-banner.fides-embedded .fides-banner__content {
        max-height: none !important;
      }
    }

    #fides-overlay-wrapper {
      height: 100vh !important;
      overflow: hidden !important;
      display: flex !important;
      flex-direction: column !important;
      justify-content: space-between !important;
    }

    @media (min-width: 768px) {
      #fides-overlay-wrapper {
        --fides-overlay-padding: 48px !important;
      }
    }

    /* ============================================
     * TEMPORARY: UNTIL client no longer uses breaking custom CSS
     * ============================================ */

    #fides-banner {
      border-radius: 0 !important;
      margin: 0 !important;
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
  window.Janus.log('TCF styles injected');
};

// Create a global callback function for modal ready notification
window.Janus.onFidesModalReady = function() {
  // Inject custom styles when modal is ready
  window.Janus.injectTCFStyles();
  
  // Send ready event to native side
  window.JanusSDK.event("TCFWebViewReady");
  window.Janus.log('Fides modal fully loaded and ready');
};

// Self-executing function to fire modal ready when document is loaded
(function() {
  function waitForModalLoad() {
    const selector = '#fides-button-group';
    window.Janus.log('Starting to wait for element: ' + selector);
    
    let observer;
    let pollInterval;
    let elementFound = false;
    
    // Centralized cleanup function
    function cleanup() {
      if (observer) {
        observer.disconnect();
        observer = null;
      }
      if (pollInterval) {
        clearInterval(pollInterval);
        pollInterval = null;
      }
    }
    
    // Check if element already exists
    function checkElement(source) {
      if (elementFound) return true; // Prevent multiple calls
      
      const element = document.querySelector(selector);
      if (element) {
        elementFound = true;
        window.Janus.log('Element found via ' + source + ': ' + selector);
        cleanup();
        fireModalReady();
        return true;
      }
      return false;
    }
    
    // Immediate check
    if (checkElement('immediate')) return;
    
    // Set up MutationObserver for efficient DOM watching
    observer = new MutationObserver(() => {
      checkElement('mutation observer');
    });
    
    // Start observing
    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
    
    // Polling fallback - check every 200ms
    pollInterval = setInterval(() => {
      checkElement('poll');
    }, 200);
  }
  
  function fireModalReady() {
    window.Janus.log('Fides embedded consent fully loaded - firing onFidesModalReady');
    window.Janus.onFidesModalReady();
  }
  
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    // Document already loaded, start waiting for element
    waitForModalLoad();
  } else {
    // Document not loaded yet, wait for DOM then start waiting for element
    document.addEventListener('DOMContentLoaded', waitForModalLoad);
  }
})();

