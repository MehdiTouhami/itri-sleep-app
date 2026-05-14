import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/prefs_keys.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class UserGoals {
  final String name;
  final int    sleepGoalMins; // e.g. 480 = 8h
  final String bedtime;       // "23:00"
  final String wakeTime;      // "07:00"

  const UserGoals({
    this.name          = '',
    this.sleepGoalMins = 480,
    this.bedtime       = '23:00',
    this.wakeTime      = '07:00',
  });

  UserGoals copyWith({String? name, int? sleepGoalMins, String? bedtime, String? wakeTime}) =>
      UserGoals(
        name:          name          ?? this.name,
        sleepGoalMins: sleepGoalMins ?? this.sleepGoalMins,
        bedtime:       bedtime       ?? this.bedtime,
        wakeTime:      wakeTime      ?? this.wakeTime,
      );

  // Initials for avatar badge — e.g. "Mehdi Touhami" → "MT"
  String get initials {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class GoalsNotifier extends StateNotifier<UserGoals> {
  GoalsNotifier() : super(const UserGoals()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = UserGoals(
      name:          prefs.getString(kUserName)        ?? '',
      sleepGoalMins: prefs.getInt(kSleepGoalMins)      ?? 480,
      bedtime:       prefs.getString(kBedtimeTarget)   ?? '23:00',
      wakeTime:      prefs.getString(kWakeTime)        ?? '07:00',
    );
  }

  Future<void> update({String? name, int? sleepGoalMins, String? bedtime, String? wakeTime}) async {
    state = state.copyWith(
      name:          name,
      sleepGoalMins: sleepGoalMins,
      bedtime:       bedtime,
      wakeTime:      wakeTime,
    );
    final prefs = await SharedPreferences.getInstance();
    if (name          != null) await prefs.setString(kUserName,      name);
    if (sleepGoalMins != null) await prefs.setInt(kSleepGoalMins,    sleepGoalMins);
    if (bedtime       != null) await prefs.setString(kBedtimeTarget, bedtime);
    if (wakeTime      != null) await prefs.setString(kWakeTime,      wakeTime);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, UserGoals>((ref) => GoalsNotifier());
