import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/donut_chart_painter.dart';
import '../widgets/interactive_donut_chart.dart';
import 'package:provider/provider.dart';
import '../services/forecasting_api.dart' as fapi;
import '../services/api.dart' show baseUrl;

class ForecastAnalyticsScreen extends StatefulWidget {
  const ForecastAnalyticsScreen({super.key});
  @override
  State<ForecastAnalyticsScreen> createState() =>
      _ForecastAnalyticsScreenState();
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
  // Yearly heatmap (12 x 31)
  int _yearlyYear = DateTime.now().year;
  List<List<double?>> _yearlyGrid = const [];
  
  // Trip duration analytics
  Map<String, dynamic>? _tripDurationAnalytics;
  
  // Daily passenger count with time breakdown
  int _dailyPassengerCount = 0;
  Map<String, dynamic>? _dailyPassengerBreakdown;
  String? _selectedPeriod;
  String? _tooltipText;
  
  // Cache to prevent repeated requests (reduced for more dynamic updates)
  DateTime? _lastLoadTime;
  static const Duration _cacheTimeout = Duration(minutes: 1); // Reduced from 5 minutes to 1 minute
  
  String get _lastUpdateText {
    if (_lastLoadTime == null) return 'Never updated';
    final diff = DateTime.now().difference(_lastLoadTime!);
    if (diff.inSeconds < 60) return 'Updated ${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    return 'Updated ${diff.inHours}h ago';
  }

