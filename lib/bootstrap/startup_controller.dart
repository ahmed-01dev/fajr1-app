import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/errors/errors.dart';
import '../core/logging/app_logger.dart';

/// Finite startup state machine. There is NO state that waits forever:
///   initializing → (ready | degraded | failed), each with bounded time.
/// Missing Firebase config is NOT an error — it routes to degraded
/// (clearly labeled demo mode), never a fake success (§7).
enum StartupState { initializing, ready, degraded, failed }

class StartupController extends ChangeNotifier {
  StartupState _state = StartupState.initializing;
  StartupState get state => _state;

  bool _firebaseReady = false;
  bool get firebaseReady => _firebaseReady;

  /// True when running without cloud services — the UI must label this
  /// mode clearly and never show fake cloud success.
  bool get isLocalMode => !_firebaseReady;

  AppError? lastError;

  bool _disposed = false;
  bool _started = false; // guards against repeated init loops (§7.7)

  static const _kInitTimeout = Duration(seconds: 8);

  void _set(StartupState newState) {
    if (_disposed || _state == newState) return;
    _state = newState;
    notifyListeners(); // never called after dispose (§7.6)
  }

  Future<void> start() async {
    if (_started) return; // idempotent — no repeated init loops
    _started = true;
    _set(StartupState.initializing);

    // 1) Local preferences — defensive; corrupted values are reset (§7.4)
    await _initPreferences();

    // 2) Firebase — OPTIONAL service with a bounded timeout.
    //    Timeout or failure ⇒ degraded (usable local app), not a hang.
    final firebaseResult = await _tryInitFirebase(_kInitTimeout);
    _firebaseReady = firebaseResult;

    // 3) Everything else (FCM tokens, notifications, location) is
    //    initialized lazily AFTER the first usable screen renders —
    //    never awaited here (§7.1).
    if (firebaseResult) {
      _set(StartupState.ready);
    } else {
      _set(StartupState.degraded);
    }
  }

  Future<void> _initPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_kInitTimeout);
      final raw = prefs.getString('onboarding_done');
      if (raw != null && raw != 'true' && raw != 'false') {
        // Corrupted value → reset instead of crashing (§7.4)
        await prefs.setBool('onboarding_done', false);
      }
    } on Exception catch (error, stackTrace) {
      // Preferences are non-fatal: the app continues with defaults.
      lastError = ErrorMapper.map(error, stackTrace: stackTrace);
      AppLogger.e('initPreferences', lastError!);
    }
  }

  /// Tries to initialize Firebase with a bounded timeout.
  /// - Success            → true
  /// - Not configured     → false (demo mode, logged quietly)
  /// - Timeout/failure    → false (degraded mode, error logged)
  Future<bool> _tryInitFirebase(Duration timeout) async {
    try {
      await Firebase.initializeApp().timeout(timeout);
      return true;
    } on FirebaseException catch (error, stackTrace) {
      // FirebaseException(code: core/no-options) is thrown when
      // google-services.json is absent → expected demo mode.
      final appError = ErrorMapper.map(error, stackTrace: stackTrace);
      lastError = appError;
      AppLogger.e('initFirebase', appError);
      return false;
    } on TimeoutException catch (error, stackTrace) {
      lastError = AppError(
        ErrorCode.startupTimeout,
        cause: error,
        stackTrace: stackTrace,
      );
      AppLogger.e('initFirebase', lastError!);
      return false;
    } catch (error, stackTrace) {
      // Any other initialization failure → degraded, never a hang.
      final mapped = ErrorMapper.map(error, stackTrace: stackTrace);
      lastError = mapped.code == ErrorCode.unexpected
          ? const AppError(ErrorCode.firebaseNotConfigured)
          : mapped;
      AppLogger.e('initFirebase', lastError!);
      return false;
    }
  }

  /// Full retry from scratch — resets all flags and re-runs the FSM.
  Future<void> retry() async {
    if (_disposed) return;
    _started = false;
    lastError = null;
    _firebaseReady = false;
    await start();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
