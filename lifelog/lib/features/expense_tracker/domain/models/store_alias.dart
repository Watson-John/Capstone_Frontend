/// Maps a store/vendor name to a default expense category.
///
/// Used as a fallback when individual line-item aliases don't match.
/// Only applies to items that would otherwise be UNCATEGORIZED.
class StoreAlias {
  const StoreAlias({
    this.id,
    required this.vendorName,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String vendorName;
  final String category;
  final String createdAt;
  final String updatedAt;

  /// Normalize vendor name for consistent lookup.
  static String normalize(String raw) => raw.trim().toUpperCase();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vendor_name': vendorName,
      'category': category,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory StoreAlias.fromMap(Map<String, dynamic> map) {
    return StoreAlias(
      id: map['id'] as int?,
      vendorName: map['vendor_name'] as String,
      category: map['category'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  StoreAlias copyWith({
    int? id,
    String? vendorName,
    String? category,
    String? createdAt,
    String? updatedAt,
  }) {
    return StoreAlias(
      id: id ?? this.id,
      vendorName: vendorName ?? this.vendorName,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
