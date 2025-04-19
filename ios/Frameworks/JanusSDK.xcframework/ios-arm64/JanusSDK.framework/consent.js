/**
 * Consent management functions
 * Handles retrieval of consent values and metadata
 */

// Initialize Janus namespace if it doesn't exist
if (!window.Janus) {
    window.Janus = {};
}

// Function for native code to get current consent values
window.Janus.getFidesConsent = function() {
    window.Janus.log("Janus bridge getting consent values from Fides");
    if (window.Fides && window.Fides.consent) {
        var values = window.Fides.consent;
        return JSON.stringify(values);
    }
    return "{}";
};

// Function for native code to get the fides_string value
window.Janus.getFidesString = function() {
    window.Janus.log("Janus bridge getting fides_string from Fides");
    if (window.Fides && window.Fides.fides_string) {
        return window.Fides.fides_string;
    }
    return "";
};

// Function for native code to get current consent method
window.Janus.getFidesConsentMethod = function() {
    window.Janus.log("Janus: Getting Fides consent method");
    if (window.Fides && window.Fides.fides_meta && window.Fides.fides_meta.consentMethod) {
        return window.Fides.fides_meta.consentMethod;
    }
    return "unknown";
}

// Function for native code to get current metadata timestamps
window.Janus.getFidesConsentMetadata = function() {
    window.Janus.log("Janus bridge getting consent metadata from FidesJS");
    let result = {};
    if (window.Fides && window.Fides.fides_meta) {
        if (window.Fides.fides_meta.createdAt) {
            result.createdAt = window.Fides.fides_meta.createdAt;
        }
        if (window.Fides.fides_meta.updatedAt) {
            result.updatedAt = window.Fides.fides_meta.updatedAt;
        }
    }
    return JSON.stringify(result);
};

/**
 * Updates user consent preferences following the pattern from the TypeScript updateConsentPreferences
 * Simpler implementation that avoids TCF, GPP, and API components
 * 
 * @param {Object} newConsentValues - Map of notice keys to boolean consent values
 * @param {Object} options - Optional configuration for the update
 * @param {string} options.consentMethod - Method of consent ("save", "dismiss", default: "janus_sync")
 * @param {boolean} options.dispatchEvents - Whether to dispatch events (default: true)
 * @param {boolean} options.base64Cookie - Whether to base64 encode the cookie (default: false)
 */
window.Janus.updateConsent = function(newConsentValues, options = {}) {
    if (!window.Fides) {
        window.Janus.log("Fides not initialized", null, "error");
        return;
    }
    
    // Default options
    const {
        consentMethod = "janus_sync",
        dispatchEvents = true,
        base64Cookie = false
    } = options;
    
    // Get current cookie or create a new one if it doesn't exist
    let cookie = window.Fides.cookie || {};
    
    // Update the cookie object based on new preferences & extra details
    cookie.consent = {
        ...cookie.consent,
        ...newConsentValues
    };
    
    // Update metadata
    if (!cookie.fides_meta) {
        cookie.fides_meta = {};
    }
    const now = new Date().toISOString();
    if (!cookie.fides_meta.createdAt) {
        cookie.fides_meta.createdAt = now;
    }
    cookie.fides_meta.updatedAt = now;
    cookie.fides_meta.consentMethod = consentMethod;
    
    // Ensure identity exists
    if (!cookie.identity || !cookie.identity.fides_user_device_id) {
        cookie.identity = {
            fides_user_device_id: window.Janus.generateUUID()
        };
    }
    
    // Dispatch a "FidesUpdating" event with the new preferences
    if (dispatchEvents) {
        // Add source attribute to prevent event loops
        const updatingDetail = { ...cookie, source: "JanusSDK" };
        window.dispatchEvent(new CustomEvent("FidesUpdating", { 
            detail: updatingDetail 
        }));
    }
    
    // Update the window.Fides object
    window.Janus.log("Updating Fides objects", cookie);
    window.Fides.consent = cookie.consent;
    window.Fides.fides_meta = cookie.fides_meta;
    window.Fides.identity = cookie.identity;
    
    // Save preferences to the cookie in the browser
    window.Janus.log("Saving preferences to cookie");
    window.Janus.saveCookie(cookie, base64Cookie);
    
    // Update saved_consent (as a copy of current consent)
    window.Fides.saved_consent = {...cookie.consent};
    window.Fides.cookie = cookie;
    
    // Dispatch a "FidesUpdated" event
    if (dispatchEvents) {
        // Add source attribute to prevent event loops
        const updatedDetail = { ...cookie, source: "JanusSDK" };
        window.dispatchEvent(new CustomEvent("FidesUpdated", { 
            detail: updatedDetail 
        }));
    }
};

