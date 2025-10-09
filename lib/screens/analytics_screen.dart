import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/forecasting_api.dart' as fapi;
import '../services/api.dart' show baseUrl;

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
  int _unitsInOperation = 0;
  // Fixed fleet size
  static const int _fleetTotalUnits = 15;
  List<Map<String, dynamic>> _tripsPerUnit = const [];
  List<int> _fleetHours = const [];
  List<int> _fleetCounts = const [];

  String _formatHour12(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
  
  String _formatDateLong(DateTime d) {
    const months = [
      'January','February','March','April','May','June','July','August','September','October','November','December'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _buildPeakTimeCard() {
    return Container(
      height: 220, // Slightly taller to avoid legend overflow
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 16),
          // Chart on the left, time and date on the right
          Expanded(
            child: Row(
              children: [
                // Line chart
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: double.infinity,
                    child: CustomPaint(
                      painter: _PeakTimeChartPainter(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Time and date
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _peakHour != null ? _formatHour12(_peakHour!) : '7:15 AM',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
              _unitsInOperation.toString(),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar
          Tooltip(
            waitDuration: Duration(milliseconds: 200),
            message: (() {
              final pct = (_unitsInOperation / _fleetTotalUnits * 100).clamp(0, 100).toStringAsFixed(0);
              return '${_unitsInOperation} of ${_fleetTotalUnits} units (${pct}%)';
            })(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 12,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Colors.grey[500]), // total capacity track
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (() {
                        final f = _unitsInOperation / _fleetTotalUnits;
                        if (f.isNaN || f.isInfinite) return 0.0;
                        return f.clamp(0.0, 1.0);
                      })(),
                      child: Container(color: const Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF1E3A8A), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('Deployed Units', style: TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('Total No. of Units', style: TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
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
      // Fetch in parallel
      final hourlyF = fapi.forecastHourly();
      final dailyF = fapi.forecastDaily();
      final schedulesF = _fetchTodaySchedules();
      final tripsPerUnitF = _fetchTripsPerUnit();
      final fleetActivityF = _fetchFleetActivity();
      final hourly = await hourlyF;
      final daily = await dailyF;
      final schedules = await schedulesF;
      final tripsPU = await tripsPerUnitF;
      final fleet = await fleetActivityF;
      
      setState(() {
        _peakHour = hourly.peakHour;
        _peakValue = hourly.peakValue;
        _hours = hourly.hours;
        _hourlyPredictions = hourly.predictions;
        _dates = daily.dates;
        _dailyPredictions = daily.predictions;
        _unitsInOperation = schedules.deployedUnits;
        _tripsPerUnit = tripsPU;
        _fleetHours = fleet['hours'] ?? const [];
        _fleetCounts = fleet['counts'] ?? const [];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatDateYMD(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<({int deployedUnits, int totalUnits})> _fetchTodaySchedules() async {
    try {
      final uri = Uri.parse('$baseUrl/api/schedules?date=${_formatDateYMD(DateTime.now())}');
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        return (deployedUnits: 0, totalUnits: 0);
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = List<Map<String, dynamic>>.from(body['data'] ?? []);
      // Count unique vehicles and active entries
      final vehicleIds = <int>{};
      int active = 0;
      for (final s in list) {
        final vid = s['vehicle_id'];
        if (vid is int) vehicleIds.add(vid);
        final status = (s['status'] ?? '').toString().toLowerCase();
        if (status.isEmpty || status == 'active' || status == 'scheduled') active++;
      }
      final total = vehicleIds.isNotEmpty ? vehicleIds.length : list.length;
      final deployed = active > 0 ? active : list.length;
      return (deployedUnits: deployed, totalUnits: total == 0 ? deployed : total);
    } catch (_) {
      return (deployedUnits: 0, totalUnits: 0);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTripsPerUnit() async {
    try {
      final uri = Uri.parse('$baseUrl/api/trips-per-unit?date=${_formatDateYMD(DateTime.now())}');
      final res = await http.get(uri);
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = List<Map<String, dynamic>>.from(body['data'] ?? []);
      // normalize keys
      return list
          .map((e) => {
                'vehicle_id': e['vehicle_id'],
                'trips': e['trips'],
              })
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // Returns hours and counts for 4..20; fills zeros where no data
  Future<Map<String, List<int>>> _fetchFleetActivity() async {
    try {
      final uri = Uri.parse('$baseUrl/api/fleet-activity?date=${_formatDateYMD(DateTime.now())}');
      final res = await http.get(uri);
      final labels = List<int>.generate(17, (i) => i + 4);
      final counts = List<int>.filled(labels.length, 0);
      if (res.statusCode != 200) return {'hours': labels, 'counts': counts};
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = List<Map<String, dynamic>>.from(body['data'] ?? []);
      for (final row in list) {
        final h = (row['hour'] as num).toInt();
        final idx = labels.indexOf(h);
        if (idx >= 0) counts[idx] = (row['buses'] as num).toInt();
      }
      return {'hours': labels, 'counts': counts};
    } catch (_) {
      final labels = List<int>.generate(17, (i) => i + 4);
      final counts = List<int>.filled(labels.length, 0);
      return {'hours': labels, 'counts': counts};
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
            // Dashboard Title + Date (top row)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Analytics Dashboard',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
                      tooltip: 'Refresh Analytics Data',
                    ),
                  ],
                ),
                Row(
                  children: [
                    Tooltip(
                      message: 'Analytics data is updated automatically. Forecasts are estimates based on historical patterns.',
                      waitDuration: Duration(milliseconds: 300),
                      child: IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Color(0xFF1E3A8A)),
                                    SizedBox(width: 8),
                                    Text('Analytics Information'),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Data Sources:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text('• Fleet Activity: Real-time data from trips table'),
                                    Text('• Units in Operation: Current schedule data'),
                                    Text('• Passenger Forecasts: Machine learning predictions'),
                                    SizedBox(height: 16),
                                    Text(
                                      'Important Notes:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text('• Analytics data is updated automatically'),
                                    Text('• Forecasts are estimates based on historical patterns'),
                                    Text('• Actual operations may vary from predictions'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.info_outline, color: Color(0xFF1E3A8A)),
                        tooltip: 'Analytics Information',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatDateLong(DateTime.now()),
                        style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
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
            // Static operational metrics section
            _OperationalMetricsSection(tripsPerUnit: _tripsPerUnit),
            const SizedBox(height: 32),
            // Forecasting section title
            Row(
              children: [
                const Text(
                  'Forecasting',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  waitDuration: Duration(milliseconds: 250),
                  message: 'Forecasts are indicative and may differ from real operations.',
                  child: const Icon(Icons.info_outline, color: Color(0xFF1E3A8A), size: 18),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
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


// Static operational metrics section (mock visuals)
class _OperationalMetricsSection extends StatelessWidget {
  final List<Map<String, dynamic>>? tripsPerUnit;
  const _OperationalMetricsSection({required this.tripsPerUnit});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
                Expanded(
                  child: _Card(
                    title: 'Fleet Activity by Hour',
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: _InteractiveFleetChart(),
                    ),
                  ),
                ),
            const SizedBox(width: 16),
            Expanded(
              child: _Card(
                title: 'Passenger distribution',
                child: SizedBox(height: 180, child: CustomPaint(painter: _MockHorizontalBarsPainter())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Card(
          title: 'Trips per Unit',
          child: _TripsTable(data: tripsPerUnit ?? const []),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
      ]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _InteractiveFleetChart extends StatefulWidget {
  @override
  _InteractiveFleetChartState createState() => _InteractiveFleetChartState();
}

class _InteractiveFleetChartState extends State<_InteractiveFleetChart> {
  int? _hoveredIndex;
  List<int> _hours = List.generate(17, (i) => i + 4); // 4..20
  List<int> _counts = List.filled(17, 0);

  @override
  void initState() {
    super.initState();
    _loadFleetData();
  }

  Future<void> _loadFleetData() async {
    try {
      final uri = Uri.parse('$baseUrl/api/fleet-activity?date=${_formatDateYMD(DateTime.now())}');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = List<Map<String, dynamic>>.from(body['data'] ?? []);
        final counts = List<int>.filled(_hours.length, 0);
        for (final row in list) {
          final h = (row['hour'] as num).toInt();
          final idx = _hours.indexOf(h);
          if (idx >= 0) counts[idx] = (row['buses'] as num).toInt();
        }
        setState(() {
          _counts = counts;
        });
      }
    } catch (e) {
      // Keep default zero values
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final index = _getHoveredIndex(localPosition, box.size);
        setState(() {
          _hoveredIndex = index;
        });
      },
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final index = _getHoveredIndex(localPosition, box.size);
        setState(() {
          _hoveredIndex = index;
        });
      },
      onPanEnd: (_) {
        setState(() {
          _hoveredIndex = null;
        });
      },
      child: CustomPaint(
        painter: _FleetActivityChartPainter(
          hours: _hours,
          counts: _counts,
          hoveredIndex: _hoveredIndex,
        ),
      ),
    );
  }

  int? _getHoveredIndex(Offset position, Size size) {
    const double leftPad = 30;
    const double rightPad = 8;
    final double chartWidth = size.width - leftPad - rightPad;
    
    for (int i = 0; i < _hours.length; i++) {
      final x = leftPad + chartWidth * (i / (_hours.length - 1));
      // Increase hover sensitivity
      if ((position.dx - x).abs() < 20) {
        return i;
      }
    }
    return null;
  }

  String _formatDateYMD(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _FleetActivityChartPainter extends CustomPainter {
  final List<int> hours;
  final List<int> counts;
  final int? hoveredIndex;

  _FleetActivityChartPainter({
    required this.hours,
    required this.counts,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double bottomPad = 18;
    const double leftPad = 30; // More space for y-axis labels
    const double rightPad = 8;
    final double chartHeight = size.height - bottomPad;
    final double chartWidth = size.width - leftPad - rightPad;

    // Draw grid lines and y-axis labels
    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;

    final yAxisTextStyle = TextStyle(
      color: Colors.grey[600],
      fontSize: 9,
    );

    // Calculate dynamic max value based on actual data
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    final maxValue = maxCount > 0 ? maxCount : 20; // Use actual max or default to 20
    
    // Calculate nice step intervals starting from 0
    double stepValue;
    if (maxValue <= 4) {
      stepValue = 1; // 0, 1, 2, 3, 4
    } else if (maxValue <= 10) {
      stepValue = 2; // 0, 2, 4, 6, 8, 10
    } else if (maxValue <= 20) {
      stepValue = 5; // 0, 5, 10, 15, 20
    } else if (maxValue <= 50) {
      stepValue = 10; // 0, 10, 20, 30, 40, 50
    } else {
      stepValue = (maxValue / 4).ceil().toDouble();
    }
    
    // Ensure we have at least 4 steps for proper scaling
    final chartMaxValue = stepValue * 4;
    
    // Draw grid lines only (no y-axis labels)
    for (int i = 0; i <= 4; i++) {
      final y = chartHeight * (i / 4);
      
      // Draw grid line
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartWidth, y),
        gridPaint,
      );
    }

    // Draw chart line and points
    final linePaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dotPaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.fill;

    final hoverPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final points = <Offset>[];
    // Use the same scale as y-axis labels: stepValue * 4 = chartMaxValue
    final scale = chartMaxValue > 0 ? chartHeight / chartMaxValue : 1.0;

    for (int i = 0; i < hours.length; i++) {
      final x = leftPad + chartWidth * (i / (hours.length - 1));
      // Calculate y position: 0 at bottom, max value at top
      // Map data value to y position: y = chartHeight - (value * scale)
      final y = chartHeight - (counts[i] * scale);
      points.add(Offset(x, y));
    }

    // Draw line
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Draw dots with hover effect
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      // Highlight hovered point
      if (hoveredIndex == i) {
        canvas.drawCircle(point, 8, hoverPaint);
      }
      
      canvas.drawCircle(point, 3, dotPaint);
    }

    // Draw x-axis labels (every 2 hours)
    final tp = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    for (int i = 0; i < hours.length; i++) {
      if (hours[i] % 2 == 0 || i == hours.length - 1) {
        final x = leftPad + chartWidth * (i / (hours.length - 1));
        final hour = hours[i];
        final label = _formatHourStatic(hour);
        tp.text = TextSpan(text: label, style: const TextStyle(fontSize: 10, color: Colors.black54));
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 2));
      }
    }

    // Draw hover tooltip
    if (hoveredIndex != null && hoveredIndex! < hours.length) {
      final hour = hours[hoveredIndex!];
      final count = counts[hoveredIndex!];
      final point = points[hoveredIndex!];
      
      final tooltipText = '${_formatHourStatic(hour)}\nActive Buses: $count';
      final textSpan = TextSpan(
        text: tooltipText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      final tooltipWidth = textPainter.width + 16;
      final tooltipHeight = textPainter.height + 12;
      final tooltipX = (point.dx + tooltipWidth > size.width) 
          ? point.dx - tooltipWidth 
          : point.dx + 10;
      final tooltipY = point.dy - tooltipHeight - 10;
      
      // Draw tooltip background
      final tooltipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
        const Radius.circular(6),
      );
      final tooltipBgPaint = Paint()
        ..color = Colors.grey[800]!
        ..style = PaintingStyle.fill;
      canvas.drawRRect(tooltipRect, tooltipBgPaint);
      
      // Draw tooltip text
      textPainter.paint(
        canvas,
        Offset(tooltipX + 8, tooltipY + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MockLineChartPainter extends CustomPainter {
  final List<int>? hours;
  final List<int>? counts;
  const _MockLineChartPainter({this.hours, this.counts});
  @override
  void paint(Canvas canvas, Size size) {
    // Layout padding to avoid label overlap
    const double bottomPad = 18; // space for x labels
    const double leftPad = 8;
    const double rightPad = 8;
    final double chartHeight = size.height - bottomPad;
    final double chartWidth = size.width - leftPad - rightPad;

    final bg = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // grid
    for (int i = 0; i < 5; i++) {
      final y = chartHeight * (i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + chartWidth, y), bg);
    }
    final line = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dots = Paint()..color = const Color(0xFF1E3A8A);
    final points = <Offset>[];
    final labels = hours ?? List<int>.generate(17, (i) => i + 4); // 4..20
    final vals = counts ?? List<int>.filled(labels.length, 0);
    // Prevent divide-by-zero and compress within chart area
    final double maxY = (vals.isEmpty ? 1 : (vals.reduce((a,b)=>a>b?a:b).toDouble().clamp(1, 16)));
    for (int i = 0; i < vals.length; i++) {
      final x = leftPad + chartWidth * (i / (vals.length - 1));
      final y = chartHeight - ((vals[i].toDouble()) / maxY) * chartHeight;
      points.add(Offset(x, y));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, line);
    for (final p in points) {
      canvas.drawCircle(p, 2.5, dots);
    }
    // x-axis labels (4AM..8PM)
    final tp = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    for (int i = 0; i < labels.length; i++) {
      // label every 2 hours for readability
      if (labels[i] % 2 == 0 || i == labels.length - 1) {
        final x = leftPad + chartWidth * (i / (labels.length - 1));
        final hour = labels[i];
        final label = _formatHourStatic(hour);
        tp.text = TextSpan(text: label, style: const TextStyle(fontSize: 10, color: Colors.black54));
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _formatHourStatic(int hour) {
  if (hour == 0) return '12 AM';
  if (hour < 12) return '$hour AM';
  if (hour == 12) return '12 PM';
  return '${hour - 12} PM';
}

class _MockHorizontalBarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()..color = Colors.grey[300]!;
    final fill = Paint()..color = const Color(0xFF0B3A82);
    const rows = 3;
    for (int i = 0; i < rows; i++) {
      final top = i * (size.height / rows) + 12;
      final height = 20.0;
      // track
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, top, size.width, height), const Radius.circular(10)),
        track,
      );
      final factor = [0.8, 0.65, 1.0][i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, top, size.width * factor, height), const Radius.circular(10)),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TripsTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _TripsTable({required this.data});

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Text('Unit Number', style: headerStyle))),
          Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Text('Number of Trip', style: headerStyle))),
        ]),
      ),
      const SizedBox(height: 8),
      if (data.isEmpty)
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(12),
          child: const Text('No data for today'),
        )
      else
        ...data.map((row) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(children: [
                Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Text('${row['vehicle_id']}'))),
                Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Text('${row['trips']}'))),
              ]),
            )),
    ]);
  }
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



