import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'notif_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final baseUrl = dotenv.env['API_BASE_URL'];

class SocketService {
  late IO.Socket socket;

  // ✅ Singleton
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  //  Add this
  final NotifService _notifService = NotifService();

  // Callback list for notification updates
  final List<Function()> _notificationCallbacks = [];

  // Register a callback to be called when a new notification arrives
  void onNewNotification(Function() callback) {
    _notificationCallbacks.add(callback);
  }

  // Remove a callback
  void removeNotificationCallback(Function() callback) {
    _notificationCallbacks.remove(callback);
  }

  // Notify all registered callbacks
  void _notifyCallbacks() {
    for (var callback in _notificationCallbacks) {
      callback();
    }
  }

  //save notification locally
  Future<void> _saveNotification(dynamic notif) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stored = prefs.getStringList('notifications') ?? [];

    stored.insert(0, jsonEncode(notif));
    await prefs.setStringList('notifications', stored);
  }

  // Get saved notifications
  static Future<List<dynamic>> getStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('notifications') ?? [];
    return stored.map((e) => jsonDecode(e)).toList();
  }

  //optional: clear all notifications
  static Future<void> clearStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
  }

  void initSocket(String userId, {bool isAdmin = false}) {
    // 1. Connect to backend notifications namespace
    socket = IO.io(
      "$baseUrl/notifications", // replace with your server IP/domain
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() // we control when to connect
          .build(),
    );

    // 2. Listen for connection
    socket.onConnect((_) {
      print("✅ Connected to notifications socket");

      if (isAdmin) {
        // Join admin room
        socket.emit("subscribeAdminNotifications");
      } else {
        // Join user-specific + usersRoom
        socket.emit("subscribeNotifications", userId);
      }
    });

    // 3. Listen for disconnection
    socket.onDisconnect((_) {
      print("❌ Disconnected from notifications socket");
    });

    // 4. Listen for new notifications
    socket.on("newNotification", (data) async {
      print("📩 New notification: $data");

      // Save notification locally
      await _saveNotification(data);

      // show local notification popup
      await _notifService.showNotification(
        title: data["notif_title"] ?? "New Notification",
        body: data["content"] ?? "",
      );

      // Notify all registered callbacks to refresh their notification lists
      _notifyCallbacks();
    });

    // 5. Connect
    socket.connect();
  }

  void dispose() {
    socket.dispose();
    _notificationCallbacks.clear();
  }
}
