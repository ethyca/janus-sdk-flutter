import 'package:flutter/foundation.dart';

/// Log levels for Janus SDK logging
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error
}

/// Interface for Janus SDK logging.
/// Implement this interface to provide custom logging behavior.
abstract class JanusLogger {
  /// Log a message with optional level and metadata
  ///
  /// - [message]: The message to log
  /// - [level]: The log level (defaults to [LogLevel.info])
  /// - [metadata]: Optional metadata map to include with the log
  /// - [error]: Optional error for error-specific logging
  void log(String message, {LogLevel level = LogLevel.info, Map<String, String>? metadata, Exception? error});
}

/// Default implementation of JanusLogger that logs using debugPrint
class DefaultJanusLogger implements JanusLogger {
  
  @override
  void log(String message, {LogLevel level = LogLevel.info, Map<String, String>? metadata, Exception? error}) {
    final String logMessage;
    if (metadata != null && error != null) {
      logMessage = '[${_levelString(level)}] $message | Metadata: $metadata | Error: $error';
    } else if (metadata != null) {
      logMessage = '[${_levelString(level)}] $message | Metadata: $metadata';
    } else if (error != null) {
      logMessage = '[${_levelString(level)}] $message | Error: $error';
    } else {
      logMessage = '[${_levelString(level)}] $message';
    }
    
    debugPrint(logMessage);
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
} 