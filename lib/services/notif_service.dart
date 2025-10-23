import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  //Initialize
  Future<void> initNotification() async {
    if (_isInitialized) return; // prevent re-initialization

    // Android initialization settings
    const initSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combine settings
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    // Initialize plugin
    await notificationsPlugin.initialize(initSettings);

    //REQUEST PERMISSIONS manually for Android 13+ and iOS
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _isInitialized = true;
  }

  //Proper Notification Details
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id', // Channel ID
        'Daily Notifications', // Channel name
        channelDescription: 'Daily Notification Channel', // Description
        importance: Importance.max,
        priority: Priority.high,
        playSound: true, // ✅ ensure sound plays
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  //Use your notificationDetails() when showing
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    await notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails(), // ✅ use this instead of empty NotificationDetails()
    );
  }
}
