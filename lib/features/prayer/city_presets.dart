/// Built-in city presets. These are stable public coordinates rounded to
/// two decimals — accurate enough for prayer times (city-level precision).
///
/// This list is the MANUAL fallback: when the user denies location
/// permission, they pick a city here instead of the app failing (§4.C).
class CityPreset {
  const CityPreset(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;
}

const List<CityPreset> kCities = [
  CityPreset('مكة المكرمة', 21.42, 39.83),
  CityPreset('المدينة المنورة', 24.47, 39.61),
  CityPreset('الرياض', 24.71, 46.68),
  CityPreset('جدة', 21.54, 39.19),
  CityPreset('القاهرة', 30.04, 31.24),
  CityPreset('الإسكندرية', 31.20, 29.92),
  CityPreset('دبي', 25.20, 55.27),
  CityPreset('أبوظبي', 24.45, 54.38),
  CityPreset('الدوحة', 25.29, 51.53),
  CityPreset('الكويت', 29.38, 47.99),
  CityPreset('المنامة', 26.23, 50.59),
  CityPreset('مسقط', 23.59, 58.41),
  CityPreset('عمّان', 31.96, 35.95),
  CityPreset('القدس', 31.78, 35.22),
  CityPreset('بيروت', 33.89, 35.5),
  CityPreset('دمشق', 33.51, 36.29),
  CityPreset('بغداد', 33.31, 44.36),
  CityPreset('الخرطوم', 15.5, 32.56),
  CityPreset('الدار البيضاء', 33.57, -7.59),
  CityPreset('تونس', 36.8, 10.18),
  CityPreset('الجزائر', 36.75, 3.06),
  CityPreset('إسلام آباد', 33.68, 73.05),
  CityPreset('كراتشي', 24.86, 67.01),
  CityPreset('إسطنبول', 41.01, 28.98),
  CityPreset('لندن', 51.51, -0.13),
  CityPreset('باريس', 48.86, 2.35),
  CityPreset('برلين', 52.52, 13.41),
  CityPreset('نيويورك', 40.71, -74.01),
  CityPreset('جاكرتا', -6.21, 106.85),
  CityPreset('كوالالمبور', 3.14, 101.69),
];
