import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ConductorScreen extends StatefulWidget {
  const ConductorScreen({super.key});

  @override
  State<ConductorScreen> createState() => _ConductorScreenState();
}

class _ConductorScreenState extends State<ConductorScreen> {
  bool _isActive = true;
  int _currentPassengers = 0;
  final int _maxPassengers = 20;
  final String _currentRoute = 'Lucena - SM City';

  final List<Map<String, dynamic>> _passengerList = [
    {
      'name': 'John Doe',
      'destination': 'SM City Lucena',
      'status': 'confirmed',
    },
    {
      'name': 'Jane Smith',
      'destination': 'Lucena Grand Terminal',
      'status': 'waiting',
    },
    {
      'name': 'Mike Johnson',
      'destination': 'Quezon Provincial Capitol',
      'status': 'confirmed',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentPassengers = _passengerList
        .where((p) => p['status'] == 'confirmed')
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(13.955785338622102, 121.16551093159686),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: LatLng(13.955785338622102, 121.16551093159686),
                    child: Icon(
                      Icons.directions_bus,
                      color: const Color.fromRGBO(62, 71, 149, 1),
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color.fromRGBO(62, 71, 149, 1),
                    child: Icon(Icons.directions_bus, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conductor: ${user?.name ?? 'Driver'}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Vehicle: ${user?.vehicleId ?? 'VEH001'}',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeColor: const Color.fromRGBO(62, 71, 149, 1),
                  ),
                ],
              ),
            ),
          ),

          // Status Panel
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isActive ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Passengers',
                          '$_currentPassengers/$_maxPassengers',
                          Icons.people,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          'Route',
                          _currentRoute,
                          Icons.route,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Passenger List
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(62, 71, 149, 1),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Passenger List (${_passengerList.length})',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(8),
                      itemCount: _passengerList.length,
                      itemBuilder: (context, index) {
                        final passenger = _passengerList[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  passenger['status'] == 'confirmed'
                                  ? Colors.green
                                  : Colors.orange,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(passenger['name']),
                            subtitle: Text(passenger['destination']),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: passenger['status'] == 'confirmed'
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                passenger['status'].toUpperCase(),
                                style: TextStyle(
                                  color: passenger['status'] == 'confirmed'
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Navigation
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.dashboard, 'Dashboard', true),
                  _buildNavItem(Icons.people, 'Passengers', false),
                  _buildNavItem(Icons.route, 'Routes', false),
                  _buildNavItem(
                    Icons.logout,
                    'Logout',
                    false,
                    onTap: () => context.read<UserProvider>().logout(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color.fromRGBO(62, 71, 149, 1)),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive
                ? const Color.fromRGBO(62, 71, 149, 1)
                : Colors.grey,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? const Color.fromRGBO(62, 71, 149, 1)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
