/// Maps raw receipt text → clean display name → category.
///
/// Designed for both user-specific aliases (stored locally) and
/// global/preloaded aliases (future CSV import). The [normalizeAcronym]
/// method provides the normalization layer that fuzzy matching will extend.
class UserAlias {
  const UserAlias({
    this.id,
    required this.receiptAcronym,
    required this.decodedName,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;

  /// Normalized raw receipt text (uppercased, trimmed).
  final String receiptAcronym;

  /// Human-readable display name chosen by the user.
  final String decodedName;

  /// One of [ExpenseCategories.assignable].
  final String category;

  final String createdAt;
  final String updatedAt;

  /// Normalize raw receipt text for consistent lookup.
  /// Future fuzzy matching will extend this with a similarity threshold.
  static String normalizeAcronym(String raw) => raw.trim().toUpperCase();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'receipt_acronym': receiptAcronym,
      'decoded_name': decodedName,
      'category': category,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory UserAlias.fromMap(Map<String, dynamic> map) {
    return UserAlias(
      id: map['id'] as int?,
      receiptAcronym: map['receipt_acronym'] as String,
      decodedName: map['decoded_name'] as String,
      category: map['category'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  UserAlias copyWith({
    int? id,
    String? receiptAcronym,
    String? decodedName,
    String? category,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserAlias(
      id: id ?? this.id,
      receiptAcronym: receiptAcronym ?? this.receiptAcronym,
      decodedName: decodedName ?? this.decodedName,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
