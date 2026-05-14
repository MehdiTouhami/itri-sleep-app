import 'package:flutter/services.dart';

import '../models/sleep_night.dart';

class SleepRepository {
  // In-memory cache — data loads once per app session
  static List<SleepNight>? _cache;

  Future<List<SleepNight>> loadSleepData() async {
    if (_cache != null) return _cache!;

    final List<SleepNight> nights = [];

    for (int i = 1; i <= 279; i++) {
      try {
        final csv = await rootBundle.loadString('assets/data/Sleep-$i.csv');
        final night = _parse(csv);
        if (night != null) nights.add(night);
      } catch (_) {
        // Skip missing or malformed files silently
      }
    }

    // Sort most recent first by parsing the date field
    nights.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));

    _cache = nights;
    return nights;
  }

  SleepNight? _parse(String csv) {
    final Map<String, String> data = {};

    for (final line in csv.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final comma = trimmed.indexOf(',');
      if (comma < 1) continue;
      final key = trimmed.substring(0, comma).trim();
      final value = trimmed.substring(comma + 1).trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        data.putIfAbsent(key, () => value); // first occurrence wins
      }
    }

    final date = data['Date'] ?? '';
    if (date.isEmpty) return null;

    return SleepNight(
      date:          date,
      sleepDuration: data['Sleep Duration'] ?? '',
      sleepScore:    int.tryParse(data['Sleep Score'] ?? '') ?? 0,
      quality:       data['Quality'] ?? '',
      stressAvg:     data['Stress Avg'] ?? '',
      deepSleep:     data['Deep Sleep Duration'] ?? '',
      lightSleep:    data['Light Sleep Duration'] ?? '',
      remSleep:      data['REM Duration'] ?? '',
      awakeTime:     data['Awake Time'] ?? '',
      restingHR:     data['Resting Heart Rate'] ?? '',
      hrv:           data['Avg Overnight HRV'] ?? '',
      bodyBattery:   data['Body Battery Change'] ?? '',
      respiration:   data['Avg Respiration'] ?? '',
    );
  }

  /// Parses "11/30/25" → DateTime for sorting. Falls back to epoch on failure.
  DateTime _parseDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return DateTime(0);
      final month = int.parse(parts[0]);
      final day   = int.parse(parts[1]);
      final year  = 2000 + int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (_) {
      return DateTime(0);
    }
  }
}
