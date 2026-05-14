import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/sleep_night.dart';
import '../core/providers/sleep_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/duration_utils.dart';
import '../widgets/glass_card.dart';
import '../widgets/score_ring.dart';
import 'sleep_detail_screen.dart';

// ─── Data model for one calendar week ────────────────────────────────────────

class _WeekData {
  final String label;       // "12–18 May"
  final DateTime weekStart;
  final List<SleepNight> nights;

  _WeekData({
    required this.label,
    required this.weekStart,
    required this.nights,
  });

  int get avgScore {
    if (nights.isEmpty) return 0;
    return (nights.map((n) => n.sleepScore).reduce((a, b) => a + b) /
            nights.length)
        .round();
  }

  int get avgDurationMinutes {
    if (nights.isEmpty) return 0;
    return (nights
                .map((n) => durationToMinutes(n.sleepDuration))
                .reduce((a, b) => a + b) /
            nights.length)
        .round();
  }

  String get avgDurationLabel => minutesToDuration(avgDurationMinutes);

  int get bestScore => nights.map((n) => n.sleepScore).reduce((a, b) => a > b ? a : b);
  int get worstScore => nights.map((n) => n.sleepScore).reduce((a, b) => a < b ? a : b);
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

DateTime? _parseDate(String s) {
  try {
    final parts = s.split('/');
    if (parts.length < 3) return null;
    final m = int.parse(parts[0]);
    final d = int.parse(parts[1]);
    final y = 2000 + int.parse(parts[2]);
    return DateTime(y, m, d);
  } catch (_) {
    return null;
  }
}

// Monday of the week containing [dt]
DateTime _weekStart(DateTime dt) {
  return dt.subtract(Duration(days: dt.weekday - 1));
}

String _weekLabel(DateTime start) {
  final end = start.add(const Duration(days: 6));
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (start.month == end.month) {
    return '${start.day}–${end.day} ${months[start.month]}';
  }
  return '${start.day} ${months[start.month]} – ${end.day} ${months[end.month]}';
}

// Group nights by week, return sorted newest-first
List<_WeekData> _groupByWeek(List<SleepNight> nights) {
  final Map<DateTime, List<SleepNight>> map = {};

  for (final night in nights) {
    final dt = _parseDate(night.date);
    if (dt == null) continue;
    // Skip watch-error nights (< 60 min)
    if (durationToMinutes(night.sleepDuration) < 60) continue;
    final ws = _weekStart(dt);
    map.putIfAbsent(ws, () => []).add(night);
  }

  final weeks = map.entries
      .map((e) => _WeekData(
            label: _weekLabel(e.key),
            weekStart: e.key,
            nights: e.value
              ..sort((a, b) {
                final da = _parseDate(a.date);
                final db = _parseDate(b.date);
                if (da == null || db == null) return 0;
                return da.compareTo(db); // oldest → newest within week
              }),
          ))
      .toList()
    ..sort((a, b) => b.weekStart.compareTo(a.weekStart)); // newest week first

  return weeks;
}

// Best day-of-week across all nights (0=Mon … 6=Sun)
String _bestDayLabel(List<SleepNight> nights) {
  final Map<int, List<int>> byDow = {};
  for (final n in nights) {
    final dt = _parseDate(n.date);
    if (dt == null) continue;
    final dow = dt.weekday - 1; // 0=Mon
    byDow.putIfAbsent(dow, () => []).add(n.sleepScore);
  }
  if (byDow.isEmpty) return '–';
  final avgs = byDow.map((dow, scores) =>
      MapEntry(dow, scores.reduce((a, b) => a + b) / scores.length));
  final best = avgs.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return days[best];
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  // Tracks which week index is expanded
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ref.watch(sleepDataProvider).when(
      loading: () => const SafeArea(
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SafeArea(
        child: Center(
          child: Text('Error loading trends:\n$e', textAlign: TextAlign.center),
        ),
      ),
      data: (nights) {
        if (nights.isEmpty) {
          return const SafeArea(
              child: Center(child: Text('No sleep data found')));
        }

        final weeks = _groupByWeek(nights);
        final bestDay = _bestDayLabel(nights);
        // Last 12 weeks for the chart (reversed = oldest→newest for chart)
        final chartWeeks = weeks.take(12).toList().reversed.toList();

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Text('Trends',
                        style: textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      '${weeks.length} weeks of sleep data · ${nights.length} nights',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),

                    // ── Weekly score line chart ──
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Weekly Average Score',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            const Text('Last 12 weeks — tap a week below to explore',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 13)),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 180,
                              child: _WeeklyLineChart(weeks: chartWeeks),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Best day stat ──
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.star_rounded,
                                  color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Your best sleep day',
                                      style: TextStyle(
                                          color: Colors.white60, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(bestDay,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                            const Text('on average',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Week-by-week list ──
                    const Text('Week by Week',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Tap any week to see individual nights',
                        style:
                            TextStyle(color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 14),

                    ...List.generate(weeks.length, (i) {
                      final week = weeks[i];
                      final isExpanded = _expanded.contains(i);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _WeekCard(
                          week: week,
                          isExpanded: isExpanded,
                          onTap: () => setState(() {
                            if (isExpanded) {
                              _expanded.remove(i);
                            } else {
                              _expanded.add(i);
                            }
                          }),
                          onNightTap: (night) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SleepDetailsScreen(night: night),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Line chart (12 weeks) ────────────────────────────────────────────────────

class _WeeklyLineChart extends StatelessWidget {
  final List<_WeekData> weeks; // oldest → newest

  const _WeeklyLineChart({required this.weeks});

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) return const SizedBox.shrink();

    final spots = List.generate(
      weeks.length,
      (i) => FlSpot(i.toDouble(), weeks[i].avgScore.toDouble()),
    );

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= weeks.length) return const SizedBox.shrink();
                // Show abbreviated label every 2 weeks to avoid clutter
                if (weeks.length > 6 && i % 2 != 0) return const SizedBox.shrink();
                final parts = weeks[i].label.split(' ');
                final short = parts.length >= 2 ? parts.last : weeks[i].label;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(short,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 9)),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3.5,
                color: AppColors.primary,
                strokeWidth: 2,
                strokeColor: AppColors.background,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.spotIndex;
              final week = weeks[i];
              return LineTooltipItem(
                '${week.label}\nAvg: ${week.avgScore}',
                const TextStyle(
                    color: Colors.white, fontSize: 11, height: 1.5),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Week card (collapsible) ──────────────────────────────────────────────────

class _WeekCard extends StatelessWidget {
  final _WeekData week;
  final bool isExpanded;
  final VoidCallback onTap;
  final ValueChanged<SleepNight> onNightTap;

  const _WeekCard({
    required this.week,
    required this.isExpanded,
    required this.onTap,
    required this.onNightTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          // ── Week summary row (always visible) ──
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Score ring
                  ScoreRing(
                      score: week.avgScore,
                      size: 52,
                      strokeWidth: 4,
                      showLabel: false),
                  const SizedBox(width: 14),
                  // Week info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          week.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${week.nights.length} nights · avg ${week.avgDurationLabel}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _ScorePill(
                                label: '↑ ${week.bestScore}',
                                color: AppColors.lightSleep),
                            const SizedBox(width: 6),
                            _ScorePill(
                                label: '↓ ${week.worstScore}',
                                color: AppColors.awake),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Avg score + chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${week.avgScore}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forScore(week.avgScore),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded: individual nights ──
          if (isExpanded) ...[
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: week.nights.reversed // newest first
                    .map((night) => _NightRow(
                          night: night,
                          onTap: () => onNightTap(night),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Individual night row inside expanded week ────────────────────────────────

class _NightRow extends StatelessWidget {
  final SleepNight night;
  final VoidCallback onTap;

  const _NightRow({required this.night, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Score colour dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.forScore(night.sleepScore),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Date
            SizedBox(
              width: 70,
              child: Text(
                night.date,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
            // Duration
            Expanded(
              child: Text(
                night.sleepDuration,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13),
              ),
            ),
            // Quality badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _qualityColor(night.quality).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                night.quality,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _qualityColor(night.quality)),
              ),
            ),
            const SizedBox(width: 10),
            // Score
            Text(
              '${night.sleepScore}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.forScore(night.sleepScore),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  Color _qualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'good': return AppColors.lightSleep;
      case 'poor': return AppColors.awake;
      default:     return AppColors.accentCyan;
    }
  }
}

// ─── Small score pill ─────────────────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  final String label;
  final Color color;

  const _ScorePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
