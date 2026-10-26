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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.2.1/JanusSDK.xcframework.zip",
      checksum: "1cac9488962be30a5650053977444a7a91c119b2789870e72aabc5525d93f9f3"),
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
