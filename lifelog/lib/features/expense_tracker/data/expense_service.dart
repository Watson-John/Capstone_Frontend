import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/database/database_helper.dart';
import '../domain/models/category_constants.dart';
import '../domain/models/expense.dart';
import '../domain/models/receipt_line_item.dart';
import '../domain/models/scan_result.dart';
import '../domain/models/store_alias.dart';
import '../domain/models/user_alias.dart';

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

  /// Load line items for an expense. If already persisted in local DB, return
  /// those (preserving user corrections). Otherwise, fetch from API/stub,
  /// run through the categorization pipeline, persist, and return.
  Future<List<ReceiptLineItem>> getReceiptLineItems(
    String? veryfiDocumentId, {
    int? expenseId,
    String? vendorName,
  }) async {
    final db = DatabaseHelper();

    // 1. If we have an expenseId, check for persisted line items first.
    if (expenseId != null) {
      final persisted = await db.getLineItemsForExpense(expenseId);
      if (persisted.isNotEmpty) {
        final hasBasicStale = persisted.any((item) =>
            !ExpenseCategories.all.contains(item.category) ||
            item.decodedName.toUpperCase() ==
                item.receiptAcronym.toUpperCase());
        final isStale =
            hasBasicStale || await _hasAliasMismatch(db, persisted);
        if (!isStale) return persisted;
        // Stale items (bad category, alias not applied, or alias updated) — delete and re-fetch.
        await db.deleteLineItemsForExpense(expenseId);
      }
    }

    // 2. Fetch raw items from API (currently stub).
    final rawItems = await _fetchRawLineItems(veryfiDocumentId);

    // 3. Run each item through the categorization pipeline.
    final categorized = <ReceiptLineItem>[];
    for (final item in rawItems) {
      final resolved = await _categorize(item, vendorName: vendorName);
      categorized.add(resolved.copyWith(expenseId: expenseId));
    }

    // 4. Persist if we have an expenseId.
    if (expenseId != null) {
      await db.insertLineItems(categorized);
      // Re-fetch to get DB-assigned IDs.
      return db.getLineItemsForExpense(expenseId);
    }

    return categorized;
  }

  /// Fetch raw line items from the backend for a given veryfiDocumentId.
  /// Falls back to an empty list if the document is not found or the call fails.
  Future<List<ReceiptLineItem>> _fetchRawLineItems(
      String? veryfiDocumentId) async {
    if (veryfiDocumentId == null || veryfiDocumentId.isEmpty) return [];

    final url = Uri.parse(
        '$_baseUrl/api/expenses/receipts/$veryfiDocumentId/line-items/');
    debugPrint('[ExpenseService] GET $url');

    try {
      final response = await http.get(
        url,
        headers: {'X-Prototype-App-Key': _appKey},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawItems = data['lineItems'] as List<dynamic>? ?? [];
        return rawItems.map((e) {
          final m = e as Map<String, dynamic>;
          return ReceiptLineItem(
            receiptAcronym: m['receiptAcronym'] as String? ?? '',
            decodedName: m['decodedName'] as String? ?? '',
            category: m['category'] as String? ?? '',
            price: (m['price'] as num?)?.toDouble() ?? 0.0,
            scanOrder: (m['scanOrder'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      }

      debugPrint('[ExpenseService] line-items status=${response.statusCode}');
    } catch (e) {
      debugPrint('[ExpenseService] line-items fetch error: $e');
    }
    return [];
  }

  // ── Save with line items ─────────────────────────────────────────────────────

  /// Persist an expense and immediately store its line items (from a ScanResult).
  /// Runs each item through the categorization pipeline before inserting.
  /// Returns the saved Expense with its DB-assigned id.
  Future<Expense> saveExpenseWithLineItems({
    required Expense expense,
    required List<ReceiptLineItem> rawLineItems,
  }) async {
    final db = DatabaseHelper();

    // 1. Insert the expense and get the auto-assigned id.
    final expenseId = await db.insertExpense(expense);
    final savedExpense = Expense(
      id: expenseId,
      amount: expense.amount,
      date: expense.date,
      vendor: expense.vendor,
      category: expense.category,
      veryfiDocumentId: expense.veryfiDocumentId,
      createdAt: expense.createdAt,
    );

    // 2. Run line items through categorization pipeline and persist.
    if (rawLineItems.isNotEmpty) {
      final categorized = <ReceiptLineItem>[];
      for (final item in rawLineItems) {
        final resolved =
            await _categorize(item, vendorName: expense.vendor);
        categorized.add(resolved.copyWith(expenseId: expenseId));
      }
      await db.insertLineItems(categorized);
    }

    return savedExpense;
  }

  // ── Categorization pipeline ─────────────────────────────────────────────────

  /// Pipeline: global alias → user alias → store alias → (future: fuzzy) → existing → UNCATEGORIZED.
  Future<ReceiptLineItem> _categorize(
    ReceiptLineItem item, {
    String? vendorName,
  }) async {
    final normalized = UserAlias.normalizeAcronym(item.receiptAcronym);

    // Step 1: Global alias (stub — always null for now).
    final globalResult = await _resolveGlobalAlias(normalized);
    if (globalResult != null) {
      return item.copyWith(
        decodedName: globalResult.decodedName,
        category: globalResult.category,
      );
    }

    // Step 2: User alias.
    final userResult = await _resolveUserAlias(normalized);
    if (userResult != null) {
      return item.copyWith(
        decodedName: userResult.decodedName,
        category: userResult.category,
      );
    }

    // Step 2.5: Store alias — fallback for items with no line-item alias.
    if (vendorName != null) {
      final storeAlias = await DatabaseHelper()
          .getStoreAlias(StoreAlias.normalize(vendorName));
      if (storeAlias != null) {
        return item.copyWith(
          decodedName: _toProperCase(item.decodedName),
          category: storeAlias.category,
        );
      }
    }

    // Step 3: Future — fuzzy matching placeholder.
    // final fuzzyResult = await _resolveFuzzyAlias(normalized);
    // if (fuzzyResult != null) return item.copyWith(...);

    final casedName = _toProperCase(item.decodedName);

    // Step 4: Only keep the category if it is a recognized app category.
    if (ExpenseCategories.all.contains(item.category)) {
      return item.copyWith(decodedName: casedName);
    }

    // Step 5: Nothing confident — mark UNCATEGORIZED.
    return item.copyWith(
        decodedName: casedName, category: ExpenseCategories.uncategorized);
  }

  /// Returns true if any persisted item has a user alias whose decoded name
  /// differs from what is stored — meaning the alias was updated after the
  /// item was last categorized.
  Future<bool> _hasAliasMismatch(
      DatabaseHelper db, List<ReceiptLineItem> items) async {
    for (final item in items) {
      final alias =
          await db.getUserAlias(UserAlias.normalizeAcronym(item.receiptAcronym));
      if (alias != null && alias.decodedName != item.decodedName) return true;
    }
    return false;
  }

  /// Convert an all-uppercase string to Title Case.
  /// Strings that already contain lowercase letters are returned unchanged.
  String _toProperCase(String text) {
    if (text != text.toUpperCase()) return text;
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// Global/preloaded alias stub — returns null for now.
  /// Future: load from bundled CSV asset and search.
  Future<({String decodedName, String category})?> _resolveGlobalAlias(
      String normalized) async {
    return null;
  }

  /// User alias lookup — queries the user_aliases table.
  Future<({String decodedName, String category})?> _resolveUserAlias(
      String normalized) async {
    final alias = await DatabaseHelper().getUserAlias(normalized);
    if (alias == null) return null;
    return (decodedName: alias.decodedName, category: alias.category);
  }

  // ── Recategorization ────────────────────────────────────────────────────────

  /// Recategorize a line item and optionally save it as a user alias.
  /// Propagates the change to all line items in the same receipt that share
  /// the same receiptAcronym. Returns the updated full item list.
  Future<List<ReceiptLineItem>> recategorizeLineItem({
    required ReceiptLineItem item,
    required String newDecodedName,
    required String newCategory,
    required bool saveAsAlias,
  }) async {
    final db = DatabaseHelper();
    final normalized = UserAlias.normalizeAcronym(item.receiptAcronym);

    // 1. If saveAsAlias, upsert into user_aliases (newest wins).
    if (saveAsAlias) {
      final now = DateTime.now().toIso8601String();
      final alias = UserAlias(
        receiptAcronym: normalized,
        decodedName: newDecodedName,
        category: newCategory,
        createdAt: now,
        updatedAt: now,
      );
      await db.upsertUserAlias(alias);
    }

    // 2. Propagate to all line items with same acronym in this receipt.
    if (item.expenseId != null) {
      await db.updateLineItemsByAcronym(
        expenseId: item.expenseId!,
        receiptAcronym: item.receiptAcronym,
        newDecodedName: newDecodedName,
        newCategory: newCategory,
      );

      // 3. Re-fetch the full receipt to get updated state.
      return db.getLineItemsForExpense(item.expenseId!);
    }

    return [];
  }

  Future<List<ReceiptLineItem>> recategorizeAllLineItems({
    required int expenseId,
    required String newCategory,
    String? vendorName,
  }) async {
    final db = DatabaseHelper();
    await db.updateAllLineItemCategories(expenseId, newCategory);

    // Save a store-level alias so future receipts from this vendor
    // default uncategorized items to this category.
    if (vendorName != null && vendorName.isNotEmpty) {
      final now = DateTime.now().toIso8601String();
      await db.upsertStoreAlias(StoreAlias(
        vendorName: StoreAlias.normalize(vendorName),
        category: newCategory,
        createdAt: now,
        updatedAt: now,
      ));
    }

    return db.getLineItemsForExpense(expenseId);
  }
}
