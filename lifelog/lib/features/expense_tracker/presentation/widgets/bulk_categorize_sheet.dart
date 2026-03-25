import 'package:flutter/material.dart';

import '../../domain/models/category_constants.dart';
import '../../domain/models/category_styles.dart';

class BulkCategorizeSheet extends StatefulWidget {
  const BulkCategorizeSheet({
    super.key,
    required this.itemCount,
    required this.initialCategory,
    required this.onSave,
  });

  final int itemCount;
  final String initialCategory;
  final Future<void> Function(String newCategory) onSave;

  @override
  State<BulkCategorizeSheet> createState() => _BulkCategorizeSheetState();
}

class _BulkCategorizeSheetState extends State<BulkCategorizeSheet> {
  late String _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = ExpenseCategories.assignable.contains(widget.initialCategory)
        ? widget.initialCategory
        : ExpenseCategories.assignable.first;
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
            'Categorize all items',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.itemCount} item${widget.itemCount == 1 ? '' : 's'} will be updated',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
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
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _isSaving ? null : _onSave,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bolt, size: 18),
            label: Text(_isSaving ? 'Applying…' : 'Apply to all'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    setState(() => _isSaving = true);
    await widget.onSave(_selectedCategory);
    if (mounted) setState(() => _isSaving = false);
  }
}
