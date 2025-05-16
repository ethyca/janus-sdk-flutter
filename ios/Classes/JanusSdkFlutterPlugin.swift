import Flutter
import UIKit
import WebKit
import JanusSDK

public class JanusSdkFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  // Map to store WebView instances by ID
  private var webViews = [String: WKWebView]()

  // Dictionary to store event listeners by ID
  private var eventListeners = [String: String]()

  // Global event listener ID for the event channel
  private var globalEventListenerId: String?

  // Event channel sink for sending events to Flutter
  private var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "janus_sdk_flutter", binaryMessenger: registrar.messenger())

    // Set up event channel for consent events
    let eventChannel = FlutterEventChannel(name: "janus_sdk_flutter/events", binaryMessenger: registrar.messenger())

    let instance = JanusSdkFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
  }

  // MARK: - FlutterStreamHandler

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events

    // Set up the global event listener when the Flutter side starts listening
    let listenerId = Janus.addConsentEventListener { [weak self] event in
      guard let self = self else { return }

      // Convert the event to a map that can be sent to Flutter
      var eventMap: [String: Any] = [:]
      let eventTypeName = event.type.rawValue

      eventMap["eventType"] = eventTypeName

      // Create a detail map with event-specific information
      var detailMap: [String: Any] = [:]

      // Add event-specific details based on event type
      switch event {
      case let experienceClosedEvent as ExperienceClosedEvent:
        detailMap["closeMethod"] = experienceClosedEvent.closeMethod

      case let experienceInteractionEvent as ExperienceInteractionEvent:
        detailMap["interaction"] = experienceInteractionEvent.interaction

      case let experienceSelectionUpdatingEvent as ExperienceSelectionUpdatingEvent:
        detailMap["consentIntended"] = experienceSelectionUpdatingEvent.consentIntended

      case let webViewFidesInitializedEvent as WebViewFidesInitializedEvent:
        detailMap["shouldShowExperience"] = webViewFidesInitializedEvent.shouldShowExperience

      case let webViewFidesUIChangedEvent as WebViewFidesUIChangedEvent:
        detailMap["interaction"] = webViewFidesUIChangedEvent.interaction

      case let webViewFidesModalClosedEvent as WebViewFidesModalClosedEvent:
        detailMap["consentMethod"] = webViewFidesModalClosedEvent.consentMethod

      case let webViewFidesUpdatingEvent as WebViewFidesUpdatingEvent:
        detailMap["consentIntended"] = webViewFidesUpdatingEvent.consentIntended

      case let consentUpdatedFromWebViewEvent as ConsentUpdatedFromWebViewEvent:
        detailMap["values"] = consentUpdatedFromWebViewEvent.getConsentValues()
        detailMap["fidesString"] = consentUpdatedFromWebViewEvent.getFidesString()

      default:
        // For event types without additional data, we don't need to add anything
        break
      }

      eventMap["detail"] = detailMap

      // Send the event to Flutter through the event channel
      DispatchQueue.main.async {
        self.eventSink?(eventMap)
      }
    }

    // Store the listener ID for cleanup
    self.globalEventListenerId = listenerId

    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    // Clean up the global event listener
    if let listenerId = globalEventListenerId {
      Janus.removeConsentEventListener(listenerId: listenerId)
      globalEventListenerId = nil
    }

    eventSink = nil
    return nil
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }

      guard let apiHost = args["apiHost"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "apiHost is required", details: nil))
        return
      }

      let propertyId = args["propertyId"] as? String ?? ""
      let privacyCenterHost = args["privacyCenterHost"] as? String ?? ""
      let ipLocation = args["ipLocation"] as? Bool ?? true
      let region = args["region"] as? String ?? ""
      let fidesEvents = args["fidesEvents"] as? Bool ?? true
      let autoShowExperience = args["autoShowExperience"] as? Bool ?? true

      let config = JanusConfiguration(
        apiHost: apiHost,
        privacyCenterHost: privacyCenterHost,
        propertyId: propertyId,
        ipLocation: ipLocation,
        region: region,
        fidesEvents: fidesEvents,
        autoShowExperience: autoShowExperience
      )

      Janus.initialize(config: config) { success, error in
        if success {
          result(true)
        } else if let error = error {
          result(FlutterError(code: "INIT_ERROR", message: error.localizedDescription, details: nil))
        } else {
          result(FlutterError(code: "INIT_ERROR", message: "Unknown error", details: nil))
        }
      }

    case "showExperience":
      DispatchQueue.main.async {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
          result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller available", details: nil))
          return
        }

        Janus.showExperience(from: rootViewController)
        result(nil)
      }

    case "getConsent":
      result(Janus.consent)

    case "getConsentMetadata":
      result([
        "createdAt": Janus.consentMetadata.createdAt?.ISO8601String() ?? "",
        "updatedAt": Janus.consentMetadata.updatedAt?.ISO8601String() ?? "",
        "consentMethod": Janus.consentMetadata.consentMethod ?? "",
        "versionHash": Janus.consentMetadata.versionHash ?? ""
      ])

    case "getFidesString":
      result(Janus.fides_string)

    case "hasExperience":
      result(Janus.hasExperience)

    case "shouldShowExperience":
      result(Janus.shouldShowExperience)

    case "clearConsent":
      let args = call.arguments as? [String: Any]
      let clearMetadata = args?["clearMetadata"] as? Bool ?? false
      Janus.clearConsent(clearMetadata: clearMetadata)
      result(nil)

    case "addConsentEventListener":
      // Create a unique ID for this listener
      let listenerId = UUID().uuidString

      // Note: We're not actually adding a new listener here since we already have a global one
      // This is just to maintain API compatibility with the Flutter side
      eventListeners[listenerId] = listenerId  // Store a mock ID

      result(listenerId)

    case "removeConsentEventListener":
      guard let args = call.arguments as? [String: Any],
            let listenerId = args["listenerId"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "listenerId is required", details: nil))
        return
      }

      // Just remove the ID from our map - we're not actually removing any listeners
      // since we're using a global listener
      eventListeners.removeValue(forKey: listenerId)

      result(nil)

    case "createConsentWebView":
      let args = call.arguments as? [String: Any]
      let autoSyncOnStart = args?["autoSyncOnStart"] as? Bool ?? true

      // Create a unique ID for this WebView
      let webViewId = UUID().uuidString

      // Create the WebView
      let webView = Janus.createConsentWebView(autoSyncOnStart: autoSyncOnStart)

      // Store the WebView in our map with the ID
      webViews[webViewId] = webView

      // Return the ID to Flutter
      result(webViewId)

    case "releaseConsentWebView":
      guard let args = call.arguments as? [String: Any],
            let webViewId = args["webViewId"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "webViewId is required", details: nil))
        return
      }

      // Get the WebView from our map
      if let webView = webViews[webViewId] {
        // Release it through the SDK
        Janus.releaseConsentWebView(webView)

        // Remove it from our map
        webViews.removeValue(forKey: webViewId)

        result(nil)
      } else {
        result(FlutterError(code: "INVALID_WEBVIEW_ID", message: "WebView ID not found", details: nil))
      }

    case "getLocationByIPAddress":
      Janus.getLocationByIPAddress { success, response, error in
        if success, let response = response {
          result([
            "region": response.region ?? "",
            "country": response.country ?? "",
            "location": response.location ?? "",
            "ip": response.ip ?? ""
          ])
        } else if let error = error {
          result(FlutterError(code: "LOCATION_ERROR", message: error.localizedDescription, details: nil))
        } else {
          result(FlutterError(code: "LOCATION_ERROR", message: "Unknown error", details: nil))
        }
      }

    case "getRegion":
      result(Janus.region ?? "")

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// Extension to format Date as ISO8601 string
extension Date {
  func ISO8601String() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: self)
  }
}
