import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages (e.g. when app is terminated).
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    // Request notification permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Only proceed if permission granted
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get and save FCM token (handled by saveToken method after auth)

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        // Token will be saved via saveToken when user is authenticated
        print('FCM Token refreshed: $newToken');
      });
    } else {
      print('Notification permission denied by user');
    }

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Foreground: show in-app notification if desired.
      // Will be implemented in Phase 1.3
    });

    // Notification opened handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // User tapped notification when app was in background.
      // Will be implemented in Phase 1.3
    });
  }

  /// Save FCM token to Firestore for the given user
  Future<void> saveToken(String userId) async {
    try {
      final token = await _messaging.getToken();

      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
        });
        print('FCM token saved for user $userId');
      } else {
        print('No FCM token available');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
      // Don't throw - this shouldn't block the user flow
    }
  }

  /// Get the current FCM token
  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  /// Delete FCM token on logout
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      print('FCM token deleted');
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
}
