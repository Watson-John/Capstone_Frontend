import 'package:flutter/painting.dart';

class CategoryStyle {
  const CategoryStyle({required this.background, required this.foreground});
  final Color background;
  final Color foreground;
}

const Map<String, CategoryStyle> kCategoryStyles = {
  'GROCERY':        CategoryStyle(background: Color(0xFFC8E6D3), foreground: Color(0xFF2E7D5A)),
  'HOUSEHOLD':      CategoryStyle(background: Color(0xFFD4DABB), foreground: Color(0xFF5A6B35)),
  'BEAUTY_CARE':    CategoryStyle(background: Color(0xFFFFD6DF), foreground: Color(0xFFB05470)),
  'PHARMACY':       CategoryStyle(background: Color(0xFFEDD9E8), foreground: Color(0xFF8B5A7A)),
  'CLOTHING':       CategoryStyle(background: Color(0xFFDDD6F0), foreground: Color(0xFF6B5AA0)),
  'KIDS':           CategoryStyle(background: Color(0xFFEAE4F8), foreground: Color(0xFF8B75C8)),
  'BOOKS_OFFICE':   CategoryStyle(background: Color(0xFFDDD0C4), foreground: Color(0xFF6B4A30)),
  'ELECTRONICS':    CategoryStyle(background: Color(0xFFD0D5F0), foreground: Color(0xFF3A4A9E)),
  'HOME_DECOR':     CategoryStyle(background: Color(0xFFF5E0BA), foreground: Color(0xFFA0620A)),
  'DINING':         CategoryStyle(background: Color(0xFFF5D4C8), foreground: Color(0xFFA04A35)),
  'PET_SUPPLIES':   CategoryStyle(background: Color(0xFFF5EBBA), foreground: Color(0xFF8A6A10)),
  'FUEL_AUTO':      CategoryStyle(background: Color(0xFFEDDFAB), foreground: Color(0xFF7A6010)),
  'TRAVEL':         CategoryStyle(background: Color(0xFFCCE8E8), foreground: Color(0xFF2A7070)),
  'FEES_TAX':       CategoryStyle(background: Color(0xFFD8DDE5), foreground: Color(0xFF4A5A6E)),
  'OTHER':          CategoryStyle(background: Color(0xFFE0DDD8), foreground: Color(0xFF5A5550)),
  'UNCATEGORIZED':  CategoryStyle(background: Color(0xFFFFF3E0), foreground: Color(0xFFE65100)),
  'MIXED':          CategoryStyle(background: Color(0xFFE8EAF0), foreground: Color(0xFF4A5268)),
};

CategoryStyle styleForCategory(String category) =>
    kCategoryStyles[category] ??
    const CategoryStyle(background: Color(0xFFE0DDD8), foreground: Color(0xFF5A5550));

String formatCategoryLabel(String category) {
  return category
      .split('_')
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}
