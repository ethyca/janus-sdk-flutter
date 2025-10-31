import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';

import 'janus_sdk_flutter_platform_interface.dart';
import 'janus_sdk_flutter_method_channel.dart';
import 'janus_web_view_controller.dart';
import 'janus_event_type.dart';
import 'janus_logger.dart';
import 'consent_flag_type.dart';
import 'consent_non_applicable_flag_mode.dart';

// Export public types
export 'janus_event_type.dart';
export 'janus_logger.dart';
export 'consent_flag_type.dart';
export 'consent_non_applicable_flag_mode.dart';

/// The main class for the Janus SDK Flutter plugin.
///
/// This class provides privacy consent management functionality by wrapping
/// the native Android and iOS SDKs.
class Janus {
  /// Private logger instance
  static JanusLogger _logger = DefaultJanusLogger();

  /// Static initializer to register log handler
  static bool _logHandlerRegistered = false;

  /// Set the logger implementation for the SDK
  ///
  /// [logger] - The logger implementation to use. Pass null to reset to default.
  static void setLogger(JanusLogger? logger) {
    _logger = logger ?? DefaultJanusLogger();

    // Register log handler if not already done
    if (!_logHandlerRegistered) {
      MethodChannelJanusSdkFlutter.setLogHandler(_handleNativeLog);
      _logHandlerRegistered = true;
    }

    // Tell native sides to use proxy loggers that call back to Flutter
    _setNativeProxyLoggers();
  }

  /// Tell native platforms to use proxy loggers that route back to Flutter
  static void _setNativeProxyLoggers() {
    try {
      log('Setting native proxy loggers', level: LogLevel.debug);
      JanusSdkFlutterPlatform.instance.setLogger(useProxy: true);
    } catch (e) {
      // If platform interface doesn't support logging yet, continue
      // This allows gradual rollout
      log('Failed to set native proxy loggers: $e', level: LogLevel.warning);
    }
  }

  /// Log a message with optional level and metadata
  /// Internal use only - not part of the public SDK API
  static void _log(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, String>? metadata,
    Exception? error,
  }) {
    _logger.log(message, level: level, metadata: metadata, error: error);
  }

  /// Package-internal logging method for use by other SDK components
  /// This is NOT part of the public API and should only be used internally
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, String>? metadata,
    Exception? error,
  }) {
    _log(message, level: level, metadata: metadata, error: error);
  }

  /// Handle log calls from native platforms (iOS/Android proxy loggers)
  /// This is called via method channel when native code logs
  static void _handleNativeLog(
    String message,
    String levelString,
    Map<String, String>? metadata,
  ) {
    // Convert string level to enum with fallback to info
    LogLevel level;
    try {
      level = LogLevel.values.byName(levelString.toLowerCase());
    } on Object catch (_) {
      level = LogLevel.info; // fallback for unknown levels
    }

    _logger.log(message, level: level, metadata: metadata);
  }

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

  /// Get the current consent values in external format.
  ///
  /// The format of values depends on the consentFlagType configuration:
  /// - boolean: Returns `Map<String, bool>`
  /// - consentMechanism: Returns `Map<String, String>`
  Future<Map<String, dynamic>> get consent {
    return JanusSdkFlutterPlatform.instance.consent;
  }

  /// Get the current consent values in internal boolean format.
  ///
  /// This always returns boolean values regardless of the consentFlagType configuration.
  /// This method is intended for internal SDK use only.
  Future<Map<String, bool>> get internalConsent {
    return JanusSdkFlutterPlatform.instance.internalConsent;
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

  /// Get the current privacy experience item, if available.
  Future<Map<String, dynamic>?> get currentExperience {
    return JanusSdkFlutterPlatform.instance.currentExperience;
  }

  /// Whether the current privacy experience is a TCF experience.
  Future<bool> get isTCFExperience {
    return JanusSdkFlutterPlatform.instance.isTCFExperience;
  }

  /// Clear all consent data.
  ///
  /// [clearMetadata] - Whether to also clear consent metadata (defaults to false).
  Future<void> clearConsent({bool clearMetadata = false}) {
    return JanusSdkFlutterPlatform.instance.clearConsent(
      clearMetadata: clearMetadata,
    );
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
  Future<JanusWebViewController> createConsentWebView({
    bool autoSyncOnStart = true,
  }) async {
    final webViewId = await JanusSdkFlutterPlatform.instance
        .createConsentWebView(autoSyncOnStart: autoSyncOnStart);

    // Create and configure the Flutter WebViewController
    final controller =
        WebViewController()
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
    return JanusSdkFlutterPlatform.instance.releaseConsentWebView(
      webViewController.id,
    );
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

  /// The privacy center host endpoint
  final String privacyCenterHost;

  /// The property identifier for this app.
  final String propertyId;

  /// Whether to use IP-based geolocation.
  final bool ipLocation;

  /// The region code to use if geolocation is false or fails.
  final String region;

  /// Whether to map Janus events to FidesJS events in WebViews.
  final bool fidesEvents;

  /// Whether to automatically show the privacy experience after initialization.
  final bool autoShowExperience;

  /// Whether to save user preferences to Fides via privacy-preferences API.
  final bool saveUserPreferencesToFides;

  /// Whether to save notices served to Fides via notices-served API.
  final bool saveNoticesServedToFides;

  /// The format for consent values returned by external interfaces.
  /// Defaults to boolean.
  final ConsentFlagType consentFlagType;

  /// Controls how non-applicable privacy notices are handled in consent objects.
  /// Defaults to omit.
  final ConsentNonApplicableFlagMode consentNonApplicableFlagMode;

  JanusConfiguration({
    required this.apiHost,
    this.privacyCenterHost = "",
    this.propertyId = "",
    this.ipLocation = true,
    this.region = "",
    this.fidesEvents = true,
    this.autoShowExperience = true,
    this.saveUserPreferencesToFides = true,
    this.saveNoticesServedToFides = true,
    this.consentFlagType = ConsentFlagType.boolean,
    this.consentNonApplicableFlagMode = ConsentNonApplicableFlagMode.omit,
  });

  /// Convert to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'apiHost': apiHost,
      'privacyCenterHost': privacyCenterHost,
      'propertyId': propertyId,
      'ipLocation': ipLocation,
      'region': region,
      'fidesEvents': fidesEvents,
      'autoShowExperience': autoShowExperience,
      'saveUserPreferencesToFides': saveUserPreferencesToFides,
      'saveNoticesServedToFides': saveNoticesServedToFides,
      'consentFlagType': consentFlagType.value,
      'consentNonApplicableFlagMode': consentNonApplicableFlagMode.value,
    };
  }
}

/// Event data from Janus SDK.
class JanusEvent {
  /// The type of the event.
  final JanusEventType eventType;

  /// Optional additional details about the event.
  final Map<String, dynamic>? detail;

  JanusEvent({required this.eventType, this.detail});

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
      detailMap = <String, dynamic>{};
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
