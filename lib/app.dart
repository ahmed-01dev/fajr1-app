import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/fajr_theme.dart';

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
      home: Scaffold(
        backgroundColor: FajrTheme.navyDeep,
        appBar: AppBar(
          title: const Text('فَجْر'),
          actions: [
            if (isLocalMode)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Chip(
                  backgroundColor: FajrTheme.gold,
                  label: Text(
                    'الوضع المحلي التجريبي',
                    style: TextStyle(fontSize: 11, color: FajrTheme.navyDeep),
                  ),
                ),
              ),
          ],
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'الشاشة الرئيسية — تُبنى في المرحلة التالية.\n'
              'ما يعمل الآن: البدء الآمن، الثيم العربي، الأذكار، أوقات الصلاة (قريبًا).',
              textAlign: TextAlign.center,
              style: FajrTheme.body,
            ),
          ),
        ),
      ),
    );
  }
}
