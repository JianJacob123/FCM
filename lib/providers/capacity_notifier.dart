import 'package:flutter/foundation.dart';

class VehicleCapacityNotifier extends ValueNotifier<int> {
  VehicleCapacityNotifier() : super(0);

  void updateCapacity(int passengerCount) {
    value = passengerCount;
  }

  void clear() {
    value = 0;
  }
}

// Global instance
final vehicleCapacityNotifier = VehicleCapacityNotifier();
