import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../../features/notifications_reminders/domain/models/in_app_notification.dart';
import 'local_notification_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Check whether the user has enabled notifications in settings.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> initialize() async {
    // The awesome_notifications singleton is owned and initialized by
    // LocalNotificationService.init(); do NOT re-initialize it here or
    // its action listeners will be silently overwritten.

    // Request permission for iOS and Android 13+
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      await _generateAndSendToken();
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
      await _generateAndSendToken();
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      await _sendTokenToBackend(newToken);
    });

    // Configure foreground notification presentation (mainly for iOS)
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle FCM taps that launch or resume the app.
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _routeFromRemoteMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_routeFromRemoteMessage);

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Message also contained a notification: ${message.notification?.title} - ${message.notification?.body}');

        // Save to SQLite
        final inAppNotification = InAppNotification(
          title: message.notification?.title ?? 'New Notification',
          body: message.notification?.body ?? '',
          timestamp: DateTime.now(),
          isRead: false,
        );

        await DatabaseHelper().insertNotification(inAppNotification);
        debugPrint('Saved foreground notification to database');

        // Show heads-up banner only if notifications are enabled in settings
        if (!await NotificationService.isEnabled()) return;
        await LocalNotificationService.instance.showFromFcm(
          type: message.data['type']?.toString(),
          title: message.notification?.title,
          body: message.notification?.body,
          extra: Map<String, dynamic>.from(message.data),
        );
      }
    });
  }

  void _routeFromRemoteMessage(RemoteMessage message) {
    final type = message.data['type']?.toString();
    debugPrint('FCM tap routed: type=$type');
    switch (type) {
      case 'gratitude':
        pendingRoute.value = '/add-gratitude';
        break;
      case 'mood':
        pendingRoute.value = '/add-mood';
        break;
      case 'task':
        pendingRoute.value = '/todo-list';
        break;
    }
  }

  Future<void> _generateAndSendToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _sendTokenToBackend(token);
      } else {
        debugPrint('Failed to get FCM token');
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    final baseUrl = dotenv.env['BACKEND_URL'];
    debugPrint('--- SEND TOKEN TO BACKEND START ---');
    debugPrint('Retrieved BACKEND_URL from .env: $baseUrl');

    if (baseUrl == null) {
      debugPrint('Error: BACKEND_URL is not set in .env');
      return;
    }

    final String platform = kIsWeb ? 'web' : Platform.operatingSystem;
    debugPrint('Detected platform: $platform');

    String tz = 'UTC';
    try {
      tz = await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      debugPrint('Could not resolve local IANA tz, defaulting to UTC: $e');
    }

    final url = Uri.parse('$baseUrl/api/commons/token/');
    debugPrint('Target API URL resolved to: $url');

    try {
      final bodyPayload = jsonEncode({
        'token': token,
        'platform': platform,
        'timezone': tz,
      });
      debugPrint('Request Body Payload: $bodyPayload');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: bodyPayload,
          )
          .timeout(
            const Duration(seconds: 10),
          );

      debugPrint('--- API RESPONSE RECEIVED ---');
      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('SUCCESS: Token successfully registered to backend');

        // Parse the response body to extract the ID and save to SharedPreferences
        try {
          final data = jsonDecode(response.body);
          if (data['id'] != null) {
            final deviceId = data['id'].toString();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('device_id', deviceId);
            debugPrint(
                'Successfully saved device_id "$deviceId" to SharedPreferences');
          } else {
            debugPrint(
                'Note: No "id" field found in the backend response body to save.');
          }
        } catch (e) {
          debugPrint(
              'Error parsing response body or saving to SharedPreferences: $e');
        }
      } else {
        debugPrint('FAILED: to register token. Check status code above.');
      }
    } catch (e) {
      debugPrint('--- API EXCEPTION CAUGHT ---');
      debugPrint('Error sending token to backend: $e');
    }
  }

  Future<String> getDailyQuote() async {
    final baseUrl = dotenv.env['BACKEND_URL'];
    if (baseUrl == null) {
      return 'Stay positive, work hard, make it happen.'; // Fallback quote
    }

    final url = Uri.parse('$baseUrl/api/notifications/daily-quote/');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming the API returns a JSON object with a 'quote' field.
        return data['quote'] ?? 'Stay positive, work hard, make it happen.';
      } else {
        debugPrint('Failed to load quote. Status code: ${response.statusCode}');
        return 'Stay positive, work hard, make it happen.';
      }
    } catch (e) {
      debugPrint('Error fetching daily quote: $e');
      return 'Stay positive, work hard, make it happen.';
    }
  }
}
