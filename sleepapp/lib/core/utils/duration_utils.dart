/// Shared helpers for converting between Garmin duration strings and minutes.
///
/// Garmin exports durations as "7h 30m", "45m", or "8h 0m".
/// These two functions are the single source of truth — import this file
/// instead of copying the logic into each screen.

/// Parses "7h 30m" → 450 (total minutes). Returns 0 on bad input.
int durationToMinutes(String value) {
  final match = RegExp(r'(?:(\d+)h)?\s*(?:(\d+)m)?').firstMatch(value.trim());
  if (match == null) return 0;
  final hours   = int.tryParse(match.group(1) ?? '0') ?? 0;
  final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
  return hours * 60 + minutes;
}

/// Converts 450 → "7h 30m". Handles 0m edge case cleanly.
String minutesToDuration(int minutes) {
  if (minutes <= 0) return '0m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}