/**
 * Helper function to save the cookie to the browser
 */
window.Janus.saveCookie = function(cookie, useBase64) {
    const COOKIE_NAME = "fides_consent";
    const COOKIE_MAX_AGE_DAYS = 365;
    
    let cookieValue = JSON.stringify(cookie);
    window.Janus.log("Saving cookie", cookieValue);
    if (useBase64) {
        // Use btoa for base64 encoding
        cookieValue = btoa(cookieValue);
    }
    const encodedCookieValue = encodeURIComponent(cookieValue);
    
    // Find the top viable domain by trying domains from most specific to least specific
    const hostnameParts = window.location.hostname.split(".");
    let successfulDomain = null;
    
    // If we're on localhost or an IP address, just set without domain
    if (hostnameParts.length <= 1 || /^(\d+\.){3}\d+$/.test(window.location.hostname)) {
        document.cookie = `${COOKIE_NAME}=${encodedCookieValue};path=/;max-age=${COOKIE_MAX_AGE_DAYS * 24 * 60 * 60}`;
        window.Janus.log("Cookie saved for localhost/IP", document.cookie);
        return;
    }
    
    // Try domains from least specific to most specific (e.g., first "com", then "example.com", then "www.example.com")
    for (let i = 1; i <= hostnameParts.length; i++) {
        const topViableDomain = hostnameParts.slice(-i).join(".");
        
        // Add leading dot to enable cookies for all subdomains
        const domainWithDot = `.${topViableDomain}`;
        
        // Create test cookie string
        const cookieString = `${COOKIE_NAME}=${encodedCookieValue};path=/;domain=${domainWithDot};max-age=${COOKIE_MAX_AGE_DAYS * 24 * 60 * 60}`;
        
        // Attempt to set cookie
        document.cookie = cookieString;
        
        // Check if cookie was successfully set
        const cookieExists = document.cookie.indexOf(`${COOKIE_NAME}=`) !== -1;
        
        if (cookieExists) {
            // Verify the cookie contains our data
            const cookies = document.cookie.split(';');
            const targetCookie = cookies.find(c => c.trim().startsWith(`${COOKIE_NAME}=`));
            
            if (targetCookie) {
                const savedValue = decodeURIComponent(targetCookie.split('=')[1]);
                
                // If we can safely decode and parse it, we've found our domain
                try {
                    if (useBase64) {
                        let decodedValue = atob(savedValue);
                        let parsedCookie = JSON.parse(decodedValue);
                        if (parsedCookie && parsedCookie.fides_meta && 
                            parsedCookie.fides_meta.updatedAt === cookie.fides_meta.updatedAt) {
                            successfulDomain = domainWithDot;
                            break;
                        }
                    } else {
                        let parsedCookie = JSON.parse(savedValue);
                        if (parsedCookie && parsedCookie.fides_meta && 
                            parsedCookie.fides_meta.updatedAt === cookie.fides_meta.updatedAt) {
                            successfulDomain = domainWithDot;
                            break;
                        }
                    }
                } catch (e) {
                    // Continue to the next domain if we couldn't verify
                    window.Janus.log("Error verifying cookie for domain", domainWithDot, e);
                }
            }
        }
    }
    
    // If we couldn't set on any domain, fallback to current domain without dot
    if (!successfulDomain) {
        document.cookie = `${COOKIE_NAME}=${encodedCookieValue};path=/;max-age=${COOKIE_MAX_AGE_DAYS * 24 * 60 * 60}`;
        window.Janus.log("Cookie saved on current domain (fallback)", document.cookie);
    } else {
        window.Janus.log(`Cookie saved on domain ${successfulDomain}`, document.cookie);
    }
};

/**
 * Helper function to generate a UUID
 * This replaces the uuid dependency used in the TypeScript code
 */
window.Janus.generateUUID = function() {
    // Simple UUID generator
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}; 