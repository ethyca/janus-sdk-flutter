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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.3.0/JanusSDK.xcframework.zip",
      checksum: "7d6c1c8cbbfd9ed5a491c88152d6216694045b07e4e917c2fafbcaf65d367bc3"),
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
