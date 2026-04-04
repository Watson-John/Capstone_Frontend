import 'package:flutter/material.dart';

import '../../../core/database/database_helper.dart';
import '../domain/models/gratitude_entry.dart';

// Pre-defined gratitude tags
const _kGratitudeTags = [
  'family',
  'health',
  'work',
  'nature',
  'friendship',
  'growth',
  'joy',
  'peace',
  'creativity',
  'learning',
];

class AddGratitudePage extends StatefulWidget {
  final GratitudeEntry? entryToEdit;
  final String prompt;

  const AddGratitudePage({
    super.key,
    this.entryToEdit,
    this.prompt = '',
  });

  @override
  State<AddGratitudePage> createState() => _AddGratitudePageState();
}

class _AddGratitudePageState extends State<AddGratitudePage> {
  final TextEditingController _bodyController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.entryToEdit;
    if (edit != null) {
      _bodyController.text = edit.body;
      if (edit.tags != null && edit.tags!.isNotEmpty) {
        _selectedTags.addAll(edit.tags!.split(',').map((t) => t.trim()));
      }
    }
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something before saving.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final entry = GratitudeEntry(
      id: widget.entryToEdit?.id,
      body: body,
      prompt: widget.prompt.isNotEmpty ? widget.prompt : null,
      dateTime: widget.entryToEdit?.dateTime ?? DateTime.now().toIso8601String(),
      tags: _selectedTags.isNotEmpty ? _selectedTags.join(',') : null,
    );

    final db = DatabaseHelper();
    if (widget.entryToEdit == null) {
      await db.insertGratitudeEntry(entry);
    } else {
      await db.updateGratitudeEntry(entry);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.entryToEdit != null;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gratitude Journal',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            Text(
              isEditing ? 'Edit Entry' : 'Add Entry',
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Prompt
                if (widget.prompt.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💭', style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.prompt,
                            style: textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Body text field
                Text(
                  "What are you grateful for?",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  minLines: 5,
                  maxLines: null,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write freely — this is just for you...',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tags
                Text(
                  'Tags',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kGratitudeTags.map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                      showCheckmark: true,
                      backgroundColor: cs.primaryContainer.withValues(alpha: 0.25),
                      selectedColor: cs.primaryContainer,
                      checkmarkColor: cs.primary,
                      side: BorderSide(
                        color: selected
                            ? cs.primary.withValues(alpha: 0.4)
                            : cs.outline.withValues(alpha: 0.5),
                        width: selected ? 1.5 : 1.0,
                      ),
                      labelStyle: TextStyle(
                        color: cs.primary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Save button
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    isEditing ? 'Update' : 'Save Entry',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
