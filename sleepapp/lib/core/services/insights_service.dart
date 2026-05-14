import '../models/sleep_night.dart';
import '../utils/duration_utils.dart';

class InsightsService {

  double sleepConsistency(List<SleepNight> nights) {
    final durations = nights
        .map((n) => durationToMinutes(n.sleepDuration))
        .toList();

    if (durations.isEmpty) return 0;

    final avg =
        durations.reduce((a, b) => a + b) / durations.length;

    double variation = 0;

    for (final d in durations) {
      variation += (d - avg).abs();
    }

    variation = variation / durations.length;

    final score = 100 - variation;
    return score.clamp(0, 100);
  }

  double recoveryScore(List<SleepNight> nights) {
    if (nights.isEmpty) return 0;

    final last = nights.last;

    final hrv = double.tryParse(last.hrv) ?? 0;

    final duration = durationToMinutes(last.sleepDuration);

    final sleepScore = (duration / 480) * 100;

    final recovery = (sleepScore + hrv) / 2;

    return recovery.clamp(0, 100);
  }

  double stressImpact(List<SleepNight> nights) {
    final stressValues = nights
        .map((n) => double.tryParse(n.stressAvg) ?? 0)
        .toList();

    if (stressValues.isEmpty) return 0;

    final avg =
        stressValues.reduce((a, b) => a + b) / stressValues.length;

    return avg.clamp(0, 100);
  }

}