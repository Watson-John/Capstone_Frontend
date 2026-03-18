import 'package:flutter/material.dart';

import '../data/expense_service.dart';
import '../domain/models/expense.dart';
import '../domain/models/receipt_line_item.dart';

// ── Category color palette ─────────────────────────────────────────────────────

class _CategoryStyle {
  const _CategoryStyle({required this.background, required this.foreground});
  final Color background;
  final Color foreground;
}

const Map<String, _CategoryStyle> _kCategoryStyles = {
  'GROCERY':      _CategoryStyle(background: Color(0xFFC8E6D3), foreground: Color(0xFF2E7D5A)),
  'HOUSEHOLD':    _CategoryStyle(background: Color(0xFFD4DABB), foreground: Color(0xFF5A6B35)),
  'BEAUTY_CARE':  _CategoryStyle(background: Color(0xFFFFD6DF), foreground: Color(0xFFB05470)),
  'PHARMACY':     _CategoryStyle(background: Color(0xFFEDD9E8), foreground: Color(0xFF8B5A7A)),
  'CLOTHING':     _CategoryStyle(background: Color(0xFFDDD6F0), foreground: Color(0xFF6B5AA0)),
  'KIDS':         _CategoryStyle(background: Color(0xFFEAE4F8), foreground: Color(0xFF8B75C8)),
  'BOOKS_OFFICE': _CategoryStyle(background: Color(0xFFDDD0C4), foreground: Color(0xFF6B4A30)),
  'ELECTRONICS':  _CategoryStyle(background: Color(0xFFD0D5F0), foreground: Color(0xFF3A4A9E)),
  'HOME_DECOR':   _CategoryStyle(background: Color(0xFFF5E0BA), foreground: Color(0xFFA0620A)),
  'DINING':       _CategoryStyle(background: Color(0xFFF5D4C8), foreground: Color(0xFFA04A35)),
  'PET_SUPPLIES': _CategoryStyle(background: Color(0xFFF5EBBA), foreground: Color(0xFF8A6A10)),
  'FUEL_AUTO':    _CategoryStyle(background: Color(0xFFEDDFAB), foreground: Color(0xFF7A6010)),
  'TRAVEL':       _CategoryStyle(background: Color(0xFFCCE8E8), foreground: Color(0xFF2A7070)),
  'FEES_TAX':     _CategoryStyle(background: Color(0xFFD8DDE5), foreground: Color(0xFF4A5A6E)),
  'OTHER':        _CategoryStyle(background: Color(0xFFE0DDD8), foreground: Color(0xFF5A5550)),
};

_CategoryStyle _styleFor(String category) =>
    _kCategoryStyles[category] ??
    const _CategoryStyle(background: Color(0xFFE0DDD8), foreground: Color(0xFF5A5550));

