import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'glass_card.dart';

/// Reusable metric card used on Dashboard and Sleep Detail screens.
///
/// Displays an icon badge, a title label, a prominent value,
/// and an optional subtitle line.
///
/// Usage:
///   MetricCard(
///     icon: Icons.bedtime_rounded,
///     title: 'Sleep Duration',
///     value: '7h 24m',
///     subtitle: 'Goal: 8h 0m',
///   )
class MetricCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;  // defaults to AppColors.textSecondary
  final String title;
  final String value;
  final String subtitle;

  const MetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 14),

            // Title
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 8),

            // Value
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            // Subtitle
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
