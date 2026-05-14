import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../core/constants/prefs_keys.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 1
  final _nameController = TextEditingController();

  // Step 2
  int _sleepGoalMins = 480;

  // Step 3
  TimeOfDay _bedtime  = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7,  minute: 0);

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kUserName,      _nameController.text.trim());
    await prefs.setInt(kSleepGoalMins,    _sleepGoalMins);
    await prefs.setString(kBedtimeTarget, _fmt(_bedtime));
    await prefs.setString(kWakeTime,      _fmt(_wakeTime));
    await prefs.setBool(kOnboardingDone,  true);
    if (!mounted) return;
    context.go('/home');
  }

  // "23:00" format
  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // "8h 0m" → "8h" if whole hour
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

  bool get _canProceed =>
      _currentPage == 0 ? _nameController.text.trim().isNotEmpty : true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Step indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => _StepDot(active: i == _currentPage, done: i < _currentPage),
              ),
            ),

            const SizedBox(height: 8),

            // Step label
            Text(
              'Step ${_currentPage + 1} of 3',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _NamePage(
                    controller: _nameController,
                    onChanged: () => setState(() {}),
                  ),
                  _GoalPage(
                    goalMins: _sleepGoalMins,
                    label: _fmtGoal(_sleepGoalMins),
                    onChanged: (v) => setState(() => _sleepGoalMins = v),
                  ),
                  _SchedulePage(
                    bedtime:        _fmt(_bedtime),
                    wakeTime:       _fmt(_wakeTime),
                    onBedtimeTap:   () => _pickTime(true),
                    onWakeTap:      () => _pickTime(false),
                  ),
                ],
              ),
            ),

            // CTA button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canProceed ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage == 2 ? 'Get Started' : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step dot indicator ────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  const _StepDot({required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width:  active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active || done ? AppColors.primary : AppColors.divider,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ─── Page 1: Name ─────────────────────────────────────────────────────────────

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _NamePage({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageIcon(icon: Icons.waving_hand_rounded, color: AppColors.accentCyan),
          const SizedBox(height: 28),
          Text(
            "What's your name?",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your sleep coach will use this to personalise your experience.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 36),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 2: Sleep goal slider ────────────────────────────────────────────────

class _GoalPage extends StatelessWidget {
  final int goalMins;
  final String label;
  final ValueChanged<int> onChanged;
  const _GoalPage({required this.goalMins, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageIcon(icon: Icons.bedtime_rounded, color: AppColors.deepSleep),
          const SizedBox(height: 28),
          Text(
            'How much sleep do you need?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adults typically need 7–9 hours. Set your personal target.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 48),

          // Big goal label
          Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -1,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // Slider — 6h to 10h in 15-min steps
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.15),
              trackHeight: 4,
            ),
            child: Slider(
              min: 360,
              max: 600,
              divisions: 16, // 15-min steps
              value: goalMins.toDouble(),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),

          // Min / max labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('6h', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted)),
              Text('10h', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Page 3: Bedtime + wake time ──────────────────────────────────────────────

class _SchedulePage extends StatelessWidget {
  final String bedtime;
  final String wakeTime;
  final VoidCallback onBedtimeTap;
  final VoidCallback onWakeTap;

  const _SchedulePage({
    required this.bedtime,
    required this.wakeTime,
    required this.onBedtimeTap,
    required this.onWakeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageIcon(icon: Icons.schedule_rounded, color: AppColors.accentCyan),
          const SizedBox(height: 28),
          Text(
            'Set your sleep schedule',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'A consistent schedule is the most effective way to improve sleep quality.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 36),

          _TimeRow(
            icon: Icons.bedtime_rounded,
            iconColor: AppColors.deepSleep,
            label: 'Bedtime',
            value: bedtime,
            onTap: onBedtimeTap,
          ),
          const SizedBox(height: 16),
          _TimeRow(
            icon: Icons.wb_sunny_rounded,
            iconColor: AppColors.accentCyan,
            label: 'Wake time',
            value: wakeTime,
            onTap: onWakeTap,
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Shared page icon ─────────────────────────────────────────────────────────

class _PageIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _PageIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
