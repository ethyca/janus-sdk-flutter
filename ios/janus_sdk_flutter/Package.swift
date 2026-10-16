// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "janus_sdk_flutter",
  platforms: [
    .iOS("15.0")
  ],
  products: [
    .library(name: "janus-sdk-flutter", targets: ["janus_sdk_flutter"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .binaryTarget(
      name: "JanusSDK",
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.2.0/JanusSDK.xcframework.zip",
      checksum: "01a70ea24937dacce7816de040fcb2c5a8a599848053085435be57eebd6470db"),
    .target(
      name: "janus_sdk_flutter",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        "JanusSDK"
      ],
      resources: [
        .process("Resources/PrivacyInfo.xcprivacy")
      ])
  ]
)
