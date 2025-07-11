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
                    height: 170,
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
        return _NotificationsWithCompose();
      case AdminSection.schedules:
        return _ScheduleWeekView();
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
            Expanded(
              child: ListView(
                children: filteredLogs.map((log) => Container(
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
                )).toList(),
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6), // more compact
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

class _NotificationsWithCompose extends StatefulWidget {
  @override
  State<_NotificationsWithCompose> createState() => _NotificationsWithComposeState();
}

class _NotificationsWithComposeState extends State<_NotificationsWithCompose> {
  bool _showCompose = false;
  bool _showSuccess = false;

  void _openCompose() => setState(() => _showCompose = true);
  void _closeCompose() => setState(() => _showCompose = false);
  void _showSuccessDialog() => setState(() { _showCompose = false; _showSuccess = true; });
  void _closeSuccessDialog() => setState(() => _showSuccess = false);

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
                    ElevatedButton.icon(
                      onPressed: _openCompose,
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
        ),
        if (_showCompose)
          _ComposeNotificationModal(
            onSave: _showSuccessDialog,
            onCancel: _closeCompose,
          ),
        if (_showSuccess)
          _NotificationSentDialog(onOk: _closeSuccessDialog),
      ],
    );
  }
}

class _ComposeNotificationModal extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  const _ComposeNotificationModal({required this.onSave, required this.onCancel});

  @override
  State<_ComposeNotificationModal> createState() => _ComposeNotificationModalState();
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
  final List<String> _recipientOptions = [
    'All Commuters',
    'All FCM Unit',
    'Specific FCM Unit',
    'Specific User',
  ];

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
                        Text('Compose', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Color(0xFF3E4795))),
                        SizedBox(width: 8),
                        Icon(Icons.edit, color: Color(0xFF3E4795), size: 28),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Notification Title', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF3E4795))),
                    const SizedBox(height: 4),
                    TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _title = v),
                    ),
                    const SizedBox(height: 20),
                    const Text('Notification Type', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF3E4795))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (v) => setState(() => _type = v),
                    ),
                    const SizedBox(height: 20),
                    const Text('Content', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF3E4795))),
                    const SizedBox(height: 4),
                    TextFormField(
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _content = v),
                    ),
                    const SizedBox(height: 20),
                    const Text('Recipient', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF3E4795))),
                    const SizedBox(height: 4),
                    Column(
                      children: _recipientOptions.map((r) => CheckboxListTile(
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
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Schedule (Optional)', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF3E4795))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(text: _schedule == null ? '' : '${_schedule!.month.toString().padLeft(2, '0')}/${_schedule!.day.toString().padLeft(2, '0')}/${_schedule!.year} -- ${_schedule!.hour.toString().padLeft(2, '0')}:${_schedule!.minute.toString().padLeft(2, '0')}'),
                            decoration: InputDecoration(
                              hintText: 'mm/dd/yyy -- : -- --',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today, color: Color(0xFF3E4795)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
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
                                  _schedule = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
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
                              widget.onSave();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E4795),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  DateTime _currentWeek = DateTime(2025, 4, 13); // Start at Sun, April 13, 2025
  bool _showModal = false;
  final List<Map<String, dynamic>> _schedules = [
    {'date': DateTime(2025, 4, 13), 'driver': 'John Doe', 'unit': 'Unit 15'},
    {'date': DateTime(2025, 4, 13), 'driver': 'Joselito V', 'unit': 'Unit 14'},
    {'date': DateTime(2025, 4, 13), 'driver': 'Ronie Par', 'unit': 'Unit 13'},
    {'date': DateTime(2025, 4, 13), 'driver': 'Rikson A.', 'unit': 'Unit 12'},
  ];

  List<DateTime> get _weekDays {
    final start = _currentWeek.subtract(Duration(days: _currentWeek.weekday % 7));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  void _nextWeek() {
    setState(() => _currentWeek = _currentWeek.add(const Duration(days: 7)));
  }
  void _prevWeek() {
    setState(() => _currentWeek = _currentWeek.subtract(const Duration(days: 7)));
  }
  void _goToday() {
    setState(() => _currentWeek = DateTime(2025, 4, 13));
  }
  void _addSchedule(Map<String, dynamic> sched) {
    setState(() {
      _schedules.add(sched);
      _showModal = false;
    });
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
                          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF3E4795)),
                          onPressed: _prevWeek,
                        ),
                        TextButton(
                          onPressed: _goToday,
                          child: const Text('Today', style: TextStyle(color: Color(0xFF3E4795), fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF3E4795)),
                          onPressed: _nextWeek,
                        ),
                      ],
                    ),
                    Text(
                      'APRIL 2025',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFF3E4795),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showModal = true),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add Driver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8EAFE),
                        foregroundColor: const Color(0xFF3E4795),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: weekDays.map((day) {
                      final daySchedules = _schedules.where((s) =>
                        s['date'] is DateTime && (s['date'] as DateTime).year == day.year && (s['date'] as DateTime).month == day.month && (s['date'] as DateTime).day == day.day
                      ).toList();
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${_weekdayLabel(day.weekday)} ${day.day}',
                                style: const TextStyle(
                                  color: Color(0xFF3E4795),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ...daySchedules.asMap().entries.map((entry) {
                                final i = entry.key;
                                final s = entry.value;
                                final fcmNumber = 'FCM No. ' + s['unit'].toString().replaceAll(RegExp(r'Unit ?'), '');
                                // Calculate first trip time with 15 min gap
                                final baseTime = DateTime(0, 1, 1, 6, 0); // 6:00 AM
                                final tripTime = baseTime.add(Duration(minutes: 15 * i));
                                final hour = tripTime.hour > 12 ? tripTime.hour - 12 : tripTime.hour == 0 ? 12 : tripTime.hour;
                                final minute = tripTime.minute.toString().padLeft(2, '0');
                                final ampm = tripTime.hour >= 12 ? 'PM' : 'AM';
                                final firstTripTime = '$hour:$minute $ampm';
                                // Last trip is 1 hour after first trip
                                final lastTripDateTime = tripTime.add(const Duration(hours: 1));
                                final lastHour = lastTripDateTime.hour > 12 ? lastTripDateTime.hour - 12 : lastTripDateTime.hour == 0 ? 12 : lastTripDateTime.hour;
                                final lastMinute = lastTripDateTime.minute.toString().padLeft(2, '0');
                                final lastAmpm = lastTripDateTime.hour >= 12 ? 'PM' : 'AM';
                                final lastTripTime = '$lastHour:$lastMinute $lastAmpm';
                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => _UnitDetailsDialog(
                                        driver: s['driver'],
                                        unit: s['unit'],
                                        date: day,
                                        routeRuns: 3, // dummy data
                                        passengers: 42, // dummy data
                                        firstTrip: firstTripTime,
                                        lastTrip: lastTripTime,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8EAFE),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          fcmNumber,
                                          style: const TextStyle(
                                            color: Color(0xFF3E4795),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                        Text(
                                          firstTripTime,
                                          style: const TextStyle(
                                            color: Color(0xFF3E4795),
                                            fontWeight: FontWeight.normal,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              if (daySchedules.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
                                  child: GestureDetector(
                                    onTap: null, // TODO: Add edit functionality if needed
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.edit, size: 16, color: Color(0xFF3E4795)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Edit Schedule',
                                          style: TextStyle(
                                            color: Color(0xFF3E4795),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.none,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.sunday:
        return 'Sun';
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tues';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      default:
        return '';
    }
  }
}

class _AddDriverModal extends StatefulWidget {
  final void Function(String driver, String unit, DateTime date) onSave;
  final VoidCallback onCancel;
  final DateTime initialDate;
  const _AddDriverModal({required this.onSave, required this.onCancel, required this.initialDate});

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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Color(0xFF3E4795)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Assigning a default driver ensures they are automatically included in the daily schedule. This can be updated anytime.',
                      style: TextStyle(fontSize: 15, color: Colors.black38, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 24),
                    const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF3E4795))),
                    const SizedBox(height: 4),
                    TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _driver = v),
                    ),
                    const SizedBox(height: 16),
                    const Text('Assign Unit Number', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF3E4795))),
                    const SizedBox(height: 4),
                    TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                              widget.onSave(_driver!, _unit!, _date ?? DateTime.now());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E4795),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  final DateTime date;
  final int routeRuns;
  final int passengers;
  final String firstTrip;
  final String lastTrip;
  const _UnitDetailsDialog({
    required this.driver,
    required this.unit,
    required this.date,
    required this.routeRuns,
    required this.passengers,
    required this.firstTrip,
    required this.lastTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FCM No. ${unit.toString().replaceAll(RegExp(r'Unit ?'), '')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF3E4795),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Driver: $driver', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Text('Date: \t${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.directions_bus, color: Color(0xFF3E4795)),
                const SizedBox(width: 8),
                const Text('Route Runs:', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(routeRuns.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.people, color: Color(0xFF3E4795)),
                const SizedBox(width: 8),
                const Text('Passengers:', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(passengers.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF3E4795)),
                const SizedBox(width: 8),
                const Text('First Trip:', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(firstTrip, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF3E4795)),
                const SizedBox(width: 8),
                const Text('Last Trip:', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(lastTrip, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 