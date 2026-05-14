import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Reusable circular sleep score ring.
///
/// Used on Dashboard, Sleep Detail, and Insights screens.
/// The ring colour reflects score quality via [AppColors.forScore].
///
/// Usage:
///   ScoreRing(score: 78)                        // 84px, shows "Score" label
///   ScoreRing(score: 78, size: 76, showLabel: false)  // compact, no label
class ScoreRing extends StatelessWidget {
  final int score;
  final double size;
  final double strokeWidth;

  /// Whether to show the "Score" caption below the number.
  final bool showLabel;

  const ScoreRing({
    super.key,
    required this.score,
    this.size = 84,
    this.strokeWidth = 7,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final colour = AppColors.forScore(score);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score.clamp(0, 100) / 100,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(colour),
            ),
          ),

          // Inner label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              if (showLabel) ...[
                const SizedBox(height: 2),
                Text(
                  'Score',
                  style: TextStyle(
                    fontSize: size * 0.13,
                    color: AppColors.textSecondary,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
