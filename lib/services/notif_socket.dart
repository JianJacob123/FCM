import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'notif_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseUrl = dotenv.env['API_BASE_URL'];

class SocketService {
  late IO.Socket socket;
  final NotifService _notifService = NotifService();

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

      // show local notification popup
      await _notifService.showNotification(
        title: data["notif_title"] ?? "New Notification",
        body: data["content"] ?? "",
      );
    });

    // 5. Connect
    socket.connect();
  }

  void dispose() {
    socket.dispose();
  }
}
