import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/errors.dart';
import '../../core/theme/fajr_theme.dart';
import 'city_presets.dart';

/// Prayer-times screen. Works fully OFFLINE:
/// - City chosen manually from a built-in list (saved preference).
/// - Times computed locally by the verified `adhan` package.
/// - No invented times: without a selected city, the screen asks the user
///   to pick one instead of showing made-up numbers (§4).
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key, required this.onCitySelected});

  /// Notifies the app shell so other features can use the chosen city.
  final void Function(CityPreset city) onCitySelected;

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  CityPreset? _city;

  @override
  void initState() {
    super.initState();
    _loadSavedCity();
  }

  Future<void> _loadSavedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('selected_city');
      if (name == null) return;
      final match = kCities.where((c) => c.name == name).firstOrNull;
      if (match != null && mounted) setState(() => _city = match);
    } on Exception {
      // Corrupted prefs are non-fatal: user just re-picks the city.
    }
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<CityPreset>(
      context: context,
      backgroundColor: FajrTheme.navyCard,
      builder: (_) => SafeArea(
        child: ListView(
          children: [
            for (final city in kCities)
              ListTile(
                title: Text(city.name, style: FajrTheme.body),
                onTap: () => Navigator.of(context).pop(city),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return; // user cancelled — no fake selection

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_city', picked.name);
    widget.onCitySelected(picked);
    if (mounted) setState(() => _city = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FajrTheme.navyDeep,
      appBar: AppBar(title: const Text('أوقات الصلاة')),
      body: _city == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_city,
                        size: 48, color: FajrTheme.gold),
                    const SizedBox(height: 16),
                    const Text(
                      'اختر مدينتك لحساب أوقات الصلاة',
                      style: FajrTheme.headline,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'الحساب يتم على جهازك بدون إنترنت، ولا نجمع موقعك.',
                      style: FajrTheme.label,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _pickCity,
                      child: const Text('اختيار المدينة'),
                    ),
                  ],
                ),
              ),
            )
          : _buildTimes(_city!),
    );
  }

  Widget _buildTimes(CityPreset city) {
    final PrayerTimes times;
    try {
      times = PrayerTimes.today(
        Coordinates(city.latitude, city.longitude),
        CalculationMethod.muslimWorldLeague().parameters,
      );
    } on Exception {
      // Computation failed (e.g. invalid coordinates) — never show
      // invented times. Offer the manual fallback (§4.C).
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ErrorMapper.userMessage(
                const AppError(ErrorCode.invalidPrayerTime),
              ),
              style: FajrTheme.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _pickCity,
              child: const Text('اختيار مدينة أخرى'),
            ),
          ],
        ),
      );
    }

    final rows = <(String, DateTime)>[
      ('الفجر', times.fajr),
      ('الشروق', times.sunrise),
      ('الظهر', times.dhuhr),
      ('العصر', times.asr),
      ('المغرب', times.maghrib),
      ('العشاء', times.isha),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(city.name, style: FajrTheme.headline),
                TextButton(
                  onPressed: _pickCity,
                  child: const Text('تغيير'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final (name, time) in rows)
          Card(
            child: ListTile(
              title: Text(name, style: FajrTheme.headline),
              trailing: Text(
                _format(time),
                style: const TextStyle(
                  color: name == 'الفجر' ? FajrTheme.gold : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'طريقة الحساب: رابطة العالم الإسلامي — الحساب محلي على جهازك.',
          style: FajrTheme.label,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _format(DateTime time) {
    final h = time.hour;
    final period = h >= 12 ? 'م' : 'ص';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }
}
