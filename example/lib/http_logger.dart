import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';
import 'package:http/http.dart' as http;

/// HTTPLogger implementation that sends logs to a remote HTTP endpoint
/// This is a sample implementation for demonstration purposes
class HTTPLogger implements JanusLogger {
  final String endpoint;
  final String authToken;
  final String source;
  final http.Client _client;
  final bool enableConsoleErrors;

  HTTPLogger({
    required this.endpoint,
    required this.authToken,
    this.source = 'FlutterExampleApp',
    this.enableConsoleErrors = false,
  }) : _client = http.Client();

  @override
  void log(String message, {LogLevel level = LogLevel.info, Map<String, String>? metadata, Object? error}) {
    final logData = _createLogPayload(message, level, metadata, error);
    _sendLogRequest(logData);
  }

  Map<String, dynamic> _createLogPayload(String message, LogLevel level, Map<String, String>? metadata, Object? error) {
    final logEntry = <String, dynamic>{
      'log_level': _levelString(level),
      'message': message,
    };

    if (metadata != null) {
      final encodedData = _encodeMetadata(metadata);
      logEntry['data'] = encodedData;
    }

    if (error != null) {
      logEntry['error'] = error.toString();
    }

    return {
      'logs': [
        {'log': logEntry}
      ],
      'source': source,
    };
  }

  String _levelString(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 'VERBOSE';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  String _encodeMetadata(Map<String, String> metadata) {
    try {
      // Try JSON encoding first
      return jsonEncode(metadata);
    } catch (e) {
      // Fallback to string representation
      return metadata.toString();
    }
  }

  void _sendLogRequest(Map<String, dynamic> logData) async {
    try {
      final jsonString = jsonEncode(logData);
      
      final response = await _client.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonString,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (enableConsoleErrors) {
          debugPrint('HTTPLogger: HTTP error - Status code: ${response.statusCode}');
          if (response.body.isNotEmpty) {
            debugPrint('HTTPLogger: Response body - ${response.body}');
          }
        }
      }
    } on SocketException catch (e) {
      if (enableConsoleErrors) {
        debugPrint('HTTPLogger: Network error - ${e.message}');
      }
    } catch (e) {
      if (enableConsoleErrors) {
        debugPrint('HTTPLogger: Failed to serialize log data - ${e.toString()}');
        debugPrint('HTTPLogger: Log data that failed: $logData');
      }
    }
  }

  void dispose() {
    _client.close();
  }
} 