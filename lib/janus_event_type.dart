/// Event types for Janus SDK events.
enum JanusEventType {
  /// Privacy experience was shown to the user
  experienceShown('experienceShown'),
  
  /// User interacted with the privacy experience
  experienceInteraction('experienceInteraction'),
  
  /// Privacy experience was closed
  experienceClosed('experienceClosed'),
  
  /// User's selection in the privacy experience is being updated
  experienceSelectionUpdating('experienceSelectionUpdating'),
  
  /// User's selection in the privacy experience has been updated
  experienceSelectionUpdated('experienceSelectionUpdated'),
  
  /// Fides is initializing in a WebView
  webviewFidesInitializing('webviewFidesInitializing'),
  
  /// Fides has been initialized in a WebView
  webviewFidesInitialized('webviewFidesInitialized'),
  
  /// Fides UI has been shown in a WebView
  webviewFidesUIShown('webviewFidesUIShown'),
  
  /// Fides UI has changed in a WebView
  webviewFidesUIChanged('webviewFidesUIChanged'),
  
  /// Fides modal has been closed in a WebView
  webviewFidesModalClosed('webviewFidesModalClosed'),
  
  /// Fides is updating in a WebView
  webviewFidesUpdating('webviewFidesUpdating'),
  
  /// Fides has been updated in a WebView
  webviewFidesUpdated('webviewFidesUpdated'),
  
  /// Consent has been updated from a WebView
  consentUpdatedFromWebView('consentUpdatedFromWebView'),
  
  /// Unknown event type
  unknown('unknown');

  /// The string value of the event type.
  final String value;
  
  /// Creates a new event type with the given string value.
  const JanusEventType(this.value);
  
  /// Get a JanusEventType from a string value.
  static JanusEventType fromString(String value) {
    return JanusEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => JanusEventType.unknown,
    );
  }
}
