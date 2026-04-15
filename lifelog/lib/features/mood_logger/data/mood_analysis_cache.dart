import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/mood_log.dart';

class MoodAnalysisCache {
  static const _textKey = 'mood_analysis.text';
  static const _signatureKey = 'mood_analysis.signature';

  String signatureFor(List<MoodLog> logs) {
    if (logs.isEmpty) return '0';
    final sorted = [...logs]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final latest = sorted.first;
    return '${logs.length}|${latest.id ?? 0}|${latest.dateTime}';
  }

  Future<String?> read(List<MoodLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final storedSig = prefs.getString(_signatureKey);
    if (storedSig == null || storedSig != signatureFor(logs)) return null;
    return prefs.getString(_textKey);
  }

  Future<void> write(String text, List<MoodLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textKey, text);
    await prefs.setString(_signatureKey, signatureFor(logs));
  }
}
