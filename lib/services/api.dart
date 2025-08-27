// lib/services/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<dynamic>> fetchNotifications() async {
  final response = await http.get(
    Uri.parse("http://localhost:8080/notifications/getNotifications"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load notifications");
  }
}
