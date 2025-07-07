import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key});

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Screen
          Positioned.fill(child: MapScreen()),

          // Search Field and Location Switch
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [SearchField(), LocationSwitch()],
            ),
          ),

          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const CustomBottomBar(),
          ),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SizedBox(
        width: 1000,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          padding: EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF23242B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black54 : Colors.grey,
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Where are you going to?',
              hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              prefixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.black54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 17),
            ),
          ),
        ),
      ),
    );
  }
}

class LocationSwitch extends StatefulWidget {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 80, color: Color.fromRGBO(62, 71, 149, 1)),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
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
}

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Image.asset('assets/icons/notifications.png', width: 24, height: 24),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
          ),
          Image.asset('assets/icons/Heart.png', width: 24, height: 24),
          Image.asset('assets/icons/location.png', width: 50, height: 50),
          Image.asset('assets/icons/Clock.png', width: 24, height: 24),
          IconButton(
            icon: Icon(Icons.settings, size: 24, color: Color.fromRGBO(62, 71, 149, 1)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
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
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Color.fromRGBO(62, 71, 149, 1),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            ...notifications.map((notif) => Padding(
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
                    child: Icon(notif['icon'] as IconData, color: Color.fromRGBO(62, 71, 149, 1), size: 28),
                  ),
                  title: Text(
                    notif['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    notif['subtitle'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Text(
                    notif['time'] as String,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(13.955785338622102, 121.16551093159686),
        initialZoom: 13.0,
        interactiveFlags: InteractiveFlag.all,
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
                Icons.location_pin,
                color: const Color.fromRGBO(62, 71, 149, 1),
                size: 40,
              ),
            ),
          ],
        ),
      ],
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
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color.fromRGBO(62, 71, 149, 1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Preferences
          Text('Preferences', style: sectionStyle),
          SwitchListTile(
            title: const Text('Notifications'),
            value: notificationsEnabled,
            onChanged: (val) => setState(() => notificationsEnabled = val),
          ),
          SwitchListTile(
            title: const Text('Dark Theme'),
            value: themeProvider.isDarkMode,
            onChanged: (val) => themeProvider.toggleTheme(val),
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
                  content: const Text('This would open the location permissions settings.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
                  content: const Text('Frequently Asked Questions will be here.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
                  content: const Text('This would open the app store for rating.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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