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

  @override
  Future<bool> initialize(JanusConfiguration config) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'initialize',
        config.toMap(),
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to initialize Janus SDK: ${e.message}');
      return false;
    }
  }

  @override
  Future<void> showExperience() async {
    try {
      await methodChannel.invokeMethod<void>('showExperience');
    } on PlatformException catch (e) {
      debugPrint('Failed to show privacy experience: ${e.message}');
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
      debugPrint('Failed to get consent: ${e.message}');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> get consentMetadata async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>('getConsentMetadata');
      return result ?? {};
    } on PlatformException catch (e) {
      debugPrint('Failed to get consent metadata: ${e.message}');
      return {};
    }
  }

  @override
  Future<String> get fidesString async {
    try {
      final result = await methodChannel.invokeMethod<String>('getFidesString');
      return result ?? '';
    } on PlatformException catch (e) {
      debugPrint('Failed to get Fides string: ${e.message}');
      return '';
    }
  }

  @override
  Future<bool> get hasExperience async {
    try {
      final result = await methodChannel.invokeMethod<bool>('hasExperience');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to check if has experience: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> get shouldShowExperience async {
    try {
      final result = await methodChannel.invokeMethod<bool>('shouldShowExperience');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to check if should show experience: ${e.message}');
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
      debugPrint('Failed to clear consent: ${e.message}');
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
      debugPrint('Failed to create consent WebView: ${e.message}');
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
      debugPrint('Failed to release consent WebView: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getLocationByIPAddress() async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>('getLocationByIPAddress');
      return result ?? {};
    } on PlatformException catch (e) {
      debugPrint('Failed to get location by IP address: ${e.message}');
      return {};
    }
  }

  @override
  Future<String> get region async {
    try {
      final result = await methodChannel.invokeMethod<String>('getRegion');
      return result ?? '';
    } on PlatformException catch (e) {
      debugPrint('Failed to get region: ${e.message}');
      return '';
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
            debugPrint('Error processing event: $e');
            debugPrint('Event data: $event');
          }
        }
      },
      onError: (dynamic error) {
        debugPrint('Error from event channel: $error');
      },
    );
  }

  /// Tear down the event channel
  void _tearDownEventChannel() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }
}
