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
import com.ethyca.janussdk.android.JanusLogger
import com.ethyca.janussdk.android.LogLevel
import com.ethyca.janussdk.android.events.JanusEvent
import com.ethyca.janussdk.android.models.ConsentFlagType
import com.ethyca.janussdk.android.models.ConsentNonApplicableFlagMode
import java.util.Date
import com.ethyca.janussdk.android.events.*
import com.ethyca.janussdk.android.models.PrivacyExperienceItem

/**
 * Proxy logger that forwards Android log calls back to Flutter
 */
class FlutterProxyLogger(private val methodChannel: MethodChannel) : JanusLogger {
    override fun log(message: String, level: LogLevel, metadata: Map<String, String>?, error: Throwable?) {
        // Convert LogLevel to string
        val levelString = when (level) {
            LogLevel.VERBOSE -> "verbose"
            LogLevel.DEBUG -> "debug"
            LogLevel.INFO -> "info"
            LogLevel.WARNING -> "warning"
            LogLevel.ERROR -> "error"
        }
        
        // Call back to Flutter via method channel
        val arguments = mutableMapOf<String, Any?>(
            "message" to message,
            "level" to levelString,
            "metadata" to metadata
        )
        
        // Add error information if present
        if (error != null) {
            arguments["error"] = mapOf(
                "message" to (error.message ?: error.javaClass.simpleName),
                "type" to error.javaClass.simpleName
            )
        }
        
        // Ensure we're on the main thread for Flutter method calls
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            methodChannel.invokeMethod("log", arguments)
        }
    }
}

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
  
  // Private logger for plugin-specific logging that flows through unified system
  private lateinit var pluginLogger: JanusLogger

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "janus_sdk_flutter")
    channel.setMethodCallHandler(this)

    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "janus_sdk_flutter/events")
    eventChannel.setStreamHandler(this)

    context = flutterPluginBinding.applicationContext
    
    // Initialize plugin logger to use proxy so errors flow through unified logging
    pluginLogger = FlutterProxyLogger(channel)
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
            val autoShowExperience = args["autoShowExperience"] as? Boolean ?: true
            val saveUserPreferencesToFides = args["saveUserPreferencesToFides"] as? Boolean ?: true
            val saveNoticesServedToFides = args["saveNoticesServedToFides"] as? Boolean ?: true
            val consentFlagTypeString = args["consentFlagType"] as? String ?: "boolean"
            val consentNonApplicableFlagModeString = args["consentNonApplicableFlagMode"] as? String ?: "omit"
            
            // Convert string to ConsentFlagType enum
            val consentFlagType = when (consentFlagTypeString.lowercase()) {
              "boolean" -> ConsentFlagType.BOOLEAN
              "consentmechanism" -> ConsentFlagType.CONSENT_MECHANISM
              else -> ConsentFlagType.BOOLEAN
            }
            
            // Convert string to ConsentNonApplicableFlagMode enum
            val consentNonApplicableFlagMode = when (consentNonApplicableFlagModeString.lowercase()) {
              "omit" -> ConsentNonApplicableFlagMode.OMIT
              "include" -> ConsentNonApplicableFlagMode.INCLUDE
              else -> ConsentNonApplicableFlagMode.OMIT
            }

            // Create configuration using Builder pattern
            val configBuilder = JanusConfiguration.Builder()
              .apiHost(apiHost)
              .propertyId(propertyId)
              .privacyCenterHost(privacyCenterHost)
              .ipLocation(ipLocation)
              .region(region)
              .fidesEvents(fidesEvents)
              .autoShowExperience(autoShowExperience)
              .saveUserPreferencesToFides(saveUserPreferencesToFides)
              .saveNoticesServedToFides(saveNoticesServedToFides)
              .consentFlagType(consentFlagType)
              .consentNonApplicableFlagMode(consentNonApplicableFlagMode)

            val config = configBuilder.build()

            // Initialize the SDK with the activity instead of context
            activity?.let { act ->
              Janus.initialize(act, config) { success, error ->
                if (success) {
                  result.success(true)
                } else {
                  pluginLogger.log("Janus SDK initialization failed", LogLevel.ERROR, null, error)
                  result.error("INIT_ERROR", error?.message ?: "Unknown error", null)
                }
              }
            } ?: run {
              pluginLogger.log("No activity available for initialization", LogLevel.ERROR, null, null)
              result.error("NO_ACTIVITY", "Activity is not available", null)
            }
          } catch (e: Exception) {
            pluginLogger.log("Failed to initialize Janus SDK", LogLevel.ERROR, null, e)
            result.error("INVALID_ARGS", e.message ?: "Unknown error", null)
          }
        }

        "showExperience" -> {
          activity?.let {
            try {
              Janus.showExperience(it)
              result.success(null)
            } catch (e: Exception) {
              pluginLogger.log("Failed to show privacy experience", LogLevel.ERROR, null, e)
              result.error("SHOW_EXP_ERROR", e.message ?: "Unknown error", null)
            }
          } ?: run {
            pluginLogger.log("No activity available for showExperience", LogLevel.ERROR, null, null)
            result.error("NO_ACTIVITY", "Activity is not available", null)
          }
        }

        "getConsent" -> {
          result.success(Janus.consent)
        }

        "getInternalConsent" -> {
          // internalConsent is marked as internal in Android SDK, so we can't access it
          // For now, return the same as consent since both should be boolean in default mode
          result.success(Janus.consent)
        }

        "getConsentMetadata" -> {
          try {
            val metadata = Janus.consentMetadata
            val resultMap = HashMap<String, Any?>()

            // Convert Date objects to timestamps
            metadata.createdAt?.let { resultMap["createdAt"] = it.time }
            metadata.updatedAt?.let { resultMap["updatedAt"] = it.time }
            resultMap["consentMethod"] = metadata.consentMethod.value
            resultMap["versionHash"] = metadata.versionHash

            result.success(resultMap)
          } catch (e: Exception) {
            pluginLogger.log("Failed to get consent metadata", LogLevel.ERROR, null, e)
            result.error("METADATA_ERROR", e.message ?: "Unknown error", null)
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

        "getCurrentExperience" -> {
          try {
            val experience = Janus.currentExperience
            if (experience != null) {
              val experienceMap = HashMap<String, Any?>()
              experienceMap["id"] = experience.id
              experienceMap["createdAt"] = experience.createdAt?.time
              experienceMap["updatedAt"] = experience.updatedAt?.time
              experienceMap["region"] = experience.region
              experienceMap["isTCFExperience"] = experience.isTCFExperience
              // Add other relevant fields as needed
              result.success(experienceMap)
            } else {
              result.success(null)
            }
          } catch (e: Exception) {
            pluginLogger.log("Failed to get current experience", LogLevel.ERROR, null, e)
            result.error("EXPERIENCE_ERROR", e.message ?: "Unknown error", null)
          }
        }

        "getIsTCFExperience" -> {
          result.success(Janus.isTCFExperience)
        }

        "clearConsent" -> {
          activity?.let {
            val args = call.arguments as? Map<String, Any>
            val clearMetadata = args?.get("clearMetadata") as? Boolean ?: false
            Janus.clearConsent(it, clearMetadata)
            result.success(null)
          } ?: run {
            pluginLogger.log("No activity available for clearConsent", LogLevel.ERROR, null, null)
            result.error("NO_ACTIVITY", "Activity is not available", null)
          }
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
              pluginLogger.log("Failed to create consent WebView", LogLevel.ERROR, null, e)
              result.error("WEBVIEW_ERROR", e.message ?: "Unknown error", null)
            }
          } ?: run {
            pluginLogger.log("No activity available for createConsentWebView", LogLevel.ERROR, null, null)
            result.error("NO_ACTIVITY", "Activity is not available", null)
          }
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
              pluginLogger.log("Invalid WebView ID provided for release", LogLevel.ERROR, mapOf("webViewId" to (webViewId ?: "null")), null)
              result.error("INVALID_WEBVIEW_ID", "WebView ID not found", null)
            }
          } catch (e: Exception) {
            pluginLogger.log("Failed to release consent WebView", LogLevel.ERROR, null, e)
            result.error("WEBVIEW_ERROR", e.message ?: "Unknown error", null)
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
              pluginLogger.log("Failed to get location by IP address", LogLevel.ERROR, null, error)
              result.error("LOCATION_ERROR", error?.message ?: "Unknown error", null)
            }
          }
        }

        "getRegion" -> {
          result.success(Janus.region)
        }

        "setLogger" -> {
          try {
            val args = call.arguments as? Map<String, Any>
            val useProxy = args?.get("useProxy") as? Boolean ?: false
            
            if (useProxy) {
              // Set proxy logger that calls back to Flutter
              Janus.setLogger(FlutterProxyLogger(channel))
            } else {
              // Reset to default logger
              Janus.setLogger(null)
            }
            
            result.success(null)
          } catch (e: Exception) {
            pluginLogger.log("Failed to set logger", LogLevel.ERROR, null, e)
            result.error("LOGGER_ERROR", e.message ?: "Unknown error", null)
          }
        }

        else -> {
          result.notImplemented()
        }
      }
    } catch (e: Exception) {
      pluginLogger.log("Unexpected error in method call", LogLevel.ERROR, null, e)
      result.error("UNEXPECTED_ERROR", e.message ?: "Unknown error", null)
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
        pluginLogger.log("Failed to send event to Flutter", LogLevel.ERROR, null, e)
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
