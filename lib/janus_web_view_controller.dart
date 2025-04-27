import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Controller for a WebView that integrates with the Janus SDK for consent management.
///
/// This class wraps a Flutter WebViewController and provides additional functionality
/// for consent management. It maintains a connection to the native Janus SDK's
/// WebView implementation.
class JanusWebViewController {
  /// The underlying Flutter WebViewController
  final WebViewController _controller;
  
  /// The unique identifier for this WebView in the native layer
  final String _id;
  
  /// Creates a new JanusWebViewController.
  ///
  /// This constructor is typically not called directly. Instead, use
  /// [Janus.createConsentWebView] to create a new controller.
  JanusWebViewController(this._controller, this._id);
  
  /// The unique identifier for this WebView in the native layer.
  ///
  /// This is used internally to track the WebView and should not
  /// normally be needed by application code.
  String get id => _id;
  
  /// The underlying Flutter WebViewController.
  ///
  /// This can be used to perform operations on the WebView that are not
  /// directly related to consent management, such as loading URLs or
  /// executing JavaScript.
  WebViewController get controller => _controller;
  
  /// Creates a Flutter widget that displays this WebView.
  ///
  /// This is a convenience method for creating a WebViewWidget with this
  /// controller. The returned widget can be placed anywhere in your Flutter
  /// widget tree.
  ///
  /// Example:
  /// ```dart
  /// final webViewController = await janus.createConsentWebView();
  /// return Scaffold(
  ///   appBar: AppBar(title: Text('Consent WebView')),
  ///   body: webViewController.buildWidget(),
  /// );
  /// ```
  Widget buildWidget() {
    return WebViewWidget(controller: _controller);
  }
  
  /// Loads the given URL in the WebView.
  ///
  /// This is a convenience method that delegates to the underlying
  /// WebViewController.
  Future<void> loadUrl(String url) {
    return _controller.loadRequest(Uri.parse(url));
  }
  
  /// Executes the given JavaScript in the WebView.
  ///
  /// This is a convenience method that delegates to the underlying
  /// WebViewController.
  Future<void> evaluateJavaScript(String javaScript) async {
    await _controller.runJavaScript(javaScript);
  }
}
