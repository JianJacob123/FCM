import 'package:flutter/material.dart';
import 'donut_chart_painter.dart';

class InteractiveDonutChart extends StatefulWidget {
  final Map<String, dynamic>? breakdown;
  final Function(String period, double percentage, int count)? onSegmentTap;

  const InteractiveDonutChart({
    Key? key,
    this.breakdown,
    this.onSegmentTap,
  }) : super(key: key);

  @override
  State<InteractiveDonutChart> createState() => _InteractiveDonutChartState();
}

class _InteractiveDonutChartState extends State<InteractiveDonutChart> {
  int? _selectedSegment;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final center = Offset(box.size.width / 2, box.size.height / 2);
        final radius = box.size.width / 2 - 10;
        
        // Calculate distance from center
        final distance = (localPosition - center).distance;
        
        // Check if tap is within the donut chart area
        print('Tap detected: distance=$distance, radius=$radius, within range: ${distance >= radius - 20 && distance <= radius + 20}');
        
        if (distance >= radius - 20 && distance <= radius + 20) {
          // Calculate angle from center (start from top, clockwise)
          final angle = (localPosition - center).direction;
          // Convert to 0-2π range starting from top (-π/2)
          final normalizedAngle = (angle + 3.14159/2 + 2 * 3.14159) % (2 * 3.14159);
          
          // Determine which segment was tapped
          final morningPct = _getPercentage('morning');
          final middayPct = _getPercentage('midday');
          final eveningPct = _getPercentage('evening');
          
          print('Segment percentages: morning=$morningPct, midday=$middayPct, evening=$eveningPct');
          print('Normalized angle: $normalizedAngle');
          
          double currentAngle = 0;
          int segmentIndex = -1;
          
          // Check morning segment (0)
          if (morningPct > 0) {
            final morningAngle = (morningPct / 100) * 2 * 3.14159;
            if (normalizedAngle >= currentAngle && normalizedAngle < currentAngle + morningAngle) {
              segmentIndex = 0;
            }
            currentAngle += morningAngle;
          }
          
          // Check midday segment (1)
          if (middayPct > 0 && segmentIndex == -1) {
            final middayAngle = (middayPct / 100) * 2 * 3.14159;
            if (normalizedAngle >= currentAngle && normalizedAngle < currentAngle + middayAngle) {
              segmentIndex = 1;
            }
            currentAngle += middayAngle;
          }
          
          // Check evening segment (2)
          if (eveningPct > 0 && segmentIndex == -1) {
            final eveningAngle = (eveningPct / 100) * 2 * 3.14159;
            if (normalizedAngle >= currentAngle && normalizedAngle < currentAngle + eveningAngle) {
              segmentIndex = 2;
            }
          }
            
          print('Detected segment index: $segmentIndex');
          if (segmentIndex != -1) {
            setState(() {
              _selectedSegment = segmentIndex; // Always select the clicked segment
            });
            
            // Call the callback with segment info
            if (widget.onSegmentTap != null) {
              final periods = ['morning', 'midday', 'evening'];
              final period = periods[segmentIndex];
              final percentage = _getPercentage(period);
              final count = _getCount(period);
              print('Calling callback: period=$period, percentage=$percentage, count=$count');
              widget.onSegmentTap!(period, percentage, count);
            }
          } else {
            print('No segment detected for this tap - clicking outside donut');
            setState(() {
              _selectedSegment = null; // Clear selection when clicking outside
            });
            // Call callback to clear tooltip
            if (widget.onSegmentTap != null) {
              widget.onSegmentTap!('', 0.0, 0);
            }
          }
        } else {
          // Tap is completely outside the donut chart area
          print('Tap outside donut chart area - clearing selection');
          setState(() {
            _selectedSegment = null; // Clear selection when clicking outside
          });
          // Call callback to clear tooltip
          if (widget.onSegmentTap != null) {
            widget.onSegmentTap!('', 0.0, 0);
          }
        }
      },
      child: CustomPaint(
        painter: DonutChartPainter(
          breakdown: widget.breakdown,
          selectedSegment: _selectedSegment,
        ),
        size: const Size(120, 120),
      ),
    );
  }

  double _getPercentage(String period) {
    if (widget.breakdown == null) return 0.0;
    final periodData = widget.breakdown![period] as Map<String, dynamic>?;
    return (periodData?['percentage'] as num?)?.toDouble() ?? 0.0;
  }

  int _getCount(String period) {
    if (widget.breakdown == null) return 0;
    final periodData = widget.breakdown![period] as Map<String, dynamic>?;
    return (periodData?['count'] as num?)?.toInt() ?? 0;
  }
}
