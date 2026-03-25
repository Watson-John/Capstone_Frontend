import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../../core/database/database_helper.dart';
import '../domain/models/mood_log.dart';

class AddMoodPage extends StatefulWidget {
  final MoodLog? moodToEdit;

  const AddMoodPage({super.key, this.moodToEdit});

  @override
  State<AddMoodPage> createState() => _AddMoodPageState();
}

class _AddMoodPageState extends State<AddMoodPage> {
  final TextEditingController _descController = TextEditingController();

  final TextEditingController _emojiController =
      TextEditingController(text: '😎');

  bool _isAnalyzing = false;
  String _aiResponse = '';

  @override
  void initState() {
    super.initState();
    if (widget.moodToEdit != null) {
      _descController.text = widget.moodToEdit!.description;
      _emojiController.text = widget.moodToEdit!.emoji;
    }
  }

  Future<void> _analyzeMood() async {
    final desc = _descController.text.trim();
    final emoji = _emojiController.text.trim();

    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description first')),
      );
      return;
    }

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
                'mood': emoji,
                'description': desc,
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

  Future<void> _saveMood() async {
    final desc = _descController.text.trim();

    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    final emoji = _emojiController.text.trim().isNotEmpty
        ? _emojiController.text.trim()
        : '😎';

    final newLog = MoodLog(
      id: widget.moodToEdit?.id,
      description: desc,
      mood: emoji,
      dateTime:
          widget.moodToEdit?.dateTime ?? DateTime.now().toIso8601String(),
      emoji: emoji,
    );

    final db = DatabaseHelper();

    if (widget.moodToEdit == null) {
      await db.insertMoodLog(newLog);

      _descController.clear();
      _emojiController.text = '😎';

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
                // Emoji picker
                Text(
                  'How are you feeling today?',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _emojiController,
                    textAlign: TextAlign.center,
                    maxLength: 2,
                    style: const TextStyle(fontSize: 32),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  'Explain about your mood',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Describe how you feel...',
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

                const SizedBox(height: 16),

                // Action buttons row
                Row(
                  children: [
                    FilledButton(
                      onPressed: _saveMood,
                      child: Text(
                        isEditing ? 'Update Mood' : 'Log Mood',
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

                // AI Response
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
}
