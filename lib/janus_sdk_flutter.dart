import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';

import 'janus_sdk_flutter_platform_interface.dart';
import 'janus_web_view_controller.dart';
import 'janus_event_type.dart';

// Export public types
export 'janus_event_type.dart';

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

  /// Creates a WebView controller for consent management.
  ///
  /// This method creates a WebView that is configured for consent management
  /// and returns a controller that can be used to interact with it.
  ///
  /// [autoSyncOnStart] determines whether to enable initial synchronization
  /// when the webview loads.
  ///
  /// Example:
  /// ```dart
  /// final webViewController = await janus.createConsentWebView();
  /// return Scaffold(
  ///   appBar: AppBar(title: Text('Consent WebView')),
  ///   body: webViewController.buildWidget(),
  /// );
  /// ```
  Future<JanusWebViewController> createConsentWebView({bool autoSyncOnStart = true}) async {
    final webViewId = await JanusSdkFlutterPlatform.instance.createConsentWebView(
      autoSyncOnStart: autoSyncOnStart
    );

    // Create and configure the Flutter WebViewController
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation requests
            return NavigationDecision.navigate;
          },
        ),
      );

    return JanusWebViewController(controller, webViewId);
  }

  /// Release a WebView from Janus management.
  ///
  /// This method should be called when you're done with a WebView to free
  /// resources and remove any event listeners.
  ///
  /// [webViewController] is the controller returned by [createConsentWebView].
  Future<void> releaseConsentWebView(JanusWebViewController webViewController) {
    return JanusSdkFlutterPlatform.instance.releaseConsentWebView(webViewController.id);
  }

  /// Get the user's region by IP address lookup.
  ///
  /// This method performs a network request to determine the user's region
  /// based on their IP address.
  ///
  /// Returns a map containing region information, including:
  /// - `region`: The ISO-3166-2 region code (e.g., "US-CA")
  /// - `country`: The ISO-3166-1 country code (e.g., "US")
  Future<Map<String, dynamic>> getLocationByIPAddress() {
    return JanusSdkFlutterPlatform.instance.getLocationByIPAddress();
  }

  /// Get the region currently being used by the SDK.
  ///
  /// This returns the region that was either:
  /// 1. Provided in the configuration
  /// 2. Determined by IP geolocation
  /// 3. Set as a fallback
  Future<String> get region {
    return JanusSdkFlutterPlatform.instance.region;
  }
}

/// Configuration for the Janus SDK.
class JanusConfiguration {
  /// The base URL of the Fides API.
  final String apiHost;

  /// The property identifier for this app.
  final String? propertyId;

  /// Whether to use IP-based geolocation.
  final bool ipLocation;

  /// The region code to use if geolocation is false or fails.
  final String? region;

  /// Whether to map Janus events to FidesJS events in WebViews.
  final bool fidesEvents;

  JanusConfiguration({
    required this.apiHost,
    this.propertyId,
    this.ipLocation = true,
    this.region,
    this.fidesEvents = true
  });

  /// Convert to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'apiHost': apiHost,
      'propertyId': propertyId,
      'ipLocation': ipLocation,
      'region': region,
      'fidesEvents': fidesEvents
    };
  }
}

/// Event data from Janus SDK.
class JanusEvent {
  /// The type of the event.
  final JanusEventType eventType;

  /// Optional additional details about the event.
  final Map<String, dynamic>? detail;

  JanusEvent({
    required this.eventType,
    this.detail,
  });

  /// Create an event from a map.
  factory JanusEvent.fromMap(Map<dynamic, dynamic> map) {
    // Get the event type string and convert it to a JanusEventType
    String eventTypeStr = '';
    if (map['eventType'] != null) {
      eventTypeStr = map['eventType'].toString();
    }

    // Convert the detail map to a Map<String, dynamic>
    Map<String, dynamic>? detailMap;
    if (map['detail'] != null) {
      detailMap = {};
      final detail = map['detail'];
      if (detail is Map) {
        detail.forEach((key, value) {
          if (key != null) {
            detailMap![key.toString()] = value;
          }
        });
      }
    }

    return JanusEvent(
      eventType: JanusEventType.fromString(eventTypeStr),
      detail: detailMap,
    );
  }
}
