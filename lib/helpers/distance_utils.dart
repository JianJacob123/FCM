import 'package:latlong2/latlong.dart';

bool isNearRoute(
  LatLng pinnedLocation,
  List<LatLng> routePoints, {
  double maxDistance = 300,
}) {
  final Distance distance = Distance();

  for (final point in routePoints) {
    final double meters = distance.as(LengthUnit.Meter, pinnedLocation, point);
    if (meters <= maxDistance) {
      return true;
    }
  }
  return false;
}
