import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/goals_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/duration_utils.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            color: AppColors.textSecondary,
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Avatar + name
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        goals.initials,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      goals.name.isEmpty ? 'Your Name' : goals.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sleep Tracker',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Goals section
              _SectionLabel(label: 'MY GOALS'),
              const SizedBox(height: 12),

              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _GoalRow(
                      icon: Icons.bedtime_rounded,
                      iconColor: AppColors.deepSleep,
                      label: 'Sleep Goal',
                      value: minutesToDuration(goals.sleepGoalMins),
                    ),
                    _Divider(),
                    _GoalRow(
                      icon: Icons.nightlight_round,
                      iconColor: AppColors.remSleep,
                      label: 'Bedtime',
                      value: goals.bedtime,
                    ),
                    _Divider(),
                    _GoalRow(
                      icon: Icons.wb_sunny_rounded,
                      iconColor: AppColors.accentCyan,
                      label: 'Wake Time',
                      value: goals.wakeTime,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Edit goals button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showEditSheet(context, ref, goals),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Goals'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, UserGoals goals) {
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

// ─── Goal row ─────────────────────────────────────────────────────────────────

class _GoalRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _GoalRow({required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.divider, height: 1, indent: 16, endIndent: 16);
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
      );
}

// ─── Edit Goals Bottom Sheet (reused from schedule) ───────────────────────────

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
    _bedtime  = _parse(widget.goals.bedtime);
    _wakeTime = _parse(widget.goals.wakeTime);
  }

  TimeOfDay _parse(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtGoal(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    return min == 0 ? '${h}h' : '${h}h ${min}m';
  }

  Future<void> _pick(bool isBedtime) async {
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
          Text('Edit Goals', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),

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

          _TimeRow(icon: Icons.bedtime_rounded,  iconColor: AppColors.deepSleep,  label: 'Bedtime',   value: _fmt(_bedtime),  onTap: () => _pick(true)),
          const SizedBox(height: 12),
          _TimeRow(icon: Icons.wb_sunny_rounded, iconColor: AppColors.accentCyan, label: 'Wake time', value: _fmt(_wakeTime), onTap: () => _pick(false)),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save Goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;
  final VoidCallback onTap;
  const _TimeRow({required this.icon, required this.iconColor, required this.label, required this.value, required this.onTap});

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
