import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../routing/app_router.dart';

/// Service to handle Firebase Cloud Messaging (FCM) push notifications.
///
/// Wires incoming push notifications to in-app navigation using GoRouter.
@lazySingleton
class PushNotificationService {
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      
      final messaging = FirebaseMessaging.instance;

      // Request permission
      await messaging.requestPermission(
        
      );

      // Handle background/terminated state messages
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // Handle foreground messages when tapped
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      // Handle foreground messages received while app is open
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground FCM message: ${message.messageId}');
        final context = rootNavigatorKey.currentContext;
        if (context != null && message.notification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.notification?.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(message.notification?.body ?? ''),
                ],
              ),
              action: SnackBarAction(
                label: 'Lihat',
                onPressed: () => _handleMessage(message),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize Firebase Messaging: $e');
      // Gracefully handle the error in cases where google-services.json is missing
    }
  }

  
  Future<void> registerToken(String userId) async {
    if (!_isInitialized) {
      debugPrint('Skipping FCM token registration: Firebase is not initialized');
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        // Send token to backend
        debugPrint('Registered FCM token: $token for user: $userId');
      }
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  Future<void> clearToken() async {
    if (!_isInitialized) {
      debugPrint('Skipping FCM token clear: Firebase is not initialized');
      return;
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
      debugPrint('Cleared FCM token');
    } catch (e) {
      debugPrint('Failed to clear FCM token: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    final type = message.data['type'];
    final targetId = message.data['targetId'];

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    if (type == 'chat' && targetId != null) {
      context.push('/chat/$targetId');
    } else if (type == 'order' && targetId != null) {
      // Navigate to order details or worker history depending on role
      // Simplified for this example
      context.push('/notifications');
    } else {
      context.push('/notifications');
    }
  }
}
