import 'package:flutter/material.dart';

import '../../../core/database/database_helper.dart';
import '../../expense_tracker/domain/models/category_constants.dart';
import '../../expense_tracker/domain/models/category_styles.dart';
import '../../expense_tracker/domain/models/store_alias.dart';
import '../../expense_tracker/domain/models/user_alias.dart';

class AliasManagementPage extends StatefulWidget {
  const AliasManagementPage({super.key});

  @override
  State<AliasManagementPage> createState() => _AliasManagementPageState();
}

class _AliasManagementPageState extends State<AliasManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserAlias> _itemAliases = [];
  List<StoreAlias> _storeAliases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = DatabaseHelper();
    final items = await db.getAllUserAliases();
    final stores = await db.getAllStoreAliases();
    if (mounted) {
      setState(() {
        _itemAliases = items;
        _storeAliases = stores;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Aliases',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Item Aliases'),
            Tab(text: 'Store Aliases'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ItemAliasTab(
                  aliases: _itemAliases,
                  onDelete: _deleteItemAlias,
                  onEdit: _editItemAlias,
                ),
                _StoreAliasTab(
                  aliases: _storeAliases,
                  onDelete: _deleteStoreAlias,
                  onEdit: _editStoreAlias,
                ),
              ],
            ),
    );
  }

  Future<void> _deleteItemAlias(UserAlias alias) async {
    final confirm = await _confirmDelete(context, alias.decodedName);
    if (confirm != true) return;
    await DatabaseHelper().deleteUserAlias(alias.id!);
    _load();
  }

  Future<void> _deleteStoreAlias(StoreAlias alias) async {
    final confirm = await _confirmDelete(context, alias.vendorName);
    if (confirm != true) return;
    await DatabaseHelper().deleteStoreAlias(alias.id!);
    _load();
  }

  void _editItemAlias(UserAlias alias) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditItemAliasSheet(
        alias: alias,
        onSave: (name, category) async {
          final now = DateTime.now().toIso8601String();
          await DatabaseHelper().upsertUserAlias(alias.copyWith(
            decodedName: name,
            category: category,
            updatedAt: now,
          ));
          if (mounted) Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  void _editStoreAlias(StoreAlias alias) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditStoreAliasSheet(
        alias: alias,
        onSave: (category) async {
          final now = DateTime.now().toIso8601String();
          await DatabaseHelper().upsertStoreAlias(alias.copyWith(
            category: category,
            updatedAt: now,
          ));
          if (mounted) Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext ctx, String name) {
    return showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Delete Alias'),
        content: Text('Remove "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete')),
        ],
      ),
    );
  }
}

// ── Item Aliases Tab ──────────────────────────────────────────────────────────

class _ItemAliasTab extends StatelessWidget {
  const _ItemAliasTab({
    required this.aliases,
    required this.onDelete,
    required this.onEdit,
  });

  final List<UserAlias> aliases;
  final void Function(UserAlias) onDelete;
  final void Function(UserAlias) onEdit;

  @override
  Widget build(BuildContext context) {
    if (aliases.isEmpty) {
      return const Center(
        child: Text('No item aliases saved yet.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: aliases.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final alias = aliases[index];
        final style = styleForCategory(alias.category);

        return Dismissible(
          key: ValueKey('item-alias-${alias.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            onDelete(alias);
            return false;
          },
          child: ListTile(
            title: Text(
              alias.decodedName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              alias.receiptAcronym,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: style.foreground),
              ),
              child: Text(
                formatCategoryLabel(alias.category),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: style.foreground,
                ),
              ),
            ),
            onTap: () => onEdit(alias),
          ),
        );
      },
    );
  }
}

// ── Store Aliases Tab ─────────────────────────────────────────────────────────

class _StoreAliasTab extends StatelessWidget {
  const _StoreAliasTab({
    required this.aliases,
    required this.onDelete,
    required this.onEdit,
  });

  final List<StoreAlias> aliases;
  final void Function(StoreAlias) onDelete;
  final void Function(StoreAlias) onEdit;

  @override
  Widget build(BuildContext context) {
    if (aliases.isEmpty) {
      return const Center(
        child: Text('No store aliases saved yet.\n\nUse "Apply to all" on a receipt to create one.',
            textAlign: TextAlign.center),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: aliases.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final alias = aliases[index];
        final style = styleForCategory(alias.category);

        return Dismissible(
          key: ValueKey('store-alias-${alias.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            onDelete(alias);
            return false;
          },
          child: ListTile(
            leading: const Icon(Icons.store_outlined),
            title: Text(
              alias.vendorName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: style.foreground),
              ),
              child: Text(
                formatCategoryLabel(alias.category),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: style.foreground,
                ),
              ),
            ),
            onTap: () => onEdit(alias),
          ),
        );
      },
    );
  }
}

// ── Edit Item Alias Bottom Sheet ──────────────────────────────────────────────

class _EditItemAliasSheet extends StatefulWidget {
  const _EditItemAliasSheet({required this.alias, required this.onSave});
  final UserAlias alias;
  final Future<void> Function(String name, String category) onSave;

  @override
  State<_EditItemAliasSheet> createState() => _EditItemAliasSheetState();
}

class _EditItemAliasSheetState extends State<_EditItemAliasSheet> {
  late TextEditingController _nameController;
  late String _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.alias.decodedName);
    _selectedCategory = widget.alias.category;
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
            'Edit Item Alias',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          // Show receipt acronym
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
                    widget.alias.receiptAcronym,
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                onSelected: (_) =>
                    setState(() => _selectedCategory = cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSaving
                ? null
                : () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;
                    setState(() => _isSaving = true);
                    await widget.onSave(name, _selectedCategory);
                    if (mounted) setState(() => _isSaving = false);
                  },
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
}

// ── Edit Store Alias Bottom Sheet ─────────────────────────────────────────────

class _EditStoreAliasSheet extends StatefulWidget {
  const _EditStoreAliasSheet({required this.alias, required this.onSave});
  final StoreAlias alias;
  final Future<void> Function(String category) onSave;

  @override
  State<_EditStoreAliasSheet> createState() => _EditStoreAliasSheetState();
}

class _EditStoreAliasSheetState extends State<_EditStoreAliasSheet> {
  late String _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.alias.category;
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
            'Edit Store Alias',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.alias.vendorName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Default Category',
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
                onSelected: (_) =>
                    setState(() => _selectedCategory = cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSaving
                ? null
                : () async {
                    setState(() => _isSaving = true);
                    await widget.onSave(_selectedCategory);
                    if (mounted) setState(() => _isSaving = false);
                  },
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
}
