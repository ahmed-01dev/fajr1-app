import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fajr/bootstrap/startup_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'startup reaches a usable state even when Firebase never responds',
    () async {
      final controller = StartupController();
      final stopwatch = Stopwatch()..start();
      await controller.start();
      stopwatch.stop();

      // Hard bound: startup MUST terminate. This is the anti-infinite-splash test.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 20)));
      expect(controller.state, isNot(StartupState.initializing));
      controller.dispose();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test('startup is idempotent — no repeated init loops', () async {
    final controller = StartupController();
    await controller.start();
    final stateAfterFirst = controller.state;

    await controller.start(); // second call must not restart or change state
    expect(controller.state, stateAfterFirst);
    controller.dispose();
  });

  test('retry resets and re-runs cleanly', () async {
    final controller = StartupController();
    await controller.start();
    final stateBefore = controller.state;

    await controller.retry();
    expect(controller.state, isNot(StartupState.initializing));
    // Deterministic: same environment ⇒ same outcome
    expect(controller.state, stateBefore);
    controller.dispose();
  });

  test('no state change or crash after dispose (setState-after-dispose guard)',
      () async {
    final controller = StartupController();
    controller.dispose();

    // A late async result must not throw after dispose.
    await controller.start();
  });

  test('missing Firebase config routes to degraded (demo), not failed',
      () async {
    // In this test environment Firebase.initializeApp throws because
    // google-services.json / firebase_options.dart are absent —
    // the controller must treat that as degraded local mode.
    final controller = StartupController();
    await controller.start();

    expect(controller.state, anyOf(StartupState.degraded, StartupState.ready));
    expect(controller.isLocalMode, controller.state != StartupState.ready);
    controller.dispose();
  });
}
