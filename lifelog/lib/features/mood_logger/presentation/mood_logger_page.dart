import 'package:flutter/material.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/app_page_header.dart';
import '../domain/models/mood_log.dart';
import '../domain/models/mood_tag_styles.dart';
import 'add_mood_page.dart';
import 'widgets/mood_calendar.dart';
import 'widgets/mood_card_shell.dart';
import 'widgets/mood_day_details_sheet.dart';
import 'widgets/mood_donut_chart.dart';
import 'widgets/mood_energy_gauge.dart';
import 'widgets/mood_filter_pills.dart';
import 'widgets/mood_radar_chart.dart';
import 'widgets/mood_trend_chart.dart';

class MoodLoggerPage extends StatefulWidget {
  const MoodLoggerPage({super.key});

  @override
  State<MoodLoggerPage> createState() => _MoodLoggerPageState();
}

class _MoodLoggerPageState extends State<MoodLoggerPage> {
  List<MoodLog> _moodLogs = [];
  bool _isLoading = true;

  // Calendar state
  late DateTime _viewMonth;
  late DateTime _selectedDate;

  // Filter state
  MoodFilterPeriod _selectedFilter = MoodFilterPeriod.monthly;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
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

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<MoodLog> get _filteredLogs {
    final now = DateTime.now();
    return _moodLogs.where((log) {
      final dt = DateTime.parse(log.dateTime);
      switch (_selectedFilter) {
        case MoodFilterPeriod.weekly:
          final monday = now.subtract(Duration(days: now.weekday - 1));
          final weekStart =
              DateTime(monday.year, monday.month, monday.day);
          return !dt.isBefore(weekStart);
        case MoodFilterPeriod.monthly:
          return dt.year == now.year && dt.month == now.month;
        case MoodFilterPeriod.yearly:
          return dt.year == now.year;
      }
    }).toList();
  }

  // ── Data aggregation ──────────────────────────────────────────────────────

  Map<String, int> _buildMoodCounts(List<MoodLog> logs) {
    final counts = <String, int>{};
    for (final log in logs) {
      counts[log.mood] = (counts[log.mood] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _buildEnergyCounts(List<MoodLog> logs) {
    final counts = <String, int>{};
    for (final log in logs) {
      if (log.energy != null) {
        counts[log.energy!] = (counts[log.energy!] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<String, int> _buildTagCounts(List<MoodLog> logs) {
    final counts = <String, int>{};
    for (final log in logs) {
      if (log.tags != null && log.tags!.isNotEmpty) {
        for (final tag in log.tags!.split(',')) {
          final t = tag.trim();
          if (t.isNotEmpty) {
            counts[t] = (counts[t] ?? 0) + 1;
          }
        }
      }
    }
    return counts;
  }

  List<TrendPoint> _buildTrendData(List<MoodLog> logs) {
    switch (_selectedFilter) {
      case MoodFilterPeriod.weekly:
        return _trendByDayOfWeek(logs);
      case MoodFilterPeriod.monthly:
        return _trendByWeekOfMonth(logs);
      case MoodFilterPeriod.yearly:
        return _trendByMonth(logs);
    }
  }

  List<TrendPoint> _trendByDayOfWeek(List<MoodLog> logs) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final buckets = List.generate(7, (_) => <int>[]);

    for (final log in logs) {
      final dt = DateTime.parse(log.dateTime);
      final dayIdx = dt.weekday - 1; // Monday = 0
      buckets[dayIdx].add(moodToValue(log.mood));
    }

    return List.generate(7, (i) {
      final vals = buckets[i];
      final avg =
          vals.isEmpty ? 0.0 : vals.reduce((a, b) => a + b) / vals.length;
      return TrendPoint(dayLabels[i], avg, vals.length);
    });
  }

  List<TrendPoint> _trendByWeekOfMonth(List<MoodLog> logs) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final weekCount = (daysInMonth / 7).ceil();
    final buckets = List.generate(weekCount, (_) => <int>[]);

    for (final log in logs) {
      final dt = DateTime.parse(log.dateTime);
      final weekIdx = ((dt.day - 1) / 7).floor();
      if (weekIdx < weekCount) {
        buckets[weekIdx].add(moodToValue(log.mood));
      }
    }

    return List.generate(weekCount, (i) {
      final vals = buckets[i];
      final avg =
          vals.isEmpty ? 0.0 : vals.reduce((a, b) => a + b) / vals.length;
      return TrendPoint('W${i + 1}', avg, vals.length);
    });
  }

  List<TrendPoint> _trendByMonth(List<MoodLog> logs) {
    const monthLabels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final buckets = List.generate(12, (_) => <int>[]);

    for (final log in logs) {
      final dt = DateTime.parse(log.dateTime);
      buckets[dt.month - 1].add(moodToValue(log.mood));
    }

    // Only return months that have data or are before/equal current month.
    final now = DateTime.now();
    final points = <TrendPoint>[];
    for (int i = 0; i <= now.month - 1; i++) {
      final vals = buckets[i];
      final avg =
          vals.isEmpty ? 0.0 : vals.reduce((a, b) => a + b) / vals.length;
      points.add(TrendPoint(monthLabels[i], avg, vals.length));
    }
    return points;
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cs.onSurfaceVariant,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filteredLogs;
    final moodCounts = _buildMoodCounts(filtered);
    final energyCounts = _buildEnergyCounts(filtered);
    final tagCounts = _buildTagCounts(filtered);
    final trendData = _buildTrendData(filtered);

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

                    // ── Emoji Calendar ────────────────────────────────────
                    MoodCardShell(
                      title: 'Mood Calendar',
                      child: MoodCalendar(
                        viewMonth: _viewMonth,
                        selectedDate: _selectedDate,
                        moodLogs: _moodLogs,
                        onPrevMonth: () {
                          setState(() {
                            _viewMonth = DateTime(
                                _viewMonth.year, _viewMonth.month - 1);
                          });
                        },
                        onNextMonth: () {
                          setState(() {
                            _viewMonth = DateTime(
                                _viewMonth.year, _viewMonth.month + 1);
                          });
                        },
                        onDayTap: (date, logs) {
                          setState(() => _selectedDate = date);
                          showMoodDayDetailsSheet(
                            context,
                            date: date,
                            logs: logs,
                            onReload: _loadData,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Analytics Card (filter + all charts) ─────────────
                    MoodCardShell(
                      title: 'Insights',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter pills
                          MoodFilterPills(
                            selectedFilter: _selectedFilter,
                            onFilterChanged: (f) =>
                                setState(() => _selectedFilter = f),
                          ),
                          const SizedBox(height: 20),

                          // Mood Over Time
                          _sectionLabel(context, 'Mood Over Time'),
                          const SizedBox(height: 8),
                          MoodTrendChart(points: trendData),
                          const SizedBox(height: 24),

                          // Mood Distribution
                          _sectionLabel(context, 'Mood Distribution'),
                          const SizedBox(height: 8),
                          MoodDonutChart(moodCounts: moodCounts),
                          const SizedBox(height: 24),

                          // Energy Levels
                          _sectionLabel(context, 'Energy Levels'),
                          const SizedBox(height: 8),
                          MoodEnergyGauge(energyCounts: energyCounts),
                          const SizedBox(height: 24),

                          // Top Tags
                          _sectionLabel(context, 'Top Tags'),
                          const SizedBox(height: 8),
                          MoodRadarChart(tagCounts: tagCounts),
                        ],
                      ),
                    ),

                    const SizedBox(height: 96),
                  ],
                ),
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: AppFab(heroTag: 'mood-fab', onPressed: _navigateToAddMood),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
