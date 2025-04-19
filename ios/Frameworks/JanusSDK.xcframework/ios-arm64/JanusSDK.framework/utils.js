/**
 * Utility functions for bridge diagnostics and checking
 */

// Initialize Janus namespace if it doesn't exist
if (!window.Janus) {
    window.Janus = {};
}

// Function to check if all required bridge functions exist
window.Janus.checkFides = function() {
    return {
        fidesExists: typeof window.Fides === 'object',
        fidesMetaExists: window.Fides && typeof window.Fides.fides_meta === 'object',
        fidesConsentExists: window.Fides && typeof window.Fides.consent === 'object'
    };
};

/**
 * Logging utility that sends logs to both the JavaScript console and iOS native code
 * @param {string} message - The message to log
 * @param {any} data - Optional data to include with the log message
 * @param {string} type - Log type (default: 'debug')
 */
window.Janus.log = function(message, data = null, type = 'debug') {
    // Log to JavaScript console with appropriate level based on type
    if (type === 'error') {
        if (data !== null) {
            console.error(message, data);
        } else {
            console.error(message);
        }
    } else {
        if (data !== null) {
            console.log(message, data);
        } else {
            console.log(message);
        }
    }
    
    // Handle Error objects specially to preserve their properties
    let processedData = data;
    if (data instanceof Error) {
        processedData = {
            name: data.name,
            message: data.message,
            stack: data.stack
        };
    }

    // Send to native code
    if (window.JanusSDK && window.JanusSDK.log) {
        window.JanusSDK.log(message, processedData, type);
    } else {
        console.log('window.JanusSDK.log is not defined');
    }
};