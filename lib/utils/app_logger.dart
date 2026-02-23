import 'package:flutter/foundation.dart';

/// Production-safe logger that only outputs in debug mode
///
/// Use this instead of [debugPrint] directly to ensure sensitive
/// information is never logged in production builds.
class AppLogger {
  /// Log a debug message (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final output = tag != null ? '[$tag] $message' : message;
      debugPrint(output);
    }
  }

  /// Log an info message (only in debug mode)
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final output = tag != null ? '[$tag] INFO: $message' : 'INFO: $message';
      debugPrint(output);
    }
  }

  /// Log a warning message (only in debug mode)
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      final output = tag != null ? '[$tag] WARN: $message' : 'WARN: $message';
      debugPrint(output);
    }
  }

  /// Log an error message (only in debug mode)
  ///
  /// Optionally includes the error object and stack trace.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ERROR: ' : 'ERROR: ';
      debugPrint('$prefix$message');
      if (error != null) {
        debugPrint('  Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('  StackTrace: $stackTrace');
      }
    }
  }

  /// Log a message with visual separator (for important sections)
  static void section(String title, {String? tag}) {
    if (kDebugMode) {
      final separator = '=' * 40;
      if (tag != null) {
        debugPrint('[$tag] $separator');
        debugPrint('[$tag] $title');
        debugPrint('[$tag] $separator');
      } else {
        debugPrint(separator);
        debugPrint(title);
        debugPrint(separator);
      }
    }
  }

  /// Redact sensitive information from a string
  ///
  /// Use this when logging data that might contain sensitive info.
  static String redact(String value, {int visibleChars = 4}) {
    if (value.length <= visibleChars * 2) {
      return '*' * value.length;
    }
    final start = value.substring(0, visibleChars);
    final end = value.substring(value.length - visibleChars);
    final middle = '*' * (value.length - visibleChars * 2).clamp(1, 10);
    return '$start$middle$end';
  }

  /// Redact a URL, keeping only the domain visible
  static String redactUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}/***';
    } catch (_) {
      return redact(url);
    }
  }

  /// Redact a file path, keeping only the filename
  static String redactPath(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    if (parts.length <= 2) {
      return path;
    }
    return '.../${parts.last}';
  }
}
