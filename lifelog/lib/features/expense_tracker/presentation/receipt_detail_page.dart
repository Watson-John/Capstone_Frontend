import 'package:flutter/material.dart';

import '../data/expense_service.dart';
import '../domain/models/category_constants.dart';
import '../domain/models/expense.dart';
import '../domain/models/receipt_line_item.dart';
import 'widgets/bulk_categorize_sheet.dart';
import 'widgets/receipt_category_legend.dart';
import 'widgets/receipt_items_list.dart';
import 'widgets/receipt_spend_bar.dart';
import 'widgets/recategorize_sheet.dart';

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
  final Set<String> _selectedChipCategories = {};

  // ── Computed ────────────────────────────────────────────────────────────────

  double get _total => (_items ?? []).fold(0.0, (s, i) => s + i.price);

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
    final items = await _service.getReceiptLineItems(
      widget.expense.veryfiDocumentId,
      expenseId: widget.expense.id,
      vendorName: widget.expense.vendor,
    );
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
      _selectedChipCategories
        ..clear()
        ..addAll(items.map((i) => i.category));
    });
  }

  void _showRecategorizeSheet(ReceiptLineItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return RecategorizeSheet(
          item: item,
          onSave: (newDecodedName, newCategory, saveAsAlias) async {
            final updatedItems = await _service.recategorizeLineItem(
              item: item,
              newDecodedName: newDecodedName,
              newCategory: newCategory,
              saveAsAlias: saveAsAlias,
            );
            if (!mounted) return;
            setState(() {
              _items = updatedItems;
            });
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  void _showBulkCategorizeSheet() {
    final sheetContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BulkCategorizeSheet(
        itemCount: _items!.length,
        initialCategory: _sortedCategories.isNotEmpty
            ? _sortedCategories.first.key
            : ExpenseCategories.assignable.first,
        onSave: (cat) async {
          final updated = await _service.recategorizeAllLineItems(
            expenseId: widget.expense.id!,
            newCategory: cat,
            vendorName: widget.expense.vendor,
          );
          if (!mounted) return;
          setState(() {
            _items = updated;
            _selectedChipCategories
              ..clear()
              ..addAll(updated.map((i) => i.category));
          });
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
      ),
    );
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
        actions: [
          if (_items != null && _items!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.bolt),
              tooltip: 'Categorize all items',
              onPressed: _showBulkCategorizeSheet,
            ),
        ],
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
                    child: ReceiptItemsList(
                      items: _items ?? [],
                      sortedCategories: _sortedCategories,
                      selectedCategories: _selectedChipCategories,
                      onRecategorize: _showRecategorizeSheet,
                      onBulkCategorize: _showBulkCategorizeSheet,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = _total;
    final cats = _sortedCategories;
    final allKeys = cats.map((e) => e.key).toSet();

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
          ReceiptSpendBar(
            categories: cats,
            total: total,
            selectedCategories: _selectedChipCategories,
          ),
          const SizedBox(height: 12),
          ReceiptCategoryLegend(
            categories: cats,
            total: total,
            selectedCategories: _selectedChipCategories,
            onToggle: (key) {
              setState(() {
                if (_selectedChipCategories.contains(key)) {
                  _selectedChipCategories.remove(key);
                } else {
                  _selectedChipCategories.add(key);
                }
              });
            },
            onToggleAll: () {
              setState(() {
                final allSelected = allKeys.isNotEmpty &&
                    allKeys.every(_selectedChipCategories.contains);
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
        ],
      ),
    );
  }
}
