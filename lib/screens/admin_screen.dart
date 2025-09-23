import 'account_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'admin_login_screen.dart';
import 'employee_management_screen.dart';
import 'vehicle_assignment_screen.dart';
import 'package:http/http.dart' as http;
import '../services/api.dart';
import 'dart:convert';

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
  employees,
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
                                icon: Icons.people,
                                label: 'Employees',
                                selected:
                                    _selectedSection == AdminSection.employees,
                                isSubItem: true,
                                onTap: () {
                                  setState(() {
                                    _selectedSection = AdminSection.employees;
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
                            ],
                          ),

                          // Settings (Expandable)
                          _ExpandableSidebarItem(
                            icon: Icons.settings,
                            label: 'Settings',
                            expanded: _settingsExpanded,
                            onToggle: () {
                              setState(() {
                                _settingsExpanded = !_settingsExpanded;
                              });
                            },
                            children: [
                              _SidebarItem(
                                icon: Icons.account_circle,
                                label: 'Account Management',
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
                              _SidebarItem(
                                icon: Icons.logout,
                                label: 'Logout',
                                selected: false,
                                isSubItem: true,
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const AdminLoginScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
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
        // Show only one bus marker and info, like the passenger map
        final busLocation = LatLng(13.9467729, 121.1555241);
        final busInfo = {
          'busNo': 'FCM No. 05',
          'plateNo': 'DAL 7674',
          'route': 'Lipa City to Bauan City',
          'eta': '9:45 AM',
          'location': 'Lalayat San Jose',
          'driver': 'Nelson Suarez',
        };
        bool _showChat = false;
        final List<_ChatMessage> _messages = [
          _ChatMessage(name: 'Nelson- FCM No. 5', isMe: false, text: 'Hello!'),
          _ChatMessage(name: 'Admin', isMe: true, text: 'Hi Nelson!'),
        ];
        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                // Map
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: busLocation,
                      initialZoom: 13.0,
                      interactiveFlags: InteractiveFlag.all,
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
                            point: busLocation,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedBusIndex = 0),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3E4795),
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
                ),
                // Top search bar
                Positioned(
                  top: 24,
                  left: 32,
                  right: 32,
                  child: AdminSearchField(
                    onLocationSelected:
                        (LatLng selectedLatLng, String placeName) {
                          // Handle location selection for admin
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Selected: $placeName')),
                          );
                        },
                  ),
                ),
                if (_selectedBusIndex != null)
                  Center(
                    child: _AdminBusInfoCard(
                      bus: busInfo,
                      onClose: () => setState(() => _selectedBusIndex = null),
                      onTrackRoute: () {
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
                // Message button (bottom right)
                Positioned(
                  bottom: 32,
                  right: 32,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFF3E4795),
                    foregroundColor: Colors.white,
                    onPressed: () {
                      setState(() => _showChat = true);
                    },
                    child: const Icon(Icons.chat_bubble_outline, size: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                ),
                if (_showChat)
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: 400,
                    child: _ChatSidebar(
                      onClose: () => setState(() => _showChat = false),
                      messages: _messages,
                      onSend: (msg) {
                        setState(() {
                          _messages.add(_ChatMessage(isMe: true, text: msg));
                        });
                      },
                    ),
                  ),
              ],
            );
          },
        );
      case AdminSection.analytics:
        return _AnalyticsPage();
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
      case AdminSection.employees:
        return Container(
          color: Colors.grey[100],
          child: const EmployeeManagementScreen(),
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
    return Container(color: Colors.white);
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
            final time = notif['notif_date'] ?? '';
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
  final List<Map<String, String>> _allLogs = [
    {
      "timestamp": "2024-12-12 10:05 AM",
      "action": "Assign",
      "entity": "Default Driver",
    },
    {
      "timestamp": "2024-12-12 10:05 AM",
      "action": "Update",
      "entity": "Schedule",
    },
    {
      "timestamp": "2024-12-12 10:05 AM",
      "action": "Delete",
      "entity": "Driver Profile",
    },
    {
      "timestamp": "2024-12-12 10:05 AM",
      "action": "Approve",
      "entity": "Unit Registration",
    },
    {
      "timestamp": "2024-12-12 10:05 AM",
      "action": "Remove",
      "entity": "Default Driver",
    },
    {
      "timestamp": "2024-12-12 10:05 AM",
      "action": "Create",
      "entity": "Maintenance Record",
    },
    {
      "timestamp": "2024-12-12 10:05 AM",
      "action": "Update",
      "entity": "Route Schedule",
    },
    {
      "timestamp": "2024-12-12 10:05 AM",
      "action": "Login",
      "entity": "Admin Portal",
    },
    {
      "timestamp": "2024-12-13 09:00 AM",
      "action": "Export Report",
      "entity": "Driver Schedule",
    },
    {
      "timestamp": "2024-12-13 11:30 AM",
      "action": "Assign",
      "entity": "Default Driver",
    },
    {
      "timestamp": "2024-12-14 08:15 AM",
      "action": "Update",
      "entity": "Schedule",
    },
  ];
  String _search = '';
  String? _filterAction;
  DateTime? _filterDate;

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _allLogs.where((log) {
      final matchesSearch =
          _search.isEmpty ||
          log.values.any(
            (v) => v.toLowerCase().contains(_search.toLowerCase()),
          );
      final matchesFilter =
          _filterAction == null || log['action'] == _filterAction;
      final matchesDate =
          _filterDate == null || _isSameDate(log['timestamp']!, _filterDate!);
      return matchesSearch && matchesFilter && matchesDate;
    }).toList();

    return Center(
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
                  'Admin Activity Logs',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E4795),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 200,
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 18,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (val) => setState(() => _search = val),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _filterDate == null
                                ? 'Date'
                                : _formatDate(_filterDate!),
                            style: const TextStyle(fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _filterDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                setState(() => _filterDate = picked);
                            },
                          ),
                          if (_filterDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _filterDate = null),
                              child: const Icon(
                                Icons.clear,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      icon: Row(
                        children: const [
                          Text(
                            'Filters',
                            style: TextStyle(color: Colors.black87),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.filter_list, color: Colors.black87),
                        ],
                      ),
                      onSelected: (value) => setState(
                        () => _filterAction = value == 'All' ? null : value,
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'All', child: Text('All')),
                        ...{..._allLogs.map((e) => e['action']).toSet()}
                            .map(
                              (action) => PopupMenuItem(
                                value: action,
                                child: Text(action!),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFBFC6E0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: const [
                  _TableHeaderCell('Time Stamp'),
                  _TableHeaderCell('Action Type'),
                  _TableHeaderCell('Affected Entity'),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: filteredLogs
                    .map(
                      (log) => Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            _TableCell(log['timestamp']!),
                            _TableCell(log['action']!),
                            _TableCell(log['entity']!),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDate(String timestamp, DateTime date) {
    // Assumes timestamp is in format 'yyyy-MM-dd HH:mm AM/PM'
    final datePart = timestamp.split(' ')[0];
    final parts = datePart.split('-');
    if (parts.length != 3) return false;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return false;
    return y == date.year && m == date.month && d == date.day;
  }

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
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

class _ChatSidebar extends StatefulWidget {
  final VoidCallback onClose;
  final List<_ChatMessage> messages;
  final void Function(String) onSend;
  const _ChatSidebar({
    required this.onClose,
    required this.messages,
    required this.onSend,
  });

  @override
  State<_ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends State<_ChatSidebar> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _ChatSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        bottomLeft: Radius.circular(24),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Message',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'FCM Team',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF3E4795)),
                  onPressed: widget.onClose,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.messages.length,
              itemBuilder: (context, i) {
                final msg = widget.messages[i];
                return _ChatBubble(
                  name: msg.name,
                  isMe: msg.isMe,
                  text: msg.text,
                );
              },
            ),
          ),
          // Message input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Write a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF3E4795),
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _send,
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
                        ElevatedButton.icon(
                          onPressed: _openScheduledModal,
                          icon: const Icon(
                            Icons.schedule,
                            color: Color(0xFF3E4795),
                          ),
                          label: const Text(
                            'View Scheduled Notifications',
                            style: TextStyle(color: Color(0xFF3E4795)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF0F3FF),
                            foregroundColor: const Color(0xFF3E4795),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
        if (_showScheduledModal)
          _ScheduledNotificationsModal(
            notifications: _scheduledNotifications,
            onEdit: (index) => _openCompose(index),
            onDelete: _deleteScheduledNotification,
            onClose: _closeScheduledModal,
          ),
        if (_showCompose)
          _ComposeNotificationModal(
            onSave: (notif) async {
              final today = DateTime.now();
              final formattedDate =
                  "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
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

              // Keep your local save if you still want scheduled ones
              _saveScheduledNotification(notif);
            },
            onCancel: _closeCompose,
            initialData: _editingIndex != null
                ? _scheduledNotifications[_editingIndex!]
                : null,
          ),
        if (_showSuccess) _NotificationSentDialog(onOk: _closeSuccessDialog),
      ],
    );
  }
}

// Modal for scheduled notifications
class _ScheduledNotificationsModal extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final void Function(int) onEdit;
  final void Function(int) onDelete;
  final VoidCallback onClose;
  const _ScheduledNotificationsModal({
    required this.notifications,
    required this.onEdit,
    required this.onDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.08),
        child: Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scheduled Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF3E4795)),
                      onPressed: onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (notifications.isEmpty)
                  const Text(
                    'No scheduled notifications.',
                    style: TextStyle(color: Colors.black54),
                  ),
                if (notifications.isNotEmpty)
                  ...notifications.asMap().entries.map((entry) {
                    final i = entry.key;
                    final notif = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          notif['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (notif['schedule'] != null)
                              Text(
                                'Scheduled: ' + notif['schedule'].toString(),
                              ),
                            if (notif['type'] != null)
                              Text('Type: ' + notif['type']),
                            if (notif['content'] != null)
                              Text('Content: ' + notif['content']),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => onEdit(i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => onDelete(i),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  DateTime? _schedule;

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
      _schedule = widget.initialData!['schedule'];
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
                    const SizedBox(height: 20),
                    const Text(
                      'Schedule (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: _schedule == null
                                  ? ''
                                  : '${_schedule!.month.toString().padLeft(2, '0')}/${_schedule!.day.toString().padLeft(2, '0')}/${_schedule!.year} -- ${_schedule!.hour.toString().padLeft(2, '0')}:${_schedule!.minute.toString().padLeft(2, '0')}',
                            ),
                            decoration: InputDecoration(
                              hintText: 'mm/dd/yyy -- : -- --',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF3E4795),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _schedule ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  _schedule = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onSave({
                                'title': _title,
                                'type': _type,
                                'content': _content,
                                'recipients': _recipients,
                                'schedule': _schedule,
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
                          onPressed: _toggleEditMode,
                          icon: Icon(
                            _isEditMode ? Icons.check_circle : Icons.edit,
                            size: 20,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isEditMode ? 'Done Editing' : 'Edit Schedule',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEditMode
                                ? Colors.green
                                : const Color(0xFF1A237E),
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

  final _formKey = GlobalKey<FormState>();
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

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:8080/api/schedules?date=${_formatDate(_selectedDate)}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _schedules = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
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
      final response = await http.get(
        Uri.parse('http://localhost:8080/vehicles'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Vehicles API Response: $data'); // Debug log

        setState(() {
          _vehicles = List<Map<String, dynamic>>.from(data);
        });

        print('Loaded ${_vehicles.length} vehicles'); // Debug log
      } else {
        print('Vehicles API failed with status: ${response.statusCode}');
        _useDummyVehicles();
      }
    } catch (e) {
      print('Error loading vehicles: $e'); // Debug log
      _useDummyVehicles();
    }
  }

  void _useDummyVehicles() {
    setState(() {
      _vehicles = [
        {'vehicle_id': 1, 'unit_number': 'Unit 1'},
        {'vehicle_id': 2, 'unit_number': 'Unit 2'},
        {'vehicle_id': 3, 'unit_number': 'Unit 3'},
        {'vehicle_id': 4, 'unit_number': 'Unit 4'},
        {'vehicle_id': 5, 'unit_number': 'Unit 5'},
        {'vehicle_id': 6, 'unit_number': 'Unit 6'},
        {'vehicle_id': 7, 'unit_number': 'Unit 7'},
        {'vehicle_id': 8, 'unit_number': 'Unit 8'},
        {'vehicle_id': 9, 'unit_number': 'Unit 9'},
        {'vehicle_id': 10, 'unit_number': 'Unit 10'},
      ];
    });
    print('Using dummy vehicles: ${_vehicles.length} units');
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    // Format time from time picker
    final hour12 = _selectedHour == 0
        ? 12
        : (_selectedHour > 12 ? _selectedHour - 12 : _selectedHour);
    final timeString =
        '${hour12.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')} ${_isAM ? 'AM' : 'PM'}';

    final scheduleData = {
      'schedule_date': _formatDate(_selectedDate),
      'time_start': timeString,
      'vehicle_id': _selectedVehicleId ?? 1,
      'status': _statusController.text.trim(),
      'reason': _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
    };

    try {
      http.Response response;
      if (_editingSchedule != null) {
        response = await http.put(
          Uri.parse(
            'http://localhost:8080/api/schedules/${_editingSchedule!['id']}',
          ),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(scheduleData),
        );
      } else {
        response = await http.post(
          Uri.parse('http://localhost:8080/api/schedules'),
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
        _showErrorSnackBar('Failed to save schedule');
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
          Uri.parse('http://localhost:8080/api/schedules/$id'),
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

      // Parse time from schedule
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
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _getFormattedTime(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Icon(Icons.access_time, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  String _getFormattedTime() {
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
                        // Add button
                        ElevatedButton.icon(
                          onPressed: _showAddFormDialog,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Add Schedule',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E4795),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Table
                Expanded(
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
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Time',
                                  style: TextStyle(
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
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Reason',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
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
                                              schedule['time_start'] ?? 'N/A',
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
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              schedule['reason'] ?? 'N/A',
                                            ),
                                          ),
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
                                  'Load Vehicles',
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
                                ? 'Loading vehicles...'
                                : 'Select Unit',
                          ),
                          items: _vehicles.map((vehicle) {
                            // Handle different possible field names for unit number
                            String unitName =
                                vehicle['unit_number'] ??
                                vehicle['unitNumber'] ??
                                vehicle['plate_number'] ??
                                vehicle['plateNumber'] ??
                                'Unit ${vehicle['vehicle_id'] ?? vehicle['id']}';

                            int vehicleId =
                                vehicle['vehicle_id'] ?? vehicle['id'] ?? 0;

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
                          items: ['Active', 'Sick', 'Maintenance', 'Coding']
                              .map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status),
                                );
                              })
                              .toList(),
                          onChanged: (value) =>
                              _statusController.text = value ?? 'Active',
                          validator: (value) =>
                              value == null ? 'Status is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Reason field
                        const Text(
                          'Reason (Optional)',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _reasonController,
                          decoration: InputDecoration(
                            hintText: 'Enter reason if applicable',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
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

class _TripHistoryPage extends StatelessWidget {
  const _TripHistoryPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Color(0xFF3E4795)),
          SizedBox(height: 16),
          Text(
            'Trip History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E4795),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'View and analyze trip records',
            style: TextStyle(fontSize: 16, color: Colors.grey),
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
