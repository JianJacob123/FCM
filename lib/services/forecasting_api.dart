// lib/services/forecasting_api.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

/// Returns the correct host for reaching a local service depending on platform.
String _flaskHost() {
  final bool isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  return isAndroid ? '10.0.2.2' : 'localhost';
}

Uri _forecastUri() => Uri.parse('http://${_flaskHost()}:5001/forecast');

/// Calls the Flask demand forecasting service with a 2D list of features.
/// Each inner list must match the model's expected feature order and length.
Future<List<dynamic>> fetchForecasts(List<List<dynamic>> features, {List<String>? columns}) async {
  final response = await http.post(
    _forecastUri(),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode(
      columns != null && columns.isNotEmpty
          ? {'columns': columns, 'features': features}
          : {'features': features},
    ),
  );

  if (response.statusCode != 200) {
    throw Exception('Forecast failed: ${response.statusCode} ${response.body}');
  }

  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  return (decoded['predictions'] as List<dynamic>);
}


