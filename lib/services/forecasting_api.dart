// lib/services/forecasting_api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Get forecasting API base URL from environment or fallback to localhost
String? _forecastingBaseUrl;

String _getForecastingBaseUrl() {
  // Return cached value if already set
  if (_forecastingBaseUrl != null) {
    return _forecastingBaseUrl!;
  }

  // Production URL for Render deployment
  const String productionUrl = 'https://forecasting-lsio.onrender.com';

  // Try to get from environment variable (for Render deployment)
  final envUrl = dotenv.env['FORECASTING_API_URL'];
  if (envUrl != null && envUrl.isNotEmpty) {
    _forecastingBaseUrl = envUrl.endsWith('/') 
        ? envUrl.substring(0, envUrl.length - 1) 
        : envUrl;
    print('Using Forecasting API URL from environment: $_forecastingBaseUrl');
    return _forecastingBaseUrl!;
  }

  // For web builds, use production URL if not in localhost
  if (kIsWeb) {
    // Check if we're running on localhost (development)
    final hostname = Uri.base.host;
    final isLocalhost = hostname == 'localhost' || 
                        hostname == '127.0.0.1' || 
                        hostname.isEmpty ||
                        hostname.startsWith('localhost:') ||
                        hostname.startsWith('127.0.0.1:');
    
    if (isLocalhost) {
      _forecastingBaseUrl = 'http://127.0.0.1:5001';
      print('Using localhost Forecasting API (web dev): $_forecastingBaseUrl');
    } else {
      // Production web deployment - use Render URL
      // This includes Render domains like fcm-server-1-z87w.onrender.com
      _forecastingBaseUrl = productionUrl;
      print('Using production Forecasting API (web): $_forecastingBaseUrl (detected hostname: $hostname)');
    }
    return _forecastingBaseUrl!;
  }

  // Fallback to localhost for development (mobile/desktop)
  String host;
  if (defaultTargetPlatform == TargetPlatform.android) {
    host = '10.0.2.2'; // Android emulator
  } else {
    host = 'localhost';
  }
  
  _forecastingBaseUrl = 'http://$host:5001';
  print('Using localhost Forecasting API: $_forecastingBaseUrl');
  return _forecastingBaseUrl!;
}

// Build URI for forecasting API
Uri _baseUri(String path) {
  final baseUrl = _getForecastingBaseUrl();
  final cleanPath = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$baseUrl$cleanPath');
}

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

// Test network connectivity to forecasting API
Future<void> testNetworkConnectivity() async {
  print('=== Testing Forecasting API Connectivity ===');
  final baseUrl = _getForecastingBaseUrl();
  try {
    print('Testing $baseUrl/health...');
    final uri = Uri.parse('$baseUrl/health');
    final res = await http.get(uri).timeout(Duration(seconds: 5));
    print('✅ $baseUrl - Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      print('✅ Forecasting API is accessible!');
    }
  } catch (e) {
    print('❌ $baseUrl - Error: $e');
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
  try {
    final uri = _baseUri('/hourly_forecast');
    final res = await http.get(uri).timeout(Duration(seconds: 8));
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
      throw Exception('Hourly forecast failed: ${res.statusCode}');
    }
  } catch (e) {
    print('Error in forecastHourly: $e');
    rethrow;
  }
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

