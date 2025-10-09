import 'package:flutter/material.dart';
import '../services/forecasting_api.dart' as fapi;

class ForecastAnalyticsScreen extends StatefulWidget {
  const ForecastAnalyticsScreen({super.key});
  @override
  State<ForecastAnalyticsScreen> createState() => _ForecastAnalyticsScreenState();
}

class _ForecastAnalyticsScreenState extends State<ForecastAnalyticsScreen> {
  bool _loading = true;
  String? _error;
  int? _peakHour;
  double? _peakValue;
  List<int> _hours = const [];
  List<double> _hourlyPredictions = const [];
  List<DateTime> _dates = const [];
  List<double> _dailyPredictions = const [];

  String _formatHour12(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  Widget _buildPeakTimeCard() {
    return Container(
      height: 200, // Fixed height for consistency
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Expected Peak Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          // Line chart placeholder
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _PeakTimeChartPainter(),
              size: const Size(double.infinity, 80),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _peakHour != null ? _formatHour12(_peakHour!) : '7:15 AM',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsCard() {
    return Container(
      height: 200, // Fixed height for consistency
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Units in Operation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '3', // Static value for now
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.6, // 3 out of 5 units
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('Deployed Units', style: TextStyle(fontSize: 12, color: Colors.black87)),
              const SizedBox(width: 16),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('Total No. of Units', style: TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCountCard() {
    return Container(
      height: 200, // Fixed height for consistency
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Passenger Count',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut chart
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _DonutChartPainter(),
                  size: const Size(80, 80),
                ),
              ),
              const SizedBox(width: 16),
              // Count and legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('172', // Static value for now
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 16),
                    _buildLegendItem('Morning', const Color(0xFF1E3A8A), 62.5),
                    const SizedBox(height: 4),
                    _buildLegendItem('Midday', const Color(0xFF3B82F6), 25.0),
                    const SizedBox(height: 4),
                    _buildLegendItem('Evening', const Color(0xFF93C5FD), 12.5),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double percentage) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$label (${percentage.toStringAsFixed(1)}%)', 
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Get hourly forecast with peak detection
      final hourly = await fapi.forecastHourly();
      // Get daily forecast
      final daily = await fapi.forecastDaily();
      
      setState(() {
        _peakHour = hourly.peakHour;
        _peakValue = hourly.peakValue;
        _hours = hourly.hours;
        _hourlyPredictions = hourly.predictions;
        _dates = daily.dates;
        _dailyPredictions = daily.predictions;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Forecast error: $_error'),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return Container(
      color: Colors.grey[100], // Light gray background to match other pages
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Title
            Center(
              child: Column(
                children: [
                  Text('Passenger Demand Forecast Dashboard',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('Daily and hourly forecasts visualized using your pre-trained models.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Top Cards Row
            Row(
              children: [
                // Expected Peak Time Card
                Expanded(
                  child: _buildPeakTimeCard(),
                ),
                const SizedBox(width: 16),
                // Units in Operation Card
                Expanded(
                  child: _buildUnitsCard(),
                ),
                const SizedBox(width: 16),
                // Daily Passenger Count Card
                Expanded(
                  child: _buildPassengerCountCard(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Charts in a row
            Row(
              children: [
                Expanded(
                  child: _DailyAreaChart(dates: _dates, values: _dailyPredictions),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _HourlyBarChart(hours: _hours, values: _hourlyPredictions),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required String value, String subtitle = ''}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF3E4795))),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]
        ],
      ),
    );
  }
}

class _DailyAreaChart extends StatelessWidget {
  final List<DateTime> dates;
  final List<double> values;
  const _DailyAreaChart({required this.dates, required this.values});
  
  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || dates.isEmpty) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Passenger Forecast', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('Prophet-based predicted demand for Mon-Sun', 
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _AreaChartPainter(values: values),
              size: const Size(double.infinity, 200),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(width: 12, height: 12, color: const Color(0xFF2196F3)),
              const SizedBox(width: 8),
              const Text('Daily Demand', style: TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourlyBarChart extends StatelessWidget {
  final List<int> hours;
  final List<double> values;
  const _HourlyBarChart({required this.hours, required this.values});
  
  String _formatHour12(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
  
  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || hours.isEmpty) return const SizedBox.shrink();
    
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);
    
    // Find top 3 peak hours
    final indexedValues = values.asMap().entries.toList();
    indexedValues.sort((a, b) => b.value.compareTo(a.value));
    final top3Indices = indexedValues.take(3).map((e) => e.key).toSet();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hourly Passenger Forecast', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text('XGBoost-based predicted passengers per hour (Top 3 hours highlighted)', 
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < hours.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Hour labels
                          if (hours[i] % 2 == 0)
                            Text(_formatHour12(hours[i]), 
                                style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          // Bar
                          Container(
                            height: maxV == 0 ? 0 : ((values[i] - minV) / range) * 160,
                            decoration: BoxDecoration(
                              color: top3Indices.contains(i) 
                                ? Colors.red  // Top 3 peak hours in red
                                : const Color(0xFF9C27B0), // Regular hours in purple
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(width: 12, height: 12, color: const Color(0xFF9C27B0)),
              const SizedBox(width: 8),
              const Text('Hourly Passengers', style: TextStyle(fontSize: 12, color: Colors.black87)),
              const SizedBox(width: 16),
              Container(width: 12, height: 12, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Top 3 peak hours', style: TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}


class _AreaChartPainter extends CustomPainter {
  final List<double> values;
  
  _AreaChartPainter({required this.values});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    
    final paint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF2196F3).withOpacity(0.3),
          const Color(0xFF2196F3).withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = (maxValue - minValue).abs() < 1e-6 ? 1.0 : (maxValue - minValue);
    
    final path = Path();
    final fillPath = Path();
    
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minValue) / range) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    // Complete the fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    // Draw fill
    canvas.drawPath(fillPath, fillPaint);
    
    // Draw line
    canvas.drawPath(path, paint);
    
    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;
    
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Draw day labels
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      textPainter.text = TextSpan(
        text: dayNames[i % dayNames.length],
        style: const TextStyle(fontSize: 10, color: Colors.black54),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height + 4));
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PeakTimeChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final pointPaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.fill;
    
    // Sample data points for the line chart
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.4, size.height * 0.5),
      Offset(size.width * 0.6, size.height * 0.4),
      Offset(size.width * 0.8, size.height * 0.8),
      Offset(size.width, size.height * 0.9),
    ];
    
    // Draw line
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
    
    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 3, pointPaint);
    }
    
    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;
    
    for (int i = 0; i <= 5; i++) {
      final y = (i / 5) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Morning segment (62.5%)
    final morningPaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    
    // Midday segment (25%)
    final middayPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    
    // Evening segment (12.5%)
    final eveningPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    
    // Draw segments
    double startAngle = -90 * (3.14159 / 180); // Start from top
    
    // Morning (62.5% = 225 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2.25 * 3.14159, // 225 degrees in radians
      false,
      morningPaint,
    );
    startAngle += 2.25 * 3.14159;
    
    // Midday (25% = 90 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      0.9 * 3.14159, // 90 degrees in radians
      false,
      middayPaint,
    );
    startAngle += 0.9 * 3.14159;
    
    // Evening (12.5% = 45 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      0.45 * 3.14159, // 45 degrees in radians
      false,
      eveningPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}



