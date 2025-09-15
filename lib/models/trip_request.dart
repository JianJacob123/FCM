class TripRequest {
  final String passengerId;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;

  TripRequest({
    required this.passengerId,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
  });

  Map<String, dynamic> toJson() {
    return {
      "passenger_id": passengerId,
      "pickup_lat": pickupLat,
      "pickup_lng": pickupLng,
      "dropoff_lat": dropoffLat,
      "dropoff_lng": dropoffLng,
    };
  }
}
