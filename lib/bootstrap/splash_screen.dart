import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../errors/errors.dart';
import 'startup_controller.dart';

/// Splash screen driven by the finite startup FSM. The spinner is BOUNDED:
/// every state transition has an exit path — there is no path that waits
/// forever (§7.11).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onNext});

  /// Called exactly once with the final FSM state.
  final void Function(StartupState state) onNext;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final StartupController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StartupController();
    _controller.addListener(_route);
    // Fire-and-forget: errors flow through the FSM state, never an
    // unhandled async callback (§7.13).
    _controller.start();
  }

  void _route() {
    if (!mounted) return; // never navigate after dispose (§7.14)
    final state = _controller.state;
    if (state == StartupState.initializing) return;
    _controller.removeListener(_route);
    widget.onNext(state);
  }

  @override
  void dispose() {
    _controller.removeListener(_route);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1630),
        body: Consumer<StartupController>(
          builder: (context, controller, _) => switch (controller.state) {
            StartupState.initializing ||
            StartupState.ready ||
            StartupState.degraded => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'فَجْر',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
            StartupState.failed => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, color: Color(0xFFD4AF37), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      controller.lastError == null
                          ? 'تعذّر بدء التطبيق.'
                          : ErrorMapper.userMessage(controller.lastError!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: controller.retry,
                      child: const Text('إعادة المحاولة'),
                    ),
                    TextButton(
                      onPressed: () => widget.onNext(StartupState.degraded),
                      child: const Text('المتابعة في الوضع المحلي'),
                    ),
                  ],
                ),
              ),
            ),
          },
        ),
      ),
    );
  }
}
