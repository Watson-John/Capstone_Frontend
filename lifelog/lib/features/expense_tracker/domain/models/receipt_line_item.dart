class ReceiptLineItem {
  const ReceiptLineItem({
    this.id,
    this.expenseId,
    required this.receiptAcronym,
    required this.decodedName,
    required this.category,
    required this.price,
    required this.scanOrder,
  });

  final int? id;
  final int? expenseId;
  final String receiptAcronym;
  final String decodedName;
  final String category;
  final double price;
  final int scanOrder;

  bool get isUncategorized => category == 'UNCATEGORIZED';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (expenseId != null) 'expense_id': expenseId,
      'receipt_acronym': receiptAcronym,
      'decoded_name': decodedName,
      'category': category,
      'price': price,
      'scan_order': scanOrder,
    };
  }

  factory ReceiptLineItem.fromMap(Map<String, dynamic> map) {
    return ReceiptLineItem(
      id: map['id'] as int?,
      expenseId: map['expense_id'] as int?,
      receiptAcronym: map['receipt_acronym'] as String,
      decodedName: map['decoded_name'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      scanOrder: (map['scan_order'] as num).toInt(),
    );
  }

  ReceiptLineItem copyWith({
    int? id,
    int? expenseId,
    String? receiptAcronym,
    String? decodedName,
    String? category,
    double? price,
    int? scanOrder,
  }) {
    return ReceiptLineItem(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      receiptAcronym: receiptAcronym ?? this.receiptAcronym,
      decodedName: decodedName ?? this.decodedName,
      category: category ?? this.category,
      price: price ?? this.price,
      scanOrder: scanOrder ?? this.scanOrder,
    );
  }
}
