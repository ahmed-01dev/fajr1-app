import 'package:flutter/material.dart';
import 'app.dart';
import 'bootstrap/splash_screen.dart';
import 'bootstrap/startup_controller.dart';

void main() => runApp(const FajrBootstrap());

/// Root widget. The ONLY route is the splash FSM — there is no code path
/// that can wait forever before the first usable screen renders (§7).
class FajrBootstrap extends StatelessWidget {
  const FajrBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: SplashScreen(
        onNext: (state) {
          // Route strictly by the FSM result:
          //   ready    → full app with cloud services
          //   degraded → clearly labeled local/demo mode (never fake success)
          //   failed   → never reaches here; retry UI is shown instead
          final isLocalMode = state != StartupState.ready;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => FajrApp(isLocalMode: isLocalMode)),
          );
        },
      ),
    );
  }
}
