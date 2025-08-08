import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapboxService {
  // Centralized access token
  static const String _accessToken = 'YOUR_MAPBOX_ACCESS_TOKEN_HERE';

  // Get place name from coordinates
  static Future<String> getPlaceNameFromCoordinates(LatLng location) async {
    final url = Uri.parse(
      'https://api.mapbox.com/search/geocode/v6/reverse'
      '?longitude=${location.longitude}&latitude=${location.latitude}'
      '&access_token=$_accessToken',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        if (features.isNotEmpty) {
          final props = features[0]['properties'];
          return props['name'] ?? props['full_address'] ?? 'Unnamed location';
        }
      }
    } catch (e) {
      print('Geocoding error: $e');
    }

    return 'Unknown location';
  }
}
