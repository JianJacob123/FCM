// lib/services/forecasting_api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Get forecasting API base URL from environment or fallback to localhost
String? _forecastingBaseUrl;

String _getForecastingBaseUrl() {
  // Return cached value if already set
  if (_forecastingBaseUrl != null) {
    return _forecastingBaseUrl!;
  }

  // Production URL for Render deployment
  const String productionUrl = 'https://forecasting-lsio.onrender.com';

  // Try to get from environment variable (highest priority)
  final envUrl = dotenv.env['FORECASTING_API_URL'];
  if (envUrl != null && envUrl.isNotEmpty) {
    _forecastingBaseUrl = envUrl.endsWith('/')
        ? envUrl.substring(0, envUrl.length - 1)
        : envUrl;
    print('Using Forecasting API URL from environment: $_forecastingBaseUrl');
    return _forecastingBaseUrl!;
  }

  // Check if we should force localhost (for local development)
  final useLocalhost = dotenv.env['USE_LOCAL_FORECASTING'] == 'true';
  if (useLocalhost) {
    // Force localhost for local development
    String host;
    if (defaultTargetPlatform == TargetPlatform.android) {
      host = '10.0.2.2'; // Android emulator
    } else if (kIsWeb) {
      host = '127.0.0.1';
    } else {
      host = 'localhost';
    }
    _forecastingBaseUrl = 'http://$host:5001';
    print('Using localhost Forecasting API (forced): $_forecastingBaseUrl');
    return _forecastingBaseUrl!;
  }

  // Default: Always use Render production URL
  _forecastingBaseUrl = productionUrl;
  print('Using production Forecasting API (Render): $_forecastingBaseUrl');
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
// Generic exponential backoff retry helper
Future<T> _retryWithBackoff<T>(Future<T> Function() action,
    {int maxAttempts = 3, Duration initialDelay = const Duration(seconds: 1)}) async {
  int attempt = 0;
  Duration delay = initialDelay;
  while (true) {
    attempt += 1;
    try {
      return await action();
    } catch (e) {
      if (attempt >= maxAttempts) rethrow;
      await Future.delayed(delay);
      delay = Duration(milliseconds: (delay.inMilliseconds * 2));
      if (delay.inSeconds > 8) {
        delay = const Duration(seconds: 8);
      }
    }
  }
}

Future<void> _saveCache(String key, String json) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json);
    await prefs.setInt('${key}_ts', DateTime.now().millisecondsSinceEpoch);
  } catch (_) {}
}

Future<String?> _loadCache(String key, {Duration maxAge = const Duration(hours: 24)}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('${key}_ts');
    if (ts == null) return prefs.getString(key);
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age <= maxAge.inMilliseconds) {
      return prefs.getString(key);
    }
    return null;
  } catch (_) {
    return null;
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
  try {
    final res = await _retryWithBackoff(() async {
      return await http
          .post(
            _baseUri('/forecast/peak'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'features': features}),
          )
          .timeout(const Duration(seconds: 25));
    });
    if (res.statusCode != 200) {
      throw Exception('Peak forecast failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['prediction'] as num).toDouble();
  } catch (e) {
    print('Error in forecastPeak: $e');
    rethrow;
  }
}

// Get 7-day daily passenger forecast (optimized)
Future<({List<DateTime> dates, List<double> predictions})>
forecastDaily() async {
  try {
    const cacheKey = 'daily_forecast_cache_v1';
    final uri = _baseUri('/daily_forecast');
    final res = await _retryWithBackoff(() async {
      return await http.get(uri).timeout(const Duration(seconds: 25));
    });
    if (res.statusCode != 200) {
      throw Exception('Daily forecast failed: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    // Save cache
    _saveCache(cacheKey, res.body);
    final dates = (data['dates'] as List)
        .map((e) => DateTime.parse(e as String))
        .toList();
    final preds = (data['predictions'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    return (dates: dates, predictions: preds);
  } catch (e) {
    print('Error in forecastDaily: $e');
    // Try cache fallback
    final cached = await _loadCache('daily_forecast_cache_v1');
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final dates = (data['dates'] as List)
            .map((e) => DateTime.parse(e as String))
            .toList();
        final preds = (data['predictions'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
        return (dates: dates, predictions: preds);
      } catch (_) {}
    }
    rethrow;
  }
}

// Get 24-hour hourly forecast with peak detection (optimized)
Future<
  ({List<int> hours, List<double> predictions, int peakHour, double peakValue})
>
forecastHourly() async {
  try {
    const cacheKey = 'hourly_forecast_cache_v1';
    final uri = _baseUri('/hourly_forecast');
    final res = await _retryWithBackoff(() async {
      return await http.get(uri).timeout(const Duration(seconds: 25));
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _saveCache(cacheKey, res.body);
      final hours = (data['hours'] as List).map((e) => e as int).toList();
      final preds = (data['predictions'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
      final peakHour = data['peak_hour'] as int;
      final peakValue = (data['peak_value'] as num).toDouble();
      return (
        hours: hours,
        predictions: preds,
        peakHour: peakHour,
        peakValue: peakValue,
      );
    } else {
      throw Exception('Hourly forecast failed: ${res.statusCode}');
    }
  } catch (e) {
    print('Error in forecastHourly: $e');
    final cached = await _loadCache('hourly_forecast_cache_v1');
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final hours = (data['hours'] as List).map((e) => e as int).toList();
        final preds = (data['predictions'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
        final peakHour = data['peak_hour'] as int;
        final peakValue = (data['peak_value'] as num).toDouble();
        return (
          hours: hours,
          predictions: preds,
          peakHour: peakHour,
          peakValue: peakValue,
        );
      } catch (_) {}
    }
    rethrow;
  }
}

// Get yearly daily forecast grid (12 x 31)
Future<({int year, List<List<double?>> grid})> forecastYearlyDaily(int year) async {
  try {
    final uri = _baseUri('/yearly_daily?year=$year');
    final cacheKey = 'yearly_daily_${year}_v1';
    final res = await _retryWithBackoff(() async {
      return await http.get(uri).timeout(const Duration(seconds: 25));
    });
    if (res.statusCode != 200) {
      throw Exception('Yearly forecast failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _saveCache(cacheKey, res.body);
    final int yr = data['year'] as int;
    final List<dynamic> rawGrid = data['grid'] as List<dynamic>;
    // Convert dynamic -> List<List<double?>> with nulls preserved
    final List<List<double?>> grid = rawGrid
        .map<List<double?>>((row) => (row as List<dynamic>)
            .map<double?>((e) => e == null ? null : (e as num).toDouble())
            .toList())
        .toList();
    return (year: yr, grid: grid);
  } catch (e) {
    print('Error in forecastYearlyDaily: $e');
    final cached = await _loadCache('yearly_daily_${year}_v1');
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final int yr = data['year'] as int;
        final List<dynamic> rawGrid = data['grid'] as List<dynamic>;
        final List<List<double?>> grid = rawGrid
            .map<List<double?>>((row) => (row as List<dynamic>)
                .map<double?>((e) => e == null ? null : (e as num).toDouble())
                .toList())
            .toList();
        return (year: yr, grid: grid);
      } catch (_) {}
    }
    rethrow;
  }
}

// Convenience: compute per-hour predictions (0..23) and return the peak hour
Future<({int hour, double value, List<double> byHour})> forecastPeakHour({
  required int dayOfWeek,
  required int month,
  required bool isWeekend,
  double weatherTemp = 30,
}) async {
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
