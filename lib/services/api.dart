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

Future<List<dynamic>> fetchTripHistory(String userId) async {
  final response = await http.get(
    Uri.parse(
      "http://localhost:8080/passengerTrips/getCompletedTrips/?id=$userId",
    ),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load trip history");
  }
}

Future<List<dynamic>> fetchFavoriteLocations(String userId) async {
  final response = await http.get(
    Uri.parse("http://localhost:8080/favLocations/getFavLocation/?id=$userId"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load favorite locations");
  }
}

Future<List<dynamic>> fetchPendingTrips() async {
  final response = await http.get(
    Uri.parse("http://localhost:8080/passengerTrips/fetchPendingTrips"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load passengerPickups");
  }
}

Future<void> addLocation(String userId, double lat, double lng) async {
  final url = Uri.parse('http://localhost:8080/favLocations/addFavLocation');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"passenger_id": userId, "lat": lat, "lng": lng}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('Location added: $data');
    } else {
      print('Failed: ${response.statusCode}');
      print('Response Body: ${response.body}');
    }
  } catch (e) {
    print('Error sending request: $e');
  }
}
