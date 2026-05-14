import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds the single dark ThemeData used across the whole app.
abstract final class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      // ── Colours ─────────────────────────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        brightness:      Brightness.dark,
        primary:         AppColors.primary,
        onPrimary:       AppColors.textPrimary,
        secondary:       AppColors.accentCyan,
        onSecondary:     AppColors.textPrimary,
        surface:         AppColors.surface,
        onSurface:       AppColors.textPrimary,
        error:           AppColors.error,
        onError:         AppColors.textPrimary,
        outline:         AppColors.divider,
        surfaceContainerHighest: AppColors.surfaceAlt,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // ── Typography — Inter via google_fonts ──────────────────────────────────
      textTheme: _buildTextTheme(),
      primaryTextTheme: _buildTextTheme(),

      // ── AppBar ───────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:  AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize:   18,
          fontWeight: FontWeight.w700,
          color:      AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ── NavigationBar ────────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:     AppColors.navBar,
        surfaceTintColor:    Colors.transparent,
        shadowColor:         Colors.black54,
        elevation:           8,
        height:              64,
        indicatorColor:      AppColors.primary.withOpacity(0.18),
        indicatorShape:      const StadiumBorder(),
        labelBehavior:       NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.navUnselected,
            size:  22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize:   11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.primary : AppColors.navUnselected,
          );
        }),
      ),

      // ── Cards ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:        AppColors.surface,
        elevation:    0,
        shape:        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin:       EdgeInsets.zero,
      ),

      // ── Divider ──────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     AppColors.divider,
        thickness: 1,
        space:     1,
      ),

      // ── Chips ────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:  AppColors.surfaceAlt,
        selectedColor:    AppColors.primary.withOpacity(0.25),
        labelStyle:       GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        side:             BorderSide.none,
        shape:            const StadiumBorder(),
        padding:          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Icon ─────────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),

      // ── ProgressIndicator ────────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      // ── Snackbar ─────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme() {
    // Base everything on Inter; colour applied separately via onSurface.
    return GoogleFonts.interTextTheme(
      const TextTheme(
        // Display
        displayLarge:  TextStyle(fontSize: 57, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displaySmall:  TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        // Headline
        headlineLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineSmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        // Title
        titleLarge:  TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleSmall:  TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        // Body
        bodyLarge:   TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium:  TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        bodySmall:   TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted),
        // Label
        labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        labelSmall:  TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted),
      ),
    );
  }
}
