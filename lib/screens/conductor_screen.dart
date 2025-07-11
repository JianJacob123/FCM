import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/login_screen.dart';
import 'dart:math';
import 'package:geocoding/geocoding.dart';

class ConductorScreen extends StatefulWidget {
  const ConductorScreen({super.key});

  @override
  State<ConductorScreen> createState() => _ConductorScreenState();
}

class _ConductorScreenState extends State<ConductorScreen> {
  int _currentIndex = 2;
  bool _showStatusCard = true;

  final List<Widget> _screens = const [
    NotificationsTab(),
    PassengerPickupTab(),
    DashboardTab(),
    MessagingTab(),
    ProfileTab(),
  ];  

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),

          if (_showStatusCard && _currentIndex == 2)
            Positioned(
              bottom: 90,
              left: 16,
              child: GestureDetector(
                onHorizontalDragEnd: (_) => setState(() => _showStatusCard = false),
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Bus Capacity',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3E4795),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showStatusCard = false),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 20,
                            color: Color(0xFF3E4795),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '2 passengers onboard',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_bus,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '18 seats available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!_showStatusCard && _currentIndex == 2)
            Positioned(
              bottom: 80,
              left: 16,
              child: GestureDetector(
                onTap: () => setState(() => _showStatusCard = true),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '2/20',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E4795),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      // Replace default BottomNavigationBar with custom one
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}

// Custom bottom bar for ConductorScreen, styled like PassengerScreen's CustomBottomBar
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_outlined,
              color: Color(0xFF3E4795),
              size: 36,
            ),
            onPressed: () => onTabChanged(0),
          ),
          IconButton(
            icon: Icon(
              Icons.group,
              color: Color(0xFF3E4795),
              size: 36,
            ),
            onPressed: () => onTabChanged(1),
          ),
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Color(0xFF3E4795),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.location_on, color: Colors.white, size: 40),
              onPressed: () => onTabChanged(2),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.message_outlined,
              color: Color(0xFF3E4795),
              size: 36,
            ),
            onPressed: () => onTabChanged(3),
          ),
          IconButton(
            icon: Icon(
              Icons.person_outline,
              color: Color(0xFF3E4795),
              size: 36,
            ),
            onPressed: () => onTabChanged(4),
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Bus location (current position)
  final LatLng busLocation = LatLng(13.7850, 121.0890); // San Jose

  // Route points following main roads (Bauan → San Jose → Lipa)
  final List<LatLng> routePoints = [
    LatLng(13.8000, 121.0500), // Bauan
    LatLng(13.7900, 121.0700), // Route point
    LatLng(13.7850, 121.0890), // San Jose (current bus position)
    LatLng(13.7800, 121.1000), // Route point
    LatLng(13.7750, 121.1100), // Route point
    LatLng(13.7700, 121.1200), // Route point
    LatLng(13.7650, 121.1300), // Route point
    LatLng(13.7600, 121.1400), // Route point
    LatLng(13.7550, 121.1500), // Route point
    LatLng(13.7500, 121.1600), // Lipa
  ];

  // Passenger pickup locations along the main road route
  final List<Map<String, dynamic>> passengers = [
    {
      'location': LatLng(13.7800, 121.1000),
      'address': 'San Jose Main St.',
      'passengers': 2,
      'waitingTime': '3 min',
    },
    {
      'location': LatLng(13.7700, 121.1200),
      'address': 'Lipa City Center',
      'passengers': 1,
      'waitingTime': '8 min',
    },
    {
      'location': LatLng(13.7550, 121.1500),
      'address': 'Lipa Terminal',
      'passengers': 3,
      'waitingTime': '12 min',
    },
  ];

  LatLng? selectedPassengerLocation;
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Simple distance calculation (in real app, use proper geolocation formulas)
    const double earthRadius = 6371; // km
    double lat1 = point1.latitude * (pi / 180);
    double lat2 = point2.latitude * (pi / 180);
    double deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
    double deltaLon = (point2.longitude - point1.longitude) * (pi / 180);

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  int _calculateETA(double distance) {
    // Assuming average speed of 30 km/h
    return (distance / 30 * 60).round();
  }

  void _showPassengerDetails(Map<String, dynamic> passenger) {
    double distance = _calculateDistance(busLocation, passenger['location']);
    int eta = _calculateETA(distance);

    setState(() {
      selectedPassengerLocation = passenger['location'];
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 90,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Close in one row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        passenger['address'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E4795),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          selectedPassengerLocation = null;
                        });
                      },
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Details
                _buildDetailRow('Location', '${passenger['location'].latitude.toStringAsFixed(4)}, ${passenger['location'].longitude.toStringAsFixed(4)}'),
                _buildDetailRow('Distance', '${distance.toStringAsFixed(1)} km'),
                _buildDetailRow('ETA', '$eta minutes'),
                _buildDetailRow('Passengers', '${passenger['passengers']} person(s)'),
                _buildDetailRow('Waiting Time', passenger['waitingTime']),
                const SizedBox(height: 20),
                // Okay Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        selectedPassengerLocation = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E4795),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Okay'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<LatLng> _getRouteToPassenger(LatLng passengerLocation) {
    // Find the route points between bus location and passenger
    List<LatLng> routeToPassenger = [];
    
    // Start from bus location
    routeToPassenger.add(busLocation);
    
    // Add route points that are between bus and passenger
    for (int i = 0; i < routePoints.length - 1; i++) {
      LatLng currentPoint = routePoints[i];
      LatLng nextPoint = routePoints[i + 1];
      
      // Check if this segment is between bus and passenger
      if (_isPointBetween(currentPoint, busLocation, passengerLocation) ||
          _isPointBetween(nextPoint, busLocation, passengerLocation)) {
        routeToPassenger.add(currentPoint);
        routeToPassenger.add(nextPoint);
      }
    }
    
    // Add passenger location
    routeToPassenger.add(passengerLocation);
    
    return routeToPassenger;
  }

  bool _isPointBetween(LatLng point, LatLng start, LatLng end) {
    // Check if point is between start and end points
    double startToPoint = _calculateDistance(start, point);
    double pointToEnd = _calculateDistance(point, end);
    double startToEnd = _calculateDistance(start, end);
    
    // Allow some tolerance for route points
    return (startToPoint + pointToEnd - startToEnd).abs() < 0.1;
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    // Add some local places as fallback
    List<Map<String, dynamic>> localPlaces = [
      {
        'name': 'Bauan Public Market',
        'address': 'Bauan, Batangas',
        'location': LatLng(13.8000, 121.0500),
      },
      {
        'name': 'San Jose Municipal Hall',
        'address': 'San Jose, Batangas',
        'location': LatLng(13.7850, 121.0890),
      },
      {
        'name': 'Lipa City Hall',
        'address': 'Lipa City, Batangas',
        'location': LatLng(13.7500, 121.1600),
      },
      {
        'name': 'Robinsons Lipa',
        'address': 'Lipa City, Batangas',
        'location': LatLng(13.7550, 121.1500),
      },
      {
        'name': 'SM Lipa',
        'address': 'Lipa City, Batangas',
        'location': LatLng(13.7600, 121.1400),
      },
    ];

    // Filter local places based on query
    List<Map<String, dynamic>> filteredLocalPlaces = localPlaces
        .where((place) => place['name'].toLowerCase().contains(query.toLowerCase()) ||
                         place['address'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    try {
      // Try to search for locations using the query
      List<Location> locations = await locationFromAddress(query);
      List<Map<String, dynamic>> results = [];
      
      // Add local places first
      results.addAll(filteredLocalPlaces);
      
      // Add online search results
      for (Location location in locations.take(3)) { // Limit to 3 online results
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            Placemark placemark = placemarks.first;
            String address = [
              placemark.street,
              placemark.subLocality,
              placemark.locality,
              placemark.administrativeArea,
            ].where((element) => element != null && element.isNotEmpty).join(', ');
            
            results.add({
              'name': placemark.name ?? placemark.street ?? 'Unknown Location',
              'address': address.isNotEmpty ? address : 'Location found',
              'location': LatLng(location.latitude, location.longitude),
            });
          }
        } catch (e) {
          // If placemark lookup fails, still add the location
          results.add({
            'name': 'Location at ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            'address': 'Coordinates found',
            'location': LatLng(location.latitude, location.longitude),
          });
        }
      }
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Search error: $e');
      // If online search fails, show local places
      setState(() {
        _searchResults = filteredLocalPlaces;
        _isSearching = false;
      });
    }
  }

  void _onSearchResultSelected(Map<String, dynamic> result) {
    _searchController.text = result['name'];
    setState(() {
      _showSearchResults = false;
    });
    
    // Show a dialog with the selected location
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${result['address']}'),
            const SizedBox(height: 8),
            Text('Coordinates: ${result['location'].latitude.toStringAsFixed(4)}, ${result['location'].longitude.toStringAsFixed(4)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Location selected: ${result['name']}'),
                  backgroundColor: const Color(0xFF3E4795),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3E4795),
            ),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E4795),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(13.7850, 121.0890),
            initialZoom: 13.0,
            interactiveFlags: InteractiveFlag.all,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: ['a', 'b', 'c', 'd'],
            ),
            // Bus marker
            MarkerLayer(
              markers: [
                Marker(
                  point: busLocation,
                  width: 50,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            // Passenger markers
            MarkerLayer(
              markers: passengers.map((passenger) {
                return Marker(
                  point: passenger['location'],
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showPassengerDetails(passenger),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E4795).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Color(0xFF3E4795),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Search for places...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        onChanged: (value) {
                          print('Search query: $value'); // Debug print
                          if (value.length > 2) {
                            _searchPlaces(value);
                          } else {
                            setState(() {
                              _showSearchResults = false;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              // Search results dropdown
              if (_showSearchResults && _searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _searchResults.map((result) {
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: Color(0xFF3E4795),
                            size: 20,
                          ),
                          title: Text(
                            result['name'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            result['address'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _onSearchResultSelected(result),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (_showSearchResults && _isSearching)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF3E4795),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Searching for places...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
// ---------------- NotificationsTab ----------------

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'icon': Icons.directions_bus,
        'iconBg': Color(0xFFBFC6F7),
        'title': 'Passenger Pickup Alert',
        'message': 'You have a new pickup at P. Laurel Ave.',
        'time': '9:41 AM',
      },
      {
        'icon': Icons.traffic,
        'iconBg': Color(0xFFBFC6F7),
        'title': 'Route Update',
        'message': 'Heavy traffic detected ahead.',
        'time': '7:50 AM',
      },
      {
        'icon': Icons.support_agent,
        'iconBg': Color(0xFFBFC6F7),
        'title': 'Quick Assistance Alert Sent',
        'message': 'Admin support will reach out shortly.',
        'time': '9:00 AM',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Notifications',
              style: TextStyle(
                color: Color(0xFF3E4795),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 16),
            ...notifications.map(
              (notif) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: notif['iconBg'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        notif['icon'] as IconData,
                        color: Color.fromRGBO(62, 71, 149, 1),
                        size: 28,
                      ),
                    ),
                    title: Text(
                      notif['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      notif['message'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Text(
                      notif['time'] as String,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- PassengerPickupTab ----------------

class PassengerPickupTab extends StatelessWidget {
  const PassengerPickupTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> pickups = [
      {
        'location': 'San Pascual',
        'coords': '(13.8000, 121.0500)',
        'time': '9:41 AM'
      },
      {
        'location': 'San Jose',
        'coords': '(13.7850, 128.0890)',
        'time': '7:50 AM'
      },
      {
        'location': 'Banay-banay',
        'coords': '(13.7850, 128.0890)',
        'time': '9:00 AM'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Passenger Pick-ups',
              style: TextStyle(
                color: Color(0xFF3E4795),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text(
                    'Passenger Capacity Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E4795),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6),
                  Text(
                    '2/20',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Can accommodate more passengers.',
                    style: TextStyle(color: Colors.green, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...pickups.map((pickup) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(0xFFBFC6F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Color.fromRGBO(62, 71, 149, 1),
                      size: 28,
                    ),
                  ),
                  title: Text(
                    pickup['location']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Location: ${pickup['coords']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Text(
                    pickup['time']!,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ---------------- MessagingTab ----------------

class MessagingTab extends StatefulWidget {
  const MessagingTab({super.key});

  @override
  State<MessagingTab> createState() => _MessagingTabState();
}

class _MessagingTabState extends State<MessagingTab> {
  final List<Map<String, dynamic>> _messages = [
    {'fromAdmin': true, 'text': 'Thanks for the quick update, FCM 22. Are you safe?'},
    {'fromAdmin': false, 'text': "Yes, I'm safe. No need for medical, but I might need a tow."},
    {'fromAdmin': true, 'text': "Copy that. I'm dispatching our on-site support now."},
    {'fromAdmin': false, 'text': "Got it. Passenger has been informed and is waiting with me."},
  ];

  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'fromAdmin': false, 'text': _controller.text.trim()});
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'FCM Admin',
              style: TextStyle(
                color: Color(0xFF3E4795),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = !msg['fromAdmin'];
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFF3E4795) : Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        msg['text'],
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Write a message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF3E4795)),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- ProfileTab ----------------

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final String busNumber = "FCM No. 05";
    final String plateNumber = "DAL 7674";
    final String driverName = "Nelson Suarez";
    final String conductorEmail = "mixednames@gmail.com";

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
        children: [
          Text(
            'Profile',
            style: TextStyle(
              color: Color(0xFF3E4795),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          
          // Account Information
          Text('Account Information', style: sectionStyle),
          ListTile(
            leading: const Icon(Icons.directions_bus, color: Color(0xFF3E4795)),
            title: const Text('Bus Number'),
            subtitle: Text(busNumber),
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number, color: Color(0xFF3E4795)),
            title: const Text('Plate Number'),
            subtitle: Text(plateNumber),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF3E4795)),
            title: const Text("Driver's Name"),
            subtitle: Text(driverName),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF3E4795)),
            title: const Text("Conductor's Name"),
            subtitle: Text(conductorEmail),
          ),
          const SizedBox(height: 24),

          // Preferences
          Text('Preferences', style: sectionStyle),
          SwitchListTile(
            title: const Text('Notifications'),
            value: notificationsEnabled,
            onChanged: (val) => setState(() => notificationsEnabled = val),
          ),
          const SizedBox(height: 24),

          // Support
          Text('Support', style: sectionStyle),
          ListTile(
            leading: const Icon(Icons.phone, color: Color(0xFF3E4795)),
            title: const Text('Call for Quick Assistance'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Quick Assistance'),
                  content: const Text('Calling emergency support...'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Color(0xFF3E4795)),
            title: const Text('View Ratings'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('View Ratings'),
                  content: const Text('Your current rating: 4.5/5 stars'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.email, color: Color(0xFF3E4795)),
            title: const Text('Contact Admin'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Contact Admin'),
                  content: const Text('Email: admin@fcmapp.com'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // About
          Text('About', style: sectionStyle),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF3E4795)),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF3E4795)),
            title: const Text('Developer'),
            subtitle: const Text('FCM App Team'),
          ),
          ListTile(
            leading: const Icon(Icons.star_rate, color: Color(0xFF3E4795)),
            title: const Text('Rate the App'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Rate the App'),
                  content: const Text(
                    'This would open the app store for rating.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Color(0xFF3E4795)),
            title: const Text('Share the App'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Share the App'),
                  content: const Text('This would open the share dialog.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Logout
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // Logout user
                          await context.read<UserProvider>().logout();
                          // Navigate to login screen
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get sectionStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color.fromRGBO(62, 71, 149, 1),
    letterSpacing: 1,
  );
}

class QuickAssistanceScreen extends StatefulWidget {
  const QuickAssistanceScreen({super.key});

  @override
  State<QuickAssistanceScreen> createState() => _QuickAssistanceScreenState();
}

class _QuickAssistanceScreenState extends State<QuickAssistanceScreen> {
  String? _selectedSituation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Quick Assistance',
          style: TextStyle(
            color: Color(0xFF3E4795),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a Situation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    value: 'Vehicle Breakdown',
                    groupValue: _selectedSituation,
                    onChanged: (val) => setState(() => _selectedSituation = val),
                    activeColor: Color(0xFF3E4795),
                    title: const Text('Vehicle Breakdown'),
                  ),
                  RadioListTile<String>(
                    value: 'Accident',
                    groupValue: _selectedSituation,
                    onChanged: (val) => setState(() => _selectedSituation = val),
                    activeColor: Color(0xFF3E4795),
                    title: const Text('Accident'),
                  ),
                  RadioListTile<String>(
                    value: 'Others',
                    groupValue: _selectedSituation,
                    onChanged: (val) => setState(() => _selectedSituation = val),
                    activeColor: Color(0xFF3E4795),
                    title: const Text('Others'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSituation == null ? null : () {
                  // TODO: Implement assistance logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Assistance requested for $_selectedSituation'),
                      backgroundColor: const Color(0xFF3E4795),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E4795),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                child: const Text('Call for Assistance'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
