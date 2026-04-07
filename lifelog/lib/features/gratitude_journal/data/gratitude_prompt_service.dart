import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GratitudePromptService {
  static const _localPrompts = [
    "What made you smile today?",
    "Who are you grateful for, and why?",
    "What small moment brought you joy recently?",
    "What is something about your health you're thankful for?",
    "What challenge helped you grow?",
    "What place are you grateful to have visited or called home?",
    "What skill or talent are you glad you have?",
    "Who showed you kindness this week?",
    "What piece of technology made your life easier today?",
    "What is something beautiful you noticed today?",
    "What opportunity are you thankful for right now?",
    "What memory always makes you feel warm inside?",
    "What are three things you take for granted that you shouldn't?",
    "What book, song, or show are you grateful exists?",
    "What lesson from a difficult time are you now thankful for?",
    "Who is someone who believed in you when you doubted yourself?",
    "What food are you genuinely happy exists in the world?",
    "What simple pleasure brought you comfort lately?",
    "What about today's weather or season are you grateful for?",
    "What is something new you learned recently that excites you?",
  ];

  /// Returns today's prompt — from server cache, server, or local fallback.
  Future<String> fetchPrompt(DateTime date) async {
    final key = 'gratitude_prompt_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Check SharedPreferences cache first
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    if (cached != null && cached.isNotEmpty) return cached;

    // Try to fetch from backend
    final baseUrl = dotenv.env['BACKEND_URL'];
    if (baseUrl != null && baseUrl.isNotEmpty) {
      try {
        final url = Uri.parse('$baseUrl/api/gratitude/prompt/');
        final response = await http.get(
          url,
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final prompt = data['prompt'] as String? ?? '';
          if (prompt.isNotEmpty) {
            await prefs.setString(key, prompt);
            return prompt;
          }
        }
      } catch (_) {
        // Network unavailable — fall through to local prompt
      }
    }

    // Local deterministic fallback — same prompt for the same calendar date
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return _localPrompts[dayOfYear % _localPrompts.length];
  }
}
