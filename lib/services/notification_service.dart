import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages (e.g. when app is terminated).
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Foreground: show in-app notification if desired.
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // User tapped notification when app was in background.
    });
  }

  Future<String?> getToken() async {
    return _messaging.getToken();
  }
}
