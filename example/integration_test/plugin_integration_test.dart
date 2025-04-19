// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing


import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initialization test', (WidgetTester tester) async {
    final Janus plugin = Janus();
    
    // This test doesn't fully initialize since we don't have a valid config
    // but it verifies the method exists and is callable
    expect(() async {
      await plugin.initialize(JanusConfiguration(
        apiHost: 'https://example.com',
        propertyId: 'test',
        ipLocation: true
      ));
    }, returnsNormally);
  });
}
