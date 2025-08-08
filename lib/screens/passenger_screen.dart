import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/vehicle_info_sheet.dart';
import '../helpers/mapbox_services.dart';
import '../helpers/distance_utils.dart';
import '../helpers/geofence_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key});

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  int _currentIndex = 2; // Default to MapScreen
  final List<Widget> _screens = [
    const NotificationsScreen(),
    const SaveRoutesScreen(),
    const MapScreen(),
    const TripHistoryScreen(),
    const SettingsScreen(),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          print('Swipe velocity: ${details.primaryVelocity}');
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -1) {
            _continueAsPassenger();
          }
        },
        child: Stack(
          children: [
            // Map Screen
            Positioned.fill(
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),

            // Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomBar(
                currentIndex: _currentIndex,
                onTabChanged: _onTabChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueAsPassenger() {
    // Implementation of _continueAsPassenger method
  }
}

class SearchField extends StatefulWidget {
  final void Function(LatLng selectedLocation, String placeName)
  onLocationSelected;

  const SearchField({super.key, required this.onLocationSelected});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];

  Future<void> _searchPlace(String query) async {
    final accessToken =
        'INSERT TOKEN HERE'; // Replace with your Mapbox access token
    final encodedQuery = Uri.encodeComponent(query);

    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json'
      '?access_token=$accessToken'
      '&limit=5&country=ph',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        setState(() {
          _suggestions = features.cast<Map<String, dynamic>>();
        });
      } else {
        print('Geocoding error: ${response.statusCode}');
      }
    } catch (e) {
      print('Search error: $e');
    }
  }

  void _selectSuggestion(Map<String, dynamic> feature) {
    final name = feature['place_name'];
    final coords = feature['geometry']['coordinates'];
    final latLng = LatLng(coords[1], coords[0]); // [lon, lat]

    widget.onLocationSelected(latLng, name);
    setState(() {
      _controller.text = name;
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 1000,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF23242B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : Colors.grey,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                onChanged: (value) {
                  if (value.trim().isNotEmpty) {
                    _searchPlace(value.trim());
                  } else {
                    setState(() => _suggestions = []);
                  }
                },
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Where are you going to?',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 17),
                ),
              ),
            ),
          ),

          // Dropdown suggestion list
          if (_suggestions.isNotEmpty)
            Container(
              width: 1000,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2E36) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black38
                        : Colors.grey.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade300),
                itemBuilder: (context, index) {
                  final feature = _suggestions[index];
                  final name = feature['place_name'];

                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(
                      name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    onTap: () => _selectSuggestion(feature),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/*class LocationSwitch extends StatefulWidget {
  const LocationSwitch({super.key});

  @override
  State<LocationSwitch> createState() => _LocationSwitchState();
}

class _LocationSwitchState extends State<LocationSwitch> {
  bool _locationEnabled = false;

  void _showLocationPermissionModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 80,
                  color: Color.fromRGBO(62, 71, 149, 1),
                ),
                SizedBox(height: 24),
                Text(
                  'Location Permission',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'To track nearby vehicles, allow us to detect your location.',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE3E6F5),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() => _locationEnabled = true);
                      Navigator.of(context).pop();
                      // Here you can add actual location permission logic
                    },
                    child: Text(
                      'TURN ON LOCATION SERVICES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Not Now',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 150,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(62, 71, 149, 1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Switch(
            value: _locationEnabled,
            onChanged: (value) {
              _showLocationPermissionModal();
            },
            activeColor: Colors.white,
            activeTrackColor: Color.fromRGBO(130, 135, 188, 1),
            inactiveTrackColor: Color.fromRGBO(206, 206, 214, 1),
            inactiveThumbColor: Colors.white,
          ),
          Text(
            'Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}*/

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
      height: 90, // Increased height for better circle
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
              Icons.favorite_border,
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
              Icons.access_time_outlined,
              color: Color(0xFF3E4795),
              size: 36,
            ),
            onPressed: () => onTabChanged(3),
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
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

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'icon': Icons.directions_bus,
        'iconBg': Color(0xFFBFC6F7),
        'title': 'FCM Incoming',
        'subtitle': 'FCM No. 07 is now approaching your stop',
        'time': '9:41 AM',
      },
      {
        'icon': Icons.location_on,
        'iconBg': Color(0xFFBFC6F7),
        'title': 'Check Near FCMs',
        'subtitle': "You're near your saved location",
        'time': '7:50 AM',
      },
      {
        'icon': Icons.star,
        'iconBg': Color(0xFFBFC6F7),
        'title': 'Rate the Ride',
        'subtitle': "Don't forget to rate No. 22 from your recent trip!",
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: Color(0xFF3E4795),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
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
                      notif['subtitle'] as String,
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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  //Declare Variables
  bool _showVehicleInfo = false;
  LatLng? _pickedLocation;
  final MapController _mapController = MapController();
  bool _showRoutePolyLine = false;
  bool _wasInsideGeofence = false;

  final List<LatLng> _routePoints = [
    LatLng(13.9467729, 121.1555241),
    LatLng(13.948197503981618, 121.15663127065292),
    LatLng(13.950278979606711, 121.15838610642095),
    LatLng(13.951033283494375, 121.15975747814403),
    LatLng(13.952865846616918, 121.16308555449044),
  ];

  void _toggleVehicleInfoAndZoom() {
    setState(() {
      _showVehicleInfo = true;
    });

    // Animate map to a slightly higher position for better visibility
    _mapController.move(LatLng(13.9465, 121.1555), 15.5);
  }

  void _hideVehicleInfo() {
    setState(() {
      _showVehicleInfo = false;
      _showRoutePolyLine = false;
    });
  }

  void _showPinInfoModal(
    LatLng location,
    String placeName,
    double distanceInKm,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // transparent to style inner container
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 90, // adjust if you have a navbar
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
                        placeName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E4795),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Distance
                Text(
                  '${distanceInKm.toStringAsFixed(2)} km away from bus location',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Add to favorites logic
                      },
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Save Favorites'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3E4795),
                        side: const BorderSide(color: Color(0xFF3E4795)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        final isValid = isNearRoute(
                          _pickedLocation!,
                          _routePoints,
                        );

                        if (!isValid) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Selected pickup location is too far from the route.',
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pick Up Location Set!'),
                          ),
                        );

                        // Proceed with saving destination logic...
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Set Pickup'),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //Geofencing simulation for testing
  List<LatLng> _geofencePoints = [
    LatLng(13.94758263613753, 121.15624906847192),
    LatLng(13.947770089296156, 121.1563622930869),
    LatLng(13.948263911430017, 121.15673707937391),
    LatLng(13.948482538852513, 121.15688566163013),
  ];
  int _currentMockIndex = 0;
  LatLng _vehiclePosition = LatLng(13.947065523186177, 121.15588275354108);

  void _startSimulation() {
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (_currentMockIndex >= _geofencePoints.length) {
        timer.cancel();
        _currentMockIndex = 0;
        _isSimulationRunning = false;
        return;
      }

      setState(() {
        _vehiclePosition = _geofencePoints[_currentMockIndex];
        _currentMockIndex++;
      });

      _checkGeofence(); // Call geofence logic on each movement
    });
  }

  bool _isSimulationRunning = false;
  //geofencing
  void _checkGeofence() {
    bool isInside = isWithinGeofence(
      point: _vehiclePosition, // Your vehicle location
      center: _geofencePoints[1],
      radiusInMeters: 10,
    );

    if (isInside && !_wasInsideGeofence) {
      // Just entered geofence
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🟢 Vehicle entered the destination area."),
          duration: Duration(seconds: 5),
        ),
      );
    } else if (!isInside && _wasInsideGeofence) {
      // Just exited geofence
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔴 Vehicle exited the destination area."),
          duration: Duration(seconds: 5),
        ),
      );
    }

    // Update tracking state
    _wasInsideGeofence = isInside;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(13.955785, 121.165510),
              initialZoom: 13.0,
              interactiveFlags: InteractiveFlag.all,
              onTap: (tapPosition, latlng) async {
                setState(() {
                  _pickedLocation = latlng;
                  _showVehicleInfo = false; // Hide vehicle info on map tap
                });
                final placeName =
                    await MapboxService.getPlaceNameFromCoordinates(latlng);
                final Distance distance = Distance();
                final busLocation = LatLng(
                  13.947234252372729,
                  121.15598193108184,
                ); // bus location

                final double distanceInMeters = distance.as(
                  LengthUnit.Meter,
                  busLocation,
                  latlng, // or selectedLatLng
                );
                final double distanceInKm = distanceInMeters / 1000;

                // Call modal with distance
                _showPinInfoModal(latlng, placeName, distanceInKm);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: ['a', 'b', 'c', 'd'],
              ),
              if (_showRoutePolyLine)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 8.0,
                      color: const Color.fromRGBO(62, 71, 149, 1),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point:
                        _vehiclePosition, // <-- Updated to use moving position
                    child: GestureDetector(
                      onTap: _toggleVehicleInfoAndZoom,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3E4795), // background color
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.directions_bus_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_pickedLocation != null)
                    Marker(
                      point: _pickedLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF3E4795),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),

                  if (_showRoutePolyLine)
                    Marker(
                      point: _routePoints.last, // Final destination
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF3E4795),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          //temporary button to start simulation
          Positioned(
            right: 16,
            // If you have a bottom nav, lift it up a bit:
            bottom: 100, // try 16 if no navbar; adjust as needed
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _isSimulationRunning
                    ? null
                    : () {
                        _startSimulation();
                        setState(() => _isSimulationRunning = true);
                      },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Simulation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: SearchField(
              onLocationSelected:
                  (LatLng selectedLatLng, String placeName) async {
                    final isValid = isNearRoute(selectedLatLng, _routePoints);

                    setState(() {
                      _pickedLocation = selectedLatLng;
                      _showVehicleInfo = false;
                    });

                    final placeName =
                        await MapboxService.getPlaceNameFromCoordinates(
                          selectedLatLng,
                        );
                    final Distance distance = Distance();
                    final busLocation = LatLng(
                      13.947234252372729,
                      121.15598193108184,
                    ); // bus location

                    final double distanceInMeters = distance.as(
                      LengthUnit.Meter,
                      busLocation,
                      selectedLatLng, // or selectedLatLng
                    );
                    final double distanceInKm = distanceInMeters / 1000;

                    if (!isValid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Selected location is too far from the route.',
                          ),
                        ),
                      );
                      return;
                    }

                    // Call modal with distance
                    _showPinInfoModal(selectedLatLng, placeName, distanceInKm);

                    //_showPinInfoModal(selectedLatLng, placeName, distanceInKm);
                  },
            ),
          ),

          // Bottom Sheet
          if (_showVehicleInfo)
            Positioned(
              left: 0,
              right: 0,
              bottom: 90,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: VehicleInfoSheet(
                  onClose: _hideVehicleInfo,
                  onTrackPressed: () {
                    setState(() {
                      _showRoutePolyLine = true;
                    });
                    _mapController.fitBounds(
                      LatLngBounds.fromPoints(_routePoints),
                      options: const FitBoundsOptions(
                        padding: EdgeInsets.all(50),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
        children: [
          const Text(
            'Settings',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF3E4795),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          // Preferences
          Text('Preferences', style: sectionStyle),
          SwitchListTile(
            title: const Text('Notifications'),
            value: notificationsEnabled,
            onChanged: (val) => setState(() => notificationsEnabled = val),
          ),
          const SizedBox(height: 24),

          // Location
          Text('Location', style: sectionStyle),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Manage Location Permissions'),
            onTap: () {
              // Placeholder: Show a dialog or open settings
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Location Permissions'),
                  content: const Text(
                    'This would open the location permissions settings.',
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
          const SizedBox(height: 24),

          // Support
          Text('Support', style: sectionStyle),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Contact Us'),
            onTap: () {
              // Placeholder: Show a dialog or launch email
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Contact Us'),
                  content: const Text('Email: support@fcmapp.com'),
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
            leading: const Icon(Icons.help_outline),
            title: const Text('FAQ'),
            onTap: () {
              // Placeholder: Show a dialog or navigate to FAQ
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('FAQ'),
                  content: const Text(
                    'Frequently Asked Questions will be here.',
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
          const SizedBox(height: 24),

          // About
          Text('About', style: sectionStyle),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Developer'),
            subtitle: const Text('FCM App Team'),
          ),
          ListTile(
            leading: const Icon(Icons.star_rate),
            title: const Text('Rate the App'),
            onTap: () {
              // Placeholder: Show a dialog or open store
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
            leading: const Icon(Icons.share),
            title: const Text('Share the App'),
            onTap: () {
              // Placeholder: Show a dialog or share
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

          // Exit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<UserProvider>().logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
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
                'Exit',
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

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trips = [
      {
        'number': '12',
        'route': 'Lipa City Terminal → Layayat, San Jose',
        'date': 'April 15, 2025',
        'time': '8:15 AM',
        'duration': '45 mins',
      },
      {
        'number': '05',
        'route': 'Lipa City Terminal → Bauan',
        'date': 'April 25, 2025',
        'time': '10:15 AM',
        'duration': '1 hour & 5 mins',
      },
      {
        'number': '01',
        'route': 'Lipa City Terminal → Bauan',
        'date': 'April 30, 2025',
        'time': '10:15 AM',
        'duration': '1 hour & 5 mins',
      },
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: trips.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 8),
              child: Text(
                'Trip History',
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Color(0xFF3E4795),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            );
          }
          final trip = trips[i - 1];
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FCM No. ${trip['number']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trip['route']!,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  '${trip['date']} | ${trip['time']} | ${trip['duration']}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SaveRoutesScreen extends StatelessWidget {
  const SaveRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saveRoutes = [
      'Lipa City Terminal → Layayat, San Jose',
      'Lipa City Terminal → Bauan City',
      'Lipa City Terminal → Lumil, San Jose',
    ];
    final favoriteLocations = [
      'Lalayat, San Jose Batangas',
      'Lipa City Terminal',
      'San Pascual, Batangas',
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        children: [
          const SizedBox(height: 24),
          const Text(
            'My Save Routes',
            style: TextStyle(
              color: Color(0xFF3E4795),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          ...saveRoutes.map(
            (route) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFBFC6F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFF3E4795),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        route,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Favorite Locations',
            style: TextStyle(
              color: Color(0xFF3E4795),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 12),
          ...favoriteLocations.map(
            (loc) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFBFC6F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFF3E4795),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
