import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'janus_sdk_flutter_platform_interface.dart';

/// Controls a Janus-managed native WebView used by a page running FidesJS.
class JanusWebViewController {
  static const String viewType = 'janus_sdk_flutter/consent_webview';

  final String _id;
  bool _released = false;

  /// Kept for source compatibility; use [Janus.createConsentWebView].
  @Deprecated('Use Janus.createConsentWebView to create managed WebViews.')
  JanusWebViewController(WebViewController controller, this._id);

  /// Creates a handle to an existing Janus-managed native WebView.
  JanusWebViewController.fromId(this._id);

  /// The native WebView identifier.
  String get id => _id;

  /// This controller is not connected to the Janus-managed native WebView.
  /// Use [loadUrl], [evaluateJavaScript] and [buildWidget] instead.
  @Deprecated(
    'This controller is not Janus-managed. Use loadUrl, evaluateJavaScript and buildWidget.',
  )
  WebViewController get controller => throw UnsupportedError(
    'JanusWebViewController.controller is not connected to the native WebView. '
    'Use loadUrl, evaluateJavaScript and buildWidget instead.',
  );

  void _ensureActive() {
    if (_released) {
      throw StateError('Janus consent WebView $_id has been released');
    }
  }

  /// Embeds the Janus-managed native WebView. The app must call [loadUrl]
  /// with a FidesJS-enabled page; this widget does not show a consent UI and
  /// stays blank until a page is loaded. Unmount it before releasing the view.
  Widget buildWidget() {
    if (_released) return const Text('Janus consent WebView has been released');
    final creationParams = {'webViewId': _id};
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: viewType,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.android:
        return PlatformViewLink(
          viewType: viewType,
          surfaceFactory: (context, controller) => AndroidViewSurface(
            controller: controller as AndroidViewController,
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          ),
          onCreatePlatformView: (params) => PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
          )..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
           ..create(),
        );
      default:
        throw UnsupportedError('Janus consent WebViews require iOS or Android');
    }
  }

  /// Loads an app-supplied FidesJS-enabled page into the managed WebView.
  Future<void> loadUrl(String url) {
    _ensureActive();
    return JanusSdkFlutterPlatform.instance.webViewLoadUrl(_id, url);
  }

  /// Evaluates JavaScript on the managed WebView and returns its result.
  Future<String?> evaluateJavaScript(String javaScript) {
    _ensureActive();
    return JanusSdkFlutterPlatform.instance.webViewEvaluateJavaScript(
      _id,
      javaScript,
    );
  }

  /// Releases the native WebView and its Janus bridge. Repeated releases are safe.
  Future<void> release() async {
    if (_released) return;
    _released = true;
    try {
      await JanusSdkFlutterPlatform.instance.releaseConsentWebView(_id);
    } on PlatformException catch (error) {
      if (error.code == 'INVALID_WEBVIEW_ID') return;
      _released = false;
      rethrow;
    } catch (_) {
      _released = false;
      rethrow;
    }
  }
}