String _formatCategoryLabel(String category) {
  return category
      .split('_')
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

// ── Page ──────────────────────────────────────────────────────────────────────

class ReceiptDetailPage extends StatefulWidget {
  const ReceiptDetailPage({super.key, required this.expense});

  final Expense expense;

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  final _service = ExpenseService();
  List<ReceiptLineItem>? _items;
  bool _isLoading = true;
  final Set<String> _selectedChipCategories = {}; // multi-select legend chips

  // ── Computed ────────────────────────────────────────────────────────────────

  double get _total => (_items ?? []).fold(0.0, (s, i) => s + i.price);

  // Categories sorted descending by total spend (for bar + legend order).
  List<MapEntry<String, double>> get _sortedCategories {
    final map = <String, double>{};
    for (final item in (_items ?? [])) {
      map[item.category] = (map[item.category] ?? 0.0) + item.price;
    }
    return map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items =
        await _service.getReceiptLineItems(widget.expense.veryfiDocumentId);
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.expense.vendor,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
            ),
            Text(
              widget.expense.date,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverToBoxAdapter(
                    child: _selectedChipCategories.isEmpty
                        ? _buildChipPlaceholder(context)
                        : _buildChipFilteredList(context),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = _total;
    final cats = _sortedCategories;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpendBar(context, cats, total),
          const SizedBox(height: 12),
          _buildLegend(context, cats),
        ],
      ),
    );
  }

  // ── Spend bar ────────────────────────────────────────────────────────────────

  Widget _buildSpendBar(
    BuildContext context,
    List<MapEntry<String, double>> cats,
    double total,
  ) {
    if (total <= 0 || cats.isEmpty) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            const gapWidth = 2.0;
            final totalGaps = (cats.length - 1) * gapWidth;
            final usableWidth = availableWidth - totalGaps;

            return SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (int i = 0; i < cats.length; i++) ...[
                    if (i > 0) const SizedBox(width: gapWidth),
                    _buildSegment(
                      cats[i].key,
                      cats[i].value / total,
                      usableWidth,
                      animValue,
                      isFirst: i == 0,
                      isLast: i == cats.length - 1,
                      dimmed: _selectedChipCategories.isNotEmpty &&
                          !_selectedChipCategories.contains(cats[i].key),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSegment(
    String category,
    double fraction,
    double usableWidth,
    double animValue, {
    required bool isFirst,
    required bool isLast,
    bool dimmed = false,
  }) {
    final style = _styleFor(category);
    final segWidth = (usableWidth * fraction * animValue).clamp(0.0, double.infinity);
    final radius = BorderRadius.horizontal(
      left: isFirst ? const Radius.circular(6) : Radius.zero,
      right: isLast ? const Radius.circular(6) : Radius.zero,
    );

    return AnimatedOpacity(
      opacity: dimmed ? 0.25 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: segWidth,
        height: 12,
        decoration: BoxDecoration(
          color: style.foreground,
          borderRadius: radius,
        ),
      ),
    );
  }

  // ── Legend ───────────────────────────────────────────────────────────────────

  Widget _buildLegend(
    BuildContext context,
    List<MapEntry<String, double>> cats,
  ) {
    final allKeys = cats.map((e) => e.key).toSet();
    final allSelected = allKeys.isNotEmpty &&
        allKeys.every(_selectedChipCategories.contains);

    return Column(
      children: [
        // "All" button — full width.
        SizedBox(
          width: double.infinity,
          child: _buildCategoryButton(
            context,
            label: 'All',
            amount: _total,
            bgColor: Theme.of(context).colorScheme.primary,
            fgColor: Theme.of(context).colorScheme.onPrimary,
            isSelected: allSelected,
            centerText: true,
            invertText: true,
            onTap: () {
              setState(() {
                if (allSelected) {
                  _selectedChipCategories.clear();
                } else {
                  _selectedChipCategories
                    ..clear()
                    ..addAll(allKeys);
                }
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        // Category buttons — 2-column grid.
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: cats.map((entry) {
            final style = _styleFor(entry.key);
            final isSelected =
                _selectedChipCategories.contains(entry.key);
            return _buildCategoryButton(
              context,
              label: _formatCategoryLabel(entry.key),
              amount: entry.value,
              bgColor: style.background,
              fgColor: style.foreground,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedChipCategories.remove(entry.key);
                  } else {
                    _selectedChipCategories.add(entry.key);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryButton(
    BuildContext context, {
    required String label,
    required double amount,
    required Color bgColor,
    required Color fgColor,
    required bool isSelected,
    required VoidCallback onTap,
    bool centerText = false,
    bool invertText = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final labelColor = invertText ? fgColor : cs.onSurface;
    final amountColor = invertText ? fgColor.withValues(alpha: 0.8) : cs.onSurfaceVariant;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: fgColor.withValues(alpha: 0.12),
        highlightColor: fgColor.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? fgColor : bgColor,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: centerText ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: amountColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.touch_app_outlined,
              size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'Tap a category above to see its items',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipFilteredList(BuildContext context) {
    final allItems = _items ?? [];
    // Group selected categories, preserving spend-descending order.
    final selectedCats = _sortedCategories
        .where((e) => _selectedChipCategories.contains(e.key))
        .toList();

    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int ci = 0; ci < selectedCats.length; ci++) ...[
            if (ci > 0) const SizedBox(height: 8),
            Builder(builder: (context) {
              final catEntry = selectedCats[ci];
              final style = _styleFor(catEntry.key);
              final items = allItems
                  .where((i) => i.category == catEntry.key)
                  .toList()
                ..sort((a, b) => b.price.compareTo(a.price));
              final categoryTotal =
                  items.fold(0.0, (s, i) => s + i.price);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category header.
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: style.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatCategoryLabel(catEntry.key),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Text(
                              '\$${categoryTotal.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: style.foreground,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Line items.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Column(
                      children: items
                          .map((item) => _buildExpandedItemRow(
                              context, item, style))
                          .toList(),
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Line item row ────────────────────────────────────────────────────────────

  Widget _buildExpandedItemRow(
    BuildContext context,
    ReceiptLineItem item,
    _CategoryStyle style,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: style.foreground,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.decodedName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${item.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
