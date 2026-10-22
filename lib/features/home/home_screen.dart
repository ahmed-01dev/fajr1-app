import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/fajr_theme.dart';
import '../../bootstrap/startup_controller.dart';
import '../adhkar/adhkar_screen.dart';
import '../prayer/city_presets.dart';
import '../prayer/prayer_times_screen.dart';

/// Main navigation hub shown after a successful (or degraded) startup.
/// Cloud-only features are DISABLED and clearly explained in demo mode —
/// never fake buttons that pretend to work (§6.11).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.isLocalMode});

  final bool isLocalMode;

  @override
  Widget build(BuildContext context) {
    final startup = context.watch<StartupController>();
    final localMode = isLocalMode || startup.isLocalMode;

    return Scaffold(
      backgroundColor: FajrTheme.navyDeep,
      appBar: AppBar(
        title: const Text('فَجْر'),
        actions: [
          if (localMode)
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
                builder: (_) => PrayerTimesScreen(
                  onCitySelected: (city) => debugPrint('city: ${city.name}'),
                ),
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
            subtitle: localMode
                ? 'يتطلب Firebase — غير متاح في الوضع المحلي'
                : 'انضم لفريق أو أنشئ فريقك الخاص',
            enabled: !localMode,
            onTap: () {},
          ),
          _SectionCard(
            icon: Icons.person_search,
            title: 'رفيق الفجر',
            subtitle: localMode
                ? 'يتطلب Firebase — غير متاح في الوضع المحلي'
                : 'اطلب من صاحبك أن يوقظك لصلاة الفجر',
            enabled: !localMode,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Text(
            localMode
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
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: enabled ? FajrTheme.navyCard : FajrTheme.navyCard.withOpacity(0.5),
        child: ListTile(
          enabled: enabled,
          leading: Icon(
            icon,
            color: enabled ? FajrTheme.gold : Colors.white24,
            size: 32,
          ),
          title: Text(
            title,
            style: FajrTheme.headline.copyWith(color: enabled ? null : Colors.white38),
          ),
          subtitle: Text(subtitle, style: FajrTheme.label),
          trailing: Icon(
            Icons.chevron_left,
            color: enabled ? FajrTheme.emerald : Colors.white24,
          ),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}
