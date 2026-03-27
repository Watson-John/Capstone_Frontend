import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the anonymous per-install identity issued by the backend.
///
/// On first launch the app registers with the backend to receive a UUID
/// [instanceId] and a one-time [instanceToken].  Both values are persisted
/// in SharedPreferences.  Subsequent launches reuse the stored credentials.
///
/// All alias write-path calls must include [instanceHeaders] so the backend
/// can scope data to this install and block bad actors via is_active=False.
class AppInstanceService {
  static const _idKey = 'app_instance_id';
  static const _tokenKey = 'app_instance_token';

  static String get _baseUrl => dotenv.env['BACKEND_URL'] ?? '';
  static String get _appKey => dotenv.env['PROTOTYPE_APP_KEY'] ?? '';

  /// Returns true if credentials are already stored.
  static Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_idKey) && prefs.containsKey(_tokenKey);
  }

  /// Returns the stored instance ID, or null if not yet registered.
  static Future<String?> get instanceId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idKey);
  }

  /// Assembles all auth headers needed for alias API calls.
  ///
  /// Returns an empty map if credentials are missing (e.g. offline at first
  /// launch).  Callers should treat a missing instance as "best-effort" and
  /// skip per-instance writes gracefully.
  static Future<Map<String, String>> instanceHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_idKey);
    final token = prefs.getString(_tokenKey);
    if (id == null || token == null) return {};
    return {
      'X-Prototype-App-Key': _appKey,
      'X-Instance-ID': id,
      'X-Instance-Token': token,
    };
  }

  /// Registers with the backend if not already registered.
  ///
  /// Safe to call on every launch — exits immediately if credentials exist.
  /// Swallows errors so a network failure at startup does not crash the app.
  static Future<void> registerIfNeeded() async {
    if (await isRegistered()) return;

    try {
      final url = Uri.parse('$_baseUrl/api/aliases/instances/register/');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Prototype-App-Key': _appKey,
            },
            body: jsonEncode({'platform': _detectPlatform()}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_idKey, data['instanceId'] as String);
        await prefs.setString(_tokenKey, data['instanceToken'] as String);
        debugPrint('[AppInstance] registered: ${data['instanceId']}');
      } else {
        debugPrint('[AppInstance] registration failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AppInstance] registration error (will retry on next launch): $e');
    }
  }

  static String _detectPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'web';
  }
}
