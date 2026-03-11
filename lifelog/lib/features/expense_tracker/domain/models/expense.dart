class Expense {
  const Expense({
    this.id,
    required this.amount,
    required this.date,
    required this.vendor,
    required this.category,
    this.veryfiDocumentId,
    required this.createdAt,
  });

  final int? id;
  final double amount;
  final String date;
  final String vendor;
  final String category;
  final String? veryfiDocumentId;
  final String createdAt;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'date': date,
      'vendor': vendor,
      'category': category,
      'veryfi_document_id': veryfiDocumentId,
      'created_at': createdAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      vendor: map['vendor'] as String,
      category: map['category'] as String,
      veryfiDocumentId: map['veryfi_document_id'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
