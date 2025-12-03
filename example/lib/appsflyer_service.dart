import 'package:appsflyer_sdk/appsflyer_sdk.dart';

class AppsflyerService {
  static final AppsflyerService _instance = AppsflyerService._internal();
  factory AppsflyerService() => _instance;
  AppsflyerService._internal();

  late AppsflyerSdk _appsflyerSdk;
  bool _initialized = false;

  // Read from --dart-define
  static const String _devKey = String.fromEnvironment('AF_DEV_KEY');
  static const String _appId = String.fromEnvironment('AF_APP_ID');

  Future<void> initialize() async {
    if (_initialized) return;

    // Validate credentials
    if (_devKey.isEmpty) {
      throw Exception('AF_DEV_KEY not provided. Pass via --dart-define=AF_DEV_KEY=your_key');
    }
    if (_appId.isEmpty) {
      throw Exception('AF_APP_ID not provided. Pass via --dart-define=AF_APP_ID=your_id');
    }

    AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: _devKey,
      appId: _appId, // Required for iOS
      showDebug: true,
      timeToWaitForATTUserAuthorization: 60, // Optional: wait for ATT
    );

    _appsflyerSdk = AppsflyerSdk(options);
    
    await _appsflyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    // Start the SDK (synchronous call, no await)
    _appsflyerSdk.startSDK();
    print('[AppsFlyer] SDK started');
    
    _initialized = true;
  }

  Future<String?> getAppsFlyerId() async {
    try {
      return await _appsflyerSdk.getAppsFlyerUID();
    } catch (e) {
      print('[AppsFlyer] Error getting AppsFlyer ID: $e');
      return null;
    }
  }

  Future<void> logEvent(String eventName, Map<String, dynamic>? eventValues) async {
    _ensureInitialized();
    final result = await _appsflyerSdk.logEvent(eventName, eventValues);
    print('[AppsFlyer] Event "$eventName" logged: $result');
  }

  void setCustomerUserId(String userId) {
    _ensureInitialized();
    _appsflyerSdk.setCustomerUserId(userId);
  }

  /// Privacy Controls
  
  /// Ensures SDK is initialized before operations
  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception('SDK not initialized. Call initialize() first.');
    }
  }
  
  /// Anonymize user - stops collecting device IDs
  void anonymizeUser(bool shouldAnonymize) {
    _ensureInitialized();
    _appsflyerSdk.anonymizeUser(shouldAnonymize);
    print('[AppsFlyer] User anonymization set to: $shouldAnonymize');
  }

  /// Stop the SDK (for consent management)
  void stop(bool shouldStop) {
    _ensureInitialized();
    _appsflyerSdk.stop(shouldStop);
    print('[AppsFlyer] SDK stopped: $shouldStop');
  }

  /// Disable advertising identifiers collection
  void disableAdvertisingIdentifiers(bool disable) {
    _ensureInitialized();
    _appsflyerSdk.setDisableAdvertisingIdentifiers(disable);
    print('[AppsFlyer] Advertising identifiers disabled: $disable');
  }

  /// Set sharing filter for specific partners
  void setSharingFilterForPartners(List<String> partners) {
    _ensureInitialized();
    _appsflyerSdk.setSharingFilterForPartners(partners);
    print('[AppsFlyer] Sharing filter set for partners: $partners');
  }

  String get devKey => _devKey;
  String get appId => _appId;
  bool get isInitialized => _initialized;
  AppsflyerSdk get sdk => _appsflyerSdk;
}
