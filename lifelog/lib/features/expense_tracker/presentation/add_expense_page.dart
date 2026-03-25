import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/database_helper.dart';
import '../domain/models/category_constants.dart';
import '../domain/models/category_styles.dart';
import '../domain/models/expense.dart';
import '../domain/models/receipt_line_item.dart';
import '../domain/models/scan_result.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  ScanResult? _scanResult;
  bool _isSaving = false;
  String? _selectedCategory;
  final List<_LineItemEntry> _lineItems = [];
  bool _showLineItems = false;

  bool get _hasLineItems => _lineItems.isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill from scan result passed via route arguments (only on first load).
    if (_scanResult == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ScanResult) {
        _scanResult = args;
        _amountController.text = args.amount?.toStringAsFixed(2) ?? '';
        _vendorController.text = args.vendor ?? '';
        // Map Veryfi category to built-in category if it matches.
        if (args.veryfiCategory != null &&
            ExpenseCategories.assignable.contains(args.veryfiCategory)) {
          _selectedCategory = args.veryfiCategory;
        }
        if (args.date != null) {
          try {
            _selectedDate = DateTime.parse(args.date!);
          } catch (_) {}
        }
        // Pre-fill line items from scan result if available.
        if (args.lineItems.isNotEmpty) {
          _showLineItems = true;
          for (final li in args.lineItems) {
            final entry = _LineItemEntry();
            entry.nameController.text = li.decodedName;
            entry.priceController.text = li.price.toStringAsFixed(2);
            entry.category = ExpenseCategories.assignable.contains(li.category)
                ? li.category
                : ExpenseCategories.assignable.first;
            _lineItems.add(entry);
          }
          _recalculateTotal();
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    for (final li in _lineItems) {
      li.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _recalculateTotal() {
    double sum = 0;
    for (final li in _lineItems) {
      sum += double.tryParse(li.priceController.text.trim()) ?? 0;
    }
    _amountController.text = sum.toStringAsFixed(2);
  }

  String? _deriveCategoryFromLineItems() {
    if (_lineItems.isEmpty) return null;
    _LineItemEntry? highest;
    double highestPrice = -1;
    for (final li in _lineItems) {
      final price = double.tryParse(li.priceController.text.trim()) ?? 0;
      if (price > highestPrice) {
        highestPrice = price;
        highest = li;
      }
    }
    return highest?.category;
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(_LineItemEntry());
      _showLineItems = true;
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems[index].dispose();
      _lineItems.removeAt(index);
      if (_lineItems.isEmpty) {
        _amountController.text = '';
      } else {
        _recalculateTotal();
      }
    });
  }

  Future<void> _save() async {
    // Derive category from line items if not explicitly set.
    if (_selectedCategory == null && _hasLineItems) {
      setState(() {
        _selectedCategory = _deriveCategoryFromLineItems();
      });
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final expense = Expense(
      amount: double.parse(_amountController.text.trim()),
      date: _selectedDate.toIso8601String().substring(0, 10),
      vendor: _vendorController.text.trim(),
      category: _selectedCategory!,
      veryfiDocumentId: _scanResult?.veryfiDocumentId,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      final expenseId = await DatabaseHelper().insertExpense(expense);

      // Insert line items if any.
      if (_hasLineItems) {
        final items = _lineItems.asMap().entries.map((e) {
          final i = e.key;
          final li = e.value;
          final name = li.nameController.text.trim();
          return ReceiptLineItem(
            expenseId: expenseId,
            receiptAcronym: name,
            decodedName: name,
            category: li.category,
            price: double.parse(li.priceController.text.trim()),
            scanOrder: i,
          );
        }).toList();
        await DatabaseHelper().insertLineItems(items);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true); // signals success to caller
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save expense: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Scan source banner
            if (_scanResult != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.document_scanner, size: 18, color: colorScheme.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _scanResult!.veryfiDocumentId != null
                            ? 'Scanned via Veryfi · doc #${_scanResult!.veryfiDocumentId}'
                            : 'Pre-filled from scanned receipt',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Amount
            TextFormField(
              controller: _amountController,
              readOnly: _hasLineItems,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                helperText: _hasLineItems ? 'Calculated from line items' : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter an amount';
                if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(dateLabel),
              ),
            ),
            const SizedBox(height: 16),

            // Vendor
            TextFormField(
              controller: _vendorController,
              decoration: const InputDecoration(
                labelText: 'Vendor / Store',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a vendor name' : null,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedCategory),
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              isExpanded: true,
              items: ExpenseCategories.assignable.map((cat) {
                final style = styleForCategory(cat);
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: style.background,
                          border: Border.all(color: style.foreground),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(formatCategoryLabel(cat)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Select a category' : null,
            ),
            const SizedBox(height: 16),

            // Line Items Section
            _buildLineItemsSection(theme, colorScheme),

            const SizedBox(height: 16),

            // Quota info
            if (_scanResult != null)
              Text(
                'Scans this month: ${_scanResult!.quota.used} / ${_scanResult!.quota.limit}',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemsSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toggle header
        InkWell(
          onTap: () => setState(() => _showLineItems = !_showLineItems),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _showLineItems ? Icons.expand_less : Icons.expand_more,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Line Items (optional)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_hasLineItems) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_lineItems.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Expanded content
        if (_showLineItems) ...[
          const SizedBox(height: 8),

          // Line item cards
          for (int i = 0; i < _lineItems.length; i++) ...[
            _buildLineItemCard(i, theme, colorScheme),
            const SizedBox(height: 8),
          ],

          // Add item button
          OutlinedButton.icon(
            onPressed: _addLineItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Item'),
          ),

          // Total summary
          if (_hasLineItems) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total: ',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '\$${_amountController.text}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLineItemCard(int index, ThemeData theme, ColorScheme colorScheme) {
    final entry = _lineItems[index];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Column(
          children: [
            // Item name + remove button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item name',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter item name' : null,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeLineItem(index),
                  icon: Icon(Icons.remove_circle_outline,
                      color: colorScheme.error, size: 20),
                  tooltip: 'Remove item',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Category + price row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category dropdown
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('li_${index}_${entry.category}'),
                    initialValue: entry.category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: ExpenseCategories.assignable.map((cat) {
                      final style = styleForCategory(cat);
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: style.background,
                                border: Border.all(color: style.foreground),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                formatCategoryLabel(cat),
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => entry.category = v);
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Price field
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: entry.priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) {
                      setState(() => _recalculateTotal());
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter price';
                      if (double.tryParse(v.trim()) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                // Spacer to align with remove button above
                const SizedBox(width: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineItemEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String category = ExpenseCategories.assignable.first;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}
