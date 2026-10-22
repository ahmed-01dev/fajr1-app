import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/fajr_theme.dart';
import 'features/home/home_screen.dart';

class FajrApp extends StatelessWidget {
  const FajrApp({super.key, required this.isLocalMode});

  /// When true, cloud features are disabled and every affected button shows
  /// a clear "يتطلب Firebase" explanation instead of pretending to work.
  final bool isLocalMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'فَجْر',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl, // explicit Arabic RTL
        child: child!,
      ),
      theme: FajrTheme.dark(),
      home: HomeScreen(isLocalMode: isLocalMode),
    );
  }
}
