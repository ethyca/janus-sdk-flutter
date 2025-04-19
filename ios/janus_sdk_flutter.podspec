#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint janus_sdk_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'janus_sdk_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Privacy consent management SDK for Flutter applications.'
  s.description      = <<-DESC
Flutter plugin for Janus SDK, providing privacy consent management functionality
by wrapping the native iOS JanusSDK.
                       DESC
  s.homepage         = 'https://github.com/ethyca/janus-sdk-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ethyca' => 'info@ethyca.com' }
  
  # Source is the git repo where the SDK is published
  s.source           = { 
    :git => 'https://github.com/ethyca/janus-sdk-flutter.git',
    :tag => s.version.to_s
  }
  
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  
  # Bundle the JanusSDK directly
  s.vendored_frameworks = 'Frameworks/JanusSDK.xcframework'
  s.preserve_paths = 'Frameworks/JanusSDK.xcframework'
  
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386', 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.ethyca.janussdk.flutter.ios' }
  s.swift_version = '5.0'
  
  # Verify the JanusSDK exists
  s.prepare_command = <<-CMD
    if [ ! -d "Frameworks/JanusSDK.xcframework" ]; then
      echo "Error: JanusSDK.xcframework not found. This framework must be bundled with the Flutter plugin."
      echo "Please contact the maintainers of the janus-sdk-flutter package."
      exit 1
    else
      echo "✅ JanusSDK.xcframework is ready to use"
    fi
  CMD

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'janus_sdk_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
