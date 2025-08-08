import 'package:latlong2/latlong.dart';

bool isWithinGeofence({
  required LatLng point,
  required LatLng center,
  required double radiusInMeters,
}) {
  final Distance distance = Distance();
  final double distanceInMeters = distance.as(LengthUnit.Meter, center, point);
  return distanceInMeters <= radiusInMeters;
}
