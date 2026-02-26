import 'package:flutter/foundation.dart';

/// Lightweight logger used internally by digia_moengage_plugin.
///
/// Mirrors the Logger from digia_ui's src/utils/logger.dart — only
/// prints in debug mode so no log leaks reach production builds.
class Logger {
  Logger._();

  static const String _defaultTag = 'digia_moengage_plugin';

  /// General log — visible only in debug builds.
  static void log(String message, {String tag = _defaultTag}) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// Error log — visible only in debug builds.
  static void error(String message, {String tag = _defaultTag, Object? error}) {
    if (kDebugMode) {
      final suffix = error != null ? ' — $error' : '';
      debugPrint('[$tag] ERROR: $message$suffix');
    }
  }

  /// Info log — visible only in debug builds.
  static void info(String message, {String tag = _defaultTag}) {
    if (kDebugMode) {
      debugPrint('[$tag] INFO: $message');
    }
  }

  /// Warning log — visible only in debug builds.
  static void warning(String message, {String tag = _defaultTag}) {
    if (kDebugMode) {
      debugPrint('[$tag] WARNING: $message');
    }
  }
}
