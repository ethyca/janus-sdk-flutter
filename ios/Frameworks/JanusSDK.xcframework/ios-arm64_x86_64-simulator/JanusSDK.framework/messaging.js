/**
 * Messaging functions for communication between native and JavaScript
 * Handles message receiving and event dispatching
 */

// Initialize Janus namespace if it doesn't exist
if (!window.Janus) {
    window.Janus = {};
}

// Define a function that native code can call to send events to FidesJS
window.Janus.receiveMessageFromNative = function(jsonString) {
    window.Janus.log("Received message from Janus:", jsonString);
    try {
        const message = JSON.parse(jsonString);

        // Handle FidesJS event dispatch message
        if (message.type === 'DispatchFidesEvent' && message.data && message.data.eventType) {
            const eventType = message.data.eventType;
            const eventData = message.data.eventData || {};
            
            // Create a custom event with the specified type and data
            const event = new CustomEvent(eventType, { 
                detail: eventData,
                bubbles: true,
                cancelable: true
            });
            
            // Dispatch the event to the document
            document.dispatchEvent(event);
            window.Janus.log(`Dispatched event from native: ${eventType}`, eventData);
            return;
        }
        
        // Dispatch based on message type
        if (message.type === 'UpdateConsent' && message.data && message.data.consent) {            
            // Get optional consentMethod or use default
            const consentMethod = message.data.consentMethod || "janus_sync";
            
            // Handle multi-value consent updates
            window.Janus.updateConsent(message.data.consent, {
                consentMethod: consentMethod,
                dispatchEvents: true
            });
            return;
        }
        
        // If we get here, we didn't handle the message
        window.Janus.log("Unhandled message type received:", message.type, "error");
    } catch (e) {
        window.Janus.log("Error processing message from native:", e, "error");
    }
}; 