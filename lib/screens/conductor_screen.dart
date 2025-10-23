import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/login_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';

final baseUrl = dotenv.env['API_BASE_URL'];

class ConductorScreen extends StatefulWidget {
  const ConductorScreen({super.key});

  @override
  State<ConductorScreen> createState() => _ConductorScreenState();
}

class _ConductorScreenState extends State<ConductorScreen> {
  int _currentIndex = 2;
  bool _showStatusCard = false;

  final List<Widget> _screens = const [
    NotificationsTab(),
    PassengerPickupTab(),
    MapScreen(),
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
              top: 40,
              left: 16,
              child: GestureDetector(
                onHorizontalDragEnd: (_) =>
                    setState(() => _showStatusCard = false),
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
                            onTap: () =>
                                setState(() => _showStatusCard = false),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.grey,
                              ),
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
            icon: Icon(Icons.group, color: Color(0xFF3E4795), size: 36),
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
            icon: Icon(Icons.schedule, color: Color(0xFF3E4795), size: 36),
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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late IO.Socket vehicleSocket;
  final Map<int, Marker> _vehicleMarkers = {}; // vehicle_id to Marker
  Map<String, dynamic>? _selectedVehicle; // selected vehicle info
  List<LatLng> _routePolyline = [];
  late final String conductorId;
  List<dynamic> _pendingPickups = [];
  LatLng? _highlightedPickup;
  bool _showPickupList = false; // show pending pickups by default

  @override
  void initState() {
    super.initState();
    _loadPendingPickups();
    final userProvider = context.read<UserProvider>();
    conductorId = userProvider.currentUser!.id;

    vehicleSocket = IO.io(
      "$baseUrl/vehicles",
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );

    vehicleSocket.connect();

    vehicleSocket.onConnect((_) {
      print('Connected to vehicle backend');
      vehicleSocket.emit(
        "subscribeConductor",
        conductorId,
      ); // 🔑 join vehicleRoom
    });

    vehicleSocket.on('vehicleUpdate', (data) {
      if (!mounted) return;

      // Ensure data is always treated as a list
      final vehicles = data is List ? data : [data];

      setState(() {
        for (var v in vehicles) {
          final id = int.parse(v["vehicle_id"].toString());
          final lat = double.parse(v["lat"].toString());
          final lng = double.parse(v["lng"].toString());
          final routeId = int.parse(v["route_id"].toString());

          _vehicleMarkers[id] = Marker(
            point: LatLng(lat, lng),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedVehicle = v;
                  _showVehicleInfo = true;
                  _routePolyline = [];
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
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

  Future<void> _loadPendingPickups() async {
    try {
      final pickups = await fetchPendingTrips(); // your API
      if (mounted) {
        setState(() {
          _pendingPickups = pickups;
        });
      }
    } catch (e) {
      print("Error fetching pickups: $e");
    }
  }

  @override
  void dispose() {
    vehicleSocket.off('vehicleUpdate');
    vehicleSocket.dispose();

    super.dispose();
  }

  final MapController _mapController = MapController();

  // ✅ Keep: vehicle info modal logic
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
                  ..._vehicleMarkers.values.toList(),

                  //Pickup markers
                  if (_highlightedPickup != null)
                    Marker(
                      point: _highlightedPickup!,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 44,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Toggle Button to show/hide pickup list
          Positioned(
            top: 40,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF3E4795),
              child: const Icon(Icons.person_search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showPickupList = true;
                });
              },
            ),
          ),

          //pickup list bottom sheet
          if (_showPickupList)
            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 100,
                  maxHeight: 220, //Enough space for ~2 items + scrolling
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
                  children: [
                    //Header row with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Pending Pickups",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E4795),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _showPickupList = false;
                              _highlightedPickup = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    //Scrollable list, limited by constraints above
                    Expanded(
                      child: ListView.builder(
                        itemCount: _pendingPickups.length,
                        itemBuilder: (context, index) {
                          final pickup = _pendingPickups[index];
                          final lat =
                              double.tryParse(
                                pickup['pickup_lat'].toString(),
                              ) ??
                              0.0;
                          final lng =
                              double.tryParse(
                                pickup['pickup_lng'].toString(),
                              ) ??
                              0.0;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: Color(0xFF3E4795),
                              ),
                              title: Text("${pickup['passenger_id']}"),
                              subtitle: Text("Going ${pickup['route_name']}"),
                              trailing: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF3E4795), // background color
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // 👈 rounded corners
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.my_location,
                                    color: Colors
                                        .white, //make icon white so it stands out
                                  ),
                                  onPressed: () {
                                    final point = LatLng(lat, lng);
                                    setState(() {
                                      _highlightedPickup = point;
                                    });
                                    _mapController.move(
                                      point,
                                      16.0,
                                    ); // zoom to point
                                  },
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

          //Keep: vehicle info bottom sheet
          if (_showVehicleInfo && _selectedVehicle != null)
            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 100,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    const SizedBox(height: 9),
                    //Animated progress bar
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0.2,
                        end:
                            (double.tryParse(
                                  _selectedVehicle!["route_progress_percent"]
                                      .toString(),
                                ) ??
                                0) /
                            100.clamp(0.0, 1.0),
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
                          children: const [
                            Text(
                              "Plate Number",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'DAL 1234',
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
        ],
      ),
    );
  }
}
// ---------------- NotificationsTab ----------------

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  late Future<List<dynamic>> notifications;

  String timeAgo(String isoDate) {
    final date = DateTime.parse(isoDate);
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM dd').format(date);
  }

  @override
  void initState() {
    super.initState();
    notifications = fetchNotifications('All FCM Unit');
  }

  IconData mapIcon(String iconName) {
    switch (iconName) {
      case "directions_bus":
        return Icons.directions_bus;
      case "location_on":
        return Icons.location_on;
      case "star":
        return Icons.star;
      default:
        return Icons.notifications;
    }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
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
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: notifications,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No notifications"));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final notif = snapshot.data![index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ListTile(
                              title: Text(
                                notif["notif_title"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                notif["content"],
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: Text(
                                timeAgo(notif["notif_date"]),
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
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- PassengerPickupTab ----------------

class PassengerPickupTab extends StatefulWidget {
  const PassengerPickupTab({super.key});

  @override
  State<PassengerPickupTab> createState() => _PassengerPickupTabState();
}

class _PassengerPickupTabState extends State<PassengerPickupTab> {
  late Future<List<dynamic>> _futurePickups;

  @override
  void initState() {
    super.initState();
    _futurePickups = fetchPendingTrips(); // 🔹 your endpoint
  }

  Future<void> _refreshData() async {
    setState(() {
      _futurePickups = fetchPendingTrips(); //refresh
    });
  }

  String timeAgo(String isoDate) {
    final date = DateTime.parse(isoDate);
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<dynamic>>(
          future: _futurePickups,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.hasData) {
              final pickups = snapshot.data!;
              if (pickups.isEmpty) {
                return const Center(child: Text("No pickups available."));
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Passenger Pick-ups',
                    style: TextStyle(
                      color: Color(0xFF3E4795),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 Capacity Status card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: const [
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
                          '2/20', // TODO: Replace with dynamic value
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
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

                  // 🔹 Dynamic pickup list
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: pickups.length,
                    itemBuilder: (context, index) {
                      final pickup = pickups[index];
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
                                Icons.location_on,
                                color: Color.fromRGBO(62, 71, 149, 1),
                                size: 28,
                              ),
                            ),
                            title: Text(
                              pickup['passenger_id'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Location: ${pickup['pickup_lat'] ?? ""}, ${pickup['pickup_lng'] ?? ""}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: Text(
                              timeAgo(pickup['created_at'] ?? ''),
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
                  ),
                ],
              );
            } else {
              return const Center(child: Text("No pickups available."));
            }
          },
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
  late final String conductorId;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    conductorId = userProvider.currentUser!.id;
  }

  String _formatTime(String isoDate) {
    final dateTime = DateTime.parse(isoDate).toLocal();
    return DateFormat('hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trips',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF3E4795),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,

      // 1. Use FutureBuilder for asynchronous data fetching
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchTripDetails(conductorId), // 👈 The future to watch
        builder: (context, snapshot) {
          // 2. Handle Loading State (Waiting)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. Handle Error State
          if (snapshot.hasError) {
            print("Error fetching trip details: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final tripData = snapshot.data;

          // 4. Handle No Data State (Data is null or empty)
          if (tripData == null) {
            return const Center(child: Text("No trip data available."));
          }

          // 5. Handle Data Received State (Data is available)
          final tripCount = tripData['trip_count'] ?? 0;
          final recentTrips = tripData['recent_trips'] ?? [];

          // The rest of your UI logic goes here
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Top Row: Trips & Passengers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Trips Container
                    // Note: Use tripCount here
                    _buildStatContainer("Trips Today", tripCount.toString()),

                    //fetch passengers count from backend after
                    _buildStatContainer("Total Passengers", "12"),
                  ],
                ),

                const SizedBox(height: 24),

                // Bottom: Recent Trips List
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Recent Trips",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E4795),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: recentTrips.length,
                          itemBuilder: (context, index) {
                            final trip = recentTrips[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              // Removed fixed height for cleaner layout
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFF3E4795),
                                    radius: 22,
                                    child: Icon(
                                      Icons.schedule,
                                      color: Colors.white,
                                      size: 27,
                                    ),
                                  ),
                                  title: Text(
                                    "Trip #${trip['trip_id'] ?? index + 1}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Started: ${_formatTime(trip['start_time'] ?? '--')} - Ended: ${_formatTime(trip['end_time'] ?? '--')}",
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
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to build the stat containers (for cleaner code)
  Widget _buildStatContainer(String title, String count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(
              0,
              4,
            ), // Changed offset for better shadow placement
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E4795),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
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
            leading: const Icon(
              Icons.confirmation_number,
              color: Color(0xFF3E4795),
            ),
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
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    value: 'Vehicle Breakdown',
                    groupValue: _selectedSituation,
                    onChanged: (val) =>
                        setState(() => _selectedSituation = val),
                    activeColor: Color(0xFF3E4795),
                    title: const Text('Vehicle Breakdown'),
                  ),
                  RadioListTile<String>(
                    value: 'Accident',
                    groupValue: _selectedSituation,
                    onChanged: (val) =>
                        setState(() => _selectedSituation = val),
                    activeColor: Color(0xFF3E4795),
                    title: const Text('Accident'),
                  ),
                  RadioListTile<String>(
                    value: 'Others',
                    groupValue: _selectedSituation,
                    onChanged: (val) =>
                        setState(() => _selectedSituation = val),
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
                onPressed: _selectedSituation == null
                    ? null
                    : () {
                        // TODO: Implement assistance logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Assistance requested for $_selectedSituation',
                            ),
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
