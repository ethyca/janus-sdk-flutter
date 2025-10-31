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
  String addConsentEventListener(void Function(JanusEvent) listener) =>
      'listener-id';

  @override
  void removeConsentEventListener(String listenerId) {}

  @override
  Future<Map<String, dynamic>> get consent => Future.value({'analytics': true});

  @override
  Future<Map<String, bool>> get internalConsent =>
      Future.value({'analytics': true});

  @override
  Future<Map<String, dynamic>> get consentMetadata => Future.value({
    'createdAt': '2023-01-01T00:00:00Z',
    'updatedAt': '2023-01-01T00:00:00Z',
    'consentMethod': 'test',
    'versionHash': 'abc123',
  });

  @override
  Future<String> get fidesString => Future.value('test-fides-string');

  @override
  Future<bool> get hasExperience => Future.value(true);

  @override
  Future<bool> get shouldShowExperience => Future.value(true);

  @override
  Future<Map<String, dynamic>?> get currentExperience => Future.value({
    'id': 'test-exp-id',
    'createdAt': '2023-01-01T00:00:00Z',
    'updatedAt': '2023-01-01T00:00:00Z',
    'region': 'US-CA',
    'isTCFExperience': true,
  });

  @override
  Future<bool> get isTCFExperience => Future.value(true);

  @override
  Future<void> clearConsent({bool clearMetadata = false}) => Future.value();

  @override
  Future<String> createConsentWebView({bool autoSyncOnStart = true}) =>
      Future.value('mock-webview-id');

  @override
  Future<void> releaseConsentWebView(String webViewId) => Future.value();

  @override
  Future<Map<String, dynamic>> getLocationByIPAddress() => Future.value({
    'region': 'NY',
    'country': 'US',
    'location': 'US-NY',
    'ip': '192.168.1.1',
  });

  @override
  Future<String> get region => Future.value('US-NY');

  @override
  Future<void> setLogger({required bool useProxy}) => Future.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final JanusSdkFlutterPlatform initialPlatform =
      JanusSdkFlutterPlatform.instance;

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
      ipLocation: true,
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

  test('JanusConfiguration toMap includes all configuration options', () {
    final config = JanusConfiguration(
      apiHost: 'https://api.example.com',
      privacyCenterHost: 'https://privacy.example.com',
      propertyId: 'test-property',
      ipLocation: false,
      region: 'US-CA',
      fidesEvents: false,
      autoShowExperience: false,
      saveUserPreferencesToFides: false,
      saveNoticesServedToFides: false,
      consentFlagType: ConsentFlagType.consentMechanism,
    );

    final map = config.toMap();

    expect(map['apiHost'], 'https://api.example.com');
    expect(map['privacyCenterHost'], 'https://privacy.example.com');
    expect(map['propertyId'], 'test-property');
    expect(map['ipLocation'], false);
    expect(map['region'], 'US-CA');
    expect(map['fidesEvents'], false);
    expect(map['autoShowExperience'], false);
    expect(map['saveUserPreferencesToFides'], false);
    expect(map['saveNoticesServedToFides'], false);
    expect(map['consentFlagType'], 'consentMechanism');
  });

  test('JanusConfiguration defaults', () {
    final config = JanusConfiguration(apiHost: 'https://api.example.com');

    final map = config.toMap();

    expect(map['apiHost'], 'https://api.example.com');
    expect(map['privacyCenterHost'], '');
    expect(map['propertyId'], '');
    expect(map['ipLocation'], true);
    expect(map['region'], '');
    expect(map['fidesEvents'], true);
    expect(map['autoShowExperience'], true);
    expect(map['saveUserPreferencesToFides'], true);
    expect(map['saveNoticesServedToFides'], true);
    expect(map['consentFlagType'], 'boolean');
  });

  test('ConsentFlagType enum values', () {
    expect(ConsentFlagType.boolean.value, 'boolean');
    expect(ConsentFlagType.consentMechanism.value, 'consentMechanism');
    expect(ConsentFlagType.boolean.toString(), 'boolean');
    expect(ConsentFlagType.consentMechanism.toString(), 'consentMechanism');
  });

  test('ConsentFlagType fromString', () {
    expect(ConsentFlagType.fromString('boolean'), ConsentFlagType.boolean);
    expect(ConsentFlagType.fromString('BOOLEAN'), ConsentFlagType.boolean);
    expect(
      ConsentFlagType.fromString('consentMechanism'),
      ConsentFlagType.consentMechanism,
    );
    expect(
      ConsentFlagType.fromString('CONSENTMECHANISM'),
      ConsentFlagType.consentMechanism,
    );
    expect(
      ConsentFlagType.fromString('invalid'),
      ConsentFlagType.boolean,
    ); // fallback
  });

  test('consent getter returns dynamic values', () async {
    Janus janusSdkPlugin = Janus();
    MockJanusSdkFlutterPlatform fakePlatform = MockJanusSdkFlutterPlatform();
    JanusSdkFlutterPlatform.instance = fakePlatform;

    final consent = await janusSdkPlugin.consent;
    expect(consent, isA<Map<String, dynamic>>());
    expect(consent['analytics'], true);
  });

  test('internalConsent getter returns boolean values', () async {
    Janus janusSdkPlugin = Janus();
    MockJanusSdkFlutterPlatform fakePlatform = MockJanusSdkFlutterPlatform();
    JanusSdkFlutterPlatform.instance = fakePlatform;

    final internalConsent = await janusSdkPlugin.internalConsent;
    expect(internalConsent, isA<Map<String, bool>>());
    expect(internalConsent['analytics'], true);
  });

  test('currentExperience getter returns experience data', () async {
    Janus janusSdkPlugin = Janus();
    MockJanusSdkFlutterPlatform fakePlatform = MockJanusSdkFlutterPlatform();
    JanusSdkFlutterPlatform.instance = fakePlatform;

    final experience = await janusSdkPlugin.currentExperience;
    expect(experience, isA<Map<String, dynamic>?>());
    expect(experience!['id'], 'test-exp-id');
    expect(experience['region'], 'US-CA');
    expect(experience['isTCFExperience'], true);
  });

  test('isTCFExperience getter returns boolean value', () async {
    Janus janusSdkPlugin = Janus();
    MockJanusSdkFlutterPlatform fakePlatform = MockJanusSdkFlutterPlatform();
    JanusSdkFlutterPlatform.instance = fakePlatform;

    final isTCF = await janusSdkPlugin.isTCFExperience;
    expect(isTCF, isA<bool>());
    expect(isTCF, true);
  });
}
