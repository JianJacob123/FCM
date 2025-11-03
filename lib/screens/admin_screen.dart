import 'account_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'admin_login_screen.dart';
import 'vehicle_assignment_screen.dart';
import 'analytics_screen.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

final baseUrl = dotenv.env['API_BASE_URL'];

// Constants for the rotating schedule
final List<String> kUnits = [for (int i = 1; i <= 15; i++) 'Unit $i'];

final List<String> kTimeSlots = List.generate(15, (i) {
  final totalMinutes = 5 * 60 + i * 15;
  final hour = totalMinutes ~/ 60;
  final minute = totalMinutes % 60;
  final period = hour < 12 ? 'AM' : 'PM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
});

enum AdminSection {
  liveTracking,
  analytics,
  notifications,
  schedule,
  vehicleAssignment,

  tripHistory,
  accountManagement,
  activityLogs,
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  AdminSection _selectedSection = AdminSection.liveTracking;
  int? _selectedBusIndex;
  bool _showRoutePolyLine = false;
  final MapController _mapController = MapController();
  bool _isEditMode = false;
  bool _isSidebarOpen = false;

  // Navigation state
  bool _recordsExpanded = false;
  bool _settingsExpanded = false;

  // Controllers for editable fields
  final List<TextEditingController> _timeControllers = List.generate(
    15,
    (index) => TextEditingController(),
  );
  final List<String> _unitValues = List.generate(
    15,
    (index) => 'Unit ${index + 1}',
  );
  final List<String> _driverValues = List.generate(
    15,
    (index) => 'Driver ${index + 1}',
  );
  final List<String> _conductorValues = List.generate(
    15,
    (index) => 'Conductor ${index + 1}',
  );
  final List<String> _statusValues = List.generate(15, (index) => 'Active');

  // Route points for tracking
  final List<LatLng> _routePoints = [
    LatLng(13.9467729, 121.1555241),
    LatLng(13.948197503981618, 121.15663127065292),
    LatLng(13.950278979606711, 121.15838610642095),
    LatLng(13.951033283494375, 121.15975747814403),
    LatLng(13.952865846616918, 121.16308555449044),
  ];

