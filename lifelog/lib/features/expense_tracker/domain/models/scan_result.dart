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
    required this.quota,
  });

  final double? amount;
  final String? date;
  final String? vendor;
  final String? veryfiCategory;
  final String? veryfiDocumentId;
  final ScanQuota quota;

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      amount: (json['amount'] as num?)?.toDouble(),
      date: json['date'] as String?,
      vendor: json['vendor'] as String?,
      veryfiCategory: json['veryfiCategory'] as String?,
      veryfiDocumentId: json['veryfiDocumentId'] as String?,
      quota: ScanQuota.fromJson(json['quota'] as Map<String, dynamic>),
    );
  }
}
