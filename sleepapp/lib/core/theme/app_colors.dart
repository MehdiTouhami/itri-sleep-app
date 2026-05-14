import 'package:flutter/material.dart';

/// Design tokens for Itri Sleep.
/// Single source of truth — reference these everywhere, never hardcode hex.
abstract final class AppColors {
  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0B1220);
  static const Color surface    = Color(0xFF121A2B);
  static const Color surfaceAlt = Color(0xFF1A2540); // slightly lifted cards

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary    = Color(0xFF3B82F6); // blue
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentBlue = Color(0xFF67D6FF);

  // ── Sleep stages ──────────────────────────────────────────────────────────
  static const Color deepSleep  = Color(0xFFA98BFF); // purple
  static const Color remSleep   = Color(0xFF5AA8FF); // blue
  static const Color lightSleep = Color(0xFF35D0A5); // teal-green
  static const Color awake      = Color(0xFFFF8FA3); // pink-red

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5); // ~60% white
  static const Color textMuted     = Color(0xFF607080); // de-emphasised

  // ── UI chrome ─────────────────────────────────────────────────────────────
  static const Color divider     = Color(0xFF1E2D45);
  static const Color cardGlass   = Color(0x14FFFFFF); // white 8 %
  static const Color navBar      = Color(0xFF0F1825); // nav background
  static const Color navSelected = primary;
  static const Color navUnselected = Color(0xFF4A5568);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);

  // ── Score gradient stops (low → high) ──────────────────────────────────────
  static const List<Color> scoreGradient = [
    Color(0xFFEF4444), // poor  < 50
    Color(0xFFF59E0B), // fair  50–65
    Color(0xFF3B82F6), // good  65–80
    Color(0xFF22C55E), // great ≥ 80
  ];

  /// Returns the appropriate score colour for a 0–100 sleep score.
  static Color forScore(int score) {
    if (score >= 80) return success;
    if (score >= 65) return primary;
    if (score >= 50) return warning;
    return error;
  }

  /// Returns the stage colour for a stage label string.
  static Color forStage(String stage) {
    switch (stage.toLowerCase()) {
      case 'deep':  return deepSleep;
      case 'rem':   return remSleep;
      case 'light': return lightSleep;
      case 'awake': return awake;
      default:      return textMuted;
    }
  }
}