  // Dummy schedule data for the week
  final Map<String, List<Map<String, dynamic>>> _weeklySchedules = {
    'Monday': [
      {
        'driver': 'John Smith',
        'unit': 'FCM No. 15',
        'firstTrip': '06:00 AM',
        'lastTrip': '07:00 AM',
      },
      {
        'driver': 'Maria Garcia',
        'unit': 'FCM No. 22',
        'firstTrip': '06:15 AM',
        'lastTrip': '07:15 AM',
      },
      {
        'driver': 'David Wilson',
        'unit': 'FCM No. 08',
        'firstTrip': '06:30 AM',
        'lastTrip': '07:30 AM',
      },
      {
        'driver': 'Sarah Johnson',
        'unit': 'FCM No. 33',
        'firstTrip': '06:45 AM',
        'lastTrip': '07:45 AM',
      },
    ],
    'Tuesday': [
      {
        'driver': 'Michael Brown',
        'unit': 'FCM No. 12',
        'firstTrip': '06:00 AM',
        'lastTrip': '07:00 AM',
      },
      {
        'driver': 'Lisa Davis',
        'unit': 'FCM No. 19',
        'firstTrip': '06:15 AM',
        'lastTrip': '07:15 AM',
      },
      {
        'driver': 'Robert Taylor',
        'unit': 'FCM No. 25',
        'firstTrip': '06:30 AM',
        'lastTrip': '07:30 AM',
      },
    ],
    'Wednesday': [
      {
        'driver': 'John Smith',
        'unit': 'FCM No. 15',
        'firstTrip': '06:00 AM',
        'lastTrip': '07:00 AM',
      },
      {
        'driver': 'Emma Wilson',
        'unit': 'FCM No. 28',
        'firstTrip': '06:15 AM',
        'lastTrip': '07:15 AM',
      },
      {
        'driver': 'James Anderson',
        'unit': 'FCM No. 11',
        'firstTrip': '06:30 AM',
        'lastTrip': '07:30 AM',
      },
      {
        'driver': 'Maria Garcia',
        'unit': 'FCM No. 22',
        'firstTrip': '06:45 AM',
        'lastTrip': '07:45 AM',
      },
    ],
    'Thursday': [
      {
        'driver': 'David Wilson',
        'unit': 'FCM No. 08',
        'firstTrip': '06:00 AM',
        'lastTrip': '07:00 AM',
      },
      {
        'driver': 'Sarah Johnson',
        'unit': 'FCM No. 33',
        'firstTrip': '06:15 AM',
        'lastTrip': '07:15 AM',
      },
      {
        'driver': 'Michael Brown',
        'unit': 'FCM No. 12',
        'firstTrip': '06:30 AM',
        'lastTrip': '07:30 AM',
      },
    ],
    'Friday': [
      {
        'driver': 'John Smith',
        'unit': 'FCM No. 15',
        'firstTrip': '06:00 AM',
        'lastTrip': '07:00 AM',
      },
      {
        'driver': 'Lisa Davis',
        'unit': 'FCM No. 19',
        'firstTrip': '06:15 AM',
        'lastTrip': '07:15 AM',
      },
      {
        'driver': 'Robert Taylor',
        'unit': 'FCM No. 25',
        'firstTrip': '06:30 AM',
        'lastTrip': '07:30 AM',
      },
      {
        'driver': 'Emma Wilson',
        'unit': 'FCM No. 28',
        'firstTrip': '06:45 AM',
        'lastTrip': '07:45 AM',
      },
    ],
    'Saturday': [
      {
        'driver': 'James Anderson',
        'unit': 'FCM No. 11',
        'firstTrip': '07:00 AM',
        'lastTrip': '08:00 AM',
      },
      {
        'driver': 'Maria Garcia',
        'unit': 'FCM No. 22',
        'firstTrip': '07:15 AM',
        'lastTrip': '08:15 AM',
      },
    ],
    'Sunday': [
      {
        'driver': 'David Wilson',
        'unit': 'FCM No. 08',
        'firstTrip': '08:00 AM',
        'lastTrip': '09:00 AM',
      },
      {
        'driver': 'Sarah Johnson',
        'unit': 'FCM No. 33',
        'firstTrip': '08:15 AM',
        'lastTrip': '09:15 AM',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    // Initialize controllers with default values for 15 units
    final timeSlots = [
      '04:00 AM',
      '04:20 AM',
      '04:40 AM',
      '05:00 AM',
      '05:20 AM',
      '05:40 AM',
      '06:00 AM',
      '06:30 AM',
      '07:00 AM',
      '07:30 AM',
      '08:00 AM',
      '08:30 AM',
      '09:00 AM',
      '09:30 AM',
      '10:00 AM',
    ];

    for (int i = 0; i < 15; i++) {
      _timeControllers[i].text = timeSlots[i];
      _unitValues[i] = 'Unit ${i + 1}';
      _driverValues[i] = 'Driver ${i + 1}';
      _conductorValues[i] = 'Conductor ${i + 1}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Coding':
        return Colors.orange;
      case 'Driver Sick':
        return Colors.red;
      case 'Maintenance':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Active':
        return Icons.check_circle;
      case 'Coding':
        return Icons.code;
      case 'Driver Sick':
        return Icons.sick;
      case 'Maintenance':
        return Icons.build;
      default:
        return Icons.check_circle;
    }
  }

  int _getActiveUnitsCount() {
    int count = 0;
    for (int i = 0; i < 15; i++) {
      if (_statusValues[i] == 'Active') {
        count++;
      }
    }
    return count;
  }

  int _getActiveUnitIndex(int displayIndex) {
    int activeCount = 0;
    for (int i = 0; i < 15; i++) {
      if (_statusValues[i] == 'Active') {
        if (activeCount == displayIndex) {
          return i;
        }
        activeCount++;
      }
    }
    return 0; // Fallback
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _timeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF3E4795),
              foregroundColor: Colors.white,
              title: const Text('FCM Admin'),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    setState(() => _isSidebarOpen = !_isSidebarOpen),
              ),
            )
          : null,
      body: Row(
        children: [
          // Sidebar - responsive visibility
          if (!isMobile || _isSidebarOpen) ...[
            Container(
              width: isMobile ? screenWidth * 0.8 : 260,
              color: Colors.white,
              child: Column(
                children: [
                  if (isMobile) ...[
                    // Mobile header with close button
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'FCM Admin',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E4795),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF3E4795),
                            ),
                            onPressed: () =>
                                setState(() => _isSidebarOpen = false),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 32),
                  ],
                  // Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Image.asset(
                      'assets/logo.png',
                      height: isMobile ? 120 : 170,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Navigation Items
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Live Tracking
                          _SidebarItem(
                            icon: Icons.map,
                            label: 'Live Tracking',
                            selected:
                                _selectedSection == AdminSection.liveTracking,
                            onTap: () {
                              setState(() {
                                _selectedSection = AdminSection.liveTracking;
                                if (isMobile) _isSidebarOpen = false;
                              });
                            },
                          ),

                          // Analytics
                          _SidebarItem(
                            icon: Icons.analytics,
                            label: 'Analytics',
                            selected:
                                _selectedSection == AdminSection.analytics,
                            onTap: () {
                              setState(() {
                                _selectedSection = AdminSection.analytics;
                                if (isMobile) _isSidebarOpen = false;
                              });
                            },
                          ),

                          // Notifications
                          _SidebarItem(
                            icon: Icons.notifications,
                            label: 'Notifications',
                            selected:
                                _selectedSection == AdminSection.notifications,
                            onTap: () {
                              setState(() {
                                _selectedSection = AdminSection.notifications;
                                if (isMobile) _isSidebarOpen = false;
                              });
                            },
                          ),

                          // Records (Expandable)
                          _ExpandableSidebarItem(
                            icon: Icons.folder,
                            label: 'Records',
                            expanded: _recordsExpanded,
                            onToggle: () {
                              setState(() {
                                _recordsExpanded = !_recordsExpanded;
                              });
                            },
                            children: [
                              _SidebarItem(
                                icon: Icons.calendar_today,
                                label: 'Schedule',
                                selected:
                                    _selectedSection == AdminSection.schedule,
                                isSubItem: true,
                                onTap: () {
                                  setState(() {
                                    _selectedSection = AdminSection.schedule;
                                    if (isMobile) _isSidebarOpen = false;
                                  });
                                },
                              ),
                              _SidebarItem(
                                icon: Icons.directions_car,
                                label: 'Vehicle Assignment',
                                selected:
                                    _selectedSection ==
                                    AdminSection.vehicleAssignment,
                                isSubItem: true,
                                onTap: () {
                                  setState(() {
                                    _selectedSection =
                                        AdminSection.vehicleAssignment;
                                    if (isMobile) _isSidebarOpen = false;
                                  });
                                },
                              ),
                              _SidebarItem(
                                icon: Icons.account_circle,
                                label: 'Employee Management',
                                selected:
                                    _selectedSection ==
                                    AdminSection.accountManagement,
                                isSubItem: true,
                                onTap: () {
                                  setState(() {
                                    _selectedSection =
                                        AdminSection.accountManagement;
                                    if (isMobile) _isSidebarOpen = false;
                                  });
                                },
                              ),

                              _SidebarItem(
                                icon: Icons.history,
                                label: 'Trip History',
                                selected:
                                    _selectedSection ==
                                    AdminSection.tripHistory,
                                isSubItem: true,
                                onTap: () {
                                  setState(() {
                                    _selectedSection = AdminSection.tripHistory;
                                    if (isMobile) _isSidebarOpen = false;
                                  });
                                },
                              ),
                              _SidebarItem(
                                icon: Icons.access_time,
                                label: 'Activity Logs',
                                selected:
                                    _selectedSection ==
                                    AdminSection.activityLogs,
                                isSubItem: true,
                                onTap: () {
                                  setState(() {
                                    _selectedSection =
                                        AdminSection.activityLogs;
                                    if (isMobile) _isSidebarOpen = false;
                                  });
                                },
                              ),
                            ],
                          ),

                          // Logout (standalone)
                          _SidebarItem(
                            icon: Icons.logout,
                            label: 'Logout',
                            selected: false,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: const Text('Logout'),
                                  content: const Text(
                                    'Are you sure you want to log out?',
                                  ),
                                  actions: [
                                    OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF3E4795,
                                        ),
                                        side: const BorderSide(
                                          color: Colors.grey,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const AdminLoginScreen(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF3E4795,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Main content
          Expanded(
            child: Stack(
              children: [
                _buildMainContent(),
                // Overlay for mobile when sidebar is open
                if (isMobile && _isSidebarOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSidebarOpen = false),
                      child: Container(color: Colors.black.withOpacity(0.5)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedSection) {
      case AdminSection.liveTracking:
        return const MapScreen();
      case AdminSection.analytics:
        return const ForecastAnalyticsScreen();
      case AdminSection.notifications:
        return Container(
          color: Colors.grey[100],
          child: _NotificationsWithCompose(),
        );
      case AdminSection.schedule:
        return Container(color: Colors.grey[100], child: _DailyScheduleView());
      case AdminSection.vehicleAssignment:
        return Container(
          color: Colors.grey[100],
          child: const VehicleAssignmentScreen(),
        );

      case AdminSection.tripHistory:
        return Container(
          color: Colors.grey[100],
          child: const _TripHistoryPage(),
        );
      case AdminSection.accountManagement:
        return Container(
          color: Colors.grey[100],
          child: const AccountManagementScreen(),
        );
      case AdminSection.activityLogs:
        return Container(
          color: Colors.grey[100],
          child: const _ActivityLogsPage(),
        );
      default:
        return const Center(
          child: Text('Section coming soon...', style: TextStyle(fontSize: 24)),
        );
    }
  }

  Widget _AnalyticsPage() {
    return const ForecastAnalyticsScreen();
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _UserManagementPage() {
    return const Center(
      child: Text(
        'User Management Page',
        style: TextStyle(fontSize: 24, color: Colors.grey),
      ),
    );
  }

  Widget _buildUserManagementCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _DailyScheduleView() {
    return const DailyScheduleCrud();
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
  List<dynamic> _pendingPickups = [];
  LatLng? _highlightedPickup;
  bool _showPickupList = false; // show pending pickups by default

  @override
  void initState() {
    super.initState();

    _loadPendingPickups();

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

  //vehicle info modal logic
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

          //search field on top temporary removal

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
              bottom: 80,
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
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
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
                    const SizedBox(height: 8),
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

// Admin Search Field similar to passenger search
class AdminSearchField extends StatefulWidget {
  final void Function(LatLng selectedLocation, String placeName)
  onLocationSelected;

  const AdminSearchField({super.key, required this.onLocationSelected});

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];

  Future<void> _searchPlace(String query) async {
    final accessToken =
        'INSERT TOKEN HERE'; // Replace with your Mapbox access token
    final encodedQuery = Uri.encodeComponent(query);

    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json'
      '?access_token=$accessToken'
      '&limit=5',
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
                  hintText: 'Search for vehicles, routes, or locations...',
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

// Enhanced Admin Bus Info Card
class _AdminBusInfoCard extends StatelessWidget {
  final Map<String, Object> bus;
  final VoidCallback onClose;
  final VoidCallback onTrackRoute;

  const _AdminBusInfoCard({
    required this.bus,
    required this.onClose,
    required this.onTrackRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus['busNo'] as String,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E4795),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bus['route'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E4795),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'ONBOARDING',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 28),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF3E4795)),
                const SizedBox(width: 8),
                const Text(
                  'Estimated Time of Arrival',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Text(
                  bus['eta'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF3E4795)),
                const SizedBox(width: 8),
                const Text('Current Location', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text(
                  bus['location'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.directions_bus, color: Color(0xFF3E4795)),
                const SizedBox(width: 8),
                const Text('Route Runs', style: TextStyle(fontSize: 16)),
                const Spacer(),
                const Text(
                  '3',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTrackRoute,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3E4795),
                  side: const BorderSide(color: Color(0xFF3E4795)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Track Live Trip'),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFF3E4795)),
                const SizedBox(width: 8),
                const Text(
                  '4.8',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: 4),
                const Text('(100 ratings)', style: TextStyle(fontSize: 16)),
                const Spacer(),
                const Text(
                  'Nelson Suarez',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: const [
                Icon(Icons.directions_bus, color: Color(0xFF3E4795)),
                SizedBox(width: 8),
                Text('Average bus rating', style: TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool isSubItem;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    this.isSubItem = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 4,
        horizontal: isSubItem ? 24 : 12,
      ),
      decoration: selected
          ? BoxDecoration(
              color: const Color(0xFFE8EAFE),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF3E4795),
          size: isSubItem ? 20 : 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: const Color(0xFF3E4795),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: isSubItem ? 14 : 16,
          ),
        ),
        selected: selected,
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSubItem ? 8 : 16,
          vertical: 4,
        ),
      ),
    );
  }
}

class _ExpandableSidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _ExpandableSidebarItem({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: ListTile(
            leading: Icon(icon, color: const Color(0xFF3E4795)),
            title: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF3E4795),
                fontWeight: FontWeight.normal,
              ),
            ),
            trailing: Icon(
              expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
              color: const Color(0xFF3E4795),
            ),
            onTap: onToggle,
          ),
        ),
        if (expanded) ...children,
      ],
    );
  }
}

class NotificationList extends StatelessWidget {
  const NotificationList({super.key});

  // The corrected timeAgo function

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
    return FutureBuilder<List<dynamic>>(
      future: fetchNotifications('all'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No notifications available."));
        }

        final notifications = snapshot.data!;

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            final title = notif['notif_title'] ?? '';
            final subtitle = notif['content'] ?? '';
            final time = timeAgo(notif['notif_date'] ?? '');
            final type = notif['notif_type'] ?? '';
            final isUrgent = type.toLowerCase() == "urgent";

            return _NotificationItem(
              title: title,
              subtitle: subtitle,
              time: time,
              urgent: isUrgent,
            );
          },
        );
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool urgent;

  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (urgent)
            const Padding(
              padding: EdgeInsets.only(right: 8.0, top: 2),
              child: Icon(Icons.error, color: Colors.red, size: 20),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgent ? 'Urgent Notification Received' : title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: urgent ? Colors.red : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: urgent ? Colors.black : Colors.black87,
                    fontStyle: urgent ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3E4795),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
    );
  }
}

class _ActivityLogsPage extends StatefulWidget {
  const _ActivityLogsPage();

