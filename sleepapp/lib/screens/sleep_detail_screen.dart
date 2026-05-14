import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/score_ring.dart';
import '../core/models/sleep_night.dart';
import '../core/utils/duration_utils.dart';

class SleepDetailsScreen extends StatelessWidget {
  final SleepNight night;

  const SleepDetailsScreen({
    super.key,
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    // Switch layout for wider screens
    final bool isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Sleep Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Make full details page scrollable
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Center(
            child: ConstrainedBox(
              // Keep layout from stretching too wide
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main summary for the selected night
                  _HeroSection(night: night),
                  const SizedBox(height: 18),

                  // Visual sleep stage distribution
                  _SleepStagesSection(night: night),
                  const SizedBox(height: 18),

                  // Different metric layout for wide vs mobile screens
                  if (isWide)
                    _MetricsSection(night: night)
                  else
                    _MetricsSectionMobile(night: night),
                  const SizedBox(height: 18),

                  // Percentage breakdown of each stage
                  _BreakdownSection(night: night),
                  const SizedBox(height: 18),

                  // Rule-based sleep feedback
                  _CoachNoteSection(night: night),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final SleepNight night;

  const _HeroSection({
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular score display
                ScoreRing(score: night.sleepScore),
                const SizedBox(width: 18),
                Expanded(child: _HeroText(night: night)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TopMetric(
                    label: 'Total Sleep',
                    value: night.sleepDuration,
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _TopMetric(
                    label: 'Deep Sleep',
                    value: night.deepSleep,
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _TopMetric(
                    label: 'HRV',
                    value: night.hrv,
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

class _HeroText extends StatelessWidget {
  final SleepNight night;

  const _HeroText({
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          night.date,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          // Convert numeric score into a readable status
          _titleFromScore(night.sleepScore),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You slept ${night.sleepDuration} with ${night.quality.toLowerCase()} quality, deep sleep of ${night.deepSleep}, and HRV of ${night.hrv}.',
          style: const TextStyle(
            color: Colors.white70,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  static String _titleFromScore(int score) {
    if (score >= 85) return 'Excellent Sleep Quality';
    if (score >= 75) return 'Strong Sleep Quality';
    if (score >= 65) return 'Decent Sleep Quality';
    return 'Sleep Needs Improvement';
  }
}

class _SleepStagesSection extends StatelessWidget {
  final SleepNight night;

  const _SleepStagesSection({
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    // Convert stage durations into minutes
    final int deepMinutes = durationToMinutes(night.deepSleep);
    final int lightMinutes = durationToMinutes(night.lightSleep);
    final int remMinutes = durationToMinutes(night.remSleep);
    final int awakeMinutes = durationToMinutes(night.awakeTime);

    // Keep flex values safe for UI rendering
    final int safeDeep = deepMinutes <= 0 ? 1 : deepMinutes;
    final int safeLight = lightMinutes <= 0 ? 1 : lightMinutes;
    final int safeRem = remMinutes <= 0 ? 1 : remMinutes;
    final int safeAwake = awakeMinutes <= 0 ? 1 : awakeMinutes;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
            const SizedBox(height: 6),
            Text(
              'A simplified view of your night on ${night.date}',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                // Bar widths are based on stage duration
                Expanded(
                  flex: safeLight,
                  child: const _StageBlock(color: Color(0xFF35D0A5)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: safeDeep,
                  child: const _StageBlock(color: Color(0xFFA98BFF)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: safeRem,
                  child: const _StageBlock(color: Color(0xFF5AA8FF)),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: safeAwake,
                  child: const _StageBlock(color: Color(0xFFFF8FA3)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _LegendDot(color: Color(0xFFFF8FA3), text: 'Awake'),
                _LegendDot(color: Color(0xFF5AA8FF), text: 'REM'),
                _LegendDot(color: Color(0xFF35D0A5), text: 'Light'),
                _LegendDot(color: Color(0xFFA98BFF), text: 'Deep'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsSection extends StatelessWidget {
  final SleepNight night;

  const _MetricsSection({
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: CupertinoIcons.heart,
                title: 'Resting HR',
                value: night.restingHR,
                subtitle: 'From Garmin data',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                icon: CupertinoIcons.moon_stars,
                title: 'Sleep Score',
                value: '${night.sleepScore}',
                subtitle: night.quality,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: CupertinoIcons.bolt_fill,
                title: 'Quality',
                value: night.quality,
                subtitle: 'Overall sleep quality',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                icon: CupertinoIcons.bed_double,
                title: 'Awake Time',
                value: night.awakeTime,
                subtitle: 'Night interruptions',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricsSectionMobile extends StatelessWidget {
  final SleepNight night;

  const _MetricsSectionMobile({
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MetricCard(
          icon: CupertinoIcons.heart,
          title: 'Resting HR',
          value: night.restingHR,
          subtitle: 'From Garmin data',
        ),
        const SizedBox(height: 12),
        MetricCard(
          icon: CupertinoIcons.moon_stars,
          title: 'Sleep Score',
          value: '${night.sleepScore}',
          subtitle: night.quality,
        ),
        const SizedBox(height: 12),
        MetricCard(
          icon: CupertinoIcons.bolt_fill,
          title: 'Quality',
          value: night.quality,
          subtitle: 'Overall sleep quality',
        ),
        const SizedBox(height: 12),
        MetricCard(
          icon: CupertinoIcons.bed_double,
          title: 'Awake Time',
          value: night.awakeTime,
          subtitle: 'Night interruptions',
        ),
      ],
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  final SleepNight night;

  const _BreakdownSection({
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    // Convert stage values to minutes for percentage calculations
    final int deepMinutes = durationToMinutes(night.deepSleep);
    final int lightMinutes = durationToMinutes(night.lightSleep);
    final int remMinutes = durationToMinutes(night.remSleep);
    final int awakeMinutes = durationToMinutes(night.awakeTime);

    final int total = deepMinutes + lightMinutes + remMinutes + awakeMinutes;

    // Percentage of each stage in the full night
    final int deepPercent =
        total == 0 ? 0 : ((deepMinutes / total) * 100).round();
    final int lightPercent =
        total == 0 ? 0 : ((lightMinutes / total) * 100).round();
    final int remPercent =
        total == 0 ? 0 : ((remMinutes / total) * 100).round();
    final int awakePercent =
        total == 0 ? 0 : ((awakeMinutes / total) * 100).round();

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stage Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _BreakdownRow(
              color: const Color(0xFFA98BFF),
              title: 'Deep Sleep',
              value: night.deepSleep,
              percentage: '$deepPercent%',
            ),
            const SizedBox(height: 10),
            _BreakdownRow(
              color: const Color(0xFF35D0A5),
              title: 'Light Sleep',
              value: night.lightSleep,
              percentage: '$lightPercent%',
            ),
            const SizedBox(height: 10),
            _BreakdownRow(
              color: const Color(0xFF5AA8FF),
              title: 'REM Sleep',
              value: night.remSleep,
              percentage: '$remPercent%',
            ),
            const SizedBox(height: 10),
            _BreakdownRow(
              color: const Color(0xFFFF8FA3),
              title: 'Awake',
              value: night.awakeTime,
              percentage: '$awakePercent%',
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachNoteSection extends StatelessWidget {
  final SleepNight night;

  const _CoachNoteSection({
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coach Note',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _CoachInsightTile(
              title: _positiveTitle(night),
              subtitle: _positiveSubtitle(night),
            ),
            const SizedBox(height: 10),
            _CoachInsightTile(
              title: _improveTitle(night),
              subtitle: _improveSubtitle(night),
            ),
          ],
        ),
      ),
    );
  }

  // Positive takeaway based on score
  static String _positiveTitle(SleepNight night) {
    if (night.sleepScore >= 80) return 'What went well';
    if (night.sleepScore >= 65) return 'What was decent';
    return 'What to keep building';
  }

  // Positive summary for the night
  static String _positiveSubtitle(SleepNight night) {
    if (night.sleepScore >= 80) {
      return 'Your sleep score was ${night.sleepScore}, which suggests a strong night overall. Deep sleep at ${night.deepSleep} helped support recovery.';
    }
    if (night.sleepScore >= 65) {
      return 'Your sleep was fair overall. You still got ${night.sleepDuration} of total sleep, which gives you a base to improve from.';
    }
    return 'Even on a weaker night, tracking your data helps identify where recovery and sleep consistency can improve.';
  }

  // Improvement heading
  static String _improveTitle(SleepNight night) {
    if (night.sleepScore >= 80) return 'What to maintain';
    return 'What to improve';
  }

  // Improvement advice based on score and duration
  static String _improveSubtitle(SleepNight night) {
    if (night.sleepScore >= 80) {
      return 'Try to protect the same routine tonight so you can keep your score and sleep quality consistently high.';
    }
    if (durationToMinutes(night.sleepDuration) < 420) {
      return 'Try to increase total sleep time tonight. Pushing your routine closer to 7–8 hours could improve recovery noticeably.';
    }
    return 'A more consistent bedtime and calmer wind-down routine could help raise your next sleep score.';
  }
}


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
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
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


class _StageBlock extends StatelessWidget {
  final Color color;

  const _StageBlock({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendDot({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final Color color;
  final String title;
  final String value;
  final String percentage;

  const _BreakdownRow({
    required this.color,
    required this.title,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            percentage,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachInsightTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CoachInsightTile({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

