import Flutter
import UIKit
import WebKit
import JanusSDK

/// Proxy logger that forwards iOS log calls back to Flutter
class FlutterProxyLogger: JanusLogger {
    private weak var channel: FlutterMethodChannel?
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    func log(_ message: String, level: LogLevel = .info, metadata: [String: String]? = nil, error: Error? = nil) {
        // Convert LogLevel to string
        let levelString: String
        switch level {
        case .verbose:
            levelString = "verbose"
        case .debug:
            levelString = "debug"
        case .info:
            levelString = "info"
        case .warning:
            levelString = "warning"
        case .error:
            levelString = "error"
        }
        
        // Call back to Flutter via method channel
        var arguments: [String: Any] = [
            "message": message,
            "level": levelString,
            "metadata": metadata as Any
        ]
        
        // Add error information if present
        if let error = error {
            arguments["error"] = [
                "message": error.localizedDescription,
                "domain": (error as NSError).domain,
                "code": (error as NSError).code
            ]
        }
        
        // Ensure we're on the main thread for Flutter method calls
        DispatchQueue.main.async {
            self.channel?.invokeMethod("log", arguments: arguments)
        }
    }
}

public class JanusSdkFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  // Map to store WebView instances by ID
  private var webViews = [String: WKWebView]()

  // Dictionary to store event listeners by ID
  private var eventListeners = [String: String]()

  // Global event listener ID for the event channel
  private var globalEventListenerId: String?

  // Event channel sink for sending events to Flutter
  private var eventSink: FlutterEventSink?
  
  // Method channel for calling back to Flutter
  private var methodChannel: FlutterMethodChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "janus_sdk_flutter", binaryMessenger: registrar.messenger())

    // Set up event channel for consent events
    let eventChannel = FlutterEventChannel(name: "janus_sdk_flutter/events", binaryMessenger: registrar.messenger())

    let instance = JanusSdkFlutterPlugin()
    instance.methodChannel = channel // Store reference for proxy logger
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
      let saveUserPreferencesToFides = args["saveUserPreferencesToFides"] as? Bool ?? true
      let saveNoticesServedToFides = args["saveNoticesServedToFides"] as? Bool ?? true
      let consentFlagTypeString = args["consentFlagType"] as? String ?? "boolean"
      let consentNonApplicableFlagModeString = args["consentNonApplicableFlagMode"] as? String ?? "omit"
      
      // Convert string to ConsentFlagType enum
      let consentFlagType: ConsentFlagType
      switch consentFlagTypeString.lowercased() {
      case "boolean":
        consentFlagType = .boolean
      case "consentmechanism":
        consentFlagType = .consentMechanism
      default:
        consentFlagType = .boolean
      }
      
      // Convert string to ConsentNonApplicableFlagMode enum
      let consentNonApplicableFlagMode: ConsentNonApplicableFlagMode
      switch consentNonApplicableFlagModeString.lowercased() {
      case "omit":
        consentNonApplicableFlagMode = .omit
      case "include":
        consentNonApplicableFlagMode = .include
      default:
        consentNonApplicableFlagMode = .omit
      }

      let config = JanusConfiguration(
        apiHost: apiHost,
        privacyCenterHost: privacyCenterHost,
        propertyId: propertyId,
        ipLocation: ipLocation,
        region: region,
        fidesEvents: fidesEvents,
        autoShowExperience: autoShowExperience,
        saveUserPreferencesToFides: saveUserPreferencesToFides,
        saveNoticesServedToFides: saveNoticesServedToFides,
        consentFlagType: consentFlagType,
        consentNonApplicableFlagMode: consentNonApplicableFlagMode
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

    case "getInternalConsent":
      // internalConsent is not accessible in iOS SDK, fall back to consent
      // In default boolean mode, both should return the same values anyway
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

    case "getCurrentExperience":
      if let experience = Janus.currentExperience {
        // Convert PrivacyExperienceItem to dictionary
        let experienceDict: [String: Any] = [
          "id": experience.id ?? "",
          "createdAt": experience.createdAt?.ISO8601String() ?? "",
          "updatedAt": experience.updatedAt?.ISO8601String() ?? "",
          "region": experience.region ?? "",
          "isTCFExperience": experience.isTCFExperience,
          // Add other relevant fields as needed
        ]
        result(experienceDict)
      } else {
        result(nil)
      }

    case "getIsTCFExperience":
      result(Janus.isTCFExperience)

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
      
    case "setLogger":
      guard let args = call.arguments as? [String: Any],
            let useProxy = args["useProxy"] as? Bool else {
        result(FlutterError(code: "INVALID_ARGS", message: "useProxy is required", details: nil))
        return
      }
      
      if useProxy, let channel = methodChannel {
        // Set proxy logger that calls back to Flutter
        let proxyLogger = FlutterProxyLogger(channel: channel)
        Janus.setLogger(proxyLogger)
      } else {
        // Reset to default logger
        Janus.setLogger(nil)
      }
      
      result(nil)

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
