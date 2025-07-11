import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'admin_login_screen.dart';

enum AdminSection { dashboard, analytics, notifications, schedules, activityLogs }

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  AdminSection _selectedSection = AdminSection.dashboard;
  int? _selectedBusIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 100,
                  ),
                ),
                const SizedBox(height: 32),
                _SidebarItem(
                  icon: Icons.map,
                  label: 'Dashboard',
                  selected: _selectedSection == AdminSection.dashboard,
                  onTap: () => setState(() => _selectedSection = AdminSection.dashboard),
                ),
                _SidebarItem(
                  icon: Icons.notifications,
                  label: 'Notifications',
                  selected: _selectedSection == AdminSection.notifications,
                  onTap: () => setState(() => _selectedSection = AdminSection.notifications),
                ),
                _SidebarItem(
                  icon: Icons.calendar_today,
                  label: 'Schedules',
                  selected: _selectedSection == AdminSection.schedules,
                  onTap: () => setState(() => _selectedSection = AdminSection.schedules),
                ),
                _SidebarItem(
                  icon: Icons.access_time,
                  label: 'Activity Logs',
                  selected: _selectedSection == AdminSection.activityLogs,
                  onTap: () => setState(() => _selectedSection = AdminSection.activityLogs),
                ),
                const Spacer(),
                // Logout
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Log out', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedSection) {
      case AdminSection.dashboard:
        final busMarkers = [
          {
            'latlng': LatLng(13.0604, 80.2496),
            'busNo': 'FCM No. 05',
            'route': 'Lipa City to Bauan City',
            'eta': '9:45 AM',
            'location': 'Lalayat San Jose',
            'runs': '3',
            'rating': '4.8',
            'ratingsCount': '100',
            'driver': 'Nelson Suarez',
            'status': 'ONBOARDING',
          },
          {
            'latlng': LatLng(13.0650, 80.2500),
            'busNo': 'FCM No. 06',
            'route': 'Tanauan to Lipa City',
            'eta': '10:10 AM',
            'location': 'Tanauan Plaza',
            'runs': '2',
            'rating': '4.6',
            'ratingsCount': '80',
            'driver': 'Maria Lopez',
            'status': 'ONBOARDING',
          },
          {
            'latlng': LatLng(13.0580, 80.2450),
            'busNo': 'FCM No. 07',
            'route': 'Bauan City to Lipa City',
            'eta': '9:55 AM',
            'location': 'Bauan Terminal',
            'runs': '4',
            'rating': '4.9',
            'ratingsCount': '120',
            'driver': 'Juan Dela Cruz',
            'status': 'ONBOARDING',
          },
        ];
        bool _showChat = false;
        final List<_ChatMessage> _messages = [
          _ChatMessage(name: 'Nelson- FCM No. 5', isMe: false, text: 'Hello!'),
          _ChatMessage(name: 'Admin', isMe: true, text: 'Hi Nelson!'),
          _ChatMessage(name: 'Joselito- FCM No. 12', isMe: false, text: 'Good morning!'),
          _ChatMessage(name: 'Rickson- FCM No. 01', isMe: false, text: 'How are you?'),
        ];
        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                // Map
                Positioned.fill(
                  child: FlutterMap(
                    options: MapOptions(
                      center: LatLng(13.0604, 80.2496),
                      zoom: 14.0,
                      interactiveFlags: InteractiveFlag.all,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: ['a', 'b', 'c', 'd'],
                      ),
                      MarkerLayer(
                        markers: [
                          ...List.generate(busMarkers.length, (i) => Marker(
                            width: 40.0,
                            height: 40.0,
                            point: busMarkers[i]['latlng'] as LatLng,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedBusIndex = i),
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
                          )),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'What are you looking for?',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedBusIndex != null)
                  Center(
                    child: _BusInfoCard(
                      bus: busMarkers[_selectedBusIndex!] as Map<String, Object>,
                      onClose: () => setState(() => _selectedBusIndex = null),
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
      case AdminSection.notifications:
        return Center(
          child: Container(
            width: 700,
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
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text('Compose'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E4795),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Notification list
                const Expanded(
                  child: _NotificationList(),
                ),
              ],
            ),
          ),
        );
      case AdminSection.activityLogs:
        return const _ActivityLogsPage();
      default:
        return const Center(child: Text('Section coming soon...', style: TextStyle(fontSize: 24)));
    }
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _SidebarItem({required this.icon, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: selected
          ? BoxDecoration(
              color: const Color(0xFFE8EAFE),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF3E4795)),
        title: Text(
          label,
          style: TextStyle(
            color: const Color(0xFF3E4795),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _NotificationItem(
          title: 'FCM No. 5 off-route',
          subtitle: 'GPS data indicates FCM No. 5 has deviated from its designated route (Route: Lipa - Tanauan).',
          time: '5 mins ago',
        ),
        _NotificationItem(
          title: 'Feedback received for FCM No.6',
          subtitle: 'Passenger rated the trip 2★ and reported driver over-speeding. Review driver conduct logs.',
          time: '9:30 AM',
        ),
        _NotificationItem(
          title: 'FCM No. 6 off-route',
          subtitle: 'GPS data indicates FCM No. 6 has deviated from its designated route (Route: Lipa - Tanauan).',
          time: '8:00 AM',
        ),
        _NotificationItem(
          title: 'FCM No. 6 off-route',
          subtitle: 'GPS data indicates FCM No. 6 has deviated from its designated route (Route: Lipa - Tanauan).',
          time: 'Yesterday 8:00 PM',
        ),
        _NotificationItem(
          title: 'Urgent Notification Received',
          subtitle: 'Sender: Conductor - Bus #02\nDate & Time: April 18, 2025, 10:51 PM\nType of Situation: Vehicle Breakdown',
          time: 'Yesterday 7:00 PM',
          urgent: true,
        ),
      ],
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
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0)),
        ),
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
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
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
    {"timestamp": "2024-12-12 10:05 AM", "action": "Assign", "entity": "Default Driver"},
    {"timestamp": "2024-12-12 10:05 AM", "action": "Update", "entity": "Schedule"},
    {"timestamp": "2024-12-12 10:05 AM", "action": "Delete", "entity": "Driver Profile"},
    {"timestamp": "2024-12-12 10:05 AM", "action": "Approve", "entity": "Unit Registration"},
    {"timestamp": "2024-12-12 10:05 AM", "action": "Remove", "entity": "Default Driver"},
    {"timestamp": "2024-12-12 10:05 AM", "action": "Create", "entity": "Maintenance Record"},
    {"timestamp": "2024-12-12 10:05 AM", "action": "Update", "entity": "Route Schedule"},
    {"timestamp": "2024-12-12 10:05 AM", "action": "Login", "entity": "Admin Portal"},
    {"timestamp": "2024-12-13 09:00 AM", "action": "Export Report", "entity": "Driver Schedule"},
    {"timestamp": "2024-12-13 11:30 AM", "action": "Assign", "entity": "Default Driver"},
    {"timestamp": "2024-12-14 08:15 AM", "action": "Update", "entity": "Schedule"},
  ];
  String _search = '';
  String? _filterAction;
  DateTime? _filterDate;

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _allLogs.where((log) {
      final matchesSearch = _search.isEmpty ||
          log.values.any((v) => v.toLowerCase().contains(_search.toLowerCase()));
      final matchesFilter = _filterAction == null || log['action'] == _filterAction;
      final matchesDate = _filterDate == null || _isSameDate(log['timestamp']!, _filterDate!);
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
                          const Icon(Icons.search, size: 18, color: Colors.black54),
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
                          const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(_filterDate == null ? 'Date' : _formatDate(_filterDate!), style: const TextStyle(fontSize: 14)),
                          IconButton(
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _filterDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setState(() => _filterDate = picked);
                            },
                          ),
                          if (_filterDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _filterDate = null),
                              child: const Icon(Icons.clear, size: 18, color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      icon: Row(
                        children: const [
                          Text('Filters', style: TextStyle(color: Colors.black87)),
                          SizedBox(width: 4),
                          Icon(Icons.filter_list, color: Colors.black87),
                        ],
                      ),
                      onSelected: (value) => setState(() => _filterAction = value == 'All' ? null : value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'All', child: Text('All')),
                        ...{
                          ..._allLogs.map((e) => e['action']).toSet()
                        }.map((action) => PopupMenuItem(value: action, child: Text(action!))).toList(),
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
            ...filteredLogs.map((log) => Container(
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
                )),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF232A4D),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BusInfoCard extends StatelessWidget {
  final Map<String, Object> bus;
  final VoidCallback onClose;
  const _BusInfoCard({required this.bus, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: onClose,
                  tooltip: 'Close',
                ),
              ],
            ),
            // Main info content below
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
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E4795),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bus['route'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF232A4D),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E4795),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    bus['status'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF3E4795)),
                const SizedBox(width: 8),
                const Text('Estimated Time of Arrival'),
                const Spacer(),
                Text(
                  bus['eta'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF3E4795)),
                const SizedBox(width: 8),
                const Text('Current Location'),
                const Spacer(),
                Text(
                  bus['location'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.directions_bus, color: Color(0xFF3E4795)),
                const SizedBox(width: 8),
                const Text('Route Runs'),
                const Spacer(),
                Text(
                  bus['runs'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Track Live Trip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF3E4795),
                      side: const BorderSide(color: Color(0xFF3E4795)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFF3E4795)),
                const SizedBox(width: 4),
                Text(
                  bus['rating'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF232A4D),
                  ),
                ),
                Text('  (${bus['ratingsCount']} ratings)'),
                const Spacer(),
                Text(
                  bus['driver'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Average bus rating'),
          ],
        ),
      ),
    );
  }
}

class _ChatSidebar extends StatefulWidget {
  final VoidCallback onClose;
  final List<_ChatMessage> messages;
  final void Function(String) onSend;
  const _ChatSidebar({required this.onClose, required this.messages, required this.onSend});

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
                    Text('Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF3E4795))),
                    SizedBox(height: 2),
                    Text('FCM Team', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF3E4795))),
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
                return _ChatBubble(name: msg.name, isMe: msg.isMe, text: msg.text);
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (name != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 2, left: 4, right: 4),
              child: Text(name!, style: const TextStyle(fontSize: 13, color: Color(0xFF3E4795), fontWeight: FontWeight.w500)),
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF3E4795) : const Color(0xFFF3F3F3),
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