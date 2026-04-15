import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../domain/models/mood_log.dart';

class MoodAnalysisService {
  static const int _tokenBudget = 8000;
  static const int _charsPerToken = 4;

  Future<String> fetchAnalysis(List<MoodLog> logs) async {
    final baseUrl = dotenv.env['BACKEND_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('BACKEND_URL not configured');
    }

    final persistence = _buildPersistence(logs);
    final url =
        Uri.parse('$baseUrl/api/notifications/analyze-mood/?for=main_page');

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'persistence': persistence}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      throw Exception('Empty analysis response');
    }
    throw Exception('Analysis request failed (${response.statusCode})');
  }

  List<Map<String, dynamic>> _buildPersistence(List<MoodLog> logs) {
    final sorted = [...logs]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final picked = <Map<String, dynamic>>[];
    int charTotal = 0;
    final charBudget = _tokenBudget * _charsPerToken;

    for (final log in sorted) {
      final entry = {
        'date': log.dateTime,
        'mood': log.mood,
        'tags': (log.tags == null || log.tags!.trim().isEmpty)
            ? <String>[]
            : log.tags!
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList(),
        'description': log.description,
        'energy': log.energy ?? '',
      };
      final entryChars = jsonEncode(entry).length;
      if (charTotal + entryChars > charBudget && picked.isNotEmpty) break;
      picked.add(entry);
      charTotal += entryChars;
    }
    return picked;
  }
}
