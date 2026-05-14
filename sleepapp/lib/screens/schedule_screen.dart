import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/sleep_provider.dart';
import '../core/providers/goals_provider.dart';
import '../core/theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../core/models/sleep_night.dart';
import '../core/utils/duration_utils.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    return ref.watch(sleepDataProvider).when(
      loading: () => const SafeArea(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading schedule data:\n$e', textAlign: TextAlign.center),
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

        final latest = nights.first;
        final consistency = _calculateConsistency(nights);
        final averageSleepMinutes = _averageSleepMinutes(nights);
        final goalMins = goals.sleepGoalMins;

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 700;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sleep Schedule',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Plan your bedtime, wake-up time, and weekly routine',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),

                        GlassCard(
                          padding: const EdgeInsets.all(0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF52E5E7),
                                            Color(0xFF6C8CFF),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.moon_fill,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Tonight's Plan",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white70,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _scheduleHeadline(latest, averageSleepMinutes),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _scheduleDescription(latest, consistency),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 18),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _PlanMetric(
                                        label: 'Last Sleep',
                                        value: latest.sleepDuration,
                                      ),
                                    ),
                                    Expanded(
                                      child: _PlanMetric(
                                        label: 'Quality',
                                        value: latest.quality,
                                      ),
                                    ),
                                    Expanded(
                                      child: _PlanMetric(
                                        label: 'Target',
                                        value: minutesToDuration(goalMins),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF5B9CFF),
                                          Color(0xFF3B82F6),
                                        ],
                                      ),
                                    ),
                                    child: TextButton(
                                      onPressed: () => _showEditSheet(context, ref, goals),
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text(
                                        'Add / Edit Schedule',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        const _SectionTitle(
                          title: 'Tonight Routine',
                          subtitle:
                              'Small habits that help you hit your target sleep window',
                        ),
                        const SizedBox(height: 10),

                        _RoutineCard(
                          icon: CupertinoIcons.flame,
                          title: _routineTitle1(latest),
                          subtitle: _routineSubtitle1(latest),
                        ),
                        const SizedBox(height: 10),
                        _RoutineCard(
                          icon: CupertinoIcons.speedometer,
                          title: _routineTitle2(latest),
                          subtitle: _routineSubtitle2(latest),
                        ),
                        const SizedBox(height: 10),
                        const _RoutineCard(
                          icon: CupertinoIcons.device_phone_portrait,
                          title: 'Reduce screen exposure',
                          subtitle:
                              'Dim screens and start winding down 30 minutes before bed.',
                        ),

                        const SizedBox(height: 18),

                        const _SectionTitle(
                          title: 'Weekly Plan',
                          subtitle: 'Keep a similar sleep schedule across the week',
                        ),
                        const SizedBox(height: 10),

                        _WeekRow(
                          day: 'Monday',
                          start: _plannedBedtime(goals.bedtime, 0),
                          end: _plannedWake(goals.wakeTime, 0),
                          highlighted: true,
                        ),
                        const SizedBox(height: 10),
                        _WeekRow(
                          day: 'Tuesday',
                          start: _plannedBedtime(goals.bedtime, -15),
                          end: _plannedWake(goals.wakeTime, 0),
                        ),
                        const SizedBox(height: 10),
                        _WeekRow(
                          day: 'Wednesday',
                          start: _plannedBedtime(goals.bedtime, 0),
                          end: _plannedWake(goals.wakeTime, 0),
                        ),
                        const SizedBox(height: 10),
                        _WeekRow(
                          day: 'Thursday',
                          start: _plannedBedtime(goals.bedtime, -10),
                          end: _plannedWake(goals.wakeTime, 0),
                        ),
                        const SizedBox(height: 10),
                        _WeekRow(
                          day: 'Friday',
                          start: _plannedBedtime(goals.bedtime, 15),
                          end: _plannedWake(goals.wakeTime, 20),
                        ),
                        const SizedBox(height: 10),
                        _WeekRow(
                          day: 'Saturday',
                          start: _plannedBedtime(goals.bedtime, 30),
                          end: _plannedWake(goals.wakeTime, 45),
                        ),
                        const SizedBox(height: 10),
                        _WeekRow(
                          day: 'Sunday',
                          start: _plannedBedtime(goals.bedtime, 0),
                          end: _plannedWake(goals.wakeTime, 0),
                        ),

                        const SizedBox(height: 18),

                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _MiniStatCard(
                                  icon: CupertinoIcons.wand_stars,
                                  title: 'Consistency',
                                  value: '$consistency%',
                                  subtitle: consistency >= 75
                                      ? 'Better than your weaker nights'
                                      : 'Needs a steadier routine',
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _MiniStatCard(
                                  icon: CupertinoIcons.clock,
                                  title: 'Sleep Goal',
                                  value: minutesToDuration(goalMins),
                                  subtitle: 'Your personal target',
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _MiniStatCard(
                                icon: CupertinoIcons.wand_stars,
                                title: 'Consistency',
                                value: '$consistency%',
                                subtitle: consistency >= 75
                                    ? 'Better than your weaker nights'
                                    : 'Needs a steadier routine',
                              ),
                              const SizedBox(height: 12),
                              _MiniStatCard(
                                icon: CupertinoIcons.clock,
                                title: 'Sleep Goal',
                                value: minutesToDuration(goalMins),
                                subtitle: 'Your personal target',
                              ),
                            ],
                          ),

                        const SizedBox(height: 18),

                        const _SectionTitle(
                          title: 'Coach Tips',
                          subtitle:
                              'Suggestions based on your routine and sleep trends',
                        ),
                        const SizedBox(height: 10),

                        _TipCard(
                          title: _coachTipTitle1(consistency),
                          subtitle: _coachTipSubtitle1(consistency),
                        ),
                        const SizedBox(height: 12),
                        _TipCard(
                          title: _coachTipTitle2(averageSleepMinutes),
                          subtitle: _coachTipSubtitle2(averageSleepMinutes),
                        ),
                        const SizedBox(height: 12),
                        _TipCard(
                          title: _coachTipTitle3(latest),
                          subtitle: _coachTipSubtitle3(latest),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static int _averageSleepMinutes(List<SleepNight> nights) {
    if (nights.isEmpty) return 0;
    final total = nights.fold<int>(
      0,
      (sum, n) => sum + durationToMinutes(n.sleepDuration),
    );
    return (total / nights.length).round();
  }

  static int _calculateConsistency(List<SleepNight> nights) {
    if (nights.isEmpty) return 0;
    final scores = nights.map((e) => e.sleepScore).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final spread = scores
            .map((s) => (s - avg).abs())
            .fold<double>(0, (a, b) => a + b) /
        scores.length;

    final value = (100 - (spread * 3)).round();
    return value.clamp(45, 95);
  }

  static String _scheduleHeadline(SleepNight latest, int averageSleepMinutes) {
    if (averageSleepMinutes < 420) {
      return 'Protect an earlier sleep window tonight';
    }
    if (latest.sleepScore >= 80) {
      return 'Keep tonight aligned with your strong sleep pattern';
    }
    return 'Stabilize tonight’s routine for better recovery';
  }

  static String _scheduleDescription(SleepNight latest, int consistency) {
    return 'Your latest sleep was ${latest.sleepDuration} with ${latest.quality.toLowerCase()} quality. Consistency is currently around $consistency%, so a steady schedule will help.';
  }

  static String _routineTitle1(SleepNight latest) {
    if (durationToMinutes(latest.sleepDuration) < 420) {
      return 'Prioritize a bigger sleep opportunity';
    }
    return 'Finish eating earlier';
  }

  static String _routineSubtitle1(SleepNight latest) {
    if (durationToMinutes(latest.sleepDuration) < 420) {
      return 'Your recent sleep duration is a bit low. Finishing dinner earlier can help you get to bed sooner.';
    }
    return 'Try to finish your last meal 2–3 hours before bed.';
  }

  static String _routineTitle2(SleepNight latest) {
    if (latest.sleepScore < 70) {
      return 'Keep tonight lighter';
    }
    return 'Lower evening intensity';
  }

  static String _routineSubtitle2(SleepNight latest) {
    if (latest.sleepScore < 70) {
      return 'Your latest sleep score was lower, so reducing evening load may help recovery tonight.';
    }
    return 'Avoid hard late sessions when possible for better recovery.';
  }

  static String _coachTipTitle1(int consistency) {
    if (consistency >= 80) return 'Keep your current rhythm stable';
    if (consistency >= 65) return 'Aim for a more stable bedtime';
    return 'Reduce schedule variation this week';
  }

  static String _coachTipSubtitle1(int consistency) {
    if (consistency >= 80) {
      return 'Your recent nights are relatively consistent. Try to keep bedtime and wake-up time within a small range.';
    }
    if (consistency >= 65) {
      return 'Keeping bedtime within a 30-minute range could noticeably improve consistency.';
    }
    return 'Your pattern varies more than ideal. Tightening your schedule should help your recovery.';
  }

  static String _coachTipTitle2(int averageSleepMinutes) {
    if (averageSleepMinutes < 420) return 'Increase total sleep time';
    if (averageSleepMinutes < 480) return 'Protect your sleep duration';
    return 'Maintain your sleep duration';
  }

  static String _coachTipSubtitle2(int averageSleepMinutes) {
    if (averageSleepMinutes < 420) {
      return 'Your average sleep is below 7 hours. Extending your sleep window would likely improve next-day recovery.';
    }
    if (averageSleepMinutes < 480) {
      return 'You are close to a strong range. An extra 20–30 minutes could make a difference.';
    }
    return 'Your current average sleep duration is solid. Focus on consistency to keep it there.';
  }

  static String _coachTipTitle3(SleepNight latest) {
    if (latest.sleepScore >= 80) return 'Use your schedule as recovery support';
    return 'Protect your wake-up time';
  }

  static String _coachTipSubtitle3(SleepNight latest) {
    if (latest.sleepScore >= 80) {
      return 'On heavier training days, plan bedtime earlier so you keep supporting recovery with strong sleep.';
    }
    return 'A stable wake-up time improves sleep rhythm more than only sleeping earlier sometimes.';
  }

  // Parse "HH:MM" goal string, apply offset in minutes
  static String _plannedBedtime(String goalBedtime, int offsetMins) {
    final parts = goalBedtime.split(':');
    final base = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    return _formatClock(base + offsetMins);
  }

  static String _plannedWake(String goalWakeTime, int offsetMins) {
    final parts = goalWakeTime.split(':');
    final base = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    return _formatClock(base + offsetMins);
  }

  static String _formatClock(int totalMinutes) {
    int minutes = totalMinutes % (24 * 60);
    if (minutes < 0) minutes += 24 * 60;

    final hour = minutes ~/ 60;
    final min = minutes % 60;

    final hh = hour.toString().padLeft(2, '0');
    final mm = min.toString().padLeft(2, '0');

    return '$hh:$mm';
  }

  static void _showEditSheet(BuildContext context, WidgetRef ref, UserGoals goals) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditGoalsSheet(goals: goals, ref: ref),
    );
  }

}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _PlanMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PlanMetric({
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
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RoutineCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final String day;
  final String start;
  final String end;
  final bool highlighted;

  const _WeekRow({
    required this.day,
    required this.start,
    required this.end,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF5AD7FF).withOpacity(0.45)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              if (highlighted) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7AE7FF),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _TimeChip(text: start),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  CupertinoIcons.arrow_right,
                  size: 16,
                  color: Colors.white54,
                ),
              ),
              _TimeChip(text: end),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String text;

  const _TimeChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _MiniStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: SizedBox(
        height: 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.white60,
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TipCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 1,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Edit Goals Bottom Sheet ──────────────────────────────────────────────────

class _EditGoalsSheet extends StatefulWidget {
  final UserGoals goals;
  final WidgetRef ref;
  const _EditGoalsSheet({required this.goals, required this.ref});

  @override
  State<_EditGoalsSheet> createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends State<_EditGoalsSheet> {
  late int _goalMins;
  late TimeOfDay _bedtime;
  late TimeOfDay _wakeTime;

  @override
  void initState() {
    super.initState();
    _goalMins = widget.goals.sleepGoalMins;
    _bedtime  = _parseTime(widget.goals.bedtime);
    _wakeTime = _parseTime(widget.goals.wakeTime);
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtGoal(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  Future<void> _pickTime(bool isBedtime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBedtime ? _bedtime : _wakeTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isBedtime) _bedtime = picked;
      else _wakeTime = picked;
    });
  }

  Future<void> _save() async {
    await widget.ref.read(goalsProvider.notifier).update(
      sleepGoalMins: _goalMins,
      bedtime:       _fmt(_bedtime),
      wakeTime:      _fmt(_wakeTime),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 32 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Edit Goals',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),

          // Sleep goal slider
          Text('Sleep Goal', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.divider,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    min: 360, max: 600, divisions: 16,
                    value: _goalMins.toDouble(),
                    onChanged: (v) => setState(() => _goalMins = v.round()),
                  ),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  _fmtGoal(_goalMins),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bedtime
          _SheetTimeRow(
            icon: Icons.bedtime_rounded,
            iconColor: AppColors.deepSleep,
            label: 'Bedtime',
            value: _fmt(_bedtime),
            onTap: () => _pickTime(true),
          ),
          const SizedBox(height: 12),

          // Wake time
          _SheetTimeRow(
            icon: Icons.wb_sunny_rounded,
            iconColor: AppColors.accentCyan,
            label: 'Wake time',
            value: _fmt(_wakeTime),
            onTap: () => _pickTime(false),
          ),
          const SizedBox(height: 28),

          // Save
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Save Goals',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTimeRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SheetTimeRow({
    required this.icon, required this.iconColor,
    required this.label, required this.value, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}
