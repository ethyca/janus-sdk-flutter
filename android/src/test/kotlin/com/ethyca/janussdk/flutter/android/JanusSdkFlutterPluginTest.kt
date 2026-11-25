package com.ethyca.janussdk.flutter.android

import com.ethyca.janussdk.android.models.AgeBracket
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
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

  @Test
  fun ageBracketFrom_mapsEachWrapperStringToTheNativeBracket() {
    assertEquals(AgeBracket.UNDER_13, ageBracketFrom("under13"))
    assertEquals(AgeBracket.AGE_13_TO_15, ageBracketFrom("age13To15"))
    assertEquals(AgeBracket.AGE_16_TO_17, ageBracketFrom("age16To17"))
    assertEquals(AgeBracket.ADULT, ageBracketFrom("adult"))
    assertEquals(AgeBracket.UNKNOWN, ageBracketFrom("unknown"))
    assertNull(ageBracketFrom(null))
    assertNull(ageBracketFrom("UNDER_13"))
  }

  @Test
  fun setAgeSignalWithoutAValidBracket_returnsInvalidArgs() {
    val plugin = JanusSdkFlutterPlugin()
    val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

    plugin.onMethodCall(MethodCall("setAgeSignal", mapOf("ageBracket" to "teen")), result)

    Mockito.verify(result).error("INVALID_ARGS", "Unknown ageBracket \"teen\"", null)
  }
}
