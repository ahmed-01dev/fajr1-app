import 'package:flutter/material.dart';

/// Single source of truth for the visual identity. No duplicated styles
/// anywhere in the app (§3).
abstract final class FajrTheme {
  // Palette
  static const Color navyDeep = Color(0xFF0A1630);
  static const Color navyCard = Color(0xFF12203F);
  static const Color emerald = Color(0xFF10B981);
  static const Color gold = Color(0xFFD4AF37);
  static const Color danger = Color(0xFFEF4444);

  // Text styles
  static const splashTitle = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w700,
    color: gold,
    fontFamily: 'Amiri',
  );

  static const headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const body = TextStyle(
    fontSize: 15,
    color: Colors.white70,
    height: 1.6,
  );

  static const label = TextStyle(
    fontSize: 12,
    color: Colors.white54,
  );

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: navyDeep,
      colorScheme: base.colorScheme.copyWith(
        primary: emerald,
        secondary: gold,
        surface: navyDeep,
        error: danger,
      ),
      cardTheme: const CardThemeData(color: navyCard, elevation: 0),
      appBarTheme: const AppBarTheme(
        backgroundColor: navyDeep,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: navyDeep,
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: navyCard,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