  @override
  State<_ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<_ActivityLogsPage> {
  DateTime selectedDate = DateTime.now();

  // Filters for Activity Logs
  List<String> selectedActivityTypes = [];
  DateTime? logsStartDate;
  DateTime? logsEndDate;
  String logsSortOrder = 'asc'; // 'asc' or 'desc'

  // Example log data
  final List<Map<String, String>> activityLogs = [
    {
      "time": "08:00:00",
      "activity": "Bus departed terminal",
      "status": "Completed",
    },
    {
      "time": "08:30:00",
      "activity": "Reached first stop",
      "status": "Completed",
    },
    {"time": "09:00:00", "activity": "Bus on route", "status": "Ongoing"},
  ];

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  String timeAgo(String isoDate) {
    final date = DateTime.parse(isoDate).toLocal();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM dd').format(date);
  }

  // Apply filters to activity logs list
  List<dynamic> _applyLogFilters(List<dynamic> logs) {
    Iterable<dynamic> filtered = logs;

    if (selectedActivityTypes.isNotEmpty) {
      filtered = filtered.where(
        (log) => selectedActivityTypes.contains(
          (log['activity_type'] ?? '').toString(),
        ),
      );
    }

    if (logsStartDate != null || logsEndDate != null) {
      final DateTime? start = logsStartDate != null
          ? DateTime(
              logsStartDate!.year,
              logsStartDate!.month,
              logsStartDate!.day,
            )
          : null;
      final DateTime? end = logsEndDate != null
          ? DateTime(
              logsEndDate!.year,
              logsEndDate!.month,
              logsEndDate!.day,
              23,
              59,
              59,
            )
          : null;

      filtered = filtered.where((log) {
        try {
          final createdAt = DateTime.parse(
            (log['created_at'] ?? '').toString(),
          );
          if (start != null && createdAt.isBefore(start)) return false;
          if (end != null && createdAt.isAfter(end)) return false;
          return true;
        } catch (_) {
          return true; // keep if unparsable
        }
      });
    }

    // Apply sorting
    List<dynamic> sortedList = filtered.toList();
    sortedList.sort((a, b) {
      try {
        final dateA = DateTime.parse((a['created_at'] ?? '').toString());
        final dateB = DateTime.parse((b['created_at'] ?? '').toString());

        if (logsSortOrder == 'asc') {
          return dateA.compareTo(dateB);
        } else {
          return dateB.compareTo(dateA);
        }
      } catch (_) {
        return 0; // keep original order if parsing fails
      }
    });

    return sortedList;
  }

  void _showActivityTypeFilterModal(List<String> types) {
    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List<String>.from(selectedActivityTypes);
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool allSelected =
                types.isNotEmpty && tempSelected.length == types.length;
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                children: const [
                  Icon(Icons.filter_list, color: Color(0xFF3E4795)),
                  SizedBox(width: 8),
                  Text('Filter by Activity Type'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width < 520
                    ? MediaQuery.of(context).size.width * 0.9
                    : 480,
                height: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: const Text('Select All'),
                      value: allSelected,
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            tempSelected = List<String>.from(types);
                          } else {
                            tempSelected.clear();
                          }
                        });
                      },
                      activeColor: const Color(0xFF3E4795),
                      contentPadding: EdgeInsets.zero,
                    ),
                    Divider(color: Colors.grey[300]),
                    Container(
                      height: 200,
                      child: ListView.builder(
                        itemCount: types.length,
                        itemBuilder: (context, index) {
                          final type = types[index];
                          final bool isSelected = tempSelected.contains(type);
                          return CheckboxListTile(
                            title: Text(type),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setModalState(() {
                                if (value == true) {
                                  tempSelected.add(type);
                                } else {
                                  tempSelected.remove(type);
                                }
                              });
                            },
                            activeColor: const Color(0xFF3E4795),
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3E4795),
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedActivityTypes = tempSelected;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E4795),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTimestampFilterModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                children: const [
                  Icon(Icons.calendar_month, color: Color(0xFF3E4795)),
                  SizedBox(width: 8),
                  Text('Filter by Date'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width < 520
                    ? MediaQuery.of(context).size.width * 0.85
                    : 450,
                height: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start Date
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: logsStartDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            logsStartDate = picked;
                            if (logsEndDate != null &&
                                picked.isAfter(logsEndDate!)) {
                              logsEndDate = null;
                            }
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: Color(0xFF3E4795),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                logsStartDate != null
                                    ? '${logsStartDate!.month.toString().padLeft(2, '0')}/${logsStartDate!.day.toString().padLeft(2, '0')}/${logsStartDate!.year}'
                                    : 'Start Date',
                                style: TextStyle(
                                  color: logsStartDate != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // End Date
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate:
                              logsEndDate ?? logsStartDate ?? DateTime.now(),
                          firstDate: logsStartDate ?? DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            logsEndDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: Color(0xFF3E4795),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                logsEndDate != null
                                    ? '${logsEndDate!.month.toString().padLeft(2, '0')}/${logsEndDate!.day.toString().padLeft(2, '0')}/${logsEndDate!.year}'
                                    : 'End Date',
                                style: TextStyle(
                                  color: logsEndDate != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Sort Order Dropdown
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: logsSortOrder.isNotEmpty
                              ? logsSortOrder
                              : 'asc',
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: 'asc',
                              child: Text('Ascending'),
                            ),
                            DropdownMenuItem(
                              value: 'desc',
                              child: Text('Descending'),
                            ),
                          ],
                          onChanged: (String? value) {
                            setModalState(() {
                              logsSortOrder = value ?? 'asc';
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Clear button (text only, positioned above action buttons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              logsStartDate = null;
                              logsEndDate = null;
                              logsSortOrder = 'asc';
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFF3E4795),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          child: Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF3E4795),
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Trigger rebuild with the updated date range filters
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3E4795),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header (matching Trip History)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity Logs',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E4795),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          // Refresh activity logs
                        });
                      },
                      child: Icon(
                        Icons.refresh,
                        size: 20,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),

            // Table header (matching Trip History) with filter icons
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF3E4795),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Text(
                          'Activity Type',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            // Build unique list of activity types from current data
                            final logs = await fetchActivityLogs();
                            final types =
                                logs
                                    .map(
                                      (e) =>
                                          (e['activity_type'] ?? '').toString(),
                                    )
                                    .where((e) => e.isNotEmpty)
                                    .toSet()
                                    .toList()
                                  ..sort();
                            _showActivityTypeFilterModal(types);
                          },
                          child: Icon(
                            Icons.filter_list,
                            color: selectedActivityTypes.isNotEmpty
                                ? Colors.lightBlue
                                : Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Description',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Text(
                          'Timestamp',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showTimestampFilterModal,
                          child: Icon(
                            Icons.filter_list,
                            color:
                                (logsStartDate != null || logsEndDate != null)
                                ? Colors.lightBlue
                                : Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Table body (matching Trip History)
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: fetchActivityLogs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF3E4795)),
                          SizedBox(height: 16),
                          Text('Loading activity logs...'),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No activity logs found.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final logs = snapshot.data!;

                  final filteredLogs = _applyLogFilters(logs);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ListView.builder(
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        final isLast = index == filteredLogs.length - 1;
                        return Container(
                          decoration: BoxDecoration(
                            color: index % 2 == 0
                                ? Colors.white
                                : Colors.grey[50],
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  log['activity_type'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF232A4D),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  log['description'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF232A4D),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  timeAgo(log['created_at']),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF232A4D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15, // reduced font size
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 6,
        ), // more compact
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13, // reduced font size
            color: Color(0xFF232A4D),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String? name;
  final bool isMe;
  final String text;
  const _ChatBubble({this.name, this.isMe = false, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (name != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 2, left: 4, right: 4),
              child: Text(
                name!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF3E4795),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isMe)
                const CircleAvatar(
                  backgroundColor: Color(0xFFBFC6F7),
                  radius: 16,
                  child: Icon(Icons.person, color: Color(0xFF3E4795)),
                ),
              if (!isMe) const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFF3E4795)
                      : const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 16),
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF232A4D),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String? name;
  final bool isMe;
  final String text;
  _ChatMessage({this.name, this.isMe = false, required this.text});
}

class _NotificationsWithCompose extends StatefulWidget {
  @override
  State<_NotificationsWithCompose> createState() =>
      _NotificationsWithComposeState();
}

class _NotificationsWithComposeState extends State<_NotificationsWithCompose> {
  bool _showCompose = false;
  bool _showSuccess = false;
  bool _showScheduledModal = false;
  int? _editingIndex;

