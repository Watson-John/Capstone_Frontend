class ReceiptLineItem {
  const ReceiptLineItem({
    required this.receiptAcronym,
    required this.decodedName,
    required this.category,
    required this.price,
    required this.scanOrder,
  });

  final String receiptAcronym;
  final String decodedName;
  final String category;
  final double price;
  final int scanOrder;
}
