import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/sleep_provider.dart';
import '../core/theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/score_ring.dart';
import '../core/models/sleep_night.dart';
import '../core/utils/duration_utils.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return ref.watch(sleepDataProvider).when(
      loading: () => const SafeArea(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading insights:\n$e', textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (nights) {

        if (nights.isEmpty) {
          return const SafeArea(
            child: Center(
              child: Text(
                'No sleep data found', // Empty state
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        final recent7 = nights.take(7).toList(); // Only recent data
        final latest = recent7.first; // Most recent night

        // Main metrics
        final latestScore = latest.sleepScore;
        final recentAverageScore = _averageScore(recent7);
        final averageSleepMinutes = _averageSleepMinutes(recent7);
        final trend = _trendValue(recent7);

        // Key factors
        final consistencyValue = _sleepConsistencyValue(recent7);
        final bedtimeValue = _bedtimeRoutineValue(recent7);
        final recoveryValue = _recoveryLoadValue(recent7);
        final stressImpactValue = _stressImpactValue(recent7);

        // RF feature importance (from backend — may be loading or unavailable)
        final featureAsync = ref.watch(featureImportanceProvider);

        // Average sleep stages
        final avgDeep =
            _averageDuration(recent7.map((e) => e.deepSleep).toList());
        final avgLight =
            _averageDuration(recent7.map((e) => e.lightSleep).toList());
        final avgRem = _averageDuration(recent7.map((e) => e.remSleep).toList());
        final avgAwake =
            _averageDuration(recent7.map((e) => e.awakeTime).toList());

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760), // Web width limit
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insights',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track your sleep quality, recovery, and patterns',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Top summary card
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16), // Keeps content inside card
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isTight = constraints.maxWidth < 560; // Responsive switch

                                if (isTight) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ScoreRing(score: latestScore, size: 76, strokeWidth: 5, showLabel: false),
                                      const SizedBox(height: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Latest Sleep Score',
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _headlineFromScore(latestScore),
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _summaryText(
                                              latestScore,
                                              recentAverageScore,
                                              trend,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ScoreRing(score: latestScore, size: 76, strokeWidth: 5, showLabel: false),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Latest Sleep Score',
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _headlineFromScore(latestScore),
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _summaryText(
                                              latestScore,
                                              recentAverageScore,
                                              trend,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isTight = constraints.maxWidth < 500; // Responsive metrics

                                  if (isTight) {
                                    return Column(
                                      children: [
                                        _TopMetric(
                                          label: '7-Night Average',
                                          value: '$recentAverageScore',
                                        ),
                                        const SizedBox(height: 14),
                                        _TopMetric(
                                          label: 'Average Sleep',
                                          value: minutesToDuration(
                                            averageSleepMinutes,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        _TopMetric(
                                          label: 'Trend',
                                          value: trend > 0
                                              ? '+$trend'
                                              : trend.toString(),
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _TopMetric(
                                          label: '7-Night Average',
                                          value: '$recentAverageScore',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _TopMetric(
                                          label: 'Average Sleep',
                                          value: minutesToDuration(
                                            averageSleepMinutes,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _TopMetric(
                                          label: 'Trend',
                                          value: trend > 0
                                              ? '+$trend'
                                              : trend.toString(),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Weekly score chart
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weekly Trend',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your sleep score over the last 7 nights',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 190,
                              child: _WeeklyTrendChart(nights: recent7),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Key factor progress bars
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Key Factors',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FactorTile(
                              title: 'Sleep Consistency',
                              status: _factorStatus(consistencyValue),
                              value: consistencyValue,
                            ),
                            const SizedBox(height: 12),
                            _FactorTile(
                              title: 'Bedtime Routine',
                              status: _factorStatus(bedtimeValue),
                              value: bedtimeValue,
                            ),
                            const SizedBox(height: 12),
                            _FactorTile(
                              title: 'Recovery Load',
                              status: _factorStatus(recoveryValue),
                              value: recoveryValue,
                            ),
                            const SizedBox(height: 12),
                            _FactorTile(
                              title: 'Stress Impact',
                              status: _stressStatus(stressImpactValue),
                              value: stressImpactValue,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // RF model: top sleep score drivers
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'What Drives Your Score',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'ML Model',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Top factors from your Random Forest model',
                              style: TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            featureAsync.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              error: (_, __) => Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.cloud_off_rounded, size: 18, color: Colors.white38),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Start the backend to see ML insights',
                                        style: TextStyle(color: Colors.white54, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              data: (features) {
                                final top5 = features.take(5).toList();
                                final maxImp = top5.isNotEmpty ? top5.first.importance : 1.0;
                                return Column(
                                  children: List.generate(top5.length, (i) {
                                    final item = top5[i];
                                    final bar = maxImp > 0 ? item.importance / maxImp : 0.0;
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: i < top5.length - 1 ? 12 : 0),
                                      child: _RFFeatureBar(
                                        rank: i + 1,
                                        label: item.feature,
                                        value: bar,
                                        importance: item.importance,
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Average sleep stages
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sleep Stages',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SleepStageRow(
                              color: const Color(0xFF7B8CFF),
                              label: 'Deep Sleep',
                              value: avgDeep,
                            ),
                            const SizedBox(height: 10),
                            _SleepStageRow(
                              color: const Color(0xFF6EE7F9),
                              label: 'Light Sleep',
                              value: avgLight,
                            ),
                            const SizedBox(height: 10),
                            _SleepStageRow(
                              color: const Color(0xFFAF8CFF),
                              label: 'REM Sleep',
                              value: avgRem,
                            ),
                            const SizedBox(height: 10),
                            _SleepStageRow(
                              color: const Color(0xFFFF8FA3),
                              label: 'Awake',
                              value: avgAwake,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Smart recommendation cards
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recommendations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _RecommendationTile(
                              icon: Icons.nightlight_round,
                              title: _recommendation1Title(recent7),
                              subtitle: _recommendation1Subtitle(recent7),
                            ),
                            const SizedBox(height: 10),
                            _RecommendationTile(
                              icon: Icons.sports_tennis_rounded,
                              title: _recommendation2Title(recent7),
                              subtitle: _recommendation2Subtitle(recent7),
                            ),
                            const SizedBox(height: 10),
                            const _RecommendationTile(
                              icon: Icons.phone_iphone_rounded,
                              title: 'Lower screen exposure',
                              subtitle:
                                  'A calmer 30-minute wind-down routine could improve sleep onset and help maintain consistency.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Average score across selected nights
  static int _averageScore(List<SleepNight> nights) {
    if (nights.isEmpty) return 0;
    final total = nights.fold<int>(0, (sum, n) => sum + n.sleepScore);
    return (total / nights.length).round();
  }

  // Average sleep duration in minutes
  static int _averageSleepMinutes(List<SleepNight> nights) {
    if (nights.isEmpty) return 0;
    final total = nights.fold<int>(
      0,
      (sum, n) => sum + durationToMinutes(n.sleepDuration),
    );
    return (total / nights.length).round();
  }

  // Simple trend = latest - oldest
  static int _trendValue(List<SleepNight> nights) {
    if (nights.length < 2) return 0;
    final latest = nights.first.sleepScore;
    final oldest = nights.last.sleepScore;
    return latest - oldest;
  }

  // Consistency based on sleep duration spread
  static double _sleepConsistencyValue(List<SleepNight> nights) {
    if (nights.isEmpty) return 0.15;

    final durations = nights
        .map((e) => durationToMinutes(e.sleepDuration).toDouble())
        .toList();

    final avg = durations.reduce((a, b) => a + b) / durations.length;
    final spread = durations
            .map((d) => (d - avg).abs())
            .fold<double>(0, (a, b) => a + b) /
        durations.length;

    final value = 1 - (spread / 120);
    return value.clamp(0.15, 0.95); // Keeps UI values safe
  }

  // Routine strength based on average sleep time
  static double _bedtimeRoutineValue(List<SleepNight> nights) {
    final avgSleep = _averageSleepMinutes(nights);
    final value = avgSleep / 480; // 480 = 8h target
    return value.clamp(0.15, 0.95);
  }

  // Recovery bar based on average score
  static double _recoveryLoadValue(List<SleepNight> nights) {
    final avgScore = _averageScore(nights) / 100;
    return avgScore.clamp(0.15, 0.95);
  }

  // Stress bar based on parsed stress values
  static double _stressImpactValue(List<SleepNight> nights) {
    final values = nights.map((e) => _parseStressValue(e)).toList();
    if (values.isEmpty) return 0.4;

    final avg = values.reduce((a, b) => a + b) / values.length;
    final adjusted = 1 - (avg / 30);
    return adjusted.clamp(0.15, 0.95);
  }

  // Extracts number from stress text
  static int _parseStressValue(SleepNight night) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(night.stressAvg);
    return int.tryParse(match?.group(1) ?? '0') ?? 0;
  }

  // Average a list of duration strings
  static String _averageDuration(List<String> values) {
    if (values.isEmpty) return '--';
    final total = values.fold<int>(0, (sum, v) => sum + durationToMinutes(v));
    final avg = (total / values.length).round();
    return minutesToDuration(avg);
  }


  // Headline label from score
  static String _headlineFromScore(int score) {
    if (score >= 85) return 'Excellent Recovery';
    if (score >= 75) return 'Great Recovery';
    if (score >= 65) return 'Decent Recovery';
    return 'Recovery Needs Work';
  }

  // Top summary sentence
  static String _summaryText(int latestScore, int averageScore, int trend) {
    final trendText = trend > 0
        ? 'improving'
        : trend < 0
            ? 'slipping slightly'
            : 'staying steady';

    return 'Your latest sleep score is $latestScore. Over the last 7 nights, your average score is $averageScore, and your pattern is $trendText.';
  }

  // Label for factor bars
  static String _factorStatus(double value) {
    if (value >= 0.8) return 'Strong';
    if (value >= 0.6) return 'Moderate';
    return 'Needs Work';
  }

  // Label for stress bar
  static String _stressStatus(double value) {
    if (value >= 0.8) return 'Low';
    if (value >= 0.6) return 'Good';
    return 'Needs Work';
  }

  // Recommendation title from average sleep
  static String _recommendation1Title(List<SleepNight> nights) {
    final avgSleep = _averageSleepMinutes(nights);
    if (avgSleep < 420) return 'Sleep a bit earlier';
    if (avgSleep < 470) return 'Protect your current routine';
    return 'Keep your current sleep window';
  }

  // Recommendation text from average sleep
  static String _recommendation1Subtitle(List<SleepNight> nights) {
    final avgSleep = _averageSleepMinutes(nights);
    if (avgSleep < 420) {
      return 'Your average sleep is below 7 hours. Going to bed slightly earlier could improve recovery and consistency.';
    }
    if (avgSleep < 470) {
      return 'You are close to a strong sleep average. Protecting your current routine can help move you into a better recovery range.';
    }
    return 'Your average sleep duration is strong. Focus on keeping that routine stable across the week.';
  }

  // Recommendation title from trend
  static String _recommendation2Title(List<SleepNight> nights) {
    final trend = _trendValue(nights);
    if (trend < 0) return 'Reduce late training intensity';
    return 'Support recovery after training';
  }

  // Recommendation text from trend
  static String _recommendation2Subtitle(List<SleepNight> nights) {
    final trend = _trendValue(nights);
    if (trend < 0) {
      return 'Your recent trend is dipping slightly. Hard evening sessions may be affecting recovery and sleep score.';
    }
    return 'Your recent scores are stable or improving. Continue balancing training load with recovery habits.';
  }
}

// Weekly bar chart widget
class _WeeklyTrendChart extends StatelessWidget {
  final List<SleepNight> nights;

  const _WeeklyTrendChart({required this.nights});

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final ordered = nights.reversed.toList(); // Oldest to newest

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = math.max(ordered.length, 1);
        final itemWidth = constraints.maxWidth / count; // Keeps bars inside card

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(ordered.length, (index) {
            final night = ordered[index];
            final day = labels[index % labels.length];

            return SizedBox(
              width: itemWidth,
              child: Center(
                child: _TrendBar(
                  day: day,
                  score: night.sleepScore.toDouble(),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}


// Small summary metric
class _TopMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TopMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// One trend bar
class _TrendBar extends StatelessWidget {
  final String day;
  final double score;

  const _TrendBar({
    required this.day,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    const double maxBarHeight = 110;
    final double filledHeight = (score / 100) * maxBarHeight; // Score to bar height

    return SizedBox(
      width: 34,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            score.toInt().toString(),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 22,
            height: maxBarHeight,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 22,
              height: filledHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFF6EE7F9),
                    Color(0xFF7B8CFF),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Progress bar tile
class _FactorTile extends StatelessWidget {
  final String title;
  final String status;
  final double value;

  const _FactorTile({
    required this.title,
    required this.status,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                status,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value, // 0 to 1
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8A90FF)),
            ),
          ),
        ],
      ),
    );
  }
}

// Sleep stage row
class _SleepStageRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _SleepStageRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// RF feature importance bar
class _RFFeatureBar extends StatelessWidget {
  final int rank;
  final String label;
  final double value;       // 0–1 relative to top feature
  final double importance;  // raw importance value

  const _RFFeatureBar({
    required this.rank,
    required this.label,
    required this.value,
    required this.importance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Text(
                '${(importance * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// Recommendation tile
class _RecommendationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RecommendationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

