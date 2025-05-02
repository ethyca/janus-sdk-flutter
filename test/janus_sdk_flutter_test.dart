import 'package:flutter_test/flutter_test.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter_platform_interface.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockJanusSdkFlutterPlatform
    with MockPlatformInterfaceMixin
    implements JanusSdkFlutterPlatform {

  @override
  Future<bool> initialize(JanusConfiguration config) => Future.value(true);

  @override
  Future<void> showExperience() => Future.value();

  @override
  String addConsentEventListener(void Function(JanusEvent) listener) => 'listener-id';

  @override
  void removeConsentEventListener(String listenerId) {}

  @override
  Future<Map<String, bool>> get consent => Future.value({'analytics': true});

  @override
  Future<Map<String, dynamic>> get consentMetadata => Future.value({
    'createdAt': '2023-01-01T00:00:00Z',
    'updatedAt': '2023-01-01T00:00:00Z',
    'consentMethod': 'test',
    'versionHash': 'abc123'
  });

  @override
  Future<String> get fidesString => Future.value('test-fides-string');

  @override
  Future<bool> get hasExperience => Future.value(true);

  @override
  Future<bool> get shouldShowExperience => Future.value(true);

  @override
  Future<void> clearConsent({bool clearMetadata = false}) => Future.value();

  @override
  Future<String> createConsentWebView({bool autoSyncOnStart = true}) => Future.value('mock-webview-id');

  @override
  Future<void> releaseConsentWebView(String webViewId) => Future.value();

  @override
  Future<Map<String, dynamic>> getLocationByIPAddress() => Future.value({
    'region': 'NY',
    'country': 'US',
    'location': 'US-NY',
    'ip': '192.168.1.1'
  });

  @override
  Future<String> get region => Future.value('US-NY');
}

void main() {
  final JanusSdkFlutterPlatform initialPlatform = JanusSdkFlutterPlatform.instance;

  test('$MethodChannelJanusSdkFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelJanusSdkFlutter>());
  });

  test('initialize', () async {
    Janus janusSdkPlugin = Janus();
    MockJanusSdkFlutterPlatform fakePlatform = MockJanusSdkFlutterPlatform();
    JanusSdkFlutterPlatform.instance = fakePlatform;

    final config = JanusConfiguration(
      apiHost: 'https://api.example.com',
      propertyId: 'test-property',
      ipLocation: true
    );

    expect(await janusSdkPlugin.initialize(config), true);
  });

  test('getLocationByIPAddress returns location data', () async {
    Janus janusSdkPlugin = Janus();
    MockJanusSdkFlutterPlatform fakePlatform = MockJanusSdkFlutterPlatform();
    JanusSdkFlutterPlatform.instance = fakePlatform;

    final locationData = await janusSdkPlugin.getLocationByIPAddress();

    expect(locationData, isA<Map<String, dynamic>>());
    expect(locationData['region'], 'NY');
    expect(locationData['country'], 'US');
    expect(locationData['location'], 'US-NY');
    expect(locationData['ip'], '192.168.1.1');
  });

  test('region getter returns current region', () async {
    Janus janusSdkPlugin = Janus();
    MockJanusSdkFlutterPlatform fakePlatform = MockJanusSdkFlutterPlatform();
    JanusSdkFlutterPlatform.instance = fakePlatform;

    final region = await janusSdkPlugin.region;

    expect(region, 'US-NY');
  });
}
