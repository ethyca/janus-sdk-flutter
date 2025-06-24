import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'janus_sdk_flutter.dart';
import 'janus_sdk_flutter_platform_interface.dart';

/// An implementation of [JanusSdkFlutterPlatform] that uses method channels.
class MethodChannelJanusSdkFlutter extends JanusSdkFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('janus_sdk_flutter');

  /// The event channel for receiving consent events
  final eventChannel = const EventChannel('janus_sdk_flutter/events');

  /// Stream subscription for event channel
  StreamSubscription? _eventSubscription;

  /// Map of event listeners by ID
  final Map<String, void Function(JanusEvent)> _eventListeners = {};

  /// Counter for generating listener IDs
  int _listenerIdCounter = 0;
  
  /// Callback for handling native log calls
  static void Function(String, String, Map<String, String>?)? _logHandler;
  
  /// Set the log handler callback
  static void setLogHandler(void Function(String, String, Map<String, String>?) handler) {
    _logHandler = handler;
  }
  
  /// Constructor sets up method call handler for incoming log calls
  MethodChannelJanusSdkFlutter() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }
  
  /// Handle method calls from native platforms (including log calls)
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'log':
        final arguments = call.arguments as Map<dynamic, dynamic>;
        final message = arguments['message'] as String;
        final level = arguments['level'] as String;
        final metadataRaw = arguments['metadata'];
        
        // Convert metadata to Map<String, String>? if present
        Map<String, String>? metadata;
        if (metadataRaw != null && metadataRaw is Map) {
          metadata = <String, String>{};
          metadataRaw.forEach((key, value) {
            if (key != null && value != null) {
              metadata![key.toString()] = value.toString();
            }
          });
        }
        
        // Forward to registered log handler
        if (_logHandler != null) {
          _logHandler!(message, level, metadata);
        }
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented',
        );
    }
  }

  @override
  Future<bool> initialize(JanusConfiguration config) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'initialize',
        config.toMap(),
      );
      return result ?? false;
    } on PlatformException catch (e) {
      Janus.log('Failed to initialize Janus SDK: ${e.message}', level: LogLevel.error, metadata: {'code': e.code});
      return false;
    }
  }

  @override
  Future<void> showExperience() async {
    try {
      await methodChannel.invokeMethod<void>('showExperience');
    } on PlatformException catch (e) {
      Janus.log('Failed to show privacy experience', level: LogLevel.error, error: e);
      rethrow;
    }
  }

  @override
  String addConsentEventListener(void Function(JanusEvent) listener) {
    // Set up the event channel if this is the first listener
    if (_eventListeners.isEmpty) {
      _setupEventChannel();
    }

    // Generate a unique ID for this listener
    final id = 'listener_${_listenerIdCounter++}';
    _eventListeners[id] = listener;

    return id;
  }

  @override
  void removeConsentEventListener(String listenerId) {
    _eventListeners.remove(listenerId);

    // Clean up the event channel if there are no more listeners
    if (_eventListeners.isEmpty) {
      _tearDownEventChannel();
    }
  }

  @override
  Future<Map<String, bool>> get consent async {
    try {
      final result = await methodChannel.invokeMapMethod<String, bool>('getConsent');
      return result ?? {};
    } on PlatformException catch (e) {
      Janus.log('Failed to get consent', level: LogLevel.error, error: e);
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> get consentMetadata async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>('getConsentMetadata');
      return result ?? {};
    } on PlatformException catch (e) {
      Janus.log('Failed to get consent metadata', level: LogLevel.error, error: e);
      return {};
    }
  }

  @override
  Future<String> get fidesString async {
    try {
      final result = await methodChannel.invokeMethod<String>('getFidesString');
      return result ?? '';
    } on PlatformException catch (e) {
      Janus.log('Failed to get Fides string', level: LogLevel.error, error: e);
      return '';
    }
  }

  @override
  Future<bool> get hasExperience async {
    try {
      final result = await methodChannel.invokeMethod<bool>('hasExperience');
      return result ?? false;
    } on PlatformException catch (e) {
      Janus.log('Failed to check if has experience', level: LogLevel.error, error: e);
      return false;
    }
  }

  @override
  Future<bool> get shouldShowExperience async {
    try {
      final result = await methodChannel.invokeMethod<bool>('shouldShowExperience');
      return result ?? false;
    } on PlatformException catch (e) {
      Janus.log('Failed to check if should show experience', level: LogLevel.error, error: e);
      return false;
    }
  }

  @override
  Future<void> clearConsent({bool clearMetadata = false}) async {
    try {
      await methodChannel.invokeMethod<void>(
        'clearConsent',
        {'clearMetadata': clearMetadata},
      );
    } on PlatformException catch (e) {
      Janus.log('Failed to clear consent', level: LogLevel.error, error: e);
      rethrow;
    }
  }

  @override
  Future<String> createConsentWebView({bool autoSyncOnStart = true}) async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'createConsentWebView',
        {'autoSyncOnStart': autoSyncOnStart},
      );
      return result ?? '';
    } on PlatformException catch (e) {
      Janus.log('Failed to create consent WebView', level: LogLevel.error, error: e);
      rethrow;
    }
  }

  @override
  Future<void> releaseConsentWebView(String webViewId) async {
    try {
      await methodChannel.invokeMethod<void>(
        'releaseConsentWebView',
        {'webViewId': webViewId},
      );
    } on PlatformException catch (e) {
      Janus.log('Failed to release consent WebView', level: LogLevel.error, metadata: {'webViewId': webViewId}, error: e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getLocationByIPAddress() async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>('getLocationByIPAddress');
      return result ?? {};
    } on PlatformException catch (e) {
      Janus.log('Failed to get location by IP address', level: LogLevel.error, error: e);
      return {};
    }
  }

  @override
  Future<String> get region async {
    try {
      final result = await methodChannel.invokeMethod<String>('getRegion');
      return result ?? '';
    } on PlatformException catch (e) {
      Janus.log('Failed to get region', level: LogLevel.error, error: e);
      return '';
    }
  }

  @override
  Future<void> setLogger({required bool useProxy}) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setLogger',
        {'useProxy': useProxy},
      );
    } on PlatformException catch (e) {
      Janus.log('Failed to set logger', level: LogLevel.warning, error: e);
      // Don't rethrow - logging setup is optional
    }
  }

  /// Set up the event channel for receiving consent events
  void _setupEventChannel() {
    _eventSubscription = eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          try {
            // Pass the event map directly to JanusEvent.fromMap
            // which now handles dynamic maps properly
            final janusEvent = JanusEvent.fromMap(event);

            // Notify all listeners
            for (final listener in _eventListeners.values) {
              listener(janusEvent);
            }
          } catch (e) {
            final exception = e is Exception ? e : Exception('Error processing event: $e');
            Janus.log('Error processing event: $e', level: LogLevel.error, error: exception);
          }
        }
      },
      onError: (dynamic error) {
        Janus.log('Error from event channel: $error', level: LogLevel.error);
      },
    );
  }

  /// Tear down the event channel
  void _tearDownEventChannel() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }
}
