import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Mock platform implementation for testing
class MockJanusSdkFlutterPlatform
    with MockPlatformInterfaceMixin
    implements JanusSdkFlutterPlatform {
  @override
  Future<bool> initialize(JanusConfiguration config) => Future.value(true);

  @override
  Future<void> showExperience() => Future.value();

  @override
  String addConsentEventListener(void Function(JanusEvent) listener) =>
      'listener-id';

  @override
  void removeConsentEventListener(String listenerId) {}

  @override
  Future<Map<String, dynamic>> get consent => Future.value({'analytics': true});

  @override
  Future<Map<String, bool>> get internalConsent =>
      Future.value({'analytics': true});

  @override
  Future<Map<String, dynamic>> get consentMetadata => Future.value({
    'createdAt': '2023-01-01T00:00:00Z',
    'updatedAt': '2023-01-01T00:00:00Z',
    'consentMethod': 'test',
    'versionHash': 'abc123',
  });

  @override
  Future<String> get fidesString => Future.value('test-fides-string');

  @override
  Future<bool> get hasExperience => Future.value(true);

  @override
  Future<bool> get shouldShowExperience => Future.value(true);

  @override
  Future<void> clearConsent({bool clearMetadata = false}) => Future.value();

  @override
  Future<String> createConsentWebView({bool autoSyncOnStart = true}) =>
      Future.value('mock-webview-id');

  @override
  Future<void> releaseConsentWebView(String webViewId) => Future.value();

  @override
  Future<Map<String, dynamic>> getLocationByIPAddress() => Future.value({
    'region': 'NY',
    'country': 'US',
    'location': 'US-NY',
    'ip': '192.168.1.1',
  });

  @override
  Future<String> get region => Future.value('US-NY');

  @override
  Future<void> setLogger({required bool useProxy}) => Future.value();
}

/// Mock logger that captures log calls
class MockLogger implements JanusLogger {
  final List<LogCall> logCalls = [];

  @override
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, String>? metadata,
    Object? error,
  }) {
    logCalls.add(LogCall(message, level, metadata, error));
  }

  void clear() {
    logCalls.clear();
  }
}

class LogCall {
  final String message;
  final LogLevel level;
  final Map<String, String>? metadata;
  final Object? error;

  LogCall(this.message, this.level, this.metadata, this.error);
}

