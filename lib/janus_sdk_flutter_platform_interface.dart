import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'janus_sdk_flutter.dart';
import 'janus_sdk_flutter_method_channel.dart';

abstract class JanusSdkFlutterPlatform extends PlatformInterface {
  /// Constructs a JanusSdkFlutterPlatform.
  JanusSdkFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static JanusSdkFlutterPlatform _instance = MethodChannelJanusSdkFlutter();

  /// The default instance of [JanusSdkFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelJanusSdkFlutter].
  static JanusSdkFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [JanusSdkFlutterPlatform] when
  /// they register themselves.
  static set instance(JanusSdkFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize the Janus SDK with the provided configuration.
  Future<bool> initialize(JanusConfiguration config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Show the privacy experience UI.
  Future<void> showExperience() {
    throw UnimplementedError('showExperience() has not been implemented.');
  }

  /// Add a listener for consent events.
  String addConsentEventListener(void Function(JanusEvent) listener) {
    throw UnimplementedError('addConsentEventListener() has not been implemented.');
  }

  /// Remove a consent event listener.
  void removeConsentEventListener(String listenerId) {
    throw UnimplementedError('removeConsentEventListener() has not been implemented.');
  }

  /// Get the current consent values.
  Future<Map<String, bool>> get consent {
    throw UnimplementedError('consent getter has not been implemented.');
  }

  /// Get metadata about the consent, including creation and update timestamps.
  Future<Map<String, dynamic>> get consentMetadata {
    throw UnimplementedError('consentMetadata getter has not been implemented.');
  }

  /// Get the Fides string representation of consent.
  Future<String> get fidesString {
    throw UnimplementedError('fidesString getter has not been implemented.');
  }

  /// Check if a valid privacy experience is available.
  Future<bool> get hasExperience {
    throw UnimplementedError('hasExperience has not been implemented.');
  }

  /// Check if the privacy experience should be shown.
  Future<bool> get shouldShowExperience {
    throw UnimplementedError('shouldShowExperience has not been implemented.');
  }

  /// Create a WebView with consent functionality.
  ///
  /// Returns a unique identifier for the WebView that can be used to reference
  /// it in subsequent calls.
  Future<String> createConsentWebView({bool autoSyncOnStart = true}) {
    throw UnimplementedError('createConsentWebView() has not been implemented.');
  }

  /// Release a WebView from Janus management.
  ///
  /// [webViewId] is the identifier returned by [createConsentWebView].
  Future<void> releaseConsentWebView(String webViewId) {
    throw UnimplementedError('releaseConsentWebView() has not been implemented.');
  }

  /// Get the user's region by IP address lookup.
  ///
  /// Returns a map containing region information, including:
  /// - `region`: The ISO-3166-2 region code (e.g., "US-CA")
  /// - `country`: The ISO-3166-1 country code (e.g., "US")
  Future<Map<String, dynamic>> getLocationByIPAddress() {
    throw UnimplementedError('getLocationByIPAddress() has not been implemented.');
  }

  /// Get the region currently being used by the SDK.
  ///
  /// This returns the region that was either:
  /// 1. Provided in the configuration
  /// 2. Determined by IP geolocation
  /// 3. Set as a fallback
  Future<String> get region {
    throw UnimplementedError('region getter has not been implemented.');
  }

  /// Clear consent
  Future<void> clearConsent({bool clearMetadata = false}) {
    throw UnimplementedError('clearConsent() has not been implemented.');
  }
}
