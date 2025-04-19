package com.ethyca.janussdk.flutter.android

import android.app.Activity
import android.content.Context
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
import com.ethyca.janussdk.android.JanusEvent

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
            val propertyId = args["propertyId"] as String
            val ipLocation = args["ipLocation"] as Boolean
            val region = args["region"] as? String
            val fidesEvents = args["fidesEvents"] as? Boolean ?: true
            val webHost = args["webHost"] as? String
            
            // Create configuration using Builder pattern
            val configBuilder = JanusConfiguration.Builder()
              .apiHost(apiHost)
              .propertyId(propertyId)
              .ipLocation(ipLocation)
              
            // Add optional parameters if they exist
            region?.let { configBuilder.region(it) }
            configBuilder.fidesEvents(fidesEvents)
            webHost?.let { configBuilder.webHost(it) }
            
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
          val metadata = Janus.consentMetadata
          val resultMap = HashMap<String, Any?>()
          resultMap["createdAt"] = metadata.createdAt
          resultMap["updatedAt"] = metadata.updatedAt
          resultMap["consentMethod"] = metadata.consentMethod
          result.success(resultMap)
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
          val args = call.arguments as? Map<String, Any>
          val clearMetadata = args?.get("clearMetadata") as? Boolean ?: false
          Janus.clearConsent(clearMetadata)
          result.success(null)
        }
        
        "createConsentWebView" -> {
          val args = call.arguments as? Map<String, Any>
          val autoSyncOnStart = args?.get("autoSyncOnStart") as? Boolean ?: true
          
          activity?.let {
            try {
              // Call the SDK method and pass the result to Flutter
              val webView = Janus.createConsentWebView(it)
              // TODO Handle returning the WebView appropriately
              result.success(null)
            } catch (e: Exception) {
              result.error("WEBVIEW_ERROR", e.message, null)
            }
          } ?: result.error("NO_ACTIVITY", "Activity is not available", null)
        }
        
        "releaseConsentWebView" -> {
          try {
            val args = call.arguments as? Map<String, Any>
            // TODO Handle passing in the WebView appropriately
            //val webView = args?.get("webView") as WebView
            //Janus.releaseConsentWebView(webView)
            result.success(null)
          } catch (e: Exception) {
            result.error("WEBVIEW_ERROR", e.message, null)
          }
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
    eventListenerId = Janus.addConsentEventListener { event ->
      val eventMap = HashMap<String, Any?>()
      eventMap["eventType"] = event.eventType
      eventMap["detail"] = event.detail
      
      activity?.runOnUiThread {
        eventSink?.success(eventMap)
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
