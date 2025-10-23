import 'package:flutter/material.dart';

class DonutChartPainter extends CustomPainter {
  final Map<String, dynamic>? breakdown;
  final int? selectedSegment;
  final Function(int segmentIndex)? onSegmentTap;

  DonutChartPainter({
    this.breakdown,
    this.selectedSegment,
    this.onSegmentTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Get percentages from breakdown data
    final morningPct = _getPercentage('morning');
    final middayPct = _getPercentage('midday');
    final eveningPct = _getPercentage('evening');

    // Morning segment - highlight when selected
    final morningPaint = Paint()
      ..color = selectedSegment == 0 ? const Color(0xFF0F172A) : const Color(0xFF1E3A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selectedSegment == 0 ? 16 : 12;

    // Midday segment - highlight when selected
    final middayPaint = Paint()
      ..color = selectedSegment == 1 ? const Color(0xFF1D4ED8) : const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selectedSegment == 1 ? 16 : 12;

    // Evening segment - highlight when selected
    final eveningPaint = Paint()
      ..color = selectedSegment == 2 ? const Color(0xFF60A5FA) : const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selectedSegment == 2 ? 16 : 12;

    // Draw segments
    double startAngle = -90 * (3.14159 / 180); // Start from top

    // Morning segment
    if (morningPct > 0) {
      final morningAngle = (morningPct / 100) * 2 * 3.14159;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        morningAngle,
        false,
        morningPaint,
      );
      startAngle += morningAngle;
    }

    // Midday segment
    if (middayPct > 0) {
      final middayAngle = (middayPct / 100) * 2 * 3.14159;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        middayAngle,
        false,
        middayPaint,
      );
      startAngle += middayAngle;
    }

    // Evening segment
    if (eveningPct > 0) {
      final eveningAngle = (eveningPct / 100) * 2 * 3.14159;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        eveningAngle,
        false,
        eveningPaint,
      );
    }
  }

  double _getPercentage(String period) {
    if (breakdown == null) return 0.0;
    final periodData = breakdown![period] as Map<String, dynamic>?;
    return (periodData?['percentage'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
