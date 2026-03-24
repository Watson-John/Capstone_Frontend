/// Single source of truth for expense category strings.
class ExpenseCategories {
  ExpenseCategories._();

  static const grocery = 'GROCERY';
  static const household = 'HOUSEHOLD';
  static const beautyCare = 'BEAUTY_CARE';
  static const pharmacy = 'PHARMACY';
  static const clothing = 'CLOTHING';
  static const kids = 'KIDS';
  static const booksOffice = 'BOOKS_OFFICE';
  static const electronics = 'ELECTRONICS';
  static const homeDecor = 'HOME_DECOR';
  static const dining = 'DINING';
  static const petSupplies = 'PET_SUPPLIES';
  static const fuelAuto = 'FUEL_AUTO';
  static const travel = 'TRAVEL';
  static const feesTax = 'FEES_TAX';
  static const other = 'OTHER';
  static const uncategorized = 'UNCATEGORIZED';

  /// All assignable categories (excludes UNCATEGORIZED — it is a temporary state).
  static const List<String> assignable = [
    grocery,
    household,
    beautyCare,
    pharmacy,
    clothing,
    kids,
    booksOffice,
    electronics,
    homeDecor,
    dining,
    petSupplies,
    fuelAuto,
    travel,
    feesTax,
    other,
  ];

  /// All categories including the temporary UNCATEGORIZED.
  static const List<String> all = [
    ...assignable,
    uncategorized,
  ];
}
