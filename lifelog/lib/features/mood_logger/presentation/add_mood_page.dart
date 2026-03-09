import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../domain/models/mood_log.dart';

class AddMoodPage extends StatefulWidget {
  final MoodLog? moodToEdit;

  const AddMoodPage({super.key, this.moodToEdit});

  @override
  State<AddMoodPage> createState() => _AddMoodPageState();
}

class _AddMoodPageState extends State<AddMoodPage> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _moodController = TextEditingController();

  final TextEditingController _emojiController =
      TextEditingController(text: '😎');

  List<MoodLog> _history = [];
  List<String> _uniqueTags = [];
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String _aiResponse = '';

  @override
  void initState() {
    super.initState();
    if (widget.moodToEdit != null) {
      _descController.text = widget.moodToEdit!.description;
      _moodController.text = widget.moodToEdit!.mood;
      _emojiController.text = widget.moodToEdit!.emoji;
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final db = DatabaseHelper();
    final logs = await db.getMoodLogs();
    final uniqueTags = await db.getUniqueMoodTags();
    if (mounted) {
      setState(() {
        _history = logs;
        _uniqueTags = uniqueTags;
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzeMood() async {
    final desc = _descController.text.trim();
    final tag = _moodController.text.trim();

    if (desc.isEmpty || tag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a description and a mood tag first')),
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
                'mood': tag,
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
    final tag = _moodController.text.trim();

    if (desc.isEmpty || tag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a description and a mood tag')),
      );
      return;
    }

    final newLog = MoodLog(
      id: widget.moodToEdit?.id,
      description: desc,
      mood: tag,
      dateTime: widget.moodToEdit?.dateTime ?? DateTime.now().toIso8601String(),
      emoji: _emojiController.text.trim().isNotEmpty
          ? _emojiController.text.trim()
          : '😎',
    );

    final db = DatabaseHelper();

    if (widget.moodToEdit == null) {
      // Analyze the mood before saving so the AI response is displayed
      await _analyzeMood();

      await db.insertMoodLog(newLog);

      _descController.clear();
      _moodController.clear();
      _emojiController.text = '😎'; // reset

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mood saved successfully!')),
      );
    } else {
      await db.updateMoodLog(newLog);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mood updated successfully!')),
      );
      if (mounted) {
        Navigator.pop(context, true); // Pop out to return true status
        return; // Early return to avoid re-loading history and staying on screen
      }
    }

    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EDCE), // Theme background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF3B4863)),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: const Icon(Icons.volunteer_activism,
                  color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Lifelog',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none,
                size: 32, color: Color(0xFF3B4863)),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.notifications),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.menu, size: 32, color: Color(0xFF3B4863)),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.settings),
            tooltip: 'Settings / Menu',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                            _emojiController.text.isEmpty
                                ? '😎'
                                : _emojiController.text,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 8),
                        const Text(
                          'Mood Logger',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2B3A55),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeMood,
                      icon: const Icon(Icons.auto_awesome,
                          size: 16, color: Colors.amber),
                      label: const Text(
                        'Analyze Mood',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B4863),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Emoji picker
                const Text(
                  'How are you feeling today? (Enter an emoji)',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B4863)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 80, // restrict width to feel like emoji block
                  child: TextField(
                    controller: _emojiController,
                    textAlign: TextAlign.center,
                    maxLength: 2, // emojis can take up to 2 characters
                    style: const TextStyle(fontSize: 32),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: const Color(0xFFF0F0F0),
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

                // Explain about your mood
                const Text(
                  'Explain about your mood',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B4863)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor:
                        const Color(0xFF8692A6), // Grayish-blue from design
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Add Mood Input
                TextField(
                  controller: _moodController,
                  decoration: InputDecoration(
                    hintText: 'Enter a mood tag (e.g., Happy, Sad, Working)',
                    filled: true,
                    fillColor: const Color(0xFFF0F0F0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Render custom tag chips
                if (_uniqueTags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _uniqueTags.map((t) {
                      return ActionChip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          setState(() {
                            _moodController.text = t;
                          });
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),

                // AI Response Box placeholder
                Container(
                  constraints: const BoxConstraints(minHeight: 120),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E2EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -1,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD9E2EC),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'AI Response',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B4863),
                            ),
                          ),
                        ),
                      ),
                      // Fake dashed border visual
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DashedRectPainter(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 24.0, left: 16.0, right: 16.0, bottom: 16.0),
                        child: Center(
                          child: _isAnalyzing
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF3B4863),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'loading',
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 13),
                                    ),
                                  ],
                                )
                              : Text(
                                  _aiResponse.isEmpty
                                      ? 'AI insights will appear here...'
                                      : _aiResponse,
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      height: 1.4),
                                  textAlign: TextAlign.justify,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Save button
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: _saveMood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B4863),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Save',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),

                // Mood History Header
                const Text(
                  'Mood History',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2B3A55)),
                ),
                const SizedBox(height: 12),

                // History Table
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8692A6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Created on',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text('Mood',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white))
                          : _history.isEmpty
                              ? const Center(
                                  child: Text('No history.',
                                      style: TextStyle(color: Colors.white70)))
                              : ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight:
                                        250, // Keep list nicely sized but scrollable
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _history.length,
                                    itemBuilder: (context, index) {
                                      final log = _history[index];
                                      final date = DateFormat('MM/dd/yyyy')
                                          .format(DateTime.parse(log.dateTime));
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(date,
                                                style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12)),
                                            Text('${log.emoji} ${log.mood}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ],
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

// Painter for dashed border
class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B4863)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;

    // Draw top
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
    // Draw right
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width, startY),
          Offset(size.width, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
    // Draw bottom
    startX = size.width;
    while (startX > 0) {
      canvas.drawLine(Offset(startX, size.height),
          Offset(startX - dashWidth, size.height), paint);
      startX -= dashWidth + dashSpace;
    }
    // Draw left
    startY = size.height;
    while (startY > 0) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY - dashWidth), paint);
      startY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
