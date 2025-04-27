import 'package:janus_sdk_flutter/janus_web_view_controller.dart';

extension JanusWebViewControllerExtensions on JanusWebViewController {
  /// Load a URL in the WebView
  Future<void> loadUrl(String url) async {
    final uri = Uri.parse(url);
    await controller.loadRequest(uri);
  }
}
