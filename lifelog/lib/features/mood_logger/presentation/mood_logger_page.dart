import 'package:flutter/material.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/app_page_header.dart';
import '../domain/models/mood_log.dart';
import 'add_mood_page.dart';
import 'widgets/half_donut_chart.dart';

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
                    _buildMoodReportCard(cs),
                    const SizedBox(height: 16),
                    _buildMoodGraphCard(cs),
                    const SizedBox(height: 16),
                    _buildKeepGoingCard(cs),
                    const SizedBox(height: 96), // FAB clearance
                  ],
                ),
              ),
      ),
      floatingActionButton: AppFab(onPressed: _navigateToAddMood),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── Card shell ─────────────────────────────────────────────────────────────

  Widget _card({
    required ColorScheme cs,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ── Mood report card ───────────────────────────────────────────────────────

  Widget _buildMoodReportCard(ColorScheme cs) {
    return _card(
      cs: cs,
      title: 'My Mood Report',
      child: _buildMoodReportList(cs),
    );
  }

  Widget _buildMoodReportList(ColorScheme cs) {
    if (_moodLogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.sentiment_neutral_outlined,
                  size: 40, color: cs.outlineVariant),
              const SizedBox(height: 8),
              Text(
                'No moods logged yet.',
                style: TextStyle(color: cs.outline, fontSize: 13),
              ),
            ],
          ),
        ),
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
          final dt = DateTime.parse(log.dateTime);
          final formattedDate =
              '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';

          return InkWell(
            onTap: () => _showMoodDetailsBottomSheet(context, log),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.surfaceContainer,
                    radius: 20,
                    child: Text(log.emoji,
                        style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.mood,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
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

  // ── Mood graph card ────────────────────────────────────────────────────────

  Widget _buildMoodGraphCard(ColorScheme cs) {
    return _card(
      cs: cs,
      title: 'Mood Distribution',
      child: _buildPieChart(cs),
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

  // ── Keep going card ────────────────────────────────────────────────────────

  Widget _buildKeepGoingCard(ColorScheme cs) {
    return _card(
      cs: cs,
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
    );
  }

  // ── Bottom sheet ───────────────────────────────────────────────────────────

  void _showMoodDetailsBottomSheet(BuildContext context, MoodLog log) {
    final cs = Theme.of(context).colorScheme;
    final dt = DateTime.parse(log.dateTime);
    final formattedDate =
        '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final formattedTime =
        '$hour:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(log.emoji,
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            log.mood,
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
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
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(
                              fontSize: 12, color: cs.outline),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    log.description,
                    style: TextStyle(
                        fontSize: 14, color: cs.onSurface, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddMoodPage(moodToEdit: log),
                            ),
                          );
                          if (result == true) _loadData();
                        },
                        icon: Icon(Icons.edit,
                            color: cs.primary, size: 18),
                        label: Text('Edit',
                            style: TextStyle(color: cs.primary)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: cs.primary),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(context, log);
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 18),
                        label: const Text('Delete',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
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
              Navigator.pop(context);
              if (log.id != null) {
                final messenger = ScaffoldMessenger.of(context);
                await DatabaseHelper().deleteMoodLog(log.id!);
                _loadData();
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
}
