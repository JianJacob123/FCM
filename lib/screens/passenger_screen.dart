import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
//import '../widgets/vehicle_info_sheet.dart';
//import '../helpers/mapbox_services.dart';
import '../helpers/distance_utils.dart';
import '../helpers/location_service.dart';
import '../models/trip_request.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'login_screen.dart';
import '../services/notif_socket.dart';

final baseUrl = dotenv.env['API_BASE_URL'];

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key});

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  int _currentIndex = 2; // Default to MapScreen

  // GlobalKeys to access screen states for refresh
  final GlobalKey<_NotificationsScreenState> _notificationsKey =
      GlobalKey<_NotificationsScreenState>();
  final GlobalKey<_SaveRoutesScreenState> _saveRoutesKey =
      GlobalKey<_SaveRoutesScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      NotificationsScreen(key: _notificationsKey),
      SaveRoutesScreen(key: _saveRoutesKey),
      const MapScreen(),
      const TripHistoryScreen(),
      const SettingsScreen(),
    ];
  }

  void _onTabChanged(int index) {
    // If clicking the same tab that's already selected, refresh it
    if (_currentIndex == index) {
      if (index == 0) {
        // Refresh notifications screen
        _notificationsKey.currentState?.refreshNotifications();
      } else if (index == 1) {
        // Refresh favorites screen
        _saveRoutesKey.currentState?.refreshData();
      }
    } else {
      // Switch to the new tab
      setState(() {
        _currentIndex = index;
      });
    }
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
        'pk.eyJ1Ijoia3lsbHVoaGgiLCJhIjoiY21jNzFrbjhnMWEzdTJqb21razJzMnNzZSJ9.mTR_W24uzbK1y3Z1Y4OjTA'; // Replace with your Mapbox access token
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

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _loadLocalNotifications();

    // Listen for new notifications via socket
    _socketService.onNewNotification(_loadLocalNotifications);
  }

  @override
  void dispose() {
    _socketService.removeNotificationCallback(_loadLocalNotifications);
    super.dispose();
  }

  /// Load notifications from SharedPreferences
  Future<void> _loadLocalNotifications() async {
    final stored = await SocketService.getStoredNotifications();
    setState(() {
      _notifications = stored;
    });
  }

  Future<void> refreshNotifications() async {
    await _loadLocalNotifications();
  }

  /// Format time ago
  String timeAgo(String isoDate) {
    final date = DateTime.parse(isoDate).toLocal();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF3E4795),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _loadLocalNotifications,
          child: _notifications.isEmpty
              ? const Center(child: Text("No notifications yet"))
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return _ExpandableNotificationCard(
                      title: notif["notif_title"],
                      content: notif["content"],
                      timeAgo: timeAgo(notif["notif_date"]),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ExpandableNotificationCard extends StatefulWidget {
  final String title;
  final String content;
  final String timeAgo;

  const _ExpandableNotificationCard({
    required this.title,
    required this.content,
    required this.timeAgo,
  });

  @override
  State<_ExpandableNotificationCard> createState() =>
      _ExpandableNotificationCardState();
}

class _ExpandableNotificationCardState
    extends State<_ExpandableNotificationCard> {
  bool _isExpanded = false;
  static const int _maxPreviewLength = 100;

  @override
  Widget build(BuildContext context) {
    final bool needsExpansion = widget.content.length > _maxPreviewLength;
    final String displayContent = _isExpanded || !needsExpansion
        ? widget.content
        : '${widget.content.substring(0, _maxPreviewLength)}...';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.timeAgo,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(displayContent, style: const TextStyle(fontSize: 14)),
            ),
            if (needsExpansion)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Text(
                    _isExpanded ? 'Read less' : 'Read more',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3E4795),
                      fontWeight: FontWeight.w600,
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
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late IO.Socket vehicleSocket;
  late IO.Socket passengerTripSocket;
  LatLng? _userLocation;
  final Map<int, Marker> _vehicleMarkers = {}; // vehicle_id to Marker
  Map<String, dynamic>? _selectedVehicle; // selected vehicle info
  List<LatLng> _routePolyline = [];
  int? _selectedRouteId; // will hold the chosen route_id
  Map<String, dynamic>? _activeTrip;
  Timer? _tripRefreshTimer;
  bool _isTripExpanded = false;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();

    _startListeningToLocation();
    _loadActiveTrip();
    _tripRefreshTimer = Timer.periodic(Duration(seconds: 60), (timer) {
      if (!mounted) return; // check if widget is still mounted
      _loadActiveTrip();
    });

    // --- Vehicle socket (no userId needed) ---
    vehicleSocket = IO.io(
      "$baseUrl/vehicles",
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );

    vehicleSocket.connect();

    vehicleSocket.onConnect((_) {
      print('Connected to vehicle backend');
      vehicleSocket.emit("subscribeVehicles"); // 🔑 join vehicleRoom
    });

    vehicleSocket.on('vehicleUpdate', (data) {
      if (!mounted) return;
      //print('🚐 Vehicle update: $data');

      // data is an array of vehicles
      setState(() {
        for (var v in data) {
          final id = v["vehicle_id"];
          final lat = double.parse(v["lat"].toString());
          final lng = double.parse(v["lng"].toString());

          _vehicleMarkers[id] = Marker(
            point: LatLng(lat, lng),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedVehicle = v; // save the tapped vehicle info
                  _showVehicleInfo = true;
                  _routePolyline = []; // clear old polyline
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(0xFF3E4795),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });
    });

    vehicleSocket.onDisconnect((_) {
      print('Vehicle disconnected');
    });
  }

  @override
  void dispose() {
    _tripRefreshTimer?.cancel(); //clean up timer
    _positionSubscription?.cancel(); //clean up location subscription
    vehicleSocket.off('vehicleUpdate');
    vehicleSocket.dispose();
    super.dispose();
  }

  /*Future<void> _getUserLocation() async {
    final position = await LocationService.getCurrentLocation();

    if (!mounted) return;
    if (position != null) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } else {
      print('Unable to fetch user location');
    }
  }*/

  void _startListeningToLocation() {
    // 1. Get permission (important to run this first)
    LocationService.requestPermission().then((hasPermission) {
      if (!mounted || !hasPermission) return;

      // 2. Subscribe to the real-time stream
      _positionSubscription = LocationService.getLocationStream().listen((
        position,
      ) {
        if (!mounted) return;
        setState(() {
          // Update the user location every time a new position is received
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        // Optional: you can check the stream settings in LocationService
        // (currently set to update every 10 meters)
      });
    });
  }

  Future<void> _loadActiveTrip() async {
    //final testId = "GUEST-123";
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.isLoggedIn
        ? userProvider.currentUser!.id
        : userProvider.guestId;

    if (userId == null) {
      // Handle error: user not logged in
      throw Exception("Id Not Found");
    }

    try {
      final trips = await fetchActiveTrips(userId);

      if (!mounted) return;

      setState(() {
        _activeTrip = trips;
      });
    } catch (e) {
      print('Error loading active trip: $e');
    }
  }

  final MapController _mapController = MapController();

  //Keep: picked location for user search
  LatLng? _pickedLocation;
  bool _showPinnedLocation = false;
  String _pickedLocationName = "Selected Location"; //for now.

  //Keep: vehicle info modal logic
  bool _showVehicleInfo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(13.945, 121.163),
              zoom: 14,
              onTap: (tapPosition, point) {
                setState(() {
                  _showVehicleInfo = false;
                  _pickedLocation = point;
                  _showPinnedLocation = true;
                  _pickedLocationName = "Pinned Location";
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: ['a', 'b', 'c', 'd'],
              ),

              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePolyline,
                    strokeWidth: 4.0,
                    color: Color(0xFF3E4795),
                  ),
                ],
              ),

              MarkerLayer(
                rotate: false,
                markers: [
                  if (_routePolyline.isNotEmpty)
                    Marker(
                      point: _routePolyline.last,
                      width: 30,
                      height: 60,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFF3E4795),
                        size: 32,
                      ),
                    ),
                  if (_pickedLocation != null)
                    Marker(
                      point: _pickedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.green,
                        size: 32,
                      ),
                    ),
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 40, // Increase width/height
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(
                            0xFF3E4795,
                          ).withOpacity(0.3), // Light blue for accuracy area
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          // The center blue dot
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF3E4795), // Solid blue inner circle
                            border: Border.all(
                              color: Colors
                                  .white, // White border like a Google Maps pin
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ..._vehicleMarkers.values.toList(),
                ],
              ),
            ],
          ),

          //Keep: search field on top
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: SearchField(
              onLocationSelected: (latLng, placeName) {
                setState(() {
                  _pickedLocation = latLng;
                  _pickedLocationName = placeName; // save the name
                  _showPinnedLocation = true; // ensure the green pin shows
                  _showVehicleInfo = false; // hide vehicle info if visible
                });

                // Smooth camera movement
                _mapController.move(latLng, 16);
              },
            ),
          ),

          // === Active Trip Bottom Sheet ===
          if (_activeTrip != null && !_isTripExpanded)
            Positioned(
              bottom: 120,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isTripExpanded = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.start, // Align to start
                    children: [
                      Row(
                        children: [
                          // 1. Static Label
                          Icon(
                            Icons.directions,
                            size: 24,
                            color: Color(0xFF3E4795),
                          ),

                          const SizedBox(width: 6),

                          // 2. Dynamic Status Value
                          Text(
                            _activeTrip!["status"].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              // Use color to indicate status (e.g., Orange for pending)
                              color: _activeTrip!["status"] == "pending"
                                  ? Colors.orange
                                  : Colors
                                        .blue, // Simplified color logic for example
                            ),
                          ),
                        ],
                      ),

                      // Add some space between the status and the icon
                      const SizedBox(width: 10),

                      // Arrow icon to indicate expandability
                      const Icon(
                        Icons.keyboard_arrow_up,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_activeTrip != null && _isTripExpanded)
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 120,
                  maxHeight: 260,
                ),
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
                  mainAxisSize:
                      MainAxisSize.min, // 👈 this makes height wrap content
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Active Trip",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E4795),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _isTripExpanded = false;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Status Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _activeTrip!["status"] == "pending"
                            ? Colors.orange.withOpacity(0.15)
                            : _activeTrip!["status"] == "picked_up"
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _activeTrip!["status"].toString().toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _activeTrip!["status"] == "pending"
                              ? Colors.orange
                              : _activeTrip!["status"] == "picked_up"
                              ? Colors.blue
                              : Colors.green,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Trip info
                    Row(
                      children: [
                        Expanded(
                          // ✅ gives column flexible width
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Pickup Location",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${_activeTrip!["pickup_location_name"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow
                                    .ellipsis, // ✅ now works properly
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          // ✅ also wrap this one
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Dropoff Location",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${_activeTrip!["dropoff_location_name"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Action button
                    if (_activeTrip!["status"] == "pending")
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            //final testId = "GUEST-123";
                            final userProvider = context.read<UserProvider>();
                            final userId = userProvider.isLoggedIn
                                ? userProvider.currentUser!.id
                                : userProvider
                                      .guestId; // <-- fallback to guestId
                            if (userId == null) {
                              // Handle error: user not logged in
                              throw Exception("Id Not Found");
                            }

                            final message = await cancelTrip(
                              userId,
                            ); //CHANGE TO userId LATER

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));

                            // Optionally expand the modal automatically
                            setState(() {
                              _isTripExpanded = true;
                              _pickedLocation = null;
                              _showPinnedLocation = false;
                              _activeTrip = null;
                            });
                          },
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text("Cancel Trip"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E4795),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    if (_activeTrip!["status"] == "picked_up")
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            //final testId = "GUEST-123";
                            final userProvider = context.read<UserProvider>();
                            final userId = userProvider.isLoggedIn
                                ? userProvider.currentUser!.id
                                : userProvider
                                      .guestId; // <-- fallback to guestId
                            if (userId == null) {
                              // Handle error: user not logged in
                              throw Exception("Id Not Found");
                            }

                            final message = await markTripCompleted(
                              userId,
                            ); //CHANGE TO userId LATER

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));

                            // Optionally expand the modal automatically
                            setState(() {
                              _isTripExpanded = true;
                              _pickedLocation = null;
                              _showPinnedLocation = false;
                              _activeTrip = null;
                            });
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text("Mark as Completed"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E4795),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          //Keep: vehicle info bottom sheet
          if (_showVehicleInfo && _selectedVehicle != null)
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 100,
                  maxHeight: 280,
                ),
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FCM No. ${_selectedVehicle?["vehicle_id"] ?? "Unknown"}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E4795),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _showVehicleInfo = false;
                                _selectedVehicle = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedVehicle?["route_name"] ?? "Unknown"}',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            _selectedVehicle?["is_off_route"] == true
                                ? 'Off Route'
                                : 'On Route',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedVehicle?["is_off_route"] == true
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      //Animated progress bar
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0.2,
                          end:
                              ((double.tryParse(
                                            _selectedVehicle!["route_progress_percent"]
                                                .toString(),
                                          ) ??
                                          0) /
                                      100)
                                  .clamp(0.0, 1.0), //clamp after dividing
                        ),
                        duration: const Duration(
                          milliseconds: 800,
                        ), // animation duration
                        curve: Curves.easeOut, // makes it smooth
                        builder: (context, value, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            color: Color(0xFF3E4795),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated Time of Arrival',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            _selectedVehicle != null &&
                                    _selectedVehicle!['eta'] != null
                                ? DateFormat.jm().format(
                                    DateTime.parse(
                                      _selectedVehicle!['eta'],
                                    ).toLocal(),
                                  )
                                : '--:--',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Capacity',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            '${_selectedVehicle?["current_passenger_count"] ?? "--"}/20',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Plate Number",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${_selectedVehicle?["plate_number"] ?? "---"}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final remainingRoute =
                                  _selectedVehicle?["remaining_route_polyline"];

                              if (remainingRoute == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("No route data available."),
                                  ),
                                );
                                return;
                              }

                              // Decode JSON string into a Map
                              final routeJson = remainingRoute is String
                                  ? jsonDecode(remainingRoute)
                                  : remainingRoute;

                              final coords =
                                  (routeJson["coordinates"] as List?)
                                      ?.map(
                                        (c) => LatLng(
                                          (c[1] as num).toDouble(),
                                          (c[0] as num).toDouble(),
                                        ),
                                      )
                                      .toList() ??
                                  [];

                              if (coords.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("No route data available."),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _routePolyline = coords;
                              });
                            },
                            icon: const Icon(Icons.navigation, size: 16),
                            label: const Text(
                              'Track Trip',
                              style: TextStyle(fontSize: 14),
                            ),
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
                ),
              ),
            ),

          //PinLocationModal
          if (_showPinnedLocation && _pickedLocation != null)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Container(
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
                    // Title + close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _pickedLocationName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E4795),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _showPinnedLocation = false;
                              _pickedLocation = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Coordinates (for now, until we add reverse geocoding)
                    DropdownButtonFormField<int>(
                      value: _selectedRouteId,
                      decoration: const InputDecoration(
                        labelText: "Select Route",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text("Lipa → Bauan")),
                        DropdownMenuItem(value: 2, child: Text("Bauan → Lipa")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRouteId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final userProvider = context.read<UserProvider>();
                              final userId = userProvider.isLoggedIn
                                  ? userProvider.currentUser!.id
                                  : userProvider
                                        .guestId; // <-- fallback to guestId
                              if (userId == null) {
                                // Handle error: user not logged in
                                throw Exception("Id Not Found");
                              }
                              final message = await addLocation(
                                userId,
                                _pickedLocation!.latitude,
                                _pickedLocation!.longitude,
                              );

                              // Show status snackbar with appropriate color
                              final isSuccess =
                                  message.toLowerCase().contains(
                                    "successfully",
                                  ) ||
                                  message.toLowerCase().contains("success");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: isSuccess
                                      ? Colors.green
                                      : Colors.red,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.favorite_border),
                            label: const Text(
                              "Add Favorites",
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ), // height
                            ),
                          ),
                        ),
                        const SizedBox(width: 8), // spacing between buttons
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_routePolyline.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please track the vehicle first before setting destination.",
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (_userLocation == null ||
                                  _pickedLocation == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "User location or destination missing!",
                                    ),
                                  ),
                                );
                                return;
                              }
                              //Validate: is pickup and dropoff near the polyline?
                              final isPickupValid = isPointNearPolyline(
                                _userLocation!,
                                _routePolyline,
                              );
                              final isDropoffValid = isPointNearPolyline(
                                _pickedLocation!,
                                _routePolyline,
                              );

                              if (!isPickupValid || !isDropoffValid) {
                                //Remove pickup valid to bypass.
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Pickup or dropoff location is too far from the route. Please select a closer point.",
                                    ),
                                  ),
                                );
                                return;
                              }

                              final userProvider = context.read<UserProvider>();
                              final userId = userProvider.isLoggedIn
                                  ? userProvider.currentUser!.id
                                  : userProvider
                                        .guestId; // <-- fallback to guestId
                              if (userId == null) {
                                // Handle error: user not logged in
                                throw Exception("Id Not Found");
                              }
                              final trip = TripRequest(
                                passengerId: userId,
                                pickupLat: _userLocation!.latitude,
                                pickupLng: _userLocation!.longitude,
                                dropoffLat: _pickedLocation!.latitude,
                                dropoffLng: _pickedLocation!.longitude,
                                routeId: _selectedRouteId ?? 1,
                              );

                              print("🚖 Trip Request: ${trip.toJson()}");

                              try {
                                // Send trip request to backend
                                final message = await createRequest(trip);

                                // Show status snackbar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );

                                // ✅ Fetch and show the new active trip
                                await _loadActiveTrip();

                                // Optionally expand the modal automatically
                                setState(() {
                                  _isTripExpanded = true;
                                  _pickedLocation = null;
                                  _showPinnedLocation = false;
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Failed to create trip: $e"),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.flag),
                            label: const Text(
                              "Set Destination",
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E4795),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF3E4795), //Change the color here
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
        children: [
          // Removed Preferences/Notifications section
          const SizedBox(height: 0),

          // Permissions
          Text('Location', style: sectionStyle),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Manage Location Permissions'),
            onTap: () {
              openAppSettings();
            },
          ),
          const SizedBox(height: 8),
          Text('Notifications', style: sectionStyle),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Manage Notification Permissions'),
            onTap: () {
              openAppSettings();
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
                  backgroundColor: Colors.white,
                  title: const Text('Contact Us'),
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.email, color: Color(0xFF3E4795)),
                      SizedBox(width: 8),
                      Flexible(child: Text('support@fcmapp.com')),
                    ],
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
            leading: const Icon(Icons.help_outline),
            title: const Text('FAQ'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text('FAQ'),
                  content: SizedBox(
                    width: 600,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '1. What is the FCM Transport mobile app?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'The FCM Transport app is a convenient tool designed for passengers to track active FCM buses in real time, stay updated with important notifications, and manage their favorite routes and trips—all in one app.',
                          ),
                          SizedBox(height: 12),

                          Text(
                            '2. How do I track a vehicle?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Simply open the Map section, choose the route or vehicle number you want to monitor, and view its real-time location and movement along the Bauan–Lipa route.',
                          ),
                          SizedBox(height: 12),

                          Text(
                            '3. What kind of notifications will I receive?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You\'ll receive official updates from FCM Transport\'s admin, including:',
                          ),
                          SizedBox(height: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              _BulletLine('General Announcements'),
                              _BulletLine('System Notifications'),
                              _BulletLine('Route Updates'),
                              _BulletLine('Service Maintenance Notices'),
                            ],
                          ),
                          SizedBox(height: 12),

                          Text(
                            '4. How can I save my favorite locations?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap the “Add Favorites” icon when selecting any location on the map. Your saved locations will appear in your Favorites list, allowing quick access to tracking or trip planning later on.',
                          ),
                          SizedBox(height: 12),

                          Text(
                            '5. What is the Trip History feature for?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'The Trip History section allows you to view a summary of your previously tracked trips for easier reference to your past routes and travel activity.',
                          ),
                          SizedBox(height: 12),

                          Text(
                            '6. Does the app collect my personal information?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'The app only collects location data necessary for providing accurate tracking and route-related information. Your data is handled securely and in accordance with our Privacy Policy.',
                          ),
                          SizedBox(height: 12),

                          Text(
                            '7. Can I use the app without enabling location access?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You can browse routes and vehicles without enabling location, but you will not have the option to set a destination or view your current position on the map.',
                          ),
                          SizedBox(height: 12),

                          Text(
                            '8. How do I install the app?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You can download the FCM Transport mobile app directly from the official link provided on our website. The app is currently available for Android devices only.',
                          ),
                          SizedBox(height: 12),

                          Text(
                            '9. How often is the information on the map updated?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Bus locations and statuses are updated in real time, but minor delays may occur depending on network stability or signal strength.',
                          ),
                          SizedBox(height: 12),

                          Text(
                            '10. What should I do if the app is not working properly?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Try closing and reopening the app, ensuring that your internet connection is stable. If issues persist, you may reinstall the app or contact our support team for assistance.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
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
            subtitle: const Text('BatStateU-Lipa IT Students'),
          ),

          const SizedBox(height: 32),

          // Exit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await context.read<UserProvider>().logout();
                          // Navigate to login screen by pushing and removing all routes
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
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

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _BulletLine extends StatelessWidget {
  final String text;
  const _BulletLine(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  late Future<List<dynamic>> _futureTripHistory;

  @override
  void initState() {
    super.initState();
    //final testId = "GUEST-123";
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.isLoggedIn
        ? userProvider.currentUser!.id
        : userProvider.guestId;

    _futureTripHistory = fetchTripHistory(userId ?? "");
  }

  /// Format time ago
  String timeAgo(String isoDate) {
    final date = DateTime.parse(isoDate).toLocal();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM dd').format(date);
  }

  Future<void> _refreshData() async {
    //final testId = "GUEST-123";
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.isLoggedIn
        ? userProvider.currentUser!.id
        : userProvider.guestId;

    setState(() {
      _futureTripHistory = fetchTripHistory(userId ?? "");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Trip History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF3E4795),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // 4. Wrap the entire FutureBuilder in RefreshIndicator
      body: RefreshIndicator(
        onRefresh: _refreshData, // Assign the refresh function
        child: FutureBuilder<List<dynamic>>(
          // Use the class variable for the future
          future: _futureTripHistory,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.hasData) {
              final trips = snapshot.data!;
              if (trips.isEmpty) {
                // Ensure the list is scrollable for RefreshIndicator to work on empty data
                return ListView(
                  children: const [
                    SizedBox(height: 100), // Push the text down
                    Center(child: Text("No trip history available.")),
                  ],
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFBFC6F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_bus,
                            color: Color(0xFF3E4795),
                            size: 28,
                          ),
                        ),
                        title: Text(
                          'Trip Request ${trip["request_id"] ?? "--"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'From: ${trip["pickup_location_name"] ?? "Unknown"}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'To: ${trip["dropoff_location_name"] ?? "Unknown"}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        trailing: Text(
                          timeAgo(trip["created_at"] ?? "Unknown Date"),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              // Handle the case where snapshot.hasData is false but no error occurred (e.g., initial null data)
              return const Center(child: Text("No trip history available."));
            }
          },
        ),
      ),
    );
  }
}

class SaveRoutesScreen extends StatefulWidget {
  const SaveRoutesScreen({super.key});

  @override
  State<SaveRoutesScreen> createState() => _SaveRoutesScreenState();
}

class _SaveRoutesScreenState extends State<SaveRoutesScreen> {
  late Future<List<dynamic>> _futureLocations;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.isLoggedIn
        ? userProvider.currentUser!.id
        : userProvider.guestId;

    _futureLocations = fetchFavoriteLocations(userId ?? "");
  }

  /// Refresh data (public for external access)
  Future<void> refreshData() async {
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.isLoggedIn
        ? userProvider.currentUser!.id
        : userProvider.guestId;

    setState(() {
      _futureLocations = fetchFavoriteLocations(userId ?? "");
    });
  }

  /// Private refresh method for internal use
  Future<void> _refreshData() async {
    await refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Favorite Locations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF3E4795),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<dynamic>>(
          future: _futureLocations,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.hasData) {
              final locations = snapshot.data!;
              if (locations.isEmpty) {
                return const Center(
                  child: Text("No favorite locations available."),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final loc = locations[index];
                  return Dismissible(
                    key: Key(
                      loc["favorite_location_id"].toString(),
                    ), // unique key for each location
                    direction: DismissDirection.endToStart, // swipe left only
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.delete, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Remove',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onDismissed: (direction) async {
                      // Store the location name for success message
                      final locationName = loc["location_name"];

                      try {
                        final result = await unfavoriteLocation(
                          loc["favorite_location_id"].toString(),
                        );

                        // Check if the result indicates success
                        if (result.toLowerCase().contains("successfully") ||
                            result.toLowerCase().contains("success")) {
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$locationName removed from favorites',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          // Refresh the list
                          _refreshData();
                        } else {
                          // Show error message from API
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          // Re-add the item since removal failed
                          _refreshData();
                        }
                      } catch (e) {
                        // Only show error if it's actually an error
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to remove location: ${e.toString().replaceAll("Exception: ", "")}',
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        // Re-add the item since removal failed
                        _refreshData();
                      }
                    },

                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  loc["location_name"] ?? "Unnamed Location",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return const Center(
                child: Text("No favorite locations available."),
              );
            }
          },
        ),
      ),
    );
  }
}