  String _formatHour12(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  String _formatDateLong(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _showYearSelector() {
    final currentYear = DateTime.now().year;
    final availableYears = List.generate(5, (index) => currentYear + index);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFF3E4795)),
              SizedBox(width: 8),
              Text('Select Forecast Year'),
            ],
          ),
          content: Container(
            width: 300,
            height: 200,
            child: ListView.builder(
              itemCount: availableYears.length,
              itemBuilder: (context, index) {
                final year = availableYears[index];
                final isSelected = year == _yearlyYear;
                
                return ListTile(
                  title: Text(
                    year.toString(),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Color(0xFF3E4795) : Colors.black,
                    ),
                  ),
                  trailing: isSelected ? Icon(Icons.check, color: Color(0xFF3E4795)) : null,
                  onTap: () {
                    setState(() {
                      _yearlyYear = year;
                    });
                    _loadYearlyForecast();
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF3E4795),
                side: BorderSide(color: Colors.grey[300]!),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadYearlyForecast() async {
    try {
      if (mounted) {
        setState(() {
          _loading = true;
        });
      }
      
      final yearlyF = fapi.forecastYearlyDaily(_yearlyYear);
      final yearly = await yearlyF;
      
      if (mounted) {
        setState(() {
          _yearlyYear = yearly.year;
          _yearlyGrid = yearly.grid;
          _loading = false;
        });
      }
      
      print('Yearly forecast loaded for ${_yearlyYear}: grid length=${yearly.grid.length}');
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to load forecast for $_yearlyYear';
        if (e.toString().contains('TimeoutException')) {
          errorMessage = 'Request timed out while loading yearly forecast. The service may be slow. Please try again.';
        } else if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
          errorMessage = 'Cannot connect to forecasting service. Please check your connection.';
        } else {
          errorMessage = 'Failed to load forecast for $_yearlyYear: ${e.toString()}';
        }
        setState(() {
          _error = errorMessage;
          _loading = false;
        });
      }
      print('Error loading yearly forecast for $_yearlyYear: $e');
    }
  }

  Widget _buildPeakTimeCard() {
    // Calculate peak time from actual forecast data
    int? actualPeakHour;
    double maxValue = 0;

    if (_hourlyPredictions.isNotEmpty && _hours.isNotEmpty) {
      for (int i = 0; i < _hourlyPredictions.length; i++) {
        if (_hourlyPredictions[i] > maxValue) {
          maxValue = _hourlyPredictions[i];
          actualPeakHour = _hours[i]; // Use the actual hour from forecast data
        }
      }
    }

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
          Row(
            children: [
              Text(
                'Expected Peak Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 8),
              Tooltip(
                message: 'Disclaimer: The following forecast uses dummy data calibrated to mirror general passenger demand patterns and does not represent actual recorded values.',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
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
                      painter: _PeakTimeChartPainter(
                        hourlyData: _hourlyPredictions
                            .map((e) => e.round())
                            .toList(),
                        peakHour: actualPeakHour,
                      ),
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
                        actualPeakHour != null
                            ? _formatHour12(actualPeakHour)
                            : '7:15 AM',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Consider deploying more units during this time.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
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
      height: 220, // Fixed height for consistency
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
          const Text(
            'Units in Operation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              _unitsInOperation.toString(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar
          Tooltip(
            waitDuration: Duration(milliseconds: 200),
            message: (() {
              final pct = (_unitsInOperation / _fleetTotalUnits * 100)
                  .clamp(0, 100)
                  .toStringAsFixed(0);
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
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E3A8A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Deployed Units',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Total No. of Units',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
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
      height: 220, // Fixed height for consistency
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
          const Text(
            'Daily Passenger Count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Interactive Donut chart
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    InteractiveDonutChart(
                      breakdown: _dailyPassengerBreakdown,
                      onSegmentTap: (period, percentage, count) {
                        print('Analytics screen received tap: period=$period, percentage=$percentage, count=$count');
                        setState(() {
                          if (period.isEmpty) {
                            // Clear tooltip when clicking outside
                            _selectedPeriod = null;
                            _tooltipText = null;
                          } else {
                            // Show tooltip for segment
                            _selectedPeriod = period;
                            _tooltipText = '$period: $count passengers (${percentage.toStringAsFixed(1)}%)';
                          }
                        });
                      },
                    ),
                    // Tooltip overlay
                    if (_tooltipText != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _tooltipText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Count and legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_dailyPassengerCount ?? 0}', // Dynamic value from database
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLegendItem('Morning', const Color(0xFF1E3A8A), _getMorningPercentage()),
                    const SizedBox(height: 4),
                    _buildLegendItem('Midday', const Color(0xFF3B82F6), _getMiddayPercentage()),
                    const SizedBox(height: 4),
                    _buildLegendItem('Evening', const Color(0xFF93C5FD), _getEveningPercentage()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods to get percentages from breakdown data
  double _getMorningPercentage() {
    if (_dailyPassengerBreakdown == null) return 0.0;
    final morning = _dailyPassengerBreakdown!['morning'] as Map<String, dynamic>?;
    return (morning?['percentage'] as num?)?.toDouble() ?? 0.0;
  }

  double _getMiddayPercentage() {
    if (_dailyPassengerBreakdown == null) return 0.0;
    final midday = _dailyPassengerBreakdown!['midday'] as Map<String, dynamic>?;
    return (midday?['percentage'] as num?)?.toDouble() ?? 0.0;
  }

  double _getEveningPercentage() {
    if (_dailyPassengerBreakdown == null) return 0.0;
    final evening = _dailyPassengerBreakdown!['evening'] as Map<String, dynamic>?;
    return (evening?['percentage'] as num?)?.toDouble() ?? 0.0;
  }

  Widget _buildLegendItem(String label, Color color, double percentage) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label (${percentage.toStringAsFixed(1)}%)',
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Check cache first
    if (_lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _cacheTimeout &&
        _hourlyPredictions.isNotEmpty) {
      print('Using cached data (${DateTime.now().difference(_lastLoadTime!).inSeconds}s old)');
      return;
    }
    
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      // Fetch in parallel (removed redundant network test)
      final hourlyF = fapi.forecastHourly();
      final dailyF = fapi.forecastDaily();
      final schedulesF = _fetchTodaySchedules();
      final tripsPerUnitF = _fetchTripsPerUnit();
      final fleetActivityF = _fetchFleetActivity();
      final tripDurationF = _fetchTripDurationAnalytics();
      final dailyPassengerCountF = _fetchDailyPassengerCount();
      final hourly = await hourlyF;
      final daily = await dailyF;
      late final yearly;
      try {
        final yearlyF = fapi.forecastYearlyDaily(_yearlyYear);
        yearly = await yearlyF;
        print('Yearly forecast loaded: year=${yearly.year}, grid length=${yearly.grid.length}');
        if (yearly.grid.isEmpty) {
          print('WARNING: Yearly grid is empty!');
        }
      } catch (e) {
        print('Error loading yearly forecast: $e');
        yearly = (year: _yearlyYear, grid: <List<double?>>[]);
      }
      final schedules = await schedulesF;
      final tripsPU = await tripsPerUnitF;
      final fleet = await fleetActivityF;
      final tripDuration = await tripDurationF;
      final dailyPassengerData = await dailyPassengerCountF;

      if (mounted) {
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
          _yearlyYear = yearly.year;
          _yearlyGrid = yearly.grid;
          _tripDurationAnalytics = tripDuration;
          _dailyPassengerCount = dailyPassengerData.total;
          _dailyPassengerBreakdown = dailyPassengerData.breakdown;
          _lastLoadTime = DateTime.now(); // Update cache time
          print('Yearly grid set: ${_yearlyGrid.length} months, first month has ${_yearlyGrid.isNotEmpty ? _yearlyGrid[0].length : 0} days');
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to load analytics data';
        if (e.toString().contains('TimeoutException')) {
          errorMessage = 'Request timed out. The forecasting service may be slow or unavailable. Please try again.';
        } else if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
          errorMessage = 'Cannot connect to forecasting service. Please check your internet connection and try again.';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        setState(() => _error = errorMessage);
      }
      print('Error in _load: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatDateYMD(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<({int deployedUnits, int totalUnits})> _fetchTodaySchedules() async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/schedules?date=${_formatDateYMD(DateTime.now())}',
      );
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
        if (status.isEmpty || status == 'active' || status == 'scheduled')
          active++;
      }
      final total = vehicleIds.isNotEmpty ? vehicleIds.length : list.length;
      final deployed = active > 0 ? active : list.length;
      return (
        deployedUnits: deployed,
        totalUnits: total == 0 ? deployed : total,
      );
    } catch (_) {
      return (deployedUnits: 0, totalUnits: 0);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTripsPerUnit() async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/trips-per-unit?date=${_formatDateYMD(DateTime.now())}',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = List<Map<String, dynamic>>.from(body['data'] ?? []);
      // normalize keys
      return list
          .map((e) => {'vehicle_id': e['vehicle_id'], 'trips': e['trips']})
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // Returns hours and counts for 4..20; fills zeros where no data
  Future<Map<String, List<int>>> _fetchFleetActivity() async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/fleet-activity?date=${_formatDateYMD(DateTime.now())}',
      );
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

  Future<Map<String, dynamic>?> _fetchTripDurationAnalytics() async {
    try {
      // Fetch trips for today with start_time and end_time
      final uri = Uri.parse('$baseUrl/trips/api/admin/trips?limit=1000');
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final allTrips = List<Map<String, dynamic>>.from(body['data'] ?? []);
      
      // Filter trips for today only (use local date; API times are UTC)
      final nowLocal = DateTime.now();
      final todayLocalStr = _formatDateYMD(nowLocal);
      final trips = allTrips.where((trip) {
        final startTime = trip['start_time'] as String?;
        if (startTime == null) return false;
        try {
          final startUtc = DateTime.parse(startTime);
          final startLocal = startUtc.toLocal();
          return _formatDateYMD(startLocal) == todayLocalStr;
        } catch (_) {
          return false;
        }
      }).toList();
      
      print('Found ${trips.length} trips for today (local) out of ${allTrips.length} total trips');
      
      // Group trips by vehicle_id and calculate average duration (use local times)
      final Map<int, List<double>> vehicleDurations = {};
      
      for (final trip in trips) {
        final vehicleId = trip['vehicle_id'] as int?;
        final startTime = trip['start_time'] as String?;
        final endTime = trip['end_time'] as String?;
        
        if (vehicleId != null && startTime != null && endTime != null) {
          try {
            final startLocal = DateTime.parse(startTime).toLocal();
            final endLocal = DateTime.parse(endTime).toLocal();
            final durationMinutes = endLocal.difference(startLocal).inMinutes;
            
            if (durationMinutes > 0) {
              vehicleDurations.putIfAbsent(vehicleId, () => []).add(durationMinutes.toDouble());
            }
          } catch (e) {
            print('Error parsing trip times: $e');
          }
        }
      }
      
      // Calculate average duration for each vehicle
      final List<Map<String, dynamic>> vehicleAverages = [];
      vehicleDurations.forEach((vehicleId, durations) {
        final averageDuration = durations.reduce((a, b) => a + b) / durations.length;
        vehicleAverages.add({
          'vehicle_id': vehicleId,
          'average_duration_minutes': averageDuration,
          'trip_count': durations.length,
        });
      });
      
      // Sort by vehicle_id for consistent display
      vehicleAverages.sort((a, b) => (a['vehicle_id'] as int).compareTo(b['vehicle_id'] as int));
      
      return {
        'vehicles': vehicleAverages,
        'total_vehicles': vehicleAverages.length,
        'date': _formatDateYMD(DateTime.now()),
      };
    } catch (e) {
      print('Error fetching trip duration analytics: $e');
      return null;
    }
  }

  // Fetch daily passenger count with time breakdown from dedicated API endpoint
  Future<({int total, Map<String, dynamic> breakdown})> _fetchDailyPassengerCount() async {
    try {
      // Use the new dedicated endpoint for today's passenger count
      final uri = Uri.parse('$baseUrl/trips/api/today-passengers');
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        print('API error: ${res.statusCode} - ${res.body}');
        return (total: 0, breakdown: <String, dynamic>{});
      }
      
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final totalPassengers = body['total_passengers'] as int? ?? 0;
      final timeBreakdown = body['time_breakdown'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final date = body['date'] as String? ?? 'unknown';
      
      print('Today\'s passenger count: $totalPassengers (date: $date)');
      print('Time breakdown: $timeBreakdown');
      
      return (total: totalPassengers, breakdown: timeBreakdown);
    } catch (e) {
      print('Error fetching daily passenger count: $e');
      return (total: 0, breakdown: <String, dynamic>{});
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          onPressed: () {
                            _lastLoadTime = null; // Force refresh by clearing cache
                            _load();
                          },
                          icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
                          tooltip: 'Refresh Analytics Data (Force Update)',
                        ),
                      ],
                    ),
                    Text(
                      _lastUpdateText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Tooltip(
                      message:
                          'Analytics data is updated automatically. Forecasts are estimates based on historical patterns.',
                      waitDuration: Duration(milliseconds: 300),
                      child: IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF1E3A8A),
                                    ),
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '• Fleet Activity: Real-time data from trips table',
                                    ),
                                    Text(
                                      '• Units in Operation: Current schedule data',
                                    ),
                                    Text(
                                      '• Passenger Forecasts: Machine learning predictions',
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Important Notes:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '• Analytics data is updated automatically',
                                    ),
                                    Text(
                                      '• Forecasts are estimates based on historical patterns',
                                    ),
                                    Text(
                                      '• Actual operations may vary from predictions',
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.info_outline,
                          color: Color(0xFF1E3A8A),
                        ),
                        tooltip: 'Analytics Information',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
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
                Expanded(child: _buildPeakTimeCard()),
                const SizedBox(width: 16),
                // Units in Operation Card
                Expanded(child: _buildUnitsCard()),
                const SizedBox(width: 16),
                // Daily Passenger Count Card
                Expanded(child: _buildPassengerCountCard()),
              ],
            ),
            const SizedBox(height: 32),
            // Static operational metrics section
            _OperationalMetricsSection(tripDurationAnalytics: _tripDurationAnalytics),
            const SizedBox(height: 16),
            // Charts in a row (Daily + Hourly) directly below Fleet Activity
            Row(
              children: [
                Expanded(
                  child: _DailyAreaChart(
                    dates: _dates,
                    values: _dailyPredictions,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _HourlyBarChart(
                    hours: _hours,
                    values: _hourlyPredictions,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Yearly daily passenger forecast heatmap at the bottom
            _Card(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    child:                       Stack(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Yearly Passenger Forecast Heatmap ${_yearlyYear.toString()}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 8),
                              Tooltip(
                                message: 'Disclaimer: The following forecast uses dummy data calibrated to mirror general passenger demand patterns and does not represent actual recorded values.',
                                child: Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showYearSelector,
                            child: Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFF3E4795),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This heatmap provides an overview of the predicted passenger demand throughout the year, helping identify peak and low-demand periods across different months and days.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ],
              ),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: _yearlyGrid.isNotEmpty 
                  ? _YearlyHeatmap(grid: _yearlyGrid, year: _yearlyYear)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh, size: 32, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            _loading ? 'Loading yearly forecast...' : 'No yearly data available',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required String value,
    String subtitle = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E4795),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyAreaChart extends StatefulWidget {
  final List<DateTime> dates;
  final List<double> values;
  const _DailyAreaChart({required this.dates, required this.values});

  @override
  State<_DailyAreaChart> createState() => _DailyAreaChartState();
}

class _DailyAreaChartState extends State<_DailyAreaChart> {
  int? _hoveredIndex;

  void _showDailyYearSelector() {
    final currentYear = DateTime.now().year;
    final availableYears = List.generate(5, (index) => currentYear + index);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFF3E4795)),
              SizedBox(width: 8),
              Text('Select Forecast Year'),
            ],
          ),
          content: Container(
            width: 300,
            height: 200,
            child: ListView.builder(
              itemCount: availableYears.length,
              itemBuilder: (context, index) {
                final year = availableYears[index];
                
                return ListTile(
                  title: Text(
                    year.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Add year selection logic here if needed
                  },
                );
              },
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF3E4795),
                side: BorderSide(color: Colors.grey[300]!),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty || widget.dates.isEmpty)
      return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            child: Stack(
              children: [
                Row(
                  children: [
                    Text(
                      'Daily Passenger Forecast',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 8),
                    Tooltip(
                      message: 'Disclaimer: The following forecast uses dummy data calibrated to mirror general passenger demand patterns and does not represent actual recorded values.',
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                // Removed calendar icon button per request
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Displays the forecasted passenger demand trend from Sunday to Saturday.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onPanStart: (details) => _updateHover(details.globalPosition),
            onPanUpdate: (details) => _updateHover(details.globalPosition),
            onPanEnd: (_) => setState(() => _hoveredIndex = null),
            child: SizedBox(
              height: 200,
              child: CustomPaint(
                painter: _AreaChartPainter(
                  values: widget.values,
                  dates: widget.dates,
                  hoveredIndex: _hoveredIndex,
                ),
                size: const Size(double.infinity, 200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateHover(Offset global) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset local = box.globalToLocal(global);
    const double leftPad = 0; // padding inside CustomPaint already handled
    const double rightPad = 0;
    final double width = box.size.width - 0; // full width of paintable area
    final count = widget.values.length;
    if (count <= 1) return;
    int index = ((local.dx - leftPad) / (width) * (count - 1)).round();
    index = index.clamp(0, count - 1);
    setState(() => _hoveredIndex = index);
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hourly Passenger Forecast',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 8),
              Tooltip(
                message: 'Disclaimer: The following forecast uses dummy data calibrated to mirror general passenger demand patterns and does not represent actual recorded values.',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Shows the hourly passenger forecast and highlights the top three busiest hours.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Column(
              children: [
                // Bars area (fills most of the height)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < hours.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Tooltip(
                              message: '${values[i].round()} pax',
                              waitDuration: Duration(milliseconds: 200),
                              child: Container(
                                height: (() {
                                  // Ensure every hour shows a visible bar
                                  if (values.isEmpty) return 0.0;
                                  if (maxV == 0)
                                    return 3.0; // all zeros -> tiny bars
                                  final normalized = (values[i] - minV) / range;
                                  final h = normalized * 160.0;
                                  return h < 3.0
                                      ? 3.0
                                      : h; // minimum 3px height
                                })(),
                                decoration: BoxDecoration(
                                  color: top3Indices.contains(i)
                                      ? const Color(0xFF1E3A8A)
                                      : const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Labels row (fixed height, does not affect bar heights)
                Row(
                  children: [
                    for (int i = 0; i < hours.length; i++)
                      Expanded(
                        child: Center(
                          child: hours[i] % 2 == 0
                              ? Text(
                                  _formatHour12(hours[i]),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Legend removed as requested
        ],
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<double> values;
  final List<DateTime>? dates;
  final int? hoveredIndex;

  _AreaChartPainter({required this.values, this.dates, this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    // Reserve space at the bottom for x-axis labels so content fits exactly
    const double bottomPad = 18.0;
    final double chartHeight = size.height - bottomPad;

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
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = (maxValue - minValue).abs() < 1e-6
        ? 1.0
        : (maxValue - minValue);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = chartHeight - ((values[i] - minValue) / range) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete the fill path
    fillPath.lineTo(size.width, chartHeight);
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
      final y = (i / 4) * chartHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw day labels with optional date numbers
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final fallbackDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      String dayLabel;
      if (dates != null && dates!.length > i) {
        final d = dates![i];
        final dow =
            fallbackDayNames[(d.weekday + 6) %
                7]; // convert Mon=1..Sun=7 to index 0..6 with Mon first
        dayLabel = '$dow\n${d.day}';
      } else {
        dayLabel = fallbackDayNames[i % fallbackDayNames.length];
      }
      textPainter.text = TextSpan(
        text: dayLabel,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.black54,
          height: 1.2,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartHeight + 2),
      );
    }

    // Hover indicator and tooltip
    if (hoveredIndex != null &&
        hoveredIndex! >= 0 &&
        hoveredIndex! < values.length) {
      final idx = hoveredIndex!;
      final x = (idx / (values.length - 1)) * size.width;
      final y = chartHeight - ((values[idx] - minValue) / range) * chartHeight;

      // Highlight circle
      final hoverFill = Paint()
        ..color = const Color(0xFF1E3A8A).withOpacity(0.15);
      final hoverDot = Paint()..color = const Color(0xFF1E3A8A);
      canvas.drawCircle(Offset(x, y), 8, hoverFill);
      canvas.drawCircle(Offset(x, y), 3, hoverDot);

      // Tooltip
      final label = '${values[idx].round()} pax';
      final tp2 = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp2.layout();
      final boxW = tp2.width + 12;
      final boxH = tp2.height + 10;
      double boxX = x + 8;
      double boxY = y - boxH - 8;
      if (boxX + boxW > size.width) boxX = x - boxW - 8;
      if (boxY < 0) boxY = y + 8;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxX, boxY, boxW, boxH),
        const Radius.circular(6),
      );
      final bg = Paint()..color = Colors.black.withOpacity(0.8);
      canvas.drawRRect(rrect, bg);
      tp2.paint(canvas, Offset(boxX + 6, boxY + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Static operational metrics section (mock visuals)
class _OperationalMetricsSection extends StatelessWidget {
  final Map<String, dynamic>? tripDurationAnalytics;
  
  const _OperationalMetricsSection({this.tripDurationAnalytics});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Card(
                title: Text('Fleet Activity by Hour'),
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
                title: Text('Average Trip Duration'),
                child: SizedBox(
                  height: 180,
                  child: _TripDurationChart(tripDurationAnalytics: tripDurationAnalytics),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget title;
  final IconData? titleIcon;
  final Widget child;
  const _Card({required this.title, this.titleIcon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: title),
              if (titleIcon != null) ...[
                const SizedBox(width: 6),
                Icon(titleIcon, size: 18, color: Colors.black87),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Ensure inner drawings never overflow and expand to available width
          SizedBox(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
          ),
        ],
      ),
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
      final uri = Uri.parse(
        '$baseUrl/api/fleet-activity?date=${_formatDateYMD(DateTime.now())}',
      );
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

    final yAxisTextStyle = TextStyle(color: Colors.grey[600], fontSize: 9);

    // Calculate dynamic max value based on actual data
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    final maxValue = maxCount > 0
        ? maxCount
        : 20; // Use actual max or default to 20

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
    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i < hours.length; i++) {
      if (hours[i] % 2 == 0 || i == hours.length - 1) {
        final x = leftPad + chartWidth * (i / (hours.length - 1));
        final hour = hours[i];
        final label = _formatHourStatic(hour);
        tp.text = TextSpan(
          text: label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        );
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
      textPainter.paint(canvas, Offset(tooltipX + 8, tooltipY + 6));
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
    final double maxY = (vals.isEmpty
        ? 1
        : (vals.reduce((a, b) => a > b ? a : b).toDouble().clamp(1, 16)));
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
    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i < labels.length; i++) {
      // label every 2 hours for readability
      if (labels[i] % 2 == 0 || i == labels.length - 1) {
        final x = leftPad + chartWidth * (i / (labels.length - 1));
        final hour = labels[i];
        final label = _formatHourStatic(hour);
        tp.text = TextSpan(
          text: label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        );
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

class _TripDurationChart extends StatefulWidget {
  final Map<String, dynamic>? tripDurationAnalytics;
  
  const _TripDurationChart({this.tripDurationAnalytics});
  
  @override
  _TripDurationChartState createState() => _TripDurationChartState();
}

class _TripDurationChartState extends State<_TripDurationChart> {
  int? _hoveredIndex;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _onBarTap(details.localPosition),
      onPanStart: (details) => _updateHoveredIndex(details.localPosition),
      onPanUpdate: (details) => _updateHoveredIndex(details.localPosition),
      onPanEnd: (details) => setState(() => _hoveredIndex = null),
      child: CustomPaint(
        painter: _TripDurationBarsPainter(
          tripDurationAnalytics: widget.tripDurationAnalytics,
          hoveredIndex: _hoveredIndex,
          selectedIndex: _selectedIndex,
        ),
      ),
    );
  }

  void _onBarTap(Offset position) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    const double bottomPad = 18;
    const double leftPad = 8;
    const double rightPad = 30;
    final double chartHeight = size.height - bottomPad;
    final double chartWidth = size.width - leftPad - rightPad;

    final vehicles = widget.tripDurationAnalytics?['vehicles'] as List<dynamic>? ?? [];
    final rows = vehicles.length;
    if (rows == 0) return;

    final barHeight = 20.0;
    final spacing = rows > 1 ? (chartHeight - (rows * barHeight)) / (rows - 1) : 0.0;

    for (int i = 0; i < rows; i++) {
      final top = i * (barHeight + spacing);
      final bottom = top + barHeight;

      if (position.dy >= top &&
          position.dy <= bottom &&
          position.dx >= leftPad &&
          position.dx <= leftPad + chartWidth) {
        
        final vehicle = vehicles[i] as Map<String, dynamic>;
        final vehicleId = vehicle['vehicle_id'] as int;
        final duration = (vehicle['average_duration_minutes'] as num).toDouble();
        final tripCount = vehicle['trip_count'] as int;
        
        setState(() => _selectedIndex = i);
        
        // Show detailed information dialog
        _showVehicleDetails(vehicleId, duration, tripCount);
        return;
      }
    }
    
    // If clicked outside bars, clear selection
    setState(() => _selectedIndex = null);
  }

  void _updateHoveredIndex(Offset position) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    const double bottomPad = 18;
    const double leftPad = 8;
    const double rightPad = 30;
    final double chartHeight = size.height - bottomPad;
    final double chartWidth = size.width - leftPad - rightPad;

    final vehicles = widget.tripDurationAnalytics?['vehicles'] as List<dynamic>? ?? [];
    final rows = vehicles.length;
    if (rows == 0) return;

    final barHeight = 20.0;
    final spacing = rows > 1 ? (chartHeight - (rows * barHeight)) / (rows - 1) : 0.0;

    for (int i = 0; i < rows; i++) {
      final top = i * (barHeight + spacing);
      final bottom = top + barHeight;

      if (position.dy >= top &&
          position.dy <= bottom &&
          position.dx >= leftPad &&
          position.dx <= leftPad + chartWidth) {
        if (_hoveredIndex != i) {
          setState(() => _hoveredIndex = i);
        }
        return;
      }
    }

    if (_hoveredIndex != null) {
      setState(() => _hoveredIndex = null);
    }
  }

  void _showVehicleDetails(int vehicleId, double duration, int tripCount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.directions_bus, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text('Vehicle $vehicleId Details'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Vehicle ID', '$vehicleId'),
              _buildDetailRow('Average Trip Duration', '${duration.toStringAsFixed(1)} minutes'),
              _buildDetailRow('Total Trips Today', '$tripCount trips'),
              _buildDetailRow('Date', '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-${DateTime.now().day.toString().padLeft(2,'0')}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractivePassengerChart extends StatefulWidget {
  @override
  _InteractivePassengerChartState createState() =>
      _InteractivePassengerChartState();
}

class _InteractivePassengerChartState
    extends State<_InteractivePassengerChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _updateHoveredIndex(details.localPosition),
      onPanUpdate: (details) => _updateHoveredIndex(details.localPosition),
      onPanEnd: (details) => setState(() => _hoveredIndex = null),
      child: CustomPaint(
        painter: _MockHorizontalBarsPainter(hoveredIndex: _hoveredIndex),
      ),
    );
  }

  void _updateHoveredIndex(Offset position) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    const double bottomPad = 18;
    const double leftPad = 8;
    const double rightPad = 30;
    final double chartHeight = size.height - bottomPad;
    final double chartWidth = size.width - leftPad - rightPad;

    const rows = 3;
    final barHeight = 20.0;
    final spacing = (chartHeight - (rows * barHeight)) / (rows - 1);

    for (int i = 0; i < rows; i++) {
      final top = i * (barHeight + spacing);
      final bottom = top + barHeight;

      if (position.dy >= top &&
          position.dy <= bottom &&
          position.dx >= leftPad &&
          position.dx <= leftPad + chartWidth) {
        if (_hoveredIndex != i) {
          setState(() => _hoveredIndex = i);
        }
        return;
      }
    }

    if (_hoveredIndex != null) {
      setState(() => _hoveredIndex = null);
    }
  }

  // Removed dialog helpers from mock chart
}

class _TripDurationBarsPainter extends CustomPainter {
  final Map<String, dynamic>? tripDurationAnalytics;
  final int? hoveredIndex;
  final int? selectedIndex;

  _TripDurationBarsPainter({this.tripDurationAnalytics, this.hoveredIndex, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    const double bottomPad = 18;
    const double leftPad = 8;
    const double rightPad = 30;
    final double chartHeight = size.height - bottomPad;
    final double chartWidth = size.width - leftPad - rightPad;

    final vehicles = tripDurationAnalytics?['vehicles'] as List<dynamic>? ?? [];
    if (vehicles.isEmpty) {
      // Show "No data" message
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'No trip data available',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      return;
    }

    final track = Paint()..color = Colors.grey[200]!;
    final fills = <Paint>[];
    
    // Create color variations from light blue to dark blue
    for (int i = 0; i < vehicles.length; i++) {
      final intensity = (i + 1) / vehicles.length;
      final blueValue = (255 * (0.3 + 0.7 * intensity)).round();
      fills.add(Paint()..color = Color.fromRGBO(30, 58, 138, intensity));
    }

    final rows = vehicles.length;
    final barHeight = 20.0;
    final spacing = rows > 1 ? (chartHeight - (rows * barHeight)) / (rows - 1) : 0.0;

    // Find max duration for scaling
    double maxDuration = 0;
    for (final vehicle in vehicles) {
      final duration = (vehicle['average_duration_minutes'] as num).toDouble();
      if (duration > maxDuration) maxDuration = duration;
    }

    // If all durations are 0, set a default max
    if (maxDuration == 0) maxDuration = 100;

    for (int i = 0; i < rows; i++) {
      final vehicle = vehicles[i] as Map<String, dynamic>;
      final vehicleId = vehicle['vehicle_id'] as int;
      final duration = (vehicle['average_duration_minutes'] as num).toDouble();
      final top = i * (barHeight + spacing);

      // Background track
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(leftPad, top, chartWidth, barHeight),
          const Radius.circular(10),
        ),
        track,
      );

      // Bar fill with selection highlight
      final factor = maxDuration > 0 ? (duration / maxDuration).clamp(0.0, 1.0) : 0.0;
      final barWidth = chartWidth * factor;
      
      // Use different color for selected bar
      final barPaint = selectedIndex == i 
          ? (Paint()..color = Colors.orange[600]!)  // Orange for selected
          : fills[i];
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(leftPad, top, barWidth, barHeight),
          const Radius.circular(10),
        ),
        barPaint,
      );

      // Add border for selected bar
      if (selectedIndex == i) {
        final borderPaint = Paint()
          ..color = Colors.orange[800]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(leftPad, top, barWidth, barHeight),
            const Radius.circular(10),
          ),
          borderPaint,
        );
      }

      // Y-axis labels (vehicle_id) - positioned on the right
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$vehicleId',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width - 15, top + (barHeight - textPainter.height) / 2),
      );
    }

    // X-axis labels (0, 25%, 50%, 75%, 100% of max duration)
    final xLabels = <String>[];
    for (int i = 0; i <= 4; i++) {
      final value = (maxDuration * i / 4).round();
      xLabels.add('${value}m');
    }
    
    for (int i = 0; i < xLabels.length; i++) {
      final x = leftPad + (chartWidth / 4) * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: xLabels[i],
          style: TextStyle(color: Colors.grey[600], fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 12),
      );
    }

    // Tooltip for hovered bar
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < rows) {
      final vehicle = vehicles[hoveredIndex!] as Map<String, dynamic>;
      final vehicleId = vehicle['vehicle_id'] as int;
      final duration = (vehicle['average_duration_minutes'] as num).toDouble();
      final tripCount = vehicle['trip_count'] as int;
      
      final tooltipWidth = 120.0;
      final tooltipHeight = 50.0;
      final tooltipX = size.width - tooltipWidth - 10;
      final tooltipY = spacing + hoveredIndex! * (barHeight + spacing) - tooltipHeight - 5;

      // Tooltip background
      final tooltipPaint = Paint()..color = Colors.grey[800]!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
          const Radius.circular(4),
        ),
        tooltipPaint,
      );

      // Tooltip text
      final tooltipText = 'Vehicle $vehicleId\n${duration.toStringAsFixed(1)}m avg\n$tripCount trips';
      final tooltipTextPainter = TextPainter(
        text: TextSpan(
          text: tooltipText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tooltipTextPainter.layout();
      tooltipTextPainter.paint(
        canvas,
        Offset(
          tooltipX + (tooltipWidth - tooltipTextPainter.width) / 2,
          tooltipY + (tooltipHeight - tooltipTextPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MockHorizontalBarsPainter extends CustomPainter {
  final int? hoveredIndex;

  _MockHorizontalBarsPainter({this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // Use same padding as Fleet Activity chart
    const double bottomPad = 18;
    const double leftPad = 8;
    const double rightPad = 30; // Space for y-axis labels
    final double chartHeight = size.height - bottomPad;
    final double chartWidth = size.width - leftPad - rightPad;

    final track = Paint()..color = Colors.grey[200]!;
    final fill1 = Paint()..color = const Color(0xFF9BB5FF); // Light blue
    final fill2 = Paint()..color = const Color(0xFF1E3A8A); // Dark blue
    final fill3 = Paint()..color = const Color(0xFF9BB5FF); // Light blue

    const rows = 3;
    final barHeight = 20.0;
    final spacing = (chartHeight - (rows * barHeight)) / (rows - 1);

    // Static data values (0-100 scale)
    final values = [95, 80, 100];
    final fills = [fill1, fill2, fill3];

    for (int i = 0; i < rows; i++) {
      final top = i * (barHeight + spacing);

      // Background track
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(leftPad, top, chartWidth, barHeight),
          const Radius.circular(10),
        ),
        track,
      );

      // Bar fill
      final factor = values[i] / 100.0;
      final barWidth = chartWidth * factor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(leftPad, top, barWidth, barHeight),
          const Radius.circular(10),
        ),
        fills[i],
      );

      // Y-axis labels (1, 2, 3) - positioned on the right
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width - 15, top + (barHeight - textPainter.height) / 2),
      );
    }

    // X-axis labels (0, 20, 40, 60, 80, 100)
    final xLabels = ['0', '20', '40', '60', '80', '100'];
    for (int i = 0; i < xLabels.length; i++) {
      final x = leftPad + (chartWidth / 5) * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: xLabels[i],
          style: TextStyle(color: Colors.grey[600], fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 12),
      );
    }

    // Tooltip for hovered bar
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < rows) {
      final tooltipWidth = 80.0;
      final tooltipHeight = 40.0;
      final tooltipX = size.width - tooltipWidth - 10;
      final tooltipY =
          spacing + hoveredIndex! * (barHeight + spacing) - tooltipHeight - 5;

      // Tooltip background
      final tooltipPaint = Paint()..color = Colors.grey[800]!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
          const Radius.circular(4),
        ),
        tooltipPaint,
      );

      // Tooltip text
      final tooltipText = TextPainter(
        text: TextSpan(
          text: '${hoveredIndex! + 1}\nPassenger Co',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tooltipText.layout(maxWidth: tooltipWidth);
      tooltipText.paint(
        canvas,
        Offset(
          tooltipX + (tooltipWidth - tooltipText.width) / 2,
          tooltipY + (tooltipHeight - tooltipText.height) / 2,
        ),
      );

      // Tooltip arrow
      final arrowPath = Path();
      arrowPath.moveTo(tooltipX + tooltipWidth, tooltipY + tooltipHeight / 2);
      arrowPath.lineTo(
        tooltipX + tooltipWidth + 5,
        tooltipY + tooltipHeight / 2 - 3,
      );
      arrowPath.lineTo(
        tooltipX + tooltipWidth + 5,
        tooltipY + tooltipHeight / 2 + 3,
      );
      arrowPath.close();
      canvas.drawPath(arrowPath, tooltipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is _MockHorizontalBarsPainter &&
      oldDelegate.hoveredIndex != hoveredIndex;
}

class _HourlyHeatmap extends StatelessWidget {
  final List<int> hours;
  final List<double> hourlyPredictions;

  const _HourlyHeatmap({required this.hours, required this.hourlyPredictions});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HourlyHeatmapPainter(
        hours: hours,
        hourlyPredictions: hourlyPredictions,
      ),
    );
  }
}

class _HourlyHeatmapPainter extends CustomPainter {
  final List<int> hours;
  final List<double> hourlyPredictions;

  _HourlyHeatmapPainter({required this.hours, required this.hourlyPredictions});

  @override
  void paint(Canvas canvas, Size size) {
    // Days of the week (rows)
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    // Hours of the day (columns) - operational hours 4 AM to 8 PM
    final hours = List.generate(17, (index) => 4 + index); // 4 AM to 8 PM

    const double cellWidth = 25.0;
    const double cellHeight = 20.0;
    const double leftPadding = 50.0; // Increased for day labels
    const double topPadding = 25.0; // Increased for hour labels
    const double rightPadding = 10.0; // Add some right padding
    const double bottomPadding = 25.0; // Increased for x-axis labels

    final double availableWidth = size.width - leftPadding - rightPadding;
    final double availableHeight = size.height - topPadding - bottomPadding;

    // Calculate actual cell dimensions - use available width, not fixed width
    final double actualCellWidth = availableWidth / hours.length;
    final double actualCellHeight = availableHeight / days.length;

    // Generate heatmap data based on actual forecast model (7 days x hours)
    final List<List<double>> heatmapData = _generateModelBasedHeatmapData();

    // Find min and max values for color scaling
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;
    for (int day = 0; day < days.length; day++) {
      for (int hour = 0; hour < hours.length; hour++) {
        final value = heatmapData[day][hour];
        if (value < minValue) minValue = value;
        if (value > maxValue) maxValue = value;
      }
    }

    // Draw heatmap cells
    for (int day = 0; day < days.length; day++) {
      for (int hour = 0; hour < hours.length; hour++) {
        final value = heatmapData[day][hour];
        final normalizedValue = (value - minValue) / (maxValue - minValue);

        // Color based on normalized value
        final color = _getHeatmapColor(normalizedValue);
        final paint = Paint()..color = color;

        final x = leftPadding + hour * actualCellWidth;
        final y = topPadding + day * actualCellHeight;

        canvas.drawRect(
          Rect.fromLTWH(x, y, actualCellWidth, actualCellHeight),
          paint,
        );

        // Draw value text if cell is large enough
        if (actualCellWidth > 15 && actualCellHeight > 12) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: value.round().toString(),
              style: TextStyle(
                color: normalizedValue > 0.5 ? Colors.white : Colors.black87,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              x + (actualCellWidth - textPainter.width) / 2,
              y + (actualCellHeight - textPainter.height) / 2,
            ),
          );
        }
      }
    }

    // Draw day labels (left side) with dates (current week starting Sunday)
    final now = DateTime.now();
    final int daysFromSunday = now.weekday % 7; // 0 if Sunday, 6 if Saturday
    final DateTime sunday = now.subtract(Duration(days: daysFromSunday));
    for (int day = 0; day < days.length; day++) {
      final DateTime date = sunday.add(Duration(days: day));
      final String dd = date.day.toString().padLeft(2, '0');
      final String label = '$dd ${days[day]}';

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          5,
          topPadding +
              day * actualCellHeight +
              (actualCellHeight - textPainter.height) / 2,
        ),
      );
    }

    // Draw hour labels (top)
    for (int hour = 0; hour < hours.length; hour++) {
      final hourText = hours[hour] < 12
          ? '${hours[hour]}AM'
          : '${hours[hour] - 12}PM';
      final textPainter = TextPainter(
        text: TextSpan(
          text: hourText,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          leftPadding +
              hour * actualCellWidth +
              (actualCellWidth - textPainter.width) / 2,
          5,
        ),
      );
    }
  }

  List<List<double>> _generateModelBasedHeatmapData() {
    // Generate heatmap data based on actual forecast model
    final List<List<double>> data = [];

    // Create 7 days of data starting from today
    final now = DateTime.now();
    final int daysFromSunday = now.weekday % 7;
    final DateTime sunday = now.subtract(Duration(days: daysFromSunday));

    for (int day = 0; day < 7; day++) {
      final List<double> dayData = [];
      final DateTime currentDate = sunday.add(Duration(days: day));

      // Check if this is today (use actual forecast data) or future days (generate variations)
      if (day == daysFromSunday && hourlyPredictions.isNotEmpty) {
        // Use actual forecast data for today
        for (int hourIndex = 0; hourIndex < hours.length; hourIndex++) {
          if (hourIndex < hourlyPredictions.length) {
            dayData.add(hourlyPredictions[hourIndex]);
          } else {
            // Fallback for missing hours
            dayData.add(20.0);
          }
        }
      } else {
        // Generate variations for other days based on day of week and forecast patterns
        for (int hourIndex = 0; hourIndex < hours.length; hourIndex++) {
          final actualHour = hours[hourIndex];
          double baseValue = 20.0;

          // Use forecast data as base if available, otherwise use patterns
          if (hourIndex < hourlyPredictions.length) {
            baseValue = hourlyPredictions[hourIndex];
          }

          // Apply day-of-week variations
          if (currentDate.weekday == DateTime.sunday ||
              currentDate.weekday == DateTime.saturday) {
            // Weekend: reduce by 20-40%
            baseValue *=
                0.6 + (day * 0.1); // Slight variation between weekend days
          } else {
            // Weekday: slight variations
            baseValue *=
                0.9 + (day * 0.05); // Slight variation between weekdays
          }

          // Add some realistic daily variation (±10%)
          final variation = (day * 7 + hourIndex) % 20 - 10;
          baseValue += baseValue * (variation / 100.0);

          dayData.add(baseValue.clamp(5.0, 150.0));
        }
      }
      data.add(dayData);
    }

    return data;
  }

  Color _getHeatmapColor(double normalizedValue) {
    // Create a color gradient from light blue to dark blue
    if (normalizedValue < 0.2) {
      return const Color(0xFFE3F2FD); // Very light blue
    } else if (normalizedValue < 0.4) {
      return const Color(0xFFBBDEFB); // Light blue
    } else if (normalizedValue < 0.6) {
      return const Color(0xFF90CAF9); // Medium light blue
    } else if (normalizedValue < 0.8) {
      return const Color(0xFF64B5F6); // Medium blue
    } else {
      return const Color(0xFF1E3A8A); // Dark blue
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PeakTimeChartPainter extends CustomPainter {
  final List<int>? hourlyData;
  final int? peakHour;

  _PeakTimeChartPainter({this.hourlyData, this.peakHour});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final pointPaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.fill;

    // Use actual hourly forecast data or fallback to sample data
    List<Offset> points;
    if (hourlyData != null && hourlyData!.isNotEmpty) {
      final maxValue = hourlyData!.reduce((a, b) => a > b ? a : b);
      final scale = maxValue > 0 ? (size.height * 0.8) / maxValue : 1.0;

      points = [];
      for (int i = 0; i < hourlyData!.length; i++) {
        final x = size.width * (i / (hourlyData!.length - 1));
        final y = size.height * 0.9 - (hourlyData![i] * scale);
        points.add(Offset(x, y));
      }
    } else {
      // Fallback sample data
      points = [
        Offset(0, size.height * 0.7),
        Offset(size.width * 0.2, size.height * 0.3),
        Offset(size.width * 0.4, size.height * 0.5),
        Offset(size.width * 0.6, size.height * 0.4),
        Offset(size.width * 0.8, size.height * 0.8),
        Offset(size.width, size.height * 0.9),
      ];
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class _YearlyHeatmap extends StatefulWidget {
  final List<List<double?>> grid; // 12 x 31 with nulls for invalid days
  final int year;
  const _YearlyHeatmap({required this.grid, required this.year});

  @override
  State<_YearlyHeatmap> createState() => _YearlyHeatmapState();
}

class _YearlyHeatmapState extends State<_YearlyHeatmap> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _YearlyHeatmapPainter(
        grid: widget.grid,
        year: widget.year,
      ),
    );
  }
}

class _YearlyHeatmapPainter extends CustomPainter {
  final List<List<double?>> grid; // months x days
  final int year;
  _YearlyHeatmapPainter({
    required this.grid,
    required this.year,
  });

  static const List<String> _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const List<String> _dowLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Layout paddings
    const double leftPad = 36; // for day-of-week labels
    const double topPad = 22; // for month labels
    const double rightPad = 8;
    const double bottomPad = 8;

    final double chartWidth = size.width - leftPad - rightPad;
    final double chartHeight = size.height - topPad - bottomPad;

    const int months = 12;
    const int weeksPerMonth = 5; // fixed 5 columns per month
    final int cols = months * weeksPerMonth; // 60 columns total
    final int rows = 7; // days of week (Sun..Sat)

    // Use square cells: side length is the limiting dimension
    final double cellSize =
        (chartWidth / cols)
                .clamp(0, double.infinity)
                .compareTo(chartHeight / rows) <
            0
        ? chartWidth / cols
        : chartHeight / rows;
    final double cellW = cellSize;
    final double cellH = cellSize;

    // Center the grid within the available chart area
    final double usedWidth = cellW * cols;
    final double usedHeight = cellH * rows;
    final double originX = leftPad + (chartWidth - usedWidth) / 2;
    final double originY = topPad + (chartHeight - usedHeight) / 2;

    // Aggregate provided 12x31 grid into 12 x 5 x 7 (month x week x dow)
    // Prepare accumulators (month-major then week, then dow)
    final sums = List.generate(
      months,
      (_) =>
          List.generate(weeksPerMonth, (_) => List<double>.filled(rows, 0.0)),
    );
    final counts = List.generate(
      months,
      (_) => List.generate(weeksPerMonth, (_) => List<int>.filled(rows, 0)),
    );

    int daysInMonth(int year, int month) {
      final firstNext = month == 12
          ? DateTime(year + 1, 1, 1)
          : DateTime(year, month + 1, 1);
      return firstNext.subtract(const Duration(days: 1)).day;
    }

    final DateTime today = DateTime.now();
    final DateTime todayDate = DateTime(today.year, today.month, today.day);
    for (int m = 0; m < months; m++) {
      final dim = m < grid.length ? grid[m].length : 0; // up to 31
      final maxDay = daysInMonth(year, m + 1);
      final upto = dim < maxDay ? dim : maxDay;
      final firstDow = DateTime(year, m + 1, 1).weekday % 7; // Sun=0..Sat=6
      for (int d = 0; d < upto; d++) {
        final v = grid[m][d]; // day index d = 0..30 (represents day d+1)
        final date = DateTime(year, m + 1, d + 1);
        // Show all dates for the full year forecast
        // if (date.isAfter(todayDate)) continue;
        if (v == null) continue;
        final dow = date.weekday % 7; // Sun=0 .. Sat=6
        // Compute week-of-month column 0..4 based on Sun-start weeks
        final linearIndex = firstDow + d; // offset within a Sun-started grid
        int week = (linearIndex / 7).floor();
        if (week < 0)
          week = 0;
        else if (week >= weeksPerMonth)
          week = weeksPerMonth - 1;
        sums[m][week][dow] += v;
        counts[m][week][dow] += 1;
      }
    }

    // Compute averages and global min/max for color scaling
    double minV = double.infinity;
    double maxV = -double.infinity;
    final avg = List.generate(
      months,
      (m) =>
          List.generate(weeksPerMonth, (w) => List<double?>.filled(rows, null)),
    );
    for (int m = 0; m < months; m++) {
      for (int w = 0; w < weeksPerMonth; w++) {
        for (int r = 0; r < rows; r++) {
          if (counts[m][w][r] > 0) {
            final v = sums[m][w][r] / counts[m][w][r];
            avg[m][w][r] = v;
            if (v < minV) minV = v;
            if (v > maxV) maxV = v;
          }
        }
      }
    }
    if (!minV.isFinite || !maxV.isFinite || (maxV - minV).abs() < 1e-9) {
      minV = 0.0;
      maxV = 1.0;
    }

    // Draw cells (60 columns: 12 months x 5 weeks, 7 rows)
    for (int m = 0; m < months; m++) {
      for (int w = 0; w < weeksPerMonth; w++) {
        final colIndex = m * weeksPerMonth + w;
        for (int r = 0; r < rows; r++) {
          final x = originX + colIndex * cellW;
          final y = originY + r * cellH;
          final rect = Rect.fromLTWH(x, y, cellW, cellH);
          final v = avg[m][w][r];
          if (v == null) {
            final paint = Paint()..color = Colors.grey[100]!;
            canvas.drawRect(rect, paint);
          } else {
            final t = ((v - minV) / (maxV - minV)).clamp(0.0, 1.0);
            final paint = Paint()..color = _heatColor(t);
            canvas.drawRect(rect, paint);
          }
        }
      }
    }

    // Month labels across the top
    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int m = 0; m < months; m++) {
      tp.text = TextSpan(
        text: _monthLabels[m],
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      );
      tp.layout();
      final monthStartX = originX + (m * weeksPerMonth) * cellW;
      final monthCenterX =
          monthStartX + (weeksPerMonth * cellW) / 2 - tp.width / 2;
      tp.paint(canvas, Offset(monthCenterX, originY - tp.height - 4));
    }

    // Day-of-week labels (Sun..Sat) on the left
    for (int r = 0; r < rows; r++) {
      tp.text = TextSpan(
        text: _dowLabels[r],
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      );
      tp.layout();
      final y = originY + r * cellH + (cellH - tp.height) / 2;
      tp.paint(canvas, Offset(originX - tp.width - 6, y));
    }

    // Light grid lines (optional)
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int c = 0; c <= cols; c++) {
      final x = originX + c * cellW;
      canvas.drawLine(
        Offset(x, originY),
        Offset(x, originY + rows * cellH),
        gridPaint,
      );
    }
    for (int d = 0; d <= rows; d++) {
      final y = originY + d * cellH;
      canvas.drawLine(
        Offset(originX, y),
        Offset(originX + cols * cellW, y),
        gridPaint,
      );
    }

    // Thicker separator at month boundaries
    final sepPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.0;
    for (int m = 0; m <= months; m++) {
      final x = originX + (m * weeksPerMonth) * cellW;
      canvas.drawLine(
        Offset(x, originY),
        Offset(x, originY + rows * cellH),
        sepPaint,
      );
    }

  }

  Color _heatColor(double t) {
    // light -> dark blue gradient
    if (t < 0.2) return const Color(0xFFE3F2FD);
    if (t < 0.4) return const Color(0xFFBBDEFB);
    if (t < 0.6) return const Color(0xFF90CAF9);
    if (t < 0.8) return const Color(0xFF64B5F6);
    return const Color(0xFF1E3A8A);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class _PerformanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PerformanceMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
