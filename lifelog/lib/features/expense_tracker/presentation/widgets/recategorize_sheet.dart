import 'package:flutter/material.dart';

import '../../domain/models/category_constants.dart';
import '../../domain/models/category_styles.dart';
import '../../domain/models/receipt_line_item.dart';

class RecategorizeSheet extends StatefulWidget {
  const RecategorizeSheet({
    super.key,
    required this.item,
    required this.onSave,
  });

  final ReceiptLineItem item;
  final Future<void> Function(
    String newDecodedName,
    String newCategory,
    bool saveAsAlias,
  ) onSave;

  @override
  State<RecategorizeSheet> createState() => _RecategorizeSheetState();
}

class _RecategorizeSheetState extends State<RecategorizeSheet> {
  late TextEditingController _nameController;
  late String _selectedCategory;
  bool _saveAsAlias = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.decodedName);
    _selectedCategory = widget.item.isUncategorized
        ? ExpenseCategories.assignable.first
        : widget.item.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Recategorize Item',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.item.receiptAcronym,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          Text(
            'Category',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategories.assignable.map((cat) {
              final style = styleForCategory(cat);
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(formatCategoryLabel(cat)),
                selected: isSelected,
                selectedColor: style.background,
                labelStyle: TextStyle(
                  color: isSelected ? style.foreground : cs.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? style.foreground : cs.outlineVariant,
                ),
                onSelected: (_) => setState(() => _selectedCategory = cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Remember for future receipts'),
            subtitle: const Text('Save this mapping as an alias'),
            value: _saveAsAlias,
            onChanged: (v) => setState(() => _saveAsAlias = v),
          ),
          const SizedBox(height: 16),

          FilledButton(
            onPressed: _isSaving ? null : _onSave,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    await widget.onSave(name, _selectedCategory, _saveAsAlias);
    if (mounted) setState(() => _isSaving = false);
  }
}
