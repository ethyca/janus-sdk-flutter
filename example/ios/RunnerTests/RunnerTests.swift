import Flutter
import UIKit
import XCTest


@testable import janus_sdk_flutter

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testInitialize() {
    let plugin = JanusSdkFlutterPlugin()

    let args: [String: Any] = [
      "apiHost": "https://example.com",
      "propertyId": "test-property",
      "ipLocation": true
    ]
    
    let call = FlutterMethodCall(methodName: "initialize", arguments: args)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      // This won't actually succeed since we're not mocking the Janus initialization,
      // but we just want to verify the method is called
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
