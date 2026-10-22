import 'package:flutter/material.dart';

import '../../core/theme/fajr_theme.dart';
import '../adhkar/adhkar_screen.dart';
import '../prayer/prayer_times_screen.dart';

/// Main navigation hub shown after a successful (or degraded) startup.
/// Cloud-only features are DISABLED and clearly explained in demo mode —
/// never fake buttons that pretend to work.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.isLocalMode});

  /// True when running without Firebase — cloud features stay disabled
  /// with a clear explanation, never fake success.
  final bool isLocalMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  'الوضع المحلي',
                  style: TextStyle(
                    fontSize: 11,
                    color: FajrTheme.navyDeep,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            icon: Icons.access_time,
            title: 'أوقات الصلاة',
            subtitle: 'حساب محلي على جهازك — اختر مدينتك',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PrayerTimesScreen(onCitySelected: _noOp),
              ),
            ),
          ),
          _SectionCard(
            icon: Icons.menu_book,
            title: 'أذكار الصباح',
            subtitle: 'أذكار موثقة بالمصادر — تعمل بدون إنترنت',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdhkarScreen()),
            ),
          ),
          _SectionCard(
            icon: Icons.groups,
            title: 'الفرق',
            subtitle: isLocalMode
                ? 'يتطلب Firebase — غير متاح في الوضع المحلي'
                : 'انضم لفريق أو أنشئ فريقك الخاص (قريبًا)',
            enabled: false, // teams screen lands in the next stage
            onTap: () {},
          ),
          _SectionCard(
            icon: Icons.person_search,
            title: 'رفيق الفجر',
            subtitle: isLocalMode
                ? 'يتطلب Firebase — غير متاح في الوضع المحلي'
                : 'اطلب من صاحبك أن يوقظك لصلاة الفجر (قريبًا)',
            enabled: false, // companion screen lands in the next stage
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Text(
            isLocalMode
                ? 'يعمل التطبيق الآن في الوضع المحلي التجريبي: أوقات الصلاة والأذكار متاحة، '
                    'والميزات الاجتماعية تحتاج ربط Firebase (انظر README).'
                : 'مرحبًا بك في فَجْر — كل الميزات متاحة.',
            style: FajrTheme.label,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Placeholder callback until the shell consumes the selected city.
  static void _noOp() {}
}
