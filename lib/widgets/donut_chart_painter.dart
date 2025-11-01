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
    
    // Check if all segments are 0 (no data)
    final hasData = morningPct > 0 || middayPct > 0 || eveningPct > 0;

    // Morning segment - highlight when selected or gray when no data
    final morningPaint = Paint()
      ..color = !hasData 
          ? Colors.grey.shade300
          : selectedSegment == 0 ? const Color(0xFF0F172A) : const Color(0xFF1E3A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selectedSegment == 0 ? 16 : 12;

    // Midday segment - highlight when selected or gray when no data
    final middayPaint = Paint()
      ..color = !hasData 
          ? Colors.grey.shade300
          : selectedSegment == 1 ? const Color(0xFF1D4ED8) : const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selectedSegment == 1 ? 16 : 12;

    // Evening segment - highlight when selected or gray when no data
    final eveningPaint = Paint()
      ..color = !hasData 
          ? Colors.grey.shade300
          : selectedSegment == 2 ? const Color(0xFF60A5FA) : const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selectedSegment == 2 ? 16 : 12;

    // Draw segments
    double startAngle = -90 * (3.14159 / 180); // Start from top

    if (!hasData) {
      // When no data, show equal segments in gray
      final segmentAngle = (2 * 3.14159) / 3; // 120 degrees each
      
      // Morning segment (gray)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        false,
        morningPaint,
      );
      startAngle += segmentAngle;
      
      // Midday segment (gray)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        false,
        middayPaint,
      );
      startAngle += segmentAngle;
      
      // Evening segment (gray)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        false,
        eveningPaint,
      );
    } else {
      // Normal data display
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
  }

  double _getPercentage(String period) {
    if (breakdown == null) return 0.0;
    final periodData = breakdown![period] as Map<String, dynamic>?;
    return (periodData?['percentage'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
