import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../domain/models/receipt_line_item.dart';
import '../domain/models/scan_result.dart';

class ExpenseScanException implements Exception {
  const ExpenseScanException(this.message);
  final String message;

  @override
  String toString() => message;
}

enum ReceiptScanStage { uploading, processing, receiving }

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

  Future<ScanResult> scanReceipt(
    File imageFile, {
    void Function(ReceiptScanStage stage)? onStageChanged,
    void Function(double progress)? onReceiveProgress,
  }) async {
    final createUrl = Uri.parse('$_baseUrl/api/expenses/scan-receipt/jobs/');
    debugPrint('[ExpenseService] POST $createUrl file=${imageFile.path}');

    onStageChanged?.call(ReceiptScanStage.uploading);

    final request = http.MultipartRequest('POST', createUrl)
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

    late http.StreamedResponse createStreamed;
    try {
      createStreamed = await request.send().timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('[ExpenseService] network error: $e');
      throw const ExpenseScanException('Could not reach the server. Check your connection.');
    }

    final createResponse = await http.Response.fromStream(createStreamed);
    debugPrint('[ExpenseService] create job status=${createResponse.statusCode} body=${createResponse.body}');

    if (createResponse.statusCode != 202) {
      String errorMsg = 'Could not start receipt scan.';
      try {
        final body = jsonDecode(createResponse.body) as Map<String, dynamic>;
        errorMsg = (body['error'] as String?) ?? errorMsg;
      } catch (_) {}
      throw ExpenseScanException(errorMsg);
    }

    final createData = jsonDecode(createResponse.body) as Map<String, dynamic>;
    final jobId = createData['jobId'] as String?;
    if (jobId == null || jobId.isEmpty) {
      throw const ExpenseScanException('Invalid scan job response from server.');
    }

    final pollUrl = Uri.parse('$_baseUrl/api/expenses/scan-receipt/jobs/$jobId/');
    final deadline = DateTime.now().add(const Duration(seconds: 60));

    while (DateTime.now().isBefore(deadline)) {
      late http.Response pollResponse;
      try {
        pollResponse = await http.get(
          pollUrl,
          headers: {'X-Prototype-App-Key': _appKey},
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('[ExpenseService] poll error: $e');
        await Future.delayed(const Duration(milliseconds: 350));
        continue;
      }

      if (pollResponse.statusCode != 200) {
        await Future.delayed(const Duration(milliseconds: 350));
        continue;
      }

      final payload = jsonDecode(pollResponse.body) as Map<String, dynamic>;
      final statusValue = (payload['status'] as String? ?? '').toLowerCase();
      final overallProgress = (payload['progress'] as num?)?.toDouble() ?? 0.0;

      if (statusValue == 'queued' || statusValue == 'uploading') {
        onStageChanged?.call(ReceiptScanStage.uploading);
      } else if (statusValue == 'processing') {
        onStageChanged?.call(ReceiptScanStage.processing);
      } else if (statusValue == 'receiving') {
        onStageChanged?.call(ReceiptScanStage.receiving);
        onReceiveProgress?.call(_toReceivingProgress(overallProgress));
      } else if (statusValue == 'completed') {
        onStageChanged?.call(ReceiptScanStage.receiving);
        onReceiveProgress?.call(1.0);
        final result = payload['result'] as Map<String, dynamic>?;
        if (result == null) {
          throw const ExpenseScanException('Scan completed without a result payload.');
        }
        return ScanResult.fromJson(result);
      } else if (statusValue == 'failed') {
        final error = payload['error'] as String? ?? 'Receipt scan failed.';
        throw ExpenseScanException(error);
      }

      await Future.delayed(const Duration(milliseconds: 350));
    }

    throw const ExpenseScanException('Receipt scan timed out. Please try again.');
  }

  double _toReceivingProgress(double overallProgress) {
    const receivingStart = 0.66;
    const receivingSpan = 0.34;
    final normalized = ((overallProgress - receivingStart) / receivingSpan)
        .clamp(0.0, 1.0);
    return normalized;
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

  Future<List<ReceiptLineItem>> getReceiptLineItems(
      String? veryfiDocumentId) async {
    // Stub — replace with real API call when backend endpoint is ready.
    return const [
      ReceiptLineItem(receiptAcronym: 'GV WHL MLK 1G',  decodedName: 'Great Value Whole Milk 1 Gallon',    category: 'GROCERY',      price: 4.27,  scanOrder: 1),
      ReceiptLineItem(receiptAcronym: 'BNS CHKN BRST',  decodedName: 'Boneless Chicken Breast',            category: 'GROCERY',      price: 9.46,  scanOrder: 2),
      ReceiptLineItem(receiptAcronym: 'EQ TOOTHPST',    decodedName: 'Equate Toothpaste',                  category: 'BEAUTY_CARE',  price: 2.97,  scanOrder: 3),
      ReceiptLineItem(receiptAcronym: 'GV DISH SOAP',   decodedName: 'Great Value Dish Soap',              category: 'HOUSEHOLD',    price: 3.48,  scanOrder: 4),
      ReceiptLineItem(receiptAcronym: 'ADVIL 200CT',    decodedName: 'Advil Ibuprofen 200 Count',          category: 'PHARMACY',     price: 11.97, scanOrder: 5),
      ReceiptLineItem(receiptAcronym: 'LEGO CITY SET',  decodedName: 'LEGO City Police Set',               category: 'KIDS',         price: 24.99, scanOrder: 6),
      ReceiptLineItem(receiptAcronym: 'COMP NOTEBOOK',  decodedName: 'Composition Notebook 5-pk',          category: 'BOOKS_OFFICE', price: 6.44,  scanOrder: 7),
      ReceiptLineItem(receiptAcronym: 'USB-C CBL 6FT',  decodedName: 'USB-C Charging Cable 6ft',           category: 'ELECTRONICS',  price: 12.88, scanOrder: 8),
      ReceiptLineItem(receiptAcronym: 'THRO PILLOW',    decodedName: 'Decorative Throw Pillow',            category: 'HOME_DECOR',   price: 14.97, scanOrder: 9),
      ReceiptLineItem(receiptAcronym: 'ROTIS CHKN',     decodedName: 'Rotisserie Chicken',                 category: 'DINING',       price: 6.98,  scanOrder: 10),
      ReceiptLineItem(receiptAcronym: 'DOG TRTS LRG',   decodedName: 'Milk-Bone Large Dog Treats',         category: 'PET_SUPPLIES', price: 8.97,  scanOrder: 11),
      ReceiptLineItem(receiptAcronym: 'PRM UNLD 87',    decodedName: 'Premium Unleaded Fuel',              category: 'FUEL_AUTO',    price: 18.00, scanOrder: 12),
      ReceiptLineItem(receiptAcronym: 'SAMSNG CHRG',    decodedName: 'Samsung Phone Charger',              category: 'ELECTRONICS',  price: 9.88,  scanOrder: 13),
      ReceiptLineItem(receiptAcronym: 'GV LAUN DET',    decodedName: 'Great Value Laundry Detergent',      category: 'HOUSEHOLD',    price: 7.97,  scanOrder: 14),
      ReceiptLineItem(receiptAcronym: 'TAX',            decodedName: 'Sales Tax',                          category: 'FEES_TAX',     price: 4.60,  scanOrder: 15),
    ];
  }
}
