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
    div#fides-embed-container {
      padding-top: 10%;
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
  window.JanusSDK.log('TCF styles injected');
};

// Create a global callback function for modal ready notification
window.Janus.onFidesModalReady = function() {
  // Inject custom styles when modal is ready
  window.Janus.injectTCFStyles();
  window.Janus.setupTCFCompletionListeners();
  
  // Send ready event to native side
  window.JanusSDK.event("TCFWebViewReady");
  window.JanusSDK.log('Fides modal fully loaded and ready');
};

// Create a global callback function for TCF flow completion
window.Janus.onFidesModalCompleted = function() {
  // Send hide event to native side
  window.JanusSDK.event("TCFWebViewClose");
  window.JanusSDK.log('TCF flow completed - WebView hidden');
};

// Setup event listeners for TCF flow completion
window.Janus.setupTCFCompletionListeners = function() {
  window.JanusSDK.log('Setting up TCF completion listeners');
  
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
        
        window.JanusSDK.log('Button click detected via global handler: ' + e.target.outerHTML);
        window.Janus.onFidesModalCompleted();
      }
    }, true); // true for useCapture
    
    window.JanusSDK.log('Attached global document click listener with capture');
  }
  
  window.JanusSDK.log('TCF completion listeners set up with capture phase');
};

// Self-executing function to fire modal ready when document is loaded
(function() {
  function fireModalReady() {
    window.JanusSDK.log('Document ready - firing onFidesModalReady');
    window.Janus.onFidesModalReady();
  }
  
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    // Document already loaded, fire immediately
    fireModalReady();
  } else {
    // Document not loaded yet, set up event handler
    document.addEventListener('DOMContentLoaded', fireModalReady);
  }
})();