  // Store scheduled notifications
  List<Map<String, dynamic>> _scheduledNotifications = [
    // Example scheduled notification
    // {
    //   'title': 'System Maintenance',
    //   'type': 'Service Maintenance',
    //   'content': 'Scheduled downtime at 10pm.',
    //   'recipients': {'All Commuters'},
    //   'schedule': DateTime.now().add(Duration(days: 1)),
    // },
  ];

  void _openCompose([int? index]) {
    setState(() {
      _editingIndex = index;
      _showCompose = true;
    });
  }

  void _closeCompose() => setState(() => _showCompose = false);
  void _showSuccessDialog() => setState(() {
    _showCompose = false;
    _showSuccess = true;
  });
  void _closeSuccessDialog() => setState(() => _showSuccess = false);
  void _openScheduledModal() => setState(() => _showScheduledModal = true);
  void _closeScheduledModal() => setState(() => _showScheduledModal = false);

  void _saveScheduledNotification(Map<String, dynamic> notif) {
    setState(() {
      if (_editingIndex != null) {
        _scheduledNotifications[_editingIndex!] = notif;
      } else {
        _scheduledNotifications.add(notif);
      }
      _showCompose = false;
      _editingIndex = null;
    });
  }

  void _deleteScheduledNotification(int index) {
    setState(() {
      _scheduledNotifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            width: 900,
            margin: const EdgeInsets.symmetric(vertical: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 24,
                  offset: Offset(0, 8),
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
                      'Notifications',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _openCompose(),
                          child: Container(
                            width: 170,
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: Color(0xFFF0F3FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.edit,
                                  color: Color(0xFF3E4795),
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Compose',
                                  style: TextStyle(
                                    color: Color(0xFF3E4795),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Expanded(child: NotificationList()),
              ],
            ),
          ),
        ),
        // scheduled notifications modal removed
        if (_showCompose)
          _ComposeNotificationModal(
            onSave: (notif) async {
              final formattedDate = DateFormat(
                'yyyy-MM-dd HH:mm:ss',
              ).format(DateTime.now().toUtc());
              // Call your backend API here
              await createNotification(
                notif['title'],
                notif['type'],
                notif['content'],
                formattedDate,
                (notif['recipients'] as Set<String>).join(
                  ',',
                ), // flatten Set to string
              );

              _showSuccessDialog();
              // No scheduled storage
            },
            onCancel: _closeCompose,
            initialData: null,
          ),
        if (_showSuccess) _NotificationSentDialog(onOk: _closeSuccessDialog),
      ],
    );
  }
}

// Modal for scheduled notifications
// Scheduled notifications modal removed

// Update ComposeNotificationModal to accept initialData for editing
class _ComposeNotificationModal extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;
  final Map<String, dynamic>? initialData;
  const _ComposeNotificationModal({
    required this.onSave,
    required this.onCancel,
    this.initialData,
  });

  @override
  State<_ComposeNotificationModal> createState() =>
      _ComposeNotificationModalState();
}

