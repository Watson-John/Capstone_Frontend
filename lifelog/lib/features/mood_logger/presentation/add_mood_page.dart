import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../../core/database/database_helper.dart';
import '../domain/models/mood_log.dart';
import '../domain/models/mood_tag_styles.dart';

// ── Page ─────────────────────────────────────────────────────────────────────

class AddMoodPage extends StatefulWidget {
  final MoodLog? moodToEdit;

  const AddMoodPage({super.key, this.moodToEdit});

  @override
  State<AddMoodPage> createState() => _AddMoodPageState();
}

class _AddMoodPageState extends State<AddMoodPage> {
  final TextEditingController _noteController = TextEditingController();

  int? _selectedMoodIndex;
  String? _energy;
  final Set<String> _selectedTags = {};

  bool _isAnalyzing = false;
  String _aiResponse = '';

  @override
  void initState() {
    super.initState();
    final edit = widget.moodToEdit;
    if (edit != null) {
      _noteController.text = edit.description;
      _energy = edit.energy;

      // Restore mood selection
      final idx = kMoods.indexWhere((m) => m.emoji == edit.emoji);
      _selectedMoodIndex = idx >= 0 ? idx : null;

      // Restore tags
      if (edit.tags != null && edit.tags!.isNotEmpty) {
        _selectedTags.addAll(edit.tags!.split(','));
      }

    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ── AI Analysis (existing logic) ──────────────────────────────────────────

  Future<void> _analyzeMood() async {
    if (_selectedMoodIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a mood first')),
      );
      return;
    }

    final mood = kMoods[_selectedMoodIndex!];
    final desc = _noteController.text.trim();

    setState(() {
      _isAnalyzing = true;
      _aiResponse = '';
    });

    try {
      final baseUrl = dotenv.env['BACKEND_URL'];
      if (baseUrl != null) {
        final url = Uri.parse('$baseUrl/api/notifications/analyze-mood/');
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'mood': mood.emoji,
                'description': desc.isNotEmpty ? desc : mood.label,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _aiResponse = data['message'] ?? 'Analyzed successfully.';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _aiResponse =
                  'Error: Failed to analyze mood (Status ${response.statusCode}).';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _aiResponse = 'Error: Backend URL not configured.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiResponse = 'Error: Could not connect to the server.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveMood() async {
    if (_selectedMoodIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select how you\'re feeling')),
      );
      return;
    }

    final mood = kMoods[_selectedMoodIndex!];
    final note = _noteController.text.trim();

    final newLog = MoodLog(
      id: widget.moodToEdit?.id,
      description: note,
      mood: mood.label,
      dateTime:
          widget.moodToEdit?.dateTime ?? DateTime.now().toIso8601String(),
      emoji: mood.emoji,
      energy: _energy,
      tags: _selectedTags.isNotEmpty ? _selectedTags.join(',') : null,
    );

    final db = DatabaseHelper();

    if (widget.moodToEdit == null) {
      await db.insertMoodLog(newLog);
      _resetForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood saved successfully!')),
        );
      }
    } else {
      await db.updateMoodLog(newLog);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood updated successfully!')),
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
        return;
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedMoodIndex = null;
      _energy = null;
      _selectedTags.clear();
      _noteController.clear();
      _aiResponse = '';
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.moodToEdit != null;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Logger',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            Text(
              isEditing ? 'Edit Mood' : 'Log Mood',
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                // ── Question ────────────────────────────────────────────
                Text(
                  'How are you feeling right now?',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Mood Selector Row ───────────────────────────────────
                _buildMoodSelector(cs, textTheme),

                const SizedBox(height: 24),

                // ── Details Section ──────────────────────────────────────
                _buildDetailsSection(cs, textTheme),

                const SizedBox(height: 20),

                // ── Action Buttons ──────────────────────────────────────
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _saveMood,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        isEditing ? 'Update' : 'Save',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: _isAnalyzing ? null : _analyzeMood,
                      icon: _isAnalyzing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onSecondaryContainer,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        _isAnalyzing ? 'Analyzing...' : 'Analyze',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                // ── AI Insight ──────────────────────────────────────────
                if (_aiResponse.isNotEmpty || _isAnalyzing) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Insight',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isAnalyzing)
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            ),
                          )
                        else
                          Text(
                            _aiResponse,
                            style: textTheme.bodyMedium?.copyWith(
                              color: cs.onPrimaryContainer,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Mood Selector ─────────────────────────────────────────────────────────

  Widget _buildMoodSelector(ColorScheme cs, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(kMoods.length, (index) {
        final mood = kMoods[index];
        final isSelected = _selectedMoodIndex == index;

        return GestureDetector(
          onTap: () => setState(() => _selectedMoodIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? cs.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.25 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: Text(
                    mood.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? cs.primary
                        : cs.onSurfaceVariant,
                  ),
                  child: Text(mood.label),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Details Section ───────────────────────────────────────────────────────

  Widget _buildDetailsSection(ColorScheme cs, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Energy ──────────────────────────────────────────────────
          Text(
            'Energy',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'low',
                  label: Text('Low'),
                  icon: Icon(Icons.battery_1_bar_rounded, size: 18),
                ),
                ButtonSegment<String>(
                  value: 'medium',
                  label: Text('Medium'),
                  icon: Icon(Icons.battery_4_bar_rounded, size: 18),
                ),
                ButtonSegment<String>(
                  value: 'high',
                  label: Text('High'),
                  icon: Icon(Icons.battery_full_rounded, size: 18),
                ),
              ],
              selected: _energy != null ? {_energy!} : {},
              emptySelectionAllowed: true,
              onSelectionChanged: (newSelection) {
                setState(() {
                  _energy = newSelection.isNotEmpty
                      ? newSelection.first
                      : null;
                });
              },
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Tags ──────────────────────────────────────────────────
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
            children: kTagStyles.entries.map((entry) {
              final tag = entry.key;
              final style = entry.value;
              final isSelected = _selectedTags.contains(tag);

              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                showCheckmark: true,
                checkmarkColor: style.foreground,
                backgroundColor: style.background.withValues(alpha: 0.5),
                selectedColor: style.background,
                side: BorderSide(
                  color: isSelected
                      ? style.foreground.withValues(alpha: 0.4)
                      : style.background,
                  width: isSelected ? 1.5 : 1.0,
                ),
                labelStyle: TextStyle(
                  color: style.foreground,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── Note ──────────────────────────────────────────────────
          Text(
            'Note',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 3,
            style: TextStyle(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: 'Add a note about how you feel...',
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

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
