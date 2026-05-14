import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';

import '../data/sleep_repository.dart';
import '../models/sleep_night.dart';

// ---------------------------------------------------------------------------
// Feature importance model
// ---------------------------------------------------------------------------
class FeatureImportanceItem {
  final String feature;
  final double importance;
  const FeatureImportanceItem({required this.feature, required this.importance});
}

/// Single shared repository instance.
final sleepRepositoryProvider = Provider<SleepRepository>(
  (_) => SleepRepository(),
);

/// Async provider for all sleep nights, sorted newest first.
/// Data loads once and is shared across every screen — no per-tab reloads.
final sleepDataProvider = FutureProvider<List<SleepNight>>((ref) {
  return ref.watch(sleepRepositoryProvider).loadSleepData();
});

/// Convenience: latest single night (or null if no data).
final latestNightProvider = Provider<SleepNight?>((ref) {
  return ref.watch(sleepDataProvider).asData?.value.firstOrNull;
});

/// Convenience: most recent N nights.
final recentNightsProvider = Provider.family<List<SleepNight>, int>((ref, n) {
  final nights = ref.watch(sleepDataProvider).asData?.value ?? [];
  return nights.take(n).toList();
});

/// RF feature importances from the backend — fetched once, cached by Riverpod.
final featureImportanceProvider = FutureProvider<List<FeatureImportanceItem>>((ref) async {
  final res = await http.get(Uri.parse('${AppConfig.kBaseUrl}/feature-importance'));
  if (res.statusCode != 200) throw Exception('Backend returned ${res.statusCode}');
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final features = data['features'] as List<dynamic>;
  return features.map((f) => FeatureImportanceItem(
    feature: f['feature'] as String,
    importance: (f['importance'] as num).toDouble(),
  )).toList();
});
