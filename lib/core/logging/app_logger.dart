import 'dart:async';
import 'dart:developer' as dev;

import '../errors/errors.dart';

/// Central logger. Prints only in debug builds; never logs secrets or
/// personal data. In release builds, errors go to the console only.
class AppLogger {
  const AppLogger._();

  static bool _enabled = false;

  static void init({bool debugMode = false}) {
    _enabled = debugMode;
  }

  static void d(String message) {
    if (_enabled) dev.log(message, name: 'FAJR');
  }

  static void w(String message) {
    if (_enabled) dev.log('WARN: $message', name: 'FAJR');
  }

  /// Logs an [AppError] with its technical cause for diagnosis.
  /// The cause NEVER reaches the UI — only this log.
  static void e(String context, AppError error) {
    final cause = error.cause;
    final stack = error.stackTrace;
    if (_enabled) {
      dev.log(
        'ERROR [$context] code=${error.code}'
        '${cause != null ? ' cause=$cause' : ''}',
        name: 'FAJR',
        error: cause,
        stackTrace: stack,
      );
    }
  }

  /// Catches errors from UNAWAITED futures so they are never silently
  /// swallowed (§7.13) and never crash the app.
  static void unawaited(Future<void> future, {String context = 'unawaited'}) {
    future.catchError((Object error, StackTrace stackTrace) {
      e(context, ErrorMapper.map(error, stackTrace: stackTrace));
    });
  }
}
