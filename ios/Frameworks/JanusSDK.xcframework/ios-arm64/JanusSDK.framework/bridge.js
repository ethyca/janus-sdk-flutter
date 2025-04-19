/**
 * Core bridge functionality between native iOS and JavaScript
 * Handles event listening and message passing
 */
(function() {
    // Map of all FidesJS events we want to listen for
    const fidesEvents = [
        'FidesInitializing',
        'FidesInitialized',
        'FidesUIShown',
        'FidesUIChanged', 
        'FidesModalClosed',
        'FidesUpdating',
        'FidesUpdated'
    ];
    
    // Add listeners for each FidesJS event
    fidesEvents.forEach(eventType => {
        window.addEventListener(eventType, event => {
            // Send to native through webkit message handler
            if (window.JanusSDK && window.JanusSDK.event) {
                window.JanusSDK.event(eventType, event.detail || {});
            } else {
                window.Janus.log(`window.JanusSDK.event is not defined for event: ${eventType}`, null, 'error');
            }
        });
    });
})(); 