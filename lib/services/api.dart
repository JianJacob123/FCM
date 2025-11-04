// lib/services/api.dart
import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/trip_request.dart';

final baseUrl = dotenv.env['API_BASE_URL'];

//Fetch Activity Logs
Future<List<dynamic>> fetchActivityLogs() async {
  final response = await http.get(
    Uri.parse("$baseUrl/activityLogs/fetchActivityLogs"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load activity logs");
  }
}

Future<List<dynamic>> fetchNotifications(String recipient) async {
  final response = await http.get(
    Uri.parse("$baseUrl/notifications/getNotifications?recipient=$recipient"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load notifications");
  }
}

Future<List<dynamic>> fetchTripHistory(String userId) async {
  final response = await http.get(
    Uri.parse("$baseUrl/passengerTrips/getCompletedTrips/?id=$userId"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load trip history");
  }
}

Future<Map<String, dynamic>?> fetchActiveTrips(String userId) async {
  final response = await http.get(
    Uri.parse("$baseUrl/passengerTrips/fetchActiveTrip/?id=$userId"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load fetch active trips");
  }
}

Future<Map<String, dynamic>> fetchTripDetails(String userId) async {
  //For Conductor Trip Details
  final response = await http.get(
    Uri.parse("$baseUrl/trips/trip-count?id=$userId"),
  );

  if (response.statusCode == 200) {
    final tripData = jsonDecode(response.body);
    return tripData;
  } else {
    throw Exception("Failed to load trip details");
  }
}

Future<List<dynamic>> fetchFavoriteLocations(String userId) async {
  final response = await http.get(
    Uri.parse("$baseUrl/favLocations/getFavLocation/?id=$userId"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load favorite locations");
  }
}

Future<List<dynamic>> fetchPendingTrips() async {
  final response = await http.get(
    Uri.parse("$baseUrl/passengerTrips/fetchPendingTrips"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load passengerPickups");
  }
}

Future<void> createRequest(TripRequest trip) async {
  final url = Uri.parse('$baseUrl/passengerTrips/createRequest');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "passengerId": trip.passengerId,
        "pickupLat": trip.pickupLat,
        "pickupLng": trip.pickupLng,
        "dropoffLat": trip.dropoffLat,
        "dropoffLng": trip.dropoffLng,
        "routeId": trip.routeId,
      }),
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

Future<void> addLocation(String userId, double lat, double lng) async {
  final url = Uri.parse('$baseUrl/favLocations/addFavLocation');

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

Future<void> createNotification(
  String title,
  String type,
  String content,
  String date,
  String recipient,
) async {
  final url = Uri.parse('$baseUrl/notifications/createNotification');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "notif_title": title,
        "notif_type": type,
        "content": content,
        "notif_date": date,
        "notif_recipient": recipient,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('Notification created: $data');
    } else {
      print('Failed: ${response.statusCode}');
      print('Response Body: ${response.body}');
    }
  } catch (e) {
    print('Error sending request: $e');
  }
}

Future<Map<String, dynamic>> fetchAdminTrips({
  int page = 1,
  int limit = 50,
}) async {
  final response = await http.get(
    Uri.parse("$baseUrl/trips/api/admin/trips?page=$page&limit=$limit"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load admin trips");
  }
}
