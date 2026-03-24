import 'package:flutter/material.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/app_page_header.dart';
import '../domain/models/mood_log.dart';
import 'add_mood_page.dart';
import 'widgets/half_donut_chart.dart';
import 'widgets/mood_card_shell.dart';
import 'widgets/mood_details_bottom_sheet.dart';
import 'widgets/mood_report_list.dart';

class MoodLoggerPage extends StatefulWidget {
  const MoodLoggerPage({super.key});

  @override
  State<MoodLoggerPage> createState() => _MoodLoggerPageState();
}

class _MoodLoggerPageState extends State<MoodLoggerPage> {
  List<MoodLog> _moodLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final logs = await DatabaseHelper().getMoodLogs();
    if (mounted) {
      setState(() {
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
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppPageHeader(title: 'Mood Logger'),
                    const SizedBox(height: 16),
                    MoodCardShell(
                      title: 'My Mood Report',
                      child: MoodReportList(
                        moodLogs: _moodLogs,
                        onMoodTap: (log) => showMoodDetailsBottomSheet(
                          context,
                          log: log,
                          onReload: _loadData,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    MoodCardShell(
                      title: 'Mood Distribution',
                      child: _buildPieChart(cs),
                    ),
                    const SizedBox(height: 16),
                    MoodCardShell(
                      title: 'Keep Going',
                      child: Text(
                        'Finish what you start — your future self is watching.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
      ),
      floatingActionButton: AppFab(heroTag: 'mood-fab', onPressed: _navigateToAddMood),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPieChart(ColorScheme cs) {
    if (_moodLogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Log some moods to see your chart.',
            style: TextStyle(color: cs.outline, fontSize: 13),
          ),
        ),
      );
    }

    final Map<String, int> moodCounts = {};
    for (var log in _moodLogs) {
      moodCounts[log.mood] = (moodCounts[log.mood] ?? 0) + 1;
    }

    return HalfDonutChart(moodCounts: moodCounts);
  }
}
