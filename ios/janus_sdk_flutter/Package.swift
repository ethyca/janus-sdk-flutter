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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.4.2/JanusSDK.xcframework.zip",
      checksum: "c249be2e91d0dd0db4a2b05eaa3ae58e5af8a46c6cd8e7867271d818778abd4c"),
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
