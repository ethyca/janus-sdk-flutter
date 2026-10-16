package com.ethyca.janussdk.flutter.android

import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import android.widget.TextView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class ConsentWebViewFactory(private val webViews: Map<String, WebView>) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    val webViewId = (args as? Map<*, *>)?.get("webViewId") as? String
    val webView = webViewId?.let { webViews[it] }
    val view = if (webView == null) {
      TextView(context).apply { text = "Janus consent WebView is no longer available" }
    } else {
      (webView.parent as? ViewGroup)?.removeView(webView)
      webView
    }
    return object : PlatformView {
      override fun getView(): View = view

      override fun dispose() {
        // The explicit release method owns the WebView and Janus bridge lifecycle.
      }
    }
  }
}
