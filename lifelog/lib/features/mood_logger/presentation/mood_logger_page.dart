import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_helper.dart';
import '../domain/models/mood_log.dart';
import 'add_mood_page.dart';
import 'widgets/half_donut_chart.dart';

class MoodLoggerPage extends StatefulWidget {
  const MoodLoggerPage({super.key});

  @override
  State<MoodLoggerPage> createState() => _MoodLoggerPageState();
}

class _MoodLoggerPageState extends State<MoodLoggerPage> {
  String _userName = '';
  List<MoodLog> _moodLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName') ?? 'User';

    final dbHelper = DatabaseHelper();
    final logs = await dbHelper.getMoodLogs();

    if (mounted) {
      setState(() {
        _userName = name;
        _moodLogs = logs;
        _isLoading = false;
      });
    }
  }

  void _navigateToAddMood() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMoodPage()),
    );
    // Refresh after returning
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EDCE), // Theme background
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header text
                    Text(
                      'Hello $_userName!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2B3A55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Explore your activity.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF3B4863),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Centered Box Container mimicking "ThemedPageContent" style
                    Container(
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
                          // Top bar inside the container
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '🥹', // Happy emoji
                                    style: TextStyle(fontSize: 28),
                                  ),
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
                              ElevatedButton(
                                onPressed: _navigateToAddMood,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B4863),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Add Mood',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // My Mood Report Box
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6F8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'My Mood Report',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B4863),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildMoodReportList(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // My Mood Graph Box
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Text(
                                  'My Mood Graph',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B4863),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildPieChart(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Keep Going Box
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6F8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: const Column(
                              children: [
                                Text(
                                  'Keep Going',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B4863),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Finish what you start — your\nfuture self is watching. 🌿',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMoodReportList() {
    if (_moodLogs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('No data yet.'),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: _moodLogs.length,
        itemBuilder: (context, index) {
          final log = _moodLogs[index];
          DateTime dt = DateTime.parse(log.dateTime);
          String formattedDate = DateFormat('MM/dd/yyyy').format(dt);

          return InkWell(
            onTap: () => _showMoodDetailsBottomSheet(context, log),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF0F0F0),
                    radius: 20,
                    child:
                        Text(log.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.mood,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B4863),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B4863),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMoodDetailsBottomSheet(BuildContext context, MoodLog log) {
    DateTime dt = DateTime.parse(log.dateTime);
    String formattedDate = DateFormat('MM/dd/yyyy').format(dt);
    String formattedTime = DateFormat('h:mm a').format(dt);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Emoji & Date)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(log.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDAE3F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            log.mood,
                            style: const TextStyle(
                              color: Color(0xFF3B4863),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B4863)),
                        ),
                        Text(
                          formattedTime,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Full Description
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B4863),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    log.description,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons (Edit / Delete)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context); // Close bottom sheet
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddMoodPage(moodToEdit: log),
                            ),
                          );
                          // Refresh data if edited
                          if (result == true) {
                            _loadData();
                          }
                        },
                        icon: const Icon(Icons.edit, color: Color(0xFF3B4863)),
                        label: const Text('Edit',
                            style: TextStyle(color: Color(0xFF3B4863))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3B4863)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close bottom sheet
                          _confirmDelete(context, log);
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white),
                        label: const Text('Delete',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, MoodLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mood Log?'),
        content: const Text(
            'Are you sure you want to permanently delete this mood entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              if (log.id != null) {
                final messenger = ScaffoldMessenger.of(context);
                await DatabaseHelper().deleteMoodLog(log.id!);
                _loadData(); // Refresh UI
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Mood log deleted')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    if (_moodLogs.isEmpty) {
      return const Text('No data yet.');
    }

    // Count occurrences of each tag
    Map<String, int> moodCounts = {};
    for (var log in _moodLogs) {
      moodCounts[log.mood] = (moodCounts[log.mood] ?? 0) + 1;
    }

    return HalfDonutChart(moodCounts: moodCounts);
  }
}
