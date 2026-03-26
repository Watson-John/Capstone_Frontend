import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:permission_handler/permission_handler.dart';

import 'app.dart';
import 'core/routes/app_routes.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart'; // Uncomment after running flutterfire configure

import 'core/database/database_helper.dart';
import 'features/notifications_reminders/domain/models/in_app_notification.dart';

// Handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.notification != null) {
    final inAppNotification = InAppNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      timestamp: DateTime.now(),
      isRead: false,
    );

    await DatabaseHelper().insertNotification(inAppNotification);
  }

  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  // Note: For cross-platform support, you should run `flutterfire configure`
  // and uncomment the `options: DefaultFirebaseOptions.currentPlatform` lines.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Set up background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Notification Service
    final notificationService = NotificationService();
    // Do not await this so it doesn't block runApp if backend is slow/unreachable
    notificationService.initialize();

    // Request camera and photo library permissions after UI is up.
    // Do not await here — blocking before runApp() stalls the launch.
    [Permission.camera, Permission.photos].request();
  } catch (e) {
    debugPrint(
        "Firebase init error. Ensure native configs or flutterfire configure are setup: $e");
  }

  final prefs = await SharedPreferences.getInstance();

  // --- DEBUG: Print all SharedPreferences ---
  debugPrint('--- CURRENT SHARED PREFERENCES ---');
  final keys = prefs.getKeys();
  for (String key in keys) {
    debugPrint('$key: ${prefs.get(key)}');
  }
  debugPrint('----------------------------------');

  final userName = prefs.getString('userName');
  final initialRoute = (userName != null && userName.isNotEmpty)
      ? AppRoutes.dashboard
      : AppRoutes.onboarding;

  runApp(LifelogApp(initialRoute: initialRoute));
}
