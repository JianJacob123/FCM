import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
              top: 120,
              left: 16,
              child: GestureDetector(
                onHorizontalDragEnd: (_) => setState(() => _showStatusCard = false),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showStatusCard = false),
                            child: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('2/20 Passengers', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          if (!_showStatusCard && _currentIndex == 2)
            Positioned(
              top: 130,
              left: 8,
              child: GestureDetector(
                onTap: () => setState(() => _showStatusCard = true),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
                  ),
                  child: const Icon(Icons.chevron_right, size: 18),
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

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            center: LatLng(13.8000, 121.0500),
            zoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
          ],
        ),
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Search location...',
                    ),
                  ),
                ),
              ],
            ),
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
    final List<Map<String, String>> notifications = [
      {
        'title': 'Passenger Pickup Alert',
        'message': 'You have a new pickup at P. Laurel Ave.',
        'time': '9:41 AM',
      },
      {
        'title': 'Route Update',
        'message': 'Heavy traffic detected ahead.',
        'time': '7:50 AM',
      },
      {
        'title': 'Quick Assistance Alert Sent',
        'message': 'Admin support will reach out shortly.',
        'time': '9:00 AM',
      },
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E4795),
              ),
            ),
            const SizedBox(height: 20),
            ...notifications.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: Icon(Icons.notification_important_outlined,
                    color: Color(0xFF3E4795)),
                title: Text(item['title']!, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item['message']!),
                trailing: Text(item['time']!),
              ),
            )),
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Passenger Pick-ups',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E4795),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Text('Passenger Capacity Status'),
                  SizedBox(height: 6),
                  Text('2/20', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Can accommodate more passengers.',
                      style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...pickups.map((pickup) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: Icon(Icons.location_on, color: Color(0xFF3E4795)),
                title: Text(pickup['location']!,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Location: ${pickup['coords']}'),
                trailing: Text(pickup['time']!),
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
      appBar: AppBar(
        title: const Text('FCM Admin'),
        backgroundColor: const Color(0xFF3E4795),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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
                      color: isMe ? const Color(0xFF3E4795) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Write a message',
                      border: OutlineInputBorder(),
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
    );
  }
}

// ---------------- ProfileTab ----------------

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final String busNumber = "FCM No. 05";
    final String plateNumber = "DAL 7674";
    final String driverName = "Nelson Suarez";
    final String conductorEmail = "mixednames@gmail.com";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF3E4795),
                child: const Icon(Icons.person, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                busNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Color(0xFF3E4795),
                ),
              ),
              Text(
                plateNumber,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
            ],
          ),
          const Text(
            'Account Information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3E4795)),
          ),
          const SizedBox(height: 12),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: "Driver's Name",
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              hintText: driverName,
            ),
            controller: TextEditingController(text: driverName),
          ),
          const SizedBox(height: 12),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: "Conductor's Name",
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              hintText: conductorEmail,
            ),
            controller: TextEditingController(text: conductorEmail),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.phone, color: Color(0xFF3E4795)),
            title: const Text('Call for Quick Assistance'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Color(0xFF3E4795)),
            title: const Text('View Ratings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