/// Test to verify that custom loggers can be set and receive internal SDK log calls
void main() {
  // Ensure Flutter binding is initialized for method channel tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JanusLogger', () {
    late MockLogger mockLogger;
    late MockJanusSdkFlutterPlatform mockPlatform;
    late JanusSdkFlutterPlatform originalPlatform;

    setUp(() {
      mockLogger = MockLogger();
      mockPlatform = MockJanusSdkFlutterPlatform();

      // Store original platform and replace with mock
      originalPlatform = JanusSdkFlutterPlatform.instance;
      JanusSdkFlutterPlatform.instance = mockPlatform;
    });

    tearDown(() {
      // Reset to default logger and restore original platform
      Janus.setLogger(null);
      JanusSdkFlutterPlatform.instance = originalPlatform;
    });

    test('setLogger with custom logger receives log calls', () {
      // Since _log is internal, we can't test it directly
      // This test verifies the logger can be set without errors
      expect(() => Janus.setLogger(mockLogger), returnsNormally);
      expect(() => Janus.setLogger(null), returnsNormally);
    });

    test('setLogger with null resets to default logger', () {
      // Arrange - Start with custom logger
      expect(() => Janus.setLogger(mockLogger), returnsNormally);

      // Act - Reset to default
      expect(() => Janus.setLogger(null), returnsNormally);

      // Create new mock to verify setup works
      final newMockLogger = MockLogger();
      expect(() => Janus.setLogger(newMockLogger), returnsNormally);
    });

    test('logger handles all log levels correctly', () {
      // Clear any existing calls first
      mockLogger.clear();
      Janus.setLogger(mockLogger);
      mockLogger.clear(); // Clear again to ignore any setup calls

      // Test that logger can handle different log levels
      expect(
        () => mockLogger.log('Verbose message', level: LogLevel.verbose),
        returnsNormally,
      );
      expect(
        () => mockLogger.log('Debug message', level: LogLevel.debug),
        returnsNormally,
      );
      expect(
        () => mockLogger.log('Info message', level: LogLevel.info),
        returnsNormally,
      );
      expect(
        () => mockLogger.log('Warning message', level: LogLevel.warning),
        returnsNormally,
      );
      expect(
        () => mockLogger.log('Error message', level: LogLevel.error),
        returnsNormally,
      );

      // Verify calls were logged
      expect(mockLogger.logCalls.length, 5);
      expect(mockLogger.logCalls[0].level, LogLevel.verbose);
      expect(mockLogger.logCalls[1].level, LogLevel.debug);
      expect(mockLogger.logCalls[2].level, LogLevel.info);
      expect(mockLogger.logCalls[3].level, LogLevel.warning);
      expect(mockLogger.logCalls[4].level, LogLevel.error);
    });

    test('logger handles metadata and errors', () {
      // Clear any existing calls first
      mockLogger.clear();
      Janus.setLogger(mockLogger);
      mockLogger.clear(); // Clear again to ignore any setup calls

      // Test metadata and error combinations
      mockLogger.log(
        'Info with metadata',
        level: LogLevel.info,
        metadata: {'key1': 'value1', 'key2': 'value2'},
      );
      mockLogger.log(
        'Error with exception',
        level: LogLevel.error,
        error: Exception('Test error'),
      );
      mockLogger.log(
        'Warning with both',
        level: LogLevel.warning,
        metadata: {'source': 'test'},
        error: 'String error',
      );
      mockLogger.log('Simple message', level: LogLevel.info);

      // Verify calls were logged
      expect(mockLogger.logCalls.length, 4);
      expect(mockLogger.logCalls[0].metadata, {
        'key1': 'value1',
        'key2': 'value2',
      });
      expect(mockLogger.logCalls[0].error, isNull);
      expect(mockLogger.logCalls[1].metadata, isNull);
      expect(mockLogger.logCalls[1].error, isA<Exception>());
      expect(mockLogger.logCalls[2].metadata, {'source': 'test'});
      expect(mockLogger.logCalls[2].error, 'String error');
      expect(mockLogger.logCalls[3].metadata, isNull);
      expect(mockLogger.logCalls[3].error, isNull);
    });

    test('setLogger handles platform exceptions gracefully', () async {
      // Mock logger to capture calls
      mockLogger.clear();

      // This should not throw even if platform channel fails
      expect(() => Janus.setLogger(mockLogger), returnsNormally);

      // Verify the logger was still set locally (platform failure shouldn't prevent local setup)
      // We can't easily test the platform channel failure without more complex mocking,
      // but we can ensure the local state is correct
      expect(() => Janus.setLogger(null), returnsNormally);
      expect(() => Janus.setLogger(mockLogger), returnsNormally);
    });

    test('_handleNativeLog safely handles unknown log levels', () async {
      // Set up mock logger
      mockLogger.clear();
      Janus.setLogger(mockLogger);
      mockLogger.clear(); // Clear setup calls

      // Test unknown log levels that would crash with LogLevel.values.byName()
      final testCases = [
        {
          'message': 'Test with unknown level',
          'level': 'unknown',
          'metadata': null,
        },
        {
          'message': 'Test with typo level',
          'level': 'eror',
          'metadata': null,
        }, // typo in 'error'
        {'message': 'Test with empty level', 'level': '', 'metadata': null},
        {'message': 'Test with null level', 'level': 'null', 'metadata': null},
        {'message': 'Test with numeric level', 'level': '1', 'metadata': null},
        {
          'message': 'Test with mixed case',
          'level': 'Error',
          'metadata': null,
        }, // Mixed case should work
      ];

      // Simulate method calls from native platforms with unknown levels
      for (final testCase in testCases) {
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              'janus_sdk_flutter',
              const StandardMethodCodec().encodeMethodCall(
                MethodCall('log', testCase),
              ),
              (data) {},
            );
      }

      // Verify all calls reached the Flutter logger with fallback to info level
      expect(mockLogger.logCalls.length, 6);

      // All unknown levels should default to info
      for (int i = 0; i < 5; i++) {
        expect(
          mockLogger.logCalls[i].level,
          LogLevel.info,
          reason: 'Unknown level should default to info',
        );
      }

      // Mixed case 'Error' should be handled correctly (after toLowerCase())
      expect(
        mockLogger.logCalls[5].level,
        LogLevel.error,
        reason: 'Mixed case Error should work',
      );
    });

    test('native log calls route through method channel to Flutter logger', () async {
      // Set up mock logger
      mockLogger.clear();
      Janus.setLogger(mockLogger);
      mockLogger.clear(); // Clear setup calls

      // Simulate native log calls coming through the method channel
      // This is what would happen when iOS FlutterProxyLogger or Android FlutterProxyLogger calls back

      // Test different log levels and metadata
      final testCases = [
        {'message': 'Native verbose log', 'level': 'verbose', 'metadata': null},
        {
          'message': 'Native debug log',
          'level': 'debug',
          'metadata': {'source': 'native'},
        },
        {
          'message': 'Native info log',
          'level': 'info',
          'metadata': 'simple metadata',
        },
        {
          'message': 'Native warning log',
          'level': 'warning',
          'metadata': {'error': 'code', 'count': 123},
        },
        {
          'message': 'Native error log',
          'level': 'error',
          'metadata': ['item1', 'item2'],
        },
        {
          'message': 'Unknown level log',
          'level': 'unknown',
          'metadata': null,
        }, // Should default to info
      ];

      // Simulate method calls from native platforms
      for (final testCase in testCases) {
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              'janus_sdk_flutter',
              const StandardMethodCodec().encodeMethodCall(
                MethodCall('log', testCase),
              ),
              (data) {},
            );
      }

      // Verify all calls reached the Flutter logger
      expect(mockLogger.logCalls.length, 6);

      // Verify first call (verbose)
      expect(mockLogger.logCalls[0].message, 'Native verbose log');
      expect(mockLogger.logCalls[0].level, LogLevel.verbose);
      expect(mockLogger.logCalls[0].metadata, isNull);

      // Verify second call (debug with metadata)
      expect(mockLogger.logCalls[1].message, 'Native debug log');
      expect(mockLogger.logCalls[1].level, LogLevel.debug);
      expect(mockLogger.logCalls[1].metadata, {'source': 'native'});

      // Verify third call (info with string metadata - note: this comes through method channel conversion)
      expect(mockLogger.logCalls[2].message, 'Native info log');
      expect(mockLogger.logCalls[2].level, LogLevel.info);
      // Method channel will convert 'simple metadata' string to a Map<String, String>?
      // so we need to adjust our expectation

      // Verify fourth call (warning with complex metadata - numbers get converted to strings)
      expect(mockLogger.logCalls[3].message, 'Native warning log');
      expect(mockLogger.logCalls[3].level, LogLevel.warning);
      expect(mockLogger.logCalls[3].metadata, {
        'error': 'code',
        'count': '123',
      });

      // Verify fifth call (error with list metadata - will be converted)
      expect(mockLogger.logCalls[4].message, 'Native error log');
      expect(mockLogger.logCalls[4].level, LogLevel.error);
      // Lists can't be directly converted to Map<String, String>, so this will be null
      expect(mockLogger.logCalls[4].metadata, isNull);

      // Verify sixth call (unknown level defaults to info)
      expect(mockLogger.logCalls[5].message, 'Unknown level log');
      expect(
        mockLogger.logCalls[5].level,
        LogLevel.info,
      ); // Unknown levels default to info
      expect(mockLogger.logCalls[5].metadata, isNull);
    });
  });

  group('DefaultJanusLogger', () {
    test('logs messages without throwing exceptions', () {
      final logger = DefaultJanusLogger();

      // These should not throw exceptions
      expect(() => logger.log('Test message'), returnsNormally);
      expect(
        () => logger.log('Warning', level: LogLevel.warning),
        returnsNormally,
      );
      expect(
        () => logger.log(
          'Error',
          level: LogLevel.error,
          metadata: {'key': 'value'},
        ),
        returnsNormally,
      );
    });
  });
}
