import 'dart:async';

import 'janus_sdk_flutter_platform_interface.dart';

/// The main class for the Janus SDK Flutter plugin.
/// 
/// This class provides privacy consent management functionality by wrapping
/// the native Android and iOS SDKs.
class Janus {
  /// Initialize the Janus SDK with the provided [config].
  /// 
  /// This must be called before any other methods. The future completes with:
  /// - true if initialization succeeded
  /// - false if initialization failed
  /// 
  /// If initialization fails, an error is returned in the completer.
  Future<bool> initialize(JanusConfiguration config) {
    return JanusSdkFlutterPlatform.instance.initialize(config);
  }
  
  /// Show the privacy experience UI.
  /// 
  /// This will display the privacy notice to the user.
  Future<void> showExperience() {
    return JanusSdkFlutterPlatform.instance.showExperience();
  }
  
  /// Add a listener for consent events.
  /// 
  /// Returns a unique identifier for the listener that can be used to remove it later.
  String addConsentEventListener(void Function(JanusEvent) listener) {
    return JanusSdkFlutterPlatform.instance.addConsentEventListener(listener);
  }
  
  /// Remove a consent event listener.
  /// 
  /// [listenerId] is the identifier returned by [addConsentEventListener].
  void removeConsentEventListener(String listenerId) {
    JanusSdkFlutterPlatform.instance.removeConsentEventListener(listenerId);
  }
  
  /// Get the current consent values.
  Future<Map<String, bool>> get consent {
    return JanusSdkFlutterPlatform.instance.consent;
  }
  
  /// Get metadata about the consent, including creation and update timestamps.
  /// 
  /// Returns a map containing:
  /// - `createdAt`: A timestamp indicating when the consent was created.
  /// - `updatedAt`: A timestamp indicating when the consent was last updated.
  Future<Map<String, dynamic>> get consentMetadata {
    return JanusSdkFlutterPlatform.instance.consentMetadata;
  }
  
  /// Get the Fides string representation of consent.
  Future<String> get fidesString {
    return JanusSdkFlutterPlatform.instance.fidesString;
  }
  
  /// Check if a valid privacy experience is available.
  Future<bool> get hasExperience {
    return JanusSdkFlutterPlatform.instance.hasExperience;
  }
  
  /// Check if the privacy experience should be shown.
  Future<bool> get shouldShowExperience {
    return JanusSdkFlutterPlatform.instance.shouldShowExperience;
  }
  
  /// Clear all consent data.
  /// 
  /// [clearMetadata] - Whether to also clear consent metadata (defaults to false).
  Future<void> clearConsent({bool clearMetadata = false}) {
    return JanusSdkFlutterPlatform.instance.clearConsent(clearMetadata: clearMetadata);
  }
  
  /// Create an instance that provides WebView functionality with consent integration.
  /// 
  /// [autoSyncOnStart] determines whether to enable initial synchronization when the webview loads.
  Future<void> createConsentWebView({bool autoSyncOnStart = true}) {
    return JanusSdkFlutterPlatform.instance.createConsentWebView(
      autoSyncOnStart: autoSyncOnStart
    );
  }
  
  /// Release a WebView from Janus management.
  Future<void> releaseConsentWebView() {
    return JanusSdkFlutterPlatform.instance.releaseConsentWebView();
  }
}

/// Configuration for the Janus SDK.
class JanusConfiguration {
  /// The base URL of the Fides API.
  final String apiHost;
  
  /// The property identifier for this app.
  final String propertyId;
  
  /// Whether to use IP-based geolocation.
  final bool ipLocation;
  
  /// The region code to use if geolocation is false or fails.
  final String? region;
  
  /// Whether to map Janus events to FidesJS events in WebViews.
  final bool fidesEvents;
  
  /// The base URL of the site where you have FidesJS installed.
  /// 
  /// Required for TCF, optional for non-TCF.
  final String? webHost;
  
  JanusConfiguration({
    required this.apiHost,
    required this.propertyId,
    required this.ipLocation,
    this.region,
    this.fidesEvents = true,
    this.webHost,
  });
  
  /// Convert to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'apiHost': apiHost,
      'propertyId': propertyId,
      'ipLocation': ipLocation,
      'region': region,
      'fidesEvents': fidesEvents,
      'webHost': webHost,
    };
  }
}

/// Event data from Janus SDK.
class JanusEvent {
  /// The type of the event.
  final String eventType;
  
  /// Optional additional details about the event.
  final Map<String, dynamic>? detail;
  
  JanusEvent({
    required this.eventType,
    this.detail,
  });
  
  /// Create an event from a map.
  factory JanusEvent.fromMap(Map<String, dynamic> map) {
    return JanusEvent(
      eventType: map['eventType'],
      detail: map['detail'],
    );
  }
}
