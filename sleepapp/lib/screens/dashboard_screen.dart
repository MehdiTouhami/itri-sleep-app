import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/sleep_provider.dart';
import '../core/providers/goals_provider.dart';
import '../core/theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/score_ring.dart';
import '../core/models/sleep_night.dart';
import 'sleep_detail_screen.dart';

// Main Home screen showing latest sleep summary
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final goals     = ref.watch(goalsProvider);

    return ref.watch(sleepDataProvider).when(
      loading: () => const SafeArea(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading sleep data:\n$e', textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (nights) {
        if (nights.isEmpty) {
          return const SafeArea(
            child: Center(
              child: Text(
                'No sleep data found',
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        // Use most recent sleep record
        final latest = nights.first;

        return SafeArea(
          child: SingleChildScrollView(
            // Scrollable layout for the dashboard
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
            child: Center(
              child: ConstrainedBox(
                // Prevent UI from stretching too wide
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dashboard',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            child: Text(
                              goals.initials,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Your sleep summary for today',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Main sleep summary card
                    GestureDetector(
                      onTap: () {
                        // Navigate to full sleep details
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SleepDetailsScreen(night: latest),
                          ),
                        );
                      },
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ScoreRing(score: latest.sleepScore),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: _HeroTextSection(night: latest),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // Key sleep metrics
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _TopMetric(
                                        label: 'Sleep',
                                        value: latest.sleepDuration,
                                      ),
                                    ),
                                    const _MetricDivider(),
                                    Expanded(
                                      child: _TopMetric(
                                        label: 'Quality',
                                        value: latest.quality,
                                      ),
                                    ),
                                    const _MetricDivider(),
                                    Expanded(
                                      child: _TopMetric(
                                        label: 'HRV',
                                        value: latest.hrv,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              const Row(
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    size: 14,
                                    color: Colors.white54,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Tap to view full sleep details',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            icon: Icons.bedtime_rounded,
                            title: 'Deep Sleep',
                            value: latest.deepSleep,
                            subtitle: 'From Garmin data',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            icon: Icons.auto_graph_rounded,
                            title: 'REM Sleep',
                            value: latest.remSleep,
                            subtitle: 'From Garmin data',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            icon: Icons.favorite_outline_rounded,
                            title: 'Resting HR',
                            value: latest.restingHR,
                            subtitle: 'Stable overnight',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            icon: Icons.bolt_rounded,
                            title: 'Awake Time',
                            value: latest.awakeTime,
                            subtitle: 'Night interruptions',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Advice section based on sleep score
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tonight Focus',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _HomeActionTile(
                              icon: Icons.nightlight_round,
                              title: _bedtimeAdvice(latest),
                              subtitle:
                                  'Your latest sleep record suggests focusing on consistency and recovery tonight.',
                            ),
                            const SizedBox(height: 10),
                            const _HomeActionTile(
                              icon: Icons.phone_iphone_rounded,
                              title: 'Start winding down earlier',
                              subtitle:
                                  'Reduce screen exposure 30 minutes before bed to improve sleep onset.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Simple rule-based coach message
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Coach Message',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _CoachMessageCard(
                              message: _coachMessage(latest),
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

  // Generate bedtime advice based on score
  static String _bedtimeAdvice(SleepNight night) {
    if (night.sleepScore < 70) {
      return 'Aim for an earlier bedtime tonight';
    }
    if (night.sleepScore < 80) {
      return 'Keep your bedtime consistent tonight';
    }
    return 'Protect tonight’s good routine';
  }

  // Generate simple coach message
  static String _coachMessage(SleepNight night) {
    if (night.sleepScore < 70) {
      return 'Your sleep score was lower than ideal. Prioritize an earlier bedtime and a calmer evening routine tonight.';
    }
    if (night.sleepScore < 80) {
      return 'You had a decent night. A bit more consistency and slightly longer sleep could improve recovery further.';
    }
    return 'Your recovery looks strong. Keep your bedtime consistent for the next few nights to maintain this progress.';
  }
}

class _HeroTextSection extends StatelessWidget {
  final SleepNight night;

  const _HeroTextSection({required this.night});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last Night',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          _titleFromScore(night.sleepScore),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'You slept ${night.sleepDuration} with ${night.quality.toLowerCase()} quality and HRV of ${night.hrv}.',
          style: const TextStyle(color: Colors.white70, height: 1.35),
        ),
      ],
    );
  }

  static String _titleFromScore(int score) {
    if (score >= 85) return 'Excellent Sleep';
    if (score >= 75) return 'Great Sleep';
    if (score >= 65) return 'Decent Sleep';
    return 'Needs Improvement';
  }
}


class _TopMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TopMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            textAlign: TextAlign.center),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white10,
    );
  }
}


class _HomeActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HomeActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 19, color: Colors.white70),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white70, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachMessageCard extends StatelessWidget {
  final String message;

  const _CoachMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6EE7F9), Color(0xFF7B8CFF)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70, height: 1.42),
            ),
          ),
        ],
      ),
    );
  }
}