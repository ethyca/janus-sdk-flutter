package com.ethyca.janussdk.flutter.android

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import org.mockito.Mockito

internal class JanusSdkFlutterPluginTest {
  @Test
  fun releaseUnknownWebView_returnsInvalidIdWithoutDestroyingAnything() {
    val plugin = JanusSdkFlutterPlugin()
    val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

    plugin.onMethodCall(
      MethodCall("releaseConsentWebView", mapOf("webViewId" to "missing")),
      result
    )

    Mockito.verify(result).error("INVALID_WEBVIEW_ID", "WebView ID not found", null)
  }

  @Test
  fun loadUrl_acceptsHttpUrlsAndRejectsOtherSchemesOrMissingHosts() {
    assertTrue(isSupportedWebViewUrl("https://example.test/fides"))
    assertTrue(isSupportedWebViewUrl("http://example.test/fides"))
    assertFalse(isSupportedWebViewUrl("file:///tmp/fides.html"))
    assertFalse(isSupportedWebViewUrl("javascript:alert(1)"))
    assertFalse(isSupportedWebViewUrl("//example.test/fides"))
    assertFalse(isSupportedWebViewUrl("https:///fides"))
  }
}
