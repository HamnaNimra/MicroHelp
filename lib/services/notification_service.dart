import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages (e.g. when app is terminated).
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;

  /// Initialize notification handlers without requesting permission.
  /// Call this early (e.g. after auth) to set up listeners.
  Future<void> initHandlers() async {
    if (_initialized) return;
    _initialized = true;

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Will be implemented in Phase 1.3
    });

    // Notification opened handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Will be implemented in Phase 1.3
    });
  }

  /// Request notification permission with a rationale dialog.
  /// Returns true if permission was granted.
  Future<bool> requestPermissionWithRationale(BuildContext context) async {
    // Check if already authorized
    final current = await _messaging.getNotificationSettings();
    if (current.authorizationStatus == AuthorizationStatus.authorized ||
        current.authorizationStatus == AuthorizationStatus.provisional) {
      return true;
    }

    // Don't show rationale if already permanently denied
    if (current.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }

    // Show rationale dialog first
    if (!context.mounted) return false;
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_active, size: 40),
        title: const Text('Stay in the loop'),
        content: const Text(
          'Get notified when someone accepts your post or sends you a message. '
          'You can change this anytime in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enable notifications'),
          ),
        ],
      ),
    );

    if (shouldRequest != true) return false;

    // Actually request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) {
      // Set up handlers now that permission is granted
      await initHandlers();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
      });
    }

    return granted;
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
