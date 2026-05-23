import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

enum _Level { debug, info, warning, error }

abstract final class AppLogger {
  static void debug(String message, {Object? error, StackTrace? stack}) =>
      _log(_Level.debug, message, error: error, stack: stack);

  static void info(String message, {Object? error, StackTrace? stack}) =>
      _log(_Level.info, message, error: error, stack: stack);

  static void warning(String message, {Object? error, StackTrace? stack}) =>
      _log(_Level.warning, message, error: error, stack: stack);

  static void error(
    String message, {
    required Object error,
    StackTrace? stack,
  }) {
    _log(_Level.error, message, error: error, stack: stack);
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, reason: message);
    }
  }

  static void _log(
    _Level level,
    String message, {
    Object? error,
    StackTrace? stack,
  }) {
    if (!kDebugMode) return;
    final tag = switch (level) {
      _Level.debug => '[D]',
      _Level.info => '[I]',
      _Level.warning => '[W]',
      _Level.error => '[E]',
    };
    debugPrint('$tag $message${error != null ? '\n  $error' : ''}');
    if (stack != null && level == _Level.error) debugPrint('  $stack');
  }
}
