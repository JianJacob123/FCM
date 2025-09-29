class TripRequest {
  final String passengerId;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final int routeId;

  TripRequest({
    required this.passengerId,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.routeId,
  });

  Map<String, dynamic> toJson() {
    return {
      "passenger_id": passengerId,
      "pickup_lat": pickupLat,
      "pickup_lng": pickupLng,
      "dropoff_lat": dropoffLat,
      "dropoff_lng": dropoffLng,
      "route_id": routeId,
    };
  }
}
