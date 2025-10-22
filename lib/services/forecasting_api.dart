// lib/services/forecasting_api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

// Resolve localhost across platforms (Android emulator uses 10.0.2.2, web uses 127.0.0.1)
String _host() {
  print('Platform detection: kIsWeb=$kIsWeb, defaultTargetPlatform=$defaultTargetPlatform');
  final bool isAndroid =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  print('isAndroid: $isAndroid');
  
  if (isAndroid) {
    // Try multiple Android emulator hosts
    print('Using Android emulator hosts: 10.0.2.2, 192.168.1.6');
    return '10.0.2.2'; // Will fallback to 192.168.1.6 in the retry logic
  }
  if (kIsWeb) {
    print('Using web host: 127.0.0.1');
    return '127.0.0.1';
  }
  print('Using default host: localhost');
  return 'localhost';
}

// NOTE: Flask is configured to run on 5001 to avoid conflicts
Uri _baseUri(String path) => Uri.parse('http://${_host()}:5001$path');

// Health check (simplified - no logging for performance)
Future<bool> forecastingHealth() async {
  try {
    final uri = _baseUri('/health');
    final res = await http.get(uri).timeout(Duration(seconds: 5));
    return res.statusCode == 200;
  } catch (e) {
    return false;
  }
}

// Test network connectivity with all possible hosts
Future<void> testNetworkConnectivity() async {
  print('=== Testing Network Connectivity ===');
  final hosts = ['127.0.0.1', 'localhost', '10.0.2.2', '192.168.1.6'];
  
  for (final host in hosts) {
    try {
      print('Testing $host:5001...');
      final uri = Uri.parse('http://$host:5001/health');
      final res = await http.get(uri);
      print('✅ $host:5001 - Status: ${res.statusCode}');
      if (res.statusCode == 200) {
        print('✅ $host:5001 is accessible!');
      }
    } catch (e) {
      print('❌ $host:5001 - Error: $e');
    }
  }
  print('=== End Network Test ===');
}

// Peak demand prediction for a single feature set
Future<double> forecastPeak(Map<String, dynamic> features) async {
  final res = await http.post(
    _baseUri('/forecast/peak'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({'features': features}),
  );
  if (res.statusCode != 200) {
    throw Exception('Peak forecast failed: ${res.statusCode} ${res.body}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return (data['prediction'] as num).toDouble();
}

// Get 7-day daily passenger forecast (optimized)
Future<({List<DateTime> dates, List<double> predictions})> forecastDaily() async {
  try {
    final uri = _baseUri('/daily_forecast');
    final res = await http.get(uri).timeout(Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('Daily forecast failed: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final dates = (data['dates'] as List)
        .map((e) => DateTime.parse(e as String))
        .toList();
    final preds = (data['predictions'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    return (dates: dates, predictions: preds);
  } catch (e) {
    print('Error in forecastDaily: $e');
    rethrow;
  }
}

// Get 24-hour hourly forecast with peak detection (optimized)
Future<({List<int> hours, List<double> predictions, int peakHour, double peakValue})> forecastHourly() async {
  // Try multiple hosts as fallback (optimized - less logging)
  final hosts = ['127.0.0.1', 'localhost', '10.0.2.2', '192.168.1.6'];
  Exception? lastException;
  
  for (final host in hosts) {
    try {
      final testUri = Uri.parse('http://$host:5001/hourly_forecast');
      final res = await http.get(testUri).timeout(Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final hours = (data['hours'] as List).map((e) => e as int).toList();
        final preds = (data['predictions'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
        final peakHour = data['peak_hour'] as int;
        final peakValue = (data['peak_value'] as num).toDouble();
        return (hours: hours, predictions: preds, peakHour: peakHour, peakValue: peakValue);
      } else {
        lastException = Exception('Hourly forecast failed: ${res.statusCode}');
      }
    } catch (e) {
      lastException = Exception('Network error with $host: $e');
    }
  }
  
  // If all hosts failed, throw the last exception
  throw lastException ?? Exception('All hosts failed');
}

// Get yearly daily forecast grid (12 x 31)
Future<({int year, List<List<double?>> grid})> forecastYearlyDaily(int year) async {
  final res = await http.get(_baseUri('/yearly_daily?year=$year'));
  if (res.statusCode != 200) {
    throw Exception('Yearly forecast failed: ${res.statusCode} ${res.body}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final int yr = data['year'] as int;
  final List<dynamic> rawGrid = data['grid'] as List<dynamic>;
  // Convert dynamic -> List<List<double?>> with nulls preserved
  final List<List<double?>> grid = rawGrid
      .map<List<double?>>((row) => (row as List<dynamic>)
          .map<double?>((e) => e == null ? null : (e as num).toDouble())
          .toList())
      .toList();
  return (year: yr, grid: grid);
}

// Convenience: compute per-hour predictions (0..23) and return the peak hour
  Future<({int hour, double value, List<double> byHour})> forecastPeakHour(
    {required int dayOfWeek,
    required int month,
    required bool isWeekend,
    double weatherTemp = 30}) async {
  final List<double> byHour = [];
  for (int h = 0; h < 24; h++) {
    final features = {
      'hour': h,
      'weekday': dayOfWeek,
      'is_holiday': 0, // Assume no holiday for now
      'daily_trend': h / 24.0, // Normalized hour as trend
    };
    byHour.add(await forecastPeak(features));
  }
  int peakHour = 0;
  double peakVal = byHour[0];
  for (int i = 1; i < byHour.length; i++) {
    if (byHour[i] > peakVal) {
      peakVal = byHour[i];
      peakHour = i;
    }
  }
  return (hour: peakHour, value: peakVal, byHour: byHour);
}

