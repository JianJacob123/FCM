import 'package:latlong2/latlong.dart';

bool isPointNearPolyline(
  LatLng point,
  List<LatLng> polyline, {
  double tolerance = 50,
}) {
  final Distance distance = const Distance();

  for (final vertex in polyline) {
    final d = distance(point, vertex); // haversine distance (meters)
    if (d <= tolerance) return true;
  }

  return false;
}