class _ComposeNotificationModalState extends State<_ComposeNotificationModal> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _type;
  String? _content;
  Set<String> _recipients = {'All Commuters', 'All FCM Unit'};

  final List<String> _types = [
    'General Announcement',
    'System Notification',
    'Route Update',
    'Service Maintenance',
  ];
  final List<String> _recipientOptions = ['All Commuters', 'All FCM Unit'];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _title = widget.initialData!['title'];
      _type = widget.initialData!['type'];
      _content = widget.initialData!['content'];
      _recipients = Set<String>.from(widget.initialData!['recipients'] ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.08),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Compose',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: Color(0xFF3E4795),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.edit, color: Color(0xFF3E4795), size: 28),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Notification Title',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: _title,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (v) => setState(() => _title = v),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Notification Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      items: _types
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _type = v),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Content',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: _content,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (v) => setState(() => _content = v),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Recipient',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Column(
                      children: _recipientOptions
                          .map(
                            (r) => CheckboxListTile(
                              value: _recipients.contains(r),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _recipients.add(r);
                                  } else {
                                    _recipients.remove(r);
                                  }
                                });
                              },
                              title: Text(r),
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3E4795),
                            side: const BorderSide(color: Color(0xFF3E4795)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onSave({
                                'title': _title,
                                'type': _type,
                                'content': _content,
                                'recipients': _recipients,
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E4795),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationSentDialog extends StatelessWidget {
  final VoidCallback onOk;
  const _NotificationSentDialog({required this.onOk});
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.08),
        child: Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'NOTIFICATION SENT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Color(0xFF3E4795),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your action has been completed successfully. The notification is now live.',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onOk,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E4795),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('OK', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleWeekView extends StatefulWidget {
  @override
  State<_ScheduleWeekView> createState() => _ScheduleWeekViewState();
}

class _ScheduleWeekViewState extends State<_ScheduleWeekView> {
  DateTime _currentWeek = DateTime.now();
  bool _showModal = false;
  bool _isEditMode = false;

  // Store the order of units for each day in the current week
  late Map<int, List<String>> _weekUnitOrders;

  @override
  void initState() {
    super.initState();
    _initWeekUnitOrders();
  }

  void _initWeekUnitOrders() {
    // Use a fixed reference date (e.g., Jan 1, 2024)
    final referenceDate = DateTime(2024, 1, 1);
    _weekUnitOrders = {};
    final weekStart = _currentWeek.subtract(
      Duration(days: _currentWeek.weekday % 7),
    );
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final daysSinceStart = day.difference(referenceDate).inDays;
      final offset = daysSinceStart % kUnits.length;
      _weekUnitOrders[i] = [
        ...kUnits.sublist(offset),
        ...kUnits.sublist(0, offset),
      ];
    }
  }

  void _onReorder(int dayIndex, int oldIndex, int newIndex) {
    setState(() {
      final units = _weekUnitOrders[dayIndex]!;
      if (newIndex > oldIndex) newIndex--;
      final item = units.removeAt(oldIndex);
      units.insert(newIndex, item);
    });
  }

  List<Map<String, dynamic>> getScheduleForDay(int dayIndex) {
    final units = _weekUnitOrders[dayIndex]!;
    return List.generate(units.length, (i) {
      final timeStr = kTimeSlots[i];
      return {
        'unit': units[i],
        'startTime': timeStr,
        'driver': 'Driver ${units[i].split(' ').last}',
      };
    });
  }

  List<DateTime> get _weekDays {
    final start = _currentWeek.subtract(
      Duration(days: _currentWeek.weekday % 7),
    );
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  String _weekdayLabel(int weekday) {
    const labels = ['', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return labels[weekday];
  }

  String _getDayName(int weekday) {
    const dayNames = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return dayNames[weekday];
  }

  bool _isFutureDate(DateTime date) {
    final now = DateTime.now();
    return date.isAfter(DateTime(now.year, now.month, now.day));
  }

  void _nextWeek() {
    setState(() => _currentWeek = _currentWeek.add(const Duration(days: 7)));
  }

  void _prevWeek() {
    setState(
      () => _currentWeek = _currentWeek.subtract(const Duration(days: 7)),
    );
  }

  void _goToday() {
    setState(() => _currentWeek = DateTime.now());
  }

  void _addSchedule(Map<String, dynamic> sched) {
    setState(() {
      _showModal = false;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  // Helper to generate a dummy plate number for each unit
  String getPlateNumber(String unit) {
    // e.g., Unit 1 -> ABC 1001
    final num = int.tryParse(unit.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 'ABC ${1000 + num}';
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _weekDays;
    return Stack(
      children: [
        Center(
          child: Container(
            width: 900,
            margin: const EdgeInsets.symmetric(vertical: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 24,
                  offset: Offset(0, 8),
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
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF3E4795),
                          ),
                          onPressed: _prevWeek,
                        ),
                        TextButton(
                          onPressed: _goToday,
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              color: Color(0xFF3E4795),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF3E4795),
                          ),
                          onPressed: _nextWeek,
                        ),
                      ],
                    ),
                    Text(
                      '${_weekDays.first.month == _weekDays.last.month ? _monthName(_weekDays.first.month) : _monthName(_weekDays.first.month) + ' / ' + _monthName(_weekDays.last.month)} ${_weekDays.first.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    // Button row
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _showModal = true),
                          icon: const Icon(
                            Icons.add,
                            size: 20,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Add Driver',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time column
                      Container(
                        width: 44,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 36), // Header height
                            ...List.generate(
                              kUnits.length,
                              (i) => Container(
                                height: 32,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 1,
                                  horizontal: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  kTimeSlots[i],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 8,
                                    color: Color(0xFF3E4795),
                                  ),
                                  textAlign: TextAlign.center,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...weekDays.asMap().entries.map((entry) {
                        final dayIdx = entry.key;
                        final day = entry.value;
                        final isToday =
                            DateTime.now().year == day.year &&
                            DateTime.now().month == day.month &&
                            DateTime.now().day == day.day;
                        final isPastDay = day.isBefore(
                          DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                          ),
                        );
                        final daySchedules = getScheduleForDay(dayIdx);
                        return Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header: day number on top, day name below, both centered
                              Container(
                                height: 36,
                                width: 56,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        color: isToday
                                            ? const Color(0xFF1A237E)
                                            : const Color(0xFF3E4795),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _weekdayLabel(day.weekday),
                                      style: TextStyle(
                                        color: isToday
                                            ? const Color(0xFF1A237E)
                                            : const Color(0xFF3E4795),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                        letterSpacing: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ReorderableListView(
                                  buildDefaultDragHandles: false,
                                  onReorder: (oldIndex, newIndex) {
                                    if (isPastDay)
                                      return; // Prevent reordering for past days
                                    _onReorder(dayIdx, oldIndex, newIndex);
                                  },
                                  children: List.generate(kUnits.length, (i) {
                                    final s = daySchedules[i];
                                    return Container(
                                      key: ValueKey(s['unit']),
                                      height: 32,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 1,
                                        horizontal: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isPastDay
                                            ? Colors.grey[300]
                                            : (isToday
                                                  ? Colors.blue[50]
                                                  : const Color(0xFFE8EAFE)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      _UnitDetailsDialog(
                                                        driver: s['driver'],
                                                        unit: s['unit'],
                                                        plateNo: getPlateNumber(
                                                          s['unit'],
                                                        ),
                                                        date: day,
                                                        routeRuns: 3,
                                                        firstTrip:
                                                            s['startTime'],
                                                        lastTrip: isPastDay
                                                            ? '07:30 PM'
                                                            : '',
                                                        isPast: isPastDay,
                                                      ),
                                                );
                                              },
                                              child: Text(
                                                s['unit'],
                                                style: TextStyle(
                                                  color: isPastDay
                                                      ? Colors.grey[600]
                                                      : const Color(0xFF3E4795),
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 10,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          if (!isPastDay && _isEditMode)
                                            ReorderableDragStartListener(
                                              index: i,
                                              child: const Icon(
                                                Icons.drag_handle,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showModal)
          _AddDriverModal(
            onSave: (driver, unit, date) {
              _addSchedule({'driver': driver, 'unit': unit, 'date': date});
            },
            onCancel: () => setState(() => _showModal = false),
            initialDate: weekDays[0],
          ),
      ],
    );
  }
}

class _AddDriverModal extends StatefulWidget {
  final void Function(String driver, String unit, DateTime date) onSave;
  final VoidCallback onCancel;
  final DateTime initialDate;
  const _AddDriverModal({
    required this.onSave,
    required this.onCancel,
    required this.initialDate,
  });

  @override
  State<_AddDriverModal> createState() => _AddDriverModalState();
}

class _AddDriverModalState extends State<_AddDriverModal> {
  final _formKey = GlobalKey<FormState>();
  String? _driver;
  String? _unit;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.08),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add Default Driver',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Assigning a default driver ensures they are automatically included in the daily schedule. This can be updated anytime.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black38,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (v) => setState(() => _driver = v),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Assign Unit Number',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (v) => setState(() => _unit = v),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (_driver != null && _unit != null) {
                              widget.onSave(
                                _driver!,
                                _unit!,
                                _date ?? DateTime.now(),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E4795),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3E4795),
                            side: const BorderSide(color: Color(0xFF3E4795)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitDetailsDialog extends StatelessWidget {
  final String driver;
  final String unit;
  final String plateNo;
  final DateTime date;
  final int? routeRuns;
  final String firstTrip;
  final String lastTrip;
  final bool isPast;

  const _UnitDetailsDialog({
    Key? key,
    required this.driver,
    required this.unit,
    required this.plateNo,
    required this.date,
    this.routeRuns,
    required this.firstTrip,
    required this.lastTrip,
    required this.isPast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus, color: Color(0xFF3E4795)),
                const SizedBox(width: 8),
                Text(
                  unit,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF3E4795),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Plate Number: $plateNo',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            if (routeRuns != null) ...[
              Row(
                children: [
                  const Icon(Icons.route, size: 18, color: Color(0xFF3E4795)),
                  const SizedBox(width: 8),
                  const Text(
                    'Route Runs:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    routeRuns!.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: Color(0xFF3E4795),
                ),
                const SizedBox(width: 8),
                const Text(
                  'First Trip:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  firstTrip,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (isPast) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.timelapse,
                    size: 18,
                    color: Color(0xFF3E4795),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Last Trip:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    '07:30 PM',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Schedule CRUD Widget
class DailyScheduleCrud extends StatefulWidget {
  const DailyScheduleCrud({super.key});

  @override
  State<DailyScheduleCrud> createState() => _DailyScheduleCrudState();
}

class _DailyScheduleCrudState extends State<DailyScheduleCrud> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = false;
  bool _showAddForm = false;
  Map<String, dynamic>? _editingSchedule;
  bool _showActions = false;

  final _formKey = GlobalKey<FormState>();
  final GlobalKey _scheduleShotKey = GlobalKey();
  final _timeController = TextEditingController();
  final _unitController = TextEditingController();
  final _statusController = TextEditingController();
  final _reasonController = TextEditingController();

  // Time picker state
  int _selectedHour = 8;
  int _selectedMinute = 0;
  bool _isAM = true;

  // Vehicle data for dropdown
  List<Map<String, dynamic>> _vehicles = [];
  int? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
    _loadVehicles();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _unitController.dispose();
    _statusController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _saveScheduleAsImage() async {
    try {
      // Ensure the boundary is laid out
      await WidgetsBinding.instance.endOfFrame;
      final ctx = _scheduleShotKey.currentContext;
      if (ctx == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule view is not ready yet. Try again.')),
          );
        }
        return;
      }
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final filename = 'schedule_${DateFormat('yyyy-MM-dd').format(_selectedDate)}.png';

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..download = filename
          ..style.display = 'none';
        html.document.body!.children.add(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saving images is supported on web in this build.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
    }
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/schedules?date=${_formatDate(_selectedDate)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _schedules = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });

        // Reload vehicles to filter out already scheduled ones
        _loadVehicles();
      } else {
        _showErrorSnackBar('Failed to load schedules');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading schedules: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVehicles() async {
    try {
      // Always try vehicle assignments first since they have more complete data
      print('Loading vehicles from vehicle assignments...');
      final assignmentsResponse = await http.get(
        Uri.parse('$baseUrl/api/vehicle-assignments'),
      );

      if (assignmentsResponse.statusCode == 200) {
        final assignmentsData = json.decode(assignmentsResponse.body);
        print('Assignments API Response: $assignmentsData'); // Debug log

        if (assignmentsData['success'] == true &&
            assignmentsData['data'] != null) {
          // Extract unique vehicles from assignments
          final assignments = List<Map<String, dynamic>>.from(
            assignmentsData['data'],
          );
          final uniqueVehicles = <int, Map<String, dynamic>>{};

          for (final assignment in assignments) {
            final vehicleId = assignment['vehicle_id'];
            if (vehicleId != null && !uniqueVehicles.containsKey(vehicleId)) {
              uniqueVehicles[vehicleId] = {
                'vehicle_id': vehicleId,
                'plate_number': assignment['plate_number'],
              };
            }
          }

          // Filter out vehicles that are already scheduled for the selected date
          final availableVehicles = <Map<String, dynamic>>[];
          final scheduledVehicleIds = _schedules
              .map((schedule) => schedule['vehicle_id'])
              .toSet();

          for (final vehicle in uniqueVehicles.values) {
            final vehicleId = vehicle['vehicle_id'];
            if (!scheduledVehicleIds.contains(vehicleId)) {
              availableVehicles.add(vehicle);
            }
          }

          setState(() {
            _vehicles = availableVehicles;
          });

          print(
            'Loaded ${_vehicles.length} available vehicles (${scheduledVehicleIds.length} already scheduled): ${availableVehicles.map((v) => v['vehicle_id']).toList()}',
          );
          return;
        }
      }

      // Fallback to vehicles table if assignments fail
      print('Assignments failed, trying vehicles table...');
      final vehiclesResponse = await http.get(
        Uri.parse('$baseUrl/vehicles/getVehicles'),
      );

      if (vehiclesResponse.statusCode == 200) {
        final vehiclesData = json.decode(vehiclesResponse.body);
        print('Vehicles API Response: $vehiclesData'); // Debug log

        if (vehiclesData.isNotEmpty) {
          // Filter out vehicles that are already scheduled for the selected date
          final availableVehicles = <Map<String, dynamic>>[];
          final scheduledVehicleIds = _schedules
              .map((schedule) => schedule['vehicle_id'])
              .toSet();

          for (final vehicle in vehiclesData) {
            final vehicleId = vehicle['vehicle_id'];
            if (!scheduledVehicleIds.contains(vehicleId)) {
              availableVehicles.add(vehicle);
            }
          }

          setState(() {
            _vehicles = availableVehicles;
          });
          print(
            'Loaded ${_vehicles.length} available vehicles from vehicles table (${scheduledVehicleIds.length} already scheduled)',
          );
          return;
        }
      }

      // If both fail, use empty list
      print('Both APIs failed, using empty vehicle list');
      _useDummyVehicles();
    } catch (e) {
      print('Error loading vehicles: $e'); // Debug log
      _useDummyVehicles();
    }
  }

  void _useDummyVehicles() {
    setState(() {
      _vehicles =
          []; // Don't use dummy data - only show actual vehicles from database
    });
    print('No vehicles available from database');
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    // Format time from time picker - only if status is Active
    String? timeString;
    if (_statusController.text == 'Active') {
      final hour12 = _selectedHour == 0
          ? 12
          : (_selectedHour > 12 ? _selectedHour - 12 : _selectedHour);
      timeString =
          '${hour12.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')} ${_isAM ? 'AM' : 'PM'}';
    } else {
      timeString = null; // Send null to backend for non-active statuses
    }

    final scheduleData = {
      'schedule_date': _formatDate(_selectedDate),
      'time_start': timeString,
      // Send null unless the user actually selected a vehicle to avoid FK errors
      'vehicle_id': _selectedVehicleId,
      'status': _statusController.text.trim(),
      'reason': _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
    };

    try {
      http.Response response;
      if (_editingSchedule != null) {
        response = await http.put(
          Uri.parse('$baseUrl/api/schedules/${_editingSchedule!['id']}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(scheduleData),
        );
      } else {
        response = await http.post(
          Uri.parse('$baseUrl/api/schedules'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(scheduleData),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSnackBar(
          _editingSchedule != null ? 'Schedule updated' : 'Schedule created',
        );
        _closeForm();
        _loadSchedules();
      } else {
        final msg =
            'Failed to save schedule (HTTP ${response.statusCode})\n${response.body}';
        _showErrorSnackBar(msg);
      }
    } catch (e) {
      _showErrorSnackBar('Error saving schedule: $e');
    }
  }

  Future<void> _deleteSchedule(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse('$baseUrl/api/schedules/$id'),
        );

        if (response.statusCode == 200) {
          _showSuccessSnackBar('Schedule deleted');
          _loadSchedules();
        } else {
          _showErrorSnackBar('Failed to delete schedule');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting schedule: $e');
      }
    }
  }

  void _showAddFormDialog() {
    setState(() {
      _showAddForm = true;
      _editingSchedule = null;
      _timeController.clear();
      _unitController.clear();
      _statusController.text = 'Active';
      _reasonController.clear();
      _selectedHour = 8;
      _selectedMinute = 0;
      _isAM = true;
      _selectedVehicleId = null;
    });
  }

  void _showEditFormDialog(Map<String, dynamic> schedule) {
    setState(() {
      _showAddForm = true;
      _editingSchedule = schedule;
      _timeController.text = schedule['time_start'] ?? '';
      _unitController.text = schedule['vehicle_id']?.toString() ?? '';
      _statusController.text = schedule['status'] ?? 'Active';
      _reasonController.text = schedule['reason'] ?? '';
      _selectedVehicleId = schedule['vehicle_id'];

      // Parse time from schedule - use default if null or empty
      final timeStr = schedule['time_start'] ?? '08:00 AM';
      _parseTimeString(timeStr);
    });
  }

  void _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      final timePart = parts[0];
      final period = parts.length > 1 ? parts[1] : 'AM';

      final timeComponents = timePart.split(':');
      int hour = int.parse(timeComponents[0]);
      int minute = int.parse(timeComponents[1]);

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      _selectedHour = hour;
      _selectedMinute = minute;
      _isAM = period == 'AM';
    } catch (e) {
      _selectedHour = 8;
      _selectedMinute = 0;
      _isAM = true;
    }
  }

  void _closeForm() {
    setState(() {
      _showAddForm = false;
      _editingSchedule = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildSimpleTimePicker() {
    final bool isActive = _statusController.text == 'Active';

    return GestureDetector(
      onTap: isActive ? _selectTime : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isActive ? Colors.white : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _getFormattedTime(),
                style: TextStyle(
                  fontSize: 16,
                  color: isActive ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ),
            Icon(
              Icons.access_time,
              color: isActive ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  String _getFormattedTime() {
    // If status is not Active, show ---
    if (_statusController.text != 'Active') {
      return '---';
    }

    final hour12 = _selectedHour == 0
        ? 12
        : (_selectedHour > 12 ? _selectedHour - 12 : _selectedHour);
    return '${hour12.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')} ${_isAM ? 'AM' : 'PM'}';
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3E4795)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
        _isAM = picked.period == DayPeriod.am;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadSchedules();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.grey[100],
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date picker and add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Schedules',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    Row(
                      children: [
                        // Date picker
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF3E4795)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF3E4795),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(_selectedDate),
                                style: const TextStyle(
                                  color: Color(0xFF3E4795),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _selectDate,
                                child: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF3E4795),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Edit mode buttons
                        if (_showActions) ...[
                          // Cancel and Save buttons when editing
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _showActions = false;
                                _showAddForm = false;
                                _editingSchedule = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3E4795),
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _showActions = false);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E4795),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Save'),
                          ),
                        ] else ...[
                          // Edit toggle
                          ElevatedButton(
                            onPressed: () =>
                                setState(() => _showActions = !_showActions),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E4795),
                              minimumSize: const Size(44, 44),
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                              elevation: 0,
                            ),
                            child: Icon(
                              _showActions ? Icons.edit_off : Icons.edit,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Add button (icon only)
                          ElevatedButton(
                            onPressed: _showAddFormDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E4795),
                              minimumSize: const Size(44, 44),
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                              elevation: 0,
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _saveScheduleAsImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E4795),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Save as Image'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Table
                Expanded(
                  child: RepaintBoundary(
                    key: _scheduleShotKey,
                    child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF3E4795),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Time',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Unit Number',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Status',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Reason column removed
                              if (_showActions)
                                const Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Actions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Table content
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _schedules.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No schedules found for this date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _schedules.length,
                                  itemBuilder: (context, index) {
                                    final schedule = _schedules[index];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              schedule['status'] == 'Active'
                                                  ? (schedule['time_start'] ??
                                                        'N/A')
                                                  : '---',
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Unit ${schedule['vehicle_id'] ?? 'N/A'}',
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              schedule['status'] ?? 'N/A',
                                            ),
                                          ),
                                          // Reason cell removed
                                          if (_showActions)
                                            Expanded(
                                              flex: 1,
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        _showEditFormDialog(
                                                          schedule,
                                                        ),
                                                    tooltip: 'Edit',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        _deleteSchedule(
                                                          schedule['id'],
                                                        ),
                                                    tooltip: 'Delete',
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Add/Edit Form Modal
        if (_showAddForm)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _editingSchedule != null
                                  ? 'Edit Schedule'
                                  : 'Add Schedule',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E4795),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _closeForm,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Time picker
                        const Text(
                          'Time (HH:MM)',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        _buildSimpleTimePicker(),
                        const SizedBox(height: 16),

                        // Unit Number dropdown
                        Row(
                          children: [
                            const Text(
                              'Unit Number',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            if (_vehicles.isEmpty)
                              TextButton.icon(
                                onPressed: _loadVehicles,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text(
                                  'Refresh Vehicles',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _selectedVehicleId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: Text(
                            _vehicles.isEmpty
                                ? 'No vehicles available'
                                : 'Select Unit',
                          ),
                          items: _vehicles.map((vehicle) {
                            final int vehicleId =
                                vehicle['vehicle_id'] ?? vehicle['id'] ?? 0;
                            final String unitName = 'Unit $vehicleId';

                            return DropdownMenuItem<int>(
                              value: vehicleId,
                              child: Text(unitName),
                            );
                          }).toList(),
                          onChanged: _vehicles.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedVehicleId = value;
                                  });
                                },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a unit';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Status field
                        const Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _statusController.text.isEmpty
                              ? 'Active'
                              : _statusController.text,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items:
                              [
                                'Active',
                                'Sick',
                                'Maintenance',
                                'Coding',
                                'Other',
                              ].map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _statusController.text = value ?? 'Active';
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Status is required' : null,
                        ),
                        const SizedBox(height: 16),
                        if (_statusController.text == 'Other') ...[
                          const Text(
                            'Specify Status',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _reasonController,
                            decoration: InputDecoration(
                              hintText: 'Enter custom status',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _closeForm,
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _saveSchedule,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3E4795),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _editingSchedule != null ? 'Update' : 'Add',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Placeholder pages for new sections
class _EmployeesPage extends StatelessWidget {
  const _EmployeesPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Color(0xFF3E4795)),
          SizedBox(height: 16),
          Text(
            'Employees Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E4795),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manage driver and conductor accounts',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _TripHistoryPage extends StatefulWidget {
  const _TripHistoryPage();

  @override
  State<_TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<_TripHistoryPage> {
  List<dynamic> trips = [];
  List<dynamic> filteredTrips = [];
  bool isLoading = true;
  int currentPage = 1;
  int totalPages = 1;
  int totalTrips = 0;
  final int limit = 20;

  // Search and sort variables
  String searchQuery = '';
  String sortBy = 'start_time';
  String sortOrder = 'desc';
  final TextEditingController _searchController = TextEditingController();

  // Date filter variables
  DateTime? startDate;
  DateTime? endDate;

  // Vehicle filter variables
  List<String> selectedVehicles = [];
  List<String> availableVehicles = [];
  List<String> selectedStartTimes = [];
  List<String> selectedEndTimes = [];
  List<String> selectedDurations = [];
  List<String> availableStartTimes = [];
  List<String> availableEndTimes = [];
  List<String> availableDurations = [];

  @override
  void initState() {
    super.initState();
    // Initialize filteredTrips with empty list
    filteredTrips = [];
    // Initialize filter lists
    selectedVehicles = [];
    selectedStartTimes = [];
    selectedEndTimes = [];
    selectedDurations = [];
    availableVehicles = [];
    availableStartTimes = [];
    availableEndTimes = [];
    availableDurations = [];
    _loadTrips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAndSortTrips() {
    setState(() {
      // Ensure trips is not null
      if (trips.isEmpty) {
        filteredTrips = [];
        return;
      }

      // Filter trips based on search query and date range
      filteredTrips = trips.where((trip) {
        if (trip == null) return false;

        // Text search filter
        final vehicleNumber = (trip['vehicle_number'] ?? '')
            .toString()
            .toLowerCase();
        final query = searchQuery.toLowerCase();
        final matchesSearch = vehicleNumber.contains(query);

        // Vehicle filter
        final matchesVehicle =
            selectedVehicles.isEmpty ||
            selectedVehicles.contains(trip['vehicle_number'] ?? '');

        // Start time filter
        final startTime = _formatTime(trip['start_time']);
        final matchesStartTime =
            selectedStartTimes.isEmpty ||
            selectedStartTimes.contains(startTime);

        // End time filter
        final endTime = _formatTime(trip['end_time']);
        final matchesEndTime =
            selectedEndTimes.isEmpty || selectedEndTimes.contains(endTime);

        // Duration filter
        final duration = _formatDuration(trip['start_time'], trip['end_time']);
        final matchesDuration =
            selectedDurations.isEmpty || selectedDurations.contains(duration);

        // Date filter
        bool matchesDate = true;
        if (startDate != null || endDate != null) {
          final tripDate = DateTime.tryParse(trip['start_time'] ?? '');
          if (tripDate != null) {
            final tripDateOnly = DateTime(
              tripDate.year,
              tripDate.month,
              tripDate.day,
            );

            if (startDate != null && endDate != null) {
              final startDateOnly = DateTime(
                startDate!.year,
                startDate!.month,
                startDate!.day,
              );
              final endDateOnly = DateTime(
                endDate!.year,
                endDate!.month,
                endDate!.day,
              );
              matchesDate =
                  tripDateOnly.isAtSameMomentAs(startDateOnly) ||
                  tripDateOnly.isAtSameMomentAs(endDateOnly) ||
                  (tripDateOnly.isAfter(startDateOnly) &&
                      tripDateOnly.isBefore(endDateOnly));
            } else if (startDate != null) {
              final startDateOnly = DateTime(
                startDate!.year,
                startDate!.month,
                startDate!.day,
              );
              matchesDate =
                  tripDateOnly.isAtSameMomentAs(startDateOnly) ||
                  tripDateOnly.isAfter(startDateOnly);
            } else if (endDate != null) {
              final endDateOnly = DateTime(
                endDate!.year,
                endDate!.month,
                endDate!.day,
              );
              matchesDate =
                  tripDateOnly.isAtSameMomentAs(endDateOnly) ||
                  tripDateOnly.isBefore(endDateOnly);
            }
          } else {
            matchesDate = false;
          }
        }

        return matchesSearch &&
            matchesDate &&
            matchesVehicle &&
            matchesStartTime &&
            matchesEndTime &&
            matchesDuration;
      }).toList();

      // Sort trips
      filteredTrips.sort((a, b) {
        if (a == null || b == null) return 0;

        dynamic aValue, bValue;

        switch (sortBy) {
          case 'vehicle_id':
            aValue = a['vehicle_id'] ?? 0;
            bValue = b['vehicle_id'] ?? 0;
            break;
          case 'duration':
            final aStart = DateTime.tryParse(a['start_time'] ?? '');
            final aEnd = DateTime.tryParse(a['end_time'] ?? '');
            final bStart = DateTime.tryParse(b['start_time'] ?? '');
            final bEnd = DateTime.tryParse(b['end_time'] ?? '');
            final aDur = (aStart != null && aEnd != null)
                ? aEnd.difference(aStart).inMinutes
                : -1;
            final bDur = (bStart != null && bEnd != null)
                ? bEnd.difference(bStart).inMinutes
                : -1;
            aValue = aDur;
            bValue = bDur;
            break;
          case 'start_time':
          default:
            aValue = DateTime.tryParse(a['start_time'] ?? '') ?? DateTime(1970);
            bValue = DateTime.tryParse(b['start_time'] ?? '') ?? DateTime(1970);
            break;
        }

        if (sortOrder == 'asc') {
          return aValue.compareTo(bValue);
        } else {
          return bValue.compareTo(aValue);
        }
      });
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
    _filterAndSortTrips();
  }

  void _onSortChanged(String? newSortBy) {
    if (newSortBy != null) {
      setState(() {
        sortBy = newSortBy;
      });
      _filterAndSortTrips();
    }
  }

  void _onSortOrderChanged(String? newOrder) {
    if (newOrder != null) {
      setState(() {
        sortOrder = newOrder;
      });
      _filterAndSortTrips();
    }
  }

  void _showDateFilterModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.calendar_month, color: Color(0xFF3E4795)),
                  SizedBox(width: 8),
                  Text('Filter by Date'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width < 520
                    ? MediaQuery.of(context).size.width * 0.85
                    : 450,
                height: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start Date
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            startDate = picked;
                            if (endDate != null && picked.isAfter(endDate!)) {
                              endDate = null;
                            }
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: Color(0xFF3E4795),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                startDate != null
                                    ? '${startDate!.month.toString().padLeft(2, '0')}/${startDate!.day.toString().padLeft(2, '0')}/${startDate!.year}'
                                    : 'Start Date',
                                style: TextStyle(
                                  color: startDate != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // End Date
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? startDate ?? DateTime.now(),
                          firstDate: startDate ?? DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: Color(0xFF3E4795),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                endDate != null
                                    ? '${endDate!.month.toString().padLeft(2, '0')}/${endDate!.day.toString().padLeft(2, '0')}/${endDate!.year}'
                                    : 'End Date',
                                style: TextStyle(
                                  color: endDate != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Clear button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              startDate = null;
                              endDate = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Clear'),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF3E4795),
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterAndSortTrips();
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3E4795),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStartTimeFilterModal() {
    if (trips.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No trips available to filter')));
      return;
    }

    final times =
        trips
            .where((trip) => trip != null)
            .map((trip) => _formatTime(trip['start_time']))
            .where((time) => time.isNotEmpty && time != 'N/A')
            .toSet()
            .toList()
          ..sort();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: Color(0xFF3E4795)),
                  SizedBox(width: 8),
                  Text('Filter by Start Time'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width < 520
                    ? MediaQuery.of(context).size.width * 0.9
                    : 480,
                height: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select All option
                    CheckboxListTile(
                      title: Text('Select All'),
                      value:
                          times.isNotEmpty &&
                          selectedStartTimes.length == times.length,
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            selectedStartTimes = List.from(times);
                          } else {
                            selectedStartTimes.clear();
                          }
                        });
                      },
                      activeColor: Color(0xFF3E4795),
                      contentPadding: EdgeInsets.zero,
                    ),
                    // Separator line
                    Divider(color: Colors.grey[300]),
                    // Filter options
                    Container(
                      height: 200,
                      child: ListView.builder(
                        itemCount: times.length,
                        itemBuilder: (context, index) {
                          final time = times[index];
                          final isSelected = selectedStartTimes.contains(time);

                          return CheckboxListTile(
                            title: Text(time),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setModalState(() {
                                if (value == true) {
                                  selectedStartTimes.add(time);
                                } else {
                                  selectedStartTimes.remove(time);
                                }
                              });
                            },
                            activeColor: Color(0xFF3E4795),
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF3E4795),
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterAndSortTrips();
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3E4795),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEndTimeFilterModal() {
    if (trips.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No trips available to filter')));
      return;
    }

    final times =
        trips
            .where((trip) => trip != null)
            .map((trip) => _formatTime(trip['end_time']))
            .where((time) => time.isNotEmpty && time != 'N/A')
            .toSet()
            .toList()
          ..sort();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: Color(0xFF3E4795)),
                  SizedBox(width: 8),
                  Text('Filter by End Time'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width < 520
                    ? MediaQuery.of(context).size.width * 0.9
                    : 480,
                height: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select All option
                    CheckboxListTile(
                      title: Text('Select All'),
                      value:
                          times.isNotEmpty &&
                          selectedEndTimes.length == times.length,
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            selectedEndTimes = List.from(times);
                          } else {
                            selectedEndTimes.clear();
                          }
                        });
                      },
                      activeColor: Color(0xFF3E4795),
                      contentPadding: EdgeInsets.zero,
                    ),
                    // Separator line
                    Divider(color: Colors.grey[300]),
                    // Filter options
                    Container(
                      height: 200,
                      child: ListView.builder(
                        itemCount: times.length,
                        itemBuilder: (context, index) {
                          final time = times[index];
                          final isSelected = selectedEndTimes.contains(time);

                          return CheckboxListTile(
                            title: Text(time),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setModalState(() {
                                if (value == true) {
                                  selectedEndTimes.add(time);
                                } else {
                                  selectedEndTimes.remove(time);
                                }
                              });
                            },
                            activeColor: Color(0xFF3E4795),
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF3E4795),
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterAndSortTrips();
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3E4795),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDurationFilterModal() {
    if (trips.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No trips available to filter')));
      return;
    }

    final durations =
        trips
            .where((trip) => trip != null)
            .map(
              (trip) => _formatDuration(trip['start_time'], trip['end_time']),
            )
            .where((duration) => duration.isNotEmpty && duration != 'N/A')
            .toSet()
            .toList()
          ..sort();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: Color(0xFF3E4795)),
                  SizedBox(width: 8),
                  Text('Filter by Trip Duration'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width < 520
                    ? MediaQuery.of(context).size.width * 0.9
                    : 480,
                height: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select All option
                    CheckboxListTile(
                      title: Text('Select All'),
                      value:
                          durations.isNotEmpty &&
                          selectedDurations.length == durations.length,
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            selectedDurations = List.from(durations);
                          } else {
                            selectedDurations.clear();
                          }
                        });
                      },
                      activeColor: Color(0xFF3E4795),
                      contentPadding: EdgeInsets.zero,
                    ),
                    // Separator line
                    Divider(color: Colors.grey[300]),
                    // Filter options
                    Container(
                      height: 200,
                      child: ListView.builder(
                        itemCount: durations.length,
                        itemBuilder: (context, index) {
                          final duration = durations[index];
                          final isSelected = selectedDurations.contains(
                            duration,
                          );

                          return CheckboxListTile(
                            title: Text(duration),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setModalState(() {
                                if (value == true) {
                                  selectedDurations.add(duration);
                                } else {
                                  selectedDurations.remove(duration);
                                }
                              });
                            },
                            activeColor: Color(0xFF3E4795),
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF3E4795),
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterAndSortTrips();
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3E4795),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showVehicleFilterModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: Color(0xFF3E4795)),
                  SizedBox(width: 8),
                  Text('Filter by Unit Number'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width < 520
                    ? MediaQuery.of(context).size.width * 0.9
                    : 480,
                height: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select All option
                    CheckboxListTile(
                      title: Text('Select All'),
                      value:
                          availableVehicles.isNotEmpty &&
                          selectedVehicles.length == availableVehicles.length,
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            selectedVehicles = List.from(availableVehicles);
                          } else {
                            selectedVehicles.clear();
                          }
                        });
                      },
                      activeColor: Color(0xFF3E4795),
                      contentPadding: EdgeInsets.zero,
                    ),
                    // Separator line
                    Divider(color: Colors.grey[300]),
                    // Vehicle checklist
                    Container(
                      height: 200,
                      child: ListView.builder(
                        itemCount: availableVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = availableVehicles[index];
                          final isSelected = selectedVehicles.contains(vehicle);

                          return CheckboxListTile(
                            title: Text(vehicle),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setModalState(() {
                                if (value == true) {
                                  selectedVehicles.add(vehicle);
                                } else {
                                  selectedVehicles.remove(vehicle);
                                }
                              });
                            },
                            activeColor: Color(0xFF3E4795),
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF3E4795),
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterAndSortTrips();
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3E4795),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadTrips() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await fetchAdminTrips(page: currentPage, limit: limit);

      if (response['success']) {
        setState(() {
          trips = response['data'];
          totalPages = response['pagination']['totalPages'];
          totalTrips = response['pagination']['total'];
          isLoading = false;

          // Extract unique vehicle numbers for filtering
          availableVehicles =
              trips
                  .map((trip) => trip['vehicle_number']?.toString() ?? '')
                  .where((vehicle) => vehicle.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
        });
        _filterAndSortTrips();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading trips: $e');
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return 'Invalid Time';
    }
  }

  String _formatDuration(String? start, String? end) {
    if (start == null || end == null) return 'N/A';
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      if (e.isBefore(s)) return 'N/A';
      final diff = e.difference(s);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      if (hours <= 0 && minutes <= 0) return '0m';
      if (hours == 0) return '${minutes}m';
      if (minutes == 0) return '${hours}h';
      return '${hours}h ${minutes}m';
    } catch (_) {
      return 'N/A';
    }
  }

  String _getStatusColor(String? status) {
    if (status == null) return 'grey';
    switch (status.toLowerCase()) {
      case 'completed':
        return 'green';
      case 'active':
        return 'blue';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E4795),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _loadTrips();
                    },
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: Color(0xFF3E4795),
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Total: $totalTrips trips',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          // Search and Sort Controls
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by unit number...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF3E4795)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF3E4795)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: sortBy,
                    onChanged: _onSortChanged,
                    decoration: InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF3E4795)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'start_time',
                        child: Text('Date'),
                      ),
                      DropdownMenuItem(
                        value: 'vehicle_id',
                        child: Text('Unit Number'),
                      ),
                      DropdownMenuItem(
                        value: 'duration',
                        child: Text('Duration'),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: sortOrder,
                    onChanged: _onSortOrderChanged,
                    decoration: InputDecoration(
                      labelText: 'Order',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF3E4795)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 'desc', child: Text('Desc')),
                      DropdownMenuItem(value: 'asc', child: Text('Asc')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          if (isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF3E4795)),
                    SizedBox(height: 16),
                    Text('Loading trips...'),
                  ],
                ),
              ),
            )
          else if (filteredTrips.isEmpty || filteredTrips.length == 0)
            Expanded(
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF3E4795),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showDateFilterModal,
                                child: Icon(
                                  Icons.calendar_month,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Text(
                                'Unit Number',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showVehicleFilterModal,
                                child: Icon(
                                  Icons.filter_list,
                                  color: selectedVehicles.isNotEmpty
                                      ? Colors.lightBlue
                                      : Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Start Time',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showStartTimeFilterModal,
                                child: Icon(
                                  Icons.filter_list,
                                  color: selectedStartTimes.isNotEmpty
                                      ? Colors.lightBlue
                                      : Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'End Time',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showEndTimeFilterModal,
                                child: Icon(
                                  Icons.filter_list,
                                  color: selectedEndTimes.isNotEmpty
                                      ? Colors.lightBlue
                                      : Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Trip Duration',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showDurationFilterModal,
                                child: Icon(
                                  Icons.filter_list,
                                  color: selectedDurations.isNotEmpty
                                      ? Colors.lightBlue
                                      : Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Empty state message
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No trips found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF3E4795),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showDateFilterModal,
                                child: Icon(
                                  Icons.calendar_month,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Text(
                                'Unit Number',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showVehicleFilterModal,
                                child: Icon(
                                  Icons.filter_list,
                                  color: selectedVehicles.isNotEmpty
                                      ? Colors.lightBlue
                                      : Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Start Time',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showStartTimeFilterModal,
                                child: Icon(
                                  Icons.filter_list,
                                  color: selectedStartTimes.isNotEmpty
                                      ? Colors.lightBlue
                                      : Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'End Time',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showEndTimeFilterModal,
                                child: Icon(
                                  Icons.filter_list,
                                  color: selectedEndTimes.isNotEmpty
                                      ? Colors.lightBlue
                                      : Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Trip Duration',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showDurationFilterModal,
                                child: Icon(
                                  Icons.filter_list,
                                  color: selectedDurations.isNotEmpty
                                      ? Colors.lightBlue
                                      : Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table body
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredTrips.length,
                      itemBuilder: (context, index) {
                        if (index >= filteredTrips.length) return Container();
                        final trip = filteredTrips[index];
                        if (trip == null) return Container();
                        final isEven = index % 2 == 0;

                        return Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isEven ? Colors.grey[50] : Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(_formatDate(trip['start_time'])),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  trip['vehicle_number'] ?? 'N/A',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(_formatTime(trip['start_time'])),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(_formatTime(trip['end_time'])),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  _formatDuration(
                                    trip['start_time'],
                                    trip['end_time'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Pagination
                  if (totalPages > 1)
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: currentPage > 1
                                ? () {
                                    setState(() {
                                      currentPage--;
                                    });
                                    _loadTrips();
                                  }
                                : null,
                            icon: Icon(Icons.chevron_left),
                          ),
                          Text('Page $currentPage of $totalPages'),
                          IconButton(
                            onPressed: currentPage < totalPages
                                ? () {
                                    setState(() {
                                      currentPage++;
                                    });
                                    _loadTrips();
                                  }
                                : null,
                            icon: Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountManagementPage extends StatelessWidget {
  const _AccountManagementPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 64, color: Color(0xFF3E4795)),
          SizedBox(height: 16),
          Text(
            'Account Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E4795),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manage user accounts and permissions',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
