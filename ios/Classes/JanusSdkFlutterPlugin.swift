import Flutter
import UIKit
import JanusSDK

public class JanusSdkFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "janus_sdk_flutter", binaryMessenger: registrar.messenger())
    let instance = JanusSdkFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }
      
      guard let apiHost = args["apiHost"] as? String,
            let propertyId = args["propertyId"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "apiHost and propertyId are required", details: nil))
        return
      }
      
      let ipLocation = args["ipLocation"] as? Bool ?? true
      let region = args["region"] as? String
      let fidesEvents = args["fidesEvents"] as? Bool ?? true
      let webHost = args["webHost"] as? String
      
      let config = JanusConfiguration(
        apiHost: apiHost,
        propertyId: propertyId,
        ipLocation: ipLocation,
        region: region,
        fidesEvents: fidesEvents,
        webHost: webHost
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
        "consentMethod": Janus.consentMetadata.consentMethod ?? ""
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
      // Direct mapping to native method
      let listenerId = Janus.addConsentEventListener { event in
        // Flutter side will handle this separately
      }
      result(listenerId)
      
    case "removeConsentEventListener":
      guard let args = call.arguments as? [String: Any],
            let listenerId = args["listenerId"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "listenerId is required", details: nil))
        return
      }
      
      Janus.removeConsentEventListener(listenerId: listenerId)
      result(nil)
      
    case "createConsentWebView":
      let args = call.arguments as? [String: Any]
      let autoSyncOnStart = args?["autoSyncOnStart"] as? Bool ?? true
      let webView = Janus.createConsentWebView(autoSyncOnStart: autoSyncOnStart)
      // TODO Handle returning the WebView appropriately
      result(nil)
      
    case "releaseConsentWebView":
      // Would need WebView reference
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "Method not implemented", details: nil))
      
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
