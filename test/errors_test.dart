import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fajr/core/errors/errors.dart';

void main() {
  group('ErrorMapper.map converts technical exceptions to typed errors', () {
    test('invalid email auth error → invalidEmail with Arabic message', () {
      final authException = FirebaseAuthException(code: 'invalid-email');
      final appError = ErrorMapper.map(authException);

      expect(appError.code, ErrorCode.invalidEmail);
      expect(ErrorMapper.userMessage(appError), contains('البريد'));
    });

    test('weak password → weakPassword', () {
      final authException = FirebaseAuthException(code: 'weak-password');
      expect(ErrorMapper.map(authException).code, ErrorCode.weakPassword);
    });

    test('email already in use → emailInUse', () {
      final authException = FirebaseAuthException(code: 'email-already-in-use');
      expect(ErrorMapper.map(authException).code, ErrorCode.emailInUse);
    });

    test('too many attempts → tooManyAttempts and is not retryable', () {
      final authException = FirebaseAuthException(code: 'too-many-requests');
      final appError = ErrorMapper.map(authException);

      expect(appError.code, ErrorCode.tooManyAttempts);
      expect(appError.code.action, isNot(ErrorAction.retry));
    });

    test('network auth failure → network and is retryable', () {
      final authException = FirebaseAuthException(code: 'network-request-failed');
      final appError = ErrorMapper.map(authException);

      expect(appError.code, ErrorCode.network);
      expect(appError.code.action, ErrorAction.retry);
    });

    test('firestore permission denied → permissionDenied with editInput action',
        () {
      final firestoreException = FirebaseFirestoreException(
        code: FirestoreErrorCode.permissionDenied,
        message: 'denied',
      );
      final appError = ErrorMapper.map(firestoreException);

      expect(appError.code, ErrorCode.permissionDenied);
      expect(appError.code.action, ErrorAction.editInput);
    });

    test('firestore failed-precondition → missingIndex (index building)', () {
      final firestoreException = FirebaseFirestoreException(
        code: FirestoreErrorCode.failedPrecondition,
        message: 'index',
      );
      expect(ErrorMapper.map(firestoreException).code, ErrorCode.missingIndex);
    });

    test('timeout → startupTimeout with bounded retry action', () {
      final appError = ErrorMapper.map(TimeoutException('timeout'));
      expect(appError.code, ErrorCode.startupTimeout);
      expect(appError.code.action, ErrorAction.retryOrOffline);
    });

    test('corrupted prefs (FormatException) → corruptedPrefs', () {
      final appError = ErrorMapper.map(const FormatException('bad'));
      expect(appError.code, ErrorCode.corruptedPrefs);
    });

    test('unknown error → unexpected with Arabic fallback message', () {
      final appError = ErrorMapper.map(StateError('unknown'));
      expect(appError.code, ErrorCode.unexpected);
      expect(ErrorMapper.userMessage(appError), contains('خطأ غير متوقع'));
    });

    test('every error code has an Arabic message and an action', () {
      for (final code in ErrorCode.values) {
        final appError = AppError(code);
        final message = ErrorMapper.userMessage(appError);
        expect(message, isNotEmpty, reason: 'missing Arabic message for $code');
        expect(code.action, isNotNull, reason: 'missing action for $code');
      }
    });
  });

  group('SafeAsync always restores UI from loading state', () {
    test('onDone runs on success', () async {
      var done = false;
      await Future<void>.value().safe(onDone: () => done = true);
      expect(done, isTrue);
    });

    test('onDone runs even when the operation throws', () async {
      var done = false;
      AppError? caught;
      await Future<void>.error(StateError('boom'))
          .safe(onError: (e) => caught = e, onDone: () => done = true);
      expect(done, isTrue);
      expect(caught, isNotNull);
    });
  });

  group('RetryPolicy', () {
    test('retries idempotent network errors then succeeds', () async {
      const policy = RetryPolicy(baseDelay: Duration(milliseconds: 1));
      var attempts = 0;

      final result = await policy.run<int>(() async {
        attempts++;
        if (attempts < 3) {
          throw FirebaseAuthException(code: 'network-request-failed');
        }
        return 42;
      });

      expect(result, 42);
      expect(attempts, 3);
    });

    test('does NOT retry non-idempotent operations (retryable: false)',
        () async {
      const policy = RetryPolicy(baseDelay: Duration(milliseconds: 1));
      var attempts = 0;

      await expectLater(
        policy.run<int>(
          () async {
            attempts++;
            throw FirebaseAuthException(code: 'network-request-failed');
          },
          retryable: false,
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(attempts, 1); // exactly one attempt — never retried
    });

    test('gives up after maxAttempts (no infinite retry)', () async {
      const policy =
          RetryPolicy(maxAttempts: 2, baseDelay: Duration(milliseconds: 1));
      var attempts = 0;

      await expectLater(
        policy.run<int>(() async {
          attempts++;
          throw FirebaseAuthException(code: 'network-request-failed');
        }),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(attempts, 3); // initial + 2 retries, then it stops
    });
  });
}
