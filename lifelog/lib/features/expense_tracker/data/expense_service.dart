import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../domain/models/scan_result.dart';

class ExpenseScanException implements Exception {
  const ExpenseScanException(this.message);
  final String message;

  @override
  String toString() => message;
}

MediaType _mimeTypeFor(String path) {
  final ext = path.split('.').last.toLowerCase();
  const types = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'heic': 'image/heic',
    'heif': 'image/heif',
  };
  return MediaType.parse(types[ext] ?? 'image/jpeg');
}

class ExpenseService {
  String get _baseUrl => dotenv.env['BACKEND_URL'] ?? '';
  String get _appKey => dotenv.env['PROTOTYPE_APP_KEY'] ?? '';

  Future<ScanResult> scanReceipt(File imageFile) async {
    final url = Uri.parse('$_baseUrl/api/expenses/scan-receipt/');
    debugPrint('[ExpenseService] POST $url file=${imageFile.path}');

    final request = http.MultipartRequest('POST', url)
      ..headers['X-Prototype-App-Key'] = _appKey
      ..files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: imageFile.path
              .split('/')
              .last
              .replaceFirst(RegExp(r'\.jpg$', caseSensitive: false), '.jpeg'),
          contentType: _mimeTypeFor(imageFile.path),
        ));

    late http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('[ExpenseService] network error: $e');
      throw const ExpenseScanException('Could not reach the server. Check your connection.');
    }

    final response = await http.Response.fromStream(streamed);
    debugPrint('[ExpenseService] response status=${response.statusCode} body=${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ScanResult.fromJson(data);
    }

    // Surface the backend error message when available.
    String errorMsg = 'Receipt scan failed.';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      errorMsg = (body['error'] as String?) ?? errorMsg;
    } catch (_) {}

    debugPrint('[ExpenseService] error ${response.statusCode}: $errorMsg');
    throw ExpenseScanException(errorMsg);
  }

  Future<ScanQuota> getQuota() async {
    final url = Uri.parse('$_baseUrl/api/expenses/scan-receipt/quota/');
    try {
      final response = await http.get(
        url,
        headers: {'X-Prototype-App-Key': _appKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ScanQuota.fromJson(data);
      }
    } catch (e) {
      debugPrint('[ExpenseService] quota fetch error: $e');
    }
    // Return a placeholder on failure so the UI doesn't crash.
    return const ScanQuota(limit: 100, used: 0, remaining: 100, monthKey: '');
  }
}
