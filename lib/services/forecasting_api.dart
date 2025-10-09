// lib/services/forecasting_api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

// Resolve localhost across platforms (Android emulator uses 10.0.2.2)
String _host() {
  final bool isAndroid =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  return isAndroid ? '10.0.2.2' : 'localhost';
}

// NOTE: Flask is configured to run on 5001 to avoid conflicts
Uri _baseUri(String path) => Uri.parse('http://${_host()}:5001$path');

// Health check
Future<bool> forecastingHealth() async {
  final res = await http.get(_baseUri('/health'));
  return res.statusCode == 200;
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

// Get 7-day daily passenger forecast
Future<({List<DateTime> dates, List<double> predictions})> forecastDaily() async {
  final res = await http.get(_baseUri('/daily_forecast'));
  if (res.statusCode != 200) {
    throw Exception('Daily forecast failed: ${res.statusCode} ${res.body}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final dates = (data['dates'] as List)
      .map((e) => DateTime.parse(e as String))
      .toList();
  final preds = (data['predictions'] as List)
      .map((e) => (e as num).toDouble())
      .toList();
  return (dates: dates, predictions: preds);
}

// Get 24-hour hourly forecast with peak detection
Future<({List<int> hours, List<double> predictions, int peakHour, double peakValue})> forecastHourly() async {
  final res = await http.get(_baseUri('/hourly_forecast'));
  if (res.statusCode != 200) {
    throw Exception('Hourly forecast failed: ${res.statusCode} ${res.body}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final hours = (data['hours'] as List).map((e) => e as int).toList();
  final preds = (data['predictions'] as List)
      .map((e) => (e as num).toDouble())
      .toList();
  final peakHour = data['peak_hour'] as int;
  final peakValue = (data['peak_value'] as num).toDouble();
  return (hours: hours, predictions: preds, peakHour: peakHour, peakValue: peakValue);
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

