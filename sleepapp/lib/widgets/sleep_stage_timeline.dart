import 'package:flutter/material.dart';

class SleepStageSegment {
  final SleepStage stage;
  final double fraction; // 0..1

  const SleepStageSegment({
    required this.stage,
    required this.fraction,
  });
}

enum SleepStage { awake, rem, light, deep }

class SleepStageTimeline extends StatelessWidget {
  final List<SleepStageSegment> segments;
  final double height;

  const SleepStageTimeline({
    super.key,
    required this.segments,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SleepStageTimelinePainter(segments: segments),
      ),
    );
  }
}

class _SleepStageTimelinePainter extends CustomPainter {
  final List<SleepStageSegment> segments;

  _SleepStageTimelinePainter({required this.segments});

  Color _colorFor(SleepStage s) {
    switch (s) {
      case SleepStage.awake:
        return Colors.white54;
      case SleepStage.rem:
        return const Color(0xFF4DA3FF);
      case SleepStage.light:
        return const Color(0xFF34D399);
      case SleepStage.deep:
        return const Color(0xFFA78BFA);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    const gap = 2.0;
    final radius = Radius.circular(size.height / 2);

    double x = 0;

    final total = segments.fold<double>(0, (sum, s) => sum + s.fraction);
    final safeTotal = total == 0 ? 1.0 : total;

    for (final seg in segments) {
      final w = (seg.fraction / safeTotal) * size.width;

      final rect = Rect.fromLTWH(
        x,
        0,
        (w - gap).clamp(0, size.width),
        size.height,
      );

      paint.color = _colorFor(seg.stage);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);

      x += w;
    }
  }

  @override
  bool shouldRepaint(covariant _SleepStageTimelinePainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}