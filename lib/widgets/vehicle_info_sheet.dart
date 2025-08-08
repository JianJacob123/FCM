import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class VehicleInfoSheet extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onTrackPressed;

  const VehicleInfoSheet({
    super.key,
    required this.onClose,
    required this.onTrackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 260),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FCM No. 05',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E4795),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Plate No: DAL 7674', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          const Text(
            'Bauan City → Lipa City Terminal',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Estimated Time of Arrival',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                '8:30 AM',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Current Location',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                'Lalayat San Jose',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Driver's Name",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Nelson Suarez',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onTrackPressed,
                icon: const Icon(Icons.navigation, size: 16),
                label: const Text('Track Trip', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E4795),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
