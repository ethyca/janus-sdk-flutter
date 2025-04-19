// Initialize JanusSDK namespace if it doesn't exist
if (!window.JanusSDK) {
  window.JanusSDK = {};
}

// Function to send events to native code
window.JanusSDK.event = function(eventType, eventData = {}) {
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.fidesJSBridge) {
    window.webkit.messageHandlers.fidesJSBridge.postMessage({
      type: eventType,
      data: eventData
    });
  }
};

// Function to log messages to native code
window.JanusSDK.log = function(message, data = null, type = 'debug') {
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.fidesLogger) {
    window.webkit.messageHandlers.fidesLogger.postMessage({
      type: type,
      message: message,
      data: data
    });
  }
}; 