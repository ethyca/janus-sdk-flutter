package com.ethyca.janussdk.flutter.android

import android.app.Activity
import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import com.ethyca.janussdk.android.Janus
import com.ethyca.janussdk.android.JanusConfiguration
import com.ethyca.janussdk.android.events.JanusEvent
import java.util.Date

/** JanusSdkFlutterPlugin */
class JanusSdkFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
  /// The MethodChannel that will handle communication between Flutter and native Android
  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var activity: Activity? = null

  // Event channel sink for sending events to Flutter
  private var eventSink: EventChannel.EventSink? = null

  // Store event listener ID for removal later
  private var eventListenerId: String? = null

  // Map to store WebView instances by ID
  private val webViews = HashMap<String, android.webkit.WebView>()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "janus_sdk_flutter")
    channel.setMethodCallHandler(this)

    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "janus_sdk_flutter/events")
    eventChannel.setStreamHandler(this)

    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    try {
      when (call.method) {
        "initialize" -> {
          try {
            val args = call.arguments as Map<String, Any>
            val apiHost = args["apiHost"] as String
            val propertyId = args["propertyId"] as? String ?: ""
            val privacyCenterHost = args["privacyCenterHost"] as? String ?: ""
            val ipLocation = args["ipLocation"] as Boolean
            val region = args["region"] as? String ?: ""
            val fidesEvents = args["fidesEvents"] as? Boolean ?: true

            // Create configuration using Builder pattern
            val configBuilder = JanusConfiguration.Builder()
              .apiHost(apiHost)
              .propertyId(propertyId)
              .privacyCenterHost(privacyCenterHost)
              .ipLocation(ipLocation)
              .region(region)
              .fidesEvents(fidesEvents)

            val config = configBuilder.build()

            // Initialize the SDK with the activity instead of context
            activity?.let { act ->
              Janus.initialize(act, config) { success, error ->
                if (success) {
                  result.success(true)
                } else {
                  result.error("INIT_ERROR", error?.message ?: "Unknown error", null)
                }
              }
            } ?: result.error("NO_ACTIVITY", "Activity is not available", null)
          } catch (e: Exception) {
            result.error("INVALID_ARGS", e.message, null)
          }
        }

        "showExperience" -> {
          activity?.let {
            try {
              Janus.showExperience(it)
              result.success(null)
            } catch (e: Exception) {
              result.error("SHOW_EXP_ERROR", e.message, null)
            }
          } ?: result.error("NO_ACTIVITY", "Activity is not available", null)
        }

        "getConsent" -> {
          result.success(Janus.consent)
        }

        "getConsentMetadata" -> {
          try {
            val metadata = Janus.consentMetadata
            val resultMap = HashMap<String, Any?>()

            // Convert Date objects to timestamps
            metadata.createdAt?.let { resultMap["createdAt"] = it.time }
            metadata.updatedAt?.let { resultMap["updatedAt"] = it.time }
            resultMap["consentMethod"] = metadata.consentMethod
            resultMap["versionHash"] = metadata.versionHash

            result.success(resultMap)
          } catch (e: Exception) {
            Log.e("JanusSdkFlutterPlugin", "Error getting consent metadata: ${e.message}")
            result.error("METADATA_ERROR", e.message, null)
          }
        }

        "getFidesString" -> {
          result.success(Janus.fidesString)
        }

        "hasExperience" -> {
          result.success(Janus.hasExperience)
        }

        "shouldShowExperience" -> {
          result.success(Janus.shouldShowExperience)
        }

        "clearConsent" -> {
          activity?.let {
            val args = call.arguments as? Map<String, Any>
            val clearMetadata = args?.get("clearMetadata") as? Boolean ?: false
            Janus.clearConsent(it, clearMetadata)
            result.success(null)
          } ?: result.error("NO_ACTIVITY", "Activity is not available", null)
        }

        "createConsentWebView" -> {
          val args = call.arguments as? Map<String, Any>
          val autoSyncOnStart = args?.get("autoSyncOnStart") as? Boolean ?: true

          activity?.let {
            try {
              // Create a unique ID for this WebView
              val webViewId = java.util.UUID.randomUUID().toString()

              // Call the SDK method to create the WebView
              val webView = Janus.createConsentWebView(it, autoSyncOnStart)

              // Store the WebView in our map with the ID
              webViews[webViewId] = webView

              // Return the ID to Flutter
              result.success(webViewId)
            } catch (e: Exception) {
              result.error("WEBVIEW_ERROR", e.message, null)
            }
          } ?: result.error("NO_ACTIVITY", "Activity is not available", null)
        }

        "releaseConsentWebView" -> {
          try {
            val args = call.arguments as? Map<String, Any>
            val webViewId = args?.get("webViewId") as? String

            if (webViewId != null && webViews.containsKey(webViewId)) {
              // Get the WebView from our map
              val webView = webViews[webViewId]

              // Release it through the SDK
              webView?.let { Janus.releaseConsentWebView(it) }

              // Remove it from our map
              webViews.remove(webViewId)

              result.success(null)
            } else {
              result.error("INVALID_WEBVIEW_ID", "WebView ID not found", null)
            }
          } catch (e: Exception) {
            result.error("WEBVIEW_ERROR", e.message, null)
          }
        }

        "getLocationByIPAddress" -> {
          Janus.getLocationByIPAddress { success, response, error ->
            if (success && response != null) {
              val resultMap = HashMap<String, Any?>()
              resultMap["region"] = response.region
              resultMap["country"] = response.country
              resultMap["location"] = response.location
              resultMap["ip"] = response.ip
              result.success(resultMap)
            } else {
              result.error("LOCATION_ERROR", error?.message ?: "Unknown error", null)
            }
          }
        }

        "getRegion" -> {
          result.success(Janus.region)
        }

        else -> {
          result.notImplemented()
        }
      }
    } catch (e: Exception) {
      result.error("UNEXPECTED_ERROR", e.message, null)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    // Clean up any remaining WebViews
    for (webView in webViews.values) {
      try {
        Janus.releaseConsentWebView(webView)
      } catch (e: Exception) {
        // Ignore errors during cleanup
      }
    }
    webViews.clear()

    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }

  // ActivityAware implementation
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  // EventChannel.StreamHandler implementation
  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events

    // Set up the event listener
    eventListenerId = Janus.addConsentEventListener { event: JanusEvent ->
      try {
        val eventMap = HashMap<String, Any?>()

        Log.d("JanusSdkFlutterPlugin", "eventType runtime type: ${event.eventType::class.java.name}")

        // Get the string value directly from the enum's toString() method
        // The JanusEventType enum has been updated to override toString() to return the stringValue
        val eventTypeName = event.eventType.toString()

        eventMap["eventType"] = eventTypeName

        // Convert the detail map to ensure all values are serializable
        val detailMap = HashMap<String, Any?>()
        event.detail?.forEach<String, Any?> { (key, value) ->
          // Convert any non-serializable types to strings
          detailMap[key] = when (value) {
            is Enum<*> -> value.toString().lowercase()
            is Date -> value.time // Convert Date to timestamp
            else -> value
          }
        }

        eventMap["detail"] = detailMap

        activity?.runOnUiThread {
          eventSink?.success(eventMap)
        }
      } catch (e: Exception) {
        // Log the error but don't crash
        Log.e("JanusSdkFlutterPlugin", "Error sending event: ${e.message}")
        e.printStackTrace()
      }
    }
  }

  override fun onCancel(arguments: Any?) {
    // Remove the event listener when the stream is cancelled
    eventListenerId?.let {
      Janus.removeConsentEventListener(it)
    }
    eventSink = null
    eventListenerId = null
  }
}
