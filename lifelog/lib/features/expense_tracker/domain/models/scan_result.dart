import 'receipt_line_item.dart';

class ScanQuota {
  const ScanQuota({
    required this.limit,
    required this.used,
    required this.remaining,
    required this.monthKey,
  });

  final int limit;
  final int used;
  final int remaining;
  final String monthKey;

  factory ScanQuota.fromJson(Map<String, dynamic> json) {
    return ScanQuota(
      limit: json['limit'] as int,
      used: json['used'] as int,
      remaining: json['remaining'] as int,
      monthKey: json['monthKey'] as String,
    );
  }
}

class ScanResult {
  const ScanResult({
    this.amount,
    this.date,
    this.vendor,
    this.veryfiCategory,
    this.veryfiDocumentId,
    this.lineItems = const [],
    required this.quota,
  });

  final double? amount;
  final String? date;
  final String? vendor;
  final String? veryfiCategory;
  final String? veryfiDocumentId;

  /// Line items returned directly from the scan. Empty if the backend
  /// did not include them (e.g. quota exceeded path).
  final List<ReceiptLineItem> lineItems;

  final ScanQuota quota;

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['lineItems'] as List<dynamic>? ?? [];
    final lineItems = rawItems.map((e) {
      final m = e as Map<String, dynamic>;
      return ReceiptLineItem(
        receiptAcronym: m['receiptAcronym'] as String? ?? '',
        decodedName: m['decodedName'] as String? ?? '',
        category: m['category'] as String? ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0.0,
        scanOrder: (m['scanOrder'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return ScanResult(
      amount: (json['amount'] as num?)?.toDouble(),
      date: json['date'] as String?,
      vendor: json['vendor'] as String?,
      veryfiCategory: json['veryfiCategory'] as String?,
      veryfiDocumentId: json['veryfiDocumentId'] as String?,
      lineItems: lineItems,
      quota: ScanQuota.fromJson(json['quota'] as Map<String, dynamic>),
    );
  }
}
