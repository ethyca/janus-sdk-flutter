import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter_method_channel.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('janus_sdk_flutter');
  late List<MethodCall> calls;
  late JanusSdkFlutterPlatform originalPlatform;

  setUp(() {
    calls = [];
    originalPlatform = JanusSdkFlutterPlatform.instance;
    JanusSdkFlutterPlatform.instance = MethodChannelJanusSdkFlutter();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'createConsentWebView':
              return 'native-webview-id';
            case 'webViewEvaluateJavaScript':
              return '{"analytics":true}';
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    JanusSdkFlutterPlatform.instance = originalPlatform;
    debugDefaultTargetPlatformOverride = null;
  });

  test('loads and evaluates in the same native WebView, then releases it', () async {
    final janus = Janus();
    final controller = await janus.createConsentWebView(autoSyncOnStart: false);
    await controller.loadUrl('https://example.test/fides');
    final consent = await controller.evaluateJavaScript('window.Fides.consent');
    await janus.releaseConsentWebView(controller);

    expect(controller.id, 'native-webview-id');
    expect(consent, '{"analytics":true}');
    expect(calls.map((call) => call.method), [
      'createConsentWebView',
      'webViewLoadUrl',
      'webViewEvaluateJavaScript',
      'releaseConsentWebView',
    ]);
    expect(calls[0].arguments, {'autoSyncOnStart': false});
    expect(calls[1].arguments, {
      'webViewId': 'native-webview-id',
      'url': 'https://example.test/fides',
    });
    expect(calls[2].arguments, {
      'webViewId': 'native-webview-id',
      'script': 'window.Fides.consent',
    });
    expect(calls[3].arguments, {'webViewId': 'native-webview-id'});

    expect(controller.buildWidget(), isA<Text>());
    expect(() => controller.loadUrl('https://example.test'), throwsStateError);
    expect(() => controller.evaluateJavaScript('1'), throwsStateError);
    await janus.releaseConsentWebView(controller);
    expect(
      calls.where((call) => call.method == 'releaseConsentWebView'),
      hasLength(1),
    );
    expect(() => controller.controller, throwsUnsupportedError);
  });

  test('embeds native platform views rather than an unrelated WebView', () async {
    final controller = await Janus().createConsentWebView();

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final iosView = controller.buildWidget() as UiKitView;
    expect(iosView.viewType, JanusWebViewController.viewType);
    expect(iosView.creationParams, {'webViewId': controller.id});

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final androidView = controller.buildWidget() as PlatformViewLink;
    expect(androidView.viewType, JanusWebViewController.viewType);
    await Janus().releaseConsentWebView(controller);
  });

  test('initialize sends the age signal config fields to native', () async {
    await Janus().initialize(JanusConfiguration(
      apiHost: 'https://api.example.com',
      enableAgeSignal: true,
      ageBracket: AgeBracket.under13,
    ));

    expect(calls.single.method, 'initialize');
    expect(calls.single.arguments, containsPair('enableAgeSignal', true));
    expect(calls.single.arguments, containsPair('ageBracket', 'under13'));
  });

  test('setAgeSignal sends each bracket string to native', () async {
    for (final bracket in AgeBracket.values) {
      await Janus().setAgeSignal(bracket);
    }

    expect(calls.map((call) => call.method), everyElement('setAgeSignal'));
    expect(calls.map((call) => call.arguments['ageBracket']), [
      'under13',
      'age13To15',
      'age16To17',
      'adult',
      'unknown',
    ]);
  });

  test('setConsent sends parental_consent to native', () async {
    await Janus().setConsent(
      values: {'data_sales_and_sharing': true},
      consentMethod: ConsentMethod.parentalConsent,
      saveToFides: true,
    );

    expect(calls.single.method, 'setConsent');
    expect(calls.single.arguments, containsPair('consentMethod', 'parental_consent'));
  });
}
