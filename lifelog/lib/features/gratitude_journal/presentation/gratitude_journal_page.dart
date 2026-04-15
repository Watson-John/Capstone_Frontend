import 'package:flutter/material.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/notif_test_button.dart';
import '../../mood_logger/presentation/widgets/mood_card_shell.dart';
import '../../mood_logger/presentation/widgets/mood_filter_pills.dart';
import '../data/gratitude_prompt_service.dart';
import '../domain/models/gratitude_entry.dart';
import 'add_gratitude_page.dart';
import 'widgets/gratitude_entry_card.dart';
import 'widgets/streak_card.dart';
import 'widgets/today_prompt_card.dart';
import 'widgets/weekly_activity_chart.dart';

class GratitudeJournalPage extends StatefulWidget {
  const GratitudeJournalPage({super.key});

  @override
  State<GratitudeJournalPage> createState() => _GratitudeJournalPageState();
}

class _GratitudeJournalPageState extends State<GratitudeJournalPage> {
  List<GratitudeEntry> _entries = [];
  bool _isLoading = true;

  String _todayPrompt = '';
  bool _hasEntryToday = false;

  MoodFilterPeriod _filter = MoodFilterPeriod.monthly;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchPrompt();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final entries = await DatabaseHelper().getGratitudeEntries();
    if (!mounted) return;
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final hasToday = entries.any((e) {
      final dt = DateTime.parse(e.dateTime);
      return '${dt.year}-${dt.month}-${dt.day}' == todayKey;
    });
    setState(() {
      _entries = entries;
      _hasEntryToday = hasToday;
      _isLoading = false;
    });
  }

  Future<void> _fetchPrompt() async {
    final prompt = await GratitudePromptService().fetchPrompt(DateTime.now());
    if (mounted) setState(() => _todayPrompt = prompt);
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<GratitudeEntry> get _filteredEntries {
    final now = DateTime.now();
    List<GratitudeEntry> result = _entries.where((e) {
      final dt = DateTime.parse(e.dateTime);
      switch (_filter) {
        case MoodFilterPeriod.weekly:
          final monday = now.subtract(Duration(days: now.weekday - 1));
          final weekStart = DateTime(monday.year, monday.month, monday.day);
          return !dt.isBefore(weekStart);
        case MoodFilterPeriod.monthly:
          return dt.year == now.year && dt.month == now.month;
        case MoodFilterPeriod.yearly:
          return dt.year == now.year;
      }
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) {
        return e.body.toLowerCase().contains(q) ||
            (e.tags ?? '').toLowerCase().contains(q) ||
            (e.prompt ?? '').toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  Future<void> _openAddPage({GratitudeEntry? entry}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddGratitudePage(
          entryToEdit: entry,
          prompt: entry == null ? _todayPrompt : (entry.prompt ?? ''),
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _deleteEntry(GratitudeEntry entry) async {
    if (entry.id != null) {
      await DatabaseHelper().deleteGratitudeEntry(entry.id!);
    }
    _loadData();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filtered = _filteredEntries;

    // Entries this week for the activity chart (always the current week)
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEntries = _entries
        .where((e) => !DateTime.parse(e.dateTime).isBefore(weekStart))
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: AppFab(
          heroTag: 'gratitude_fab',
          onPressed: () => _openAddPage(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: AppPageHeader(title: 'Gratitude Journal')),
                  NotifTestButton(onPressed: () async {
                    await LocalNotificationService.instance
                        .showTestNotification('gratitude', prompt: _todayPrompt);
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // ── Today Prompt Card ──────────────────────────────────────
              TodayPromptCard(
                prompt: _todayPrompt,
                hasEntryToday: _hasEntryToday,
                onWriteTap: () => _openAddPage(),
              ),

              const SizedBox(height: 16),

              // ── Streak / Stats ─────────────────────────────────────────
              StreakCard(entries: _entries),

              const SizedBox(height: 16),

              // ── Weekly Activity Chart ──────────────────────────────────
              MoodCardShell(
                title: 'This Week',
                child: weekEntries.isEmpty && _entries.isEmpty
                    ? _EmptyChartHint(cs: cs)
                    : WeeklyActivityChart(entries: weekEntries),
              ),

              const SizedBox(height: 20),

              // ── Search ─────────────────────────────────────────────────
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search past entries…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: cs.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Filter Pills ───────────────────────────────────────────
              MoodFilterPills(
                selectedFilter: _filter,
                onFilterChanged: (p) => setState(() => _filter = p),
              ),

              const SizedBox(height: 16),

              // ── Entry List ─────────────────────────────────────────────
              if (filtered.isEmpty)
                _EmptyState(
                  searchQuery: _searchQuery,
                  cs: cs,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final entry = filtered[i];
                    return GratitudeEntryCard(
                      entry: entry,
                      onTap: () => _openAddPage(entry: entry),
                      onDelete: () => _deleteEntry(entry),
                    );
                  },
                ),

              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searchQuery, required this.cs});
  final String searchQuery;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            searchQuery.isNotEmpty ? Icons.search_rounded : Icons.eco_outlined,
            size: 48,
            color: cs.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            searchQuery.isNotEmpty
                ? 'No entries match "$searchQuery"'
                : 'No entries yet',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            searchQuery.isNotEmpty
                ? 'Try a different keyword.'
                : 'Tap + to write your first gratitude entry.',
            style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Empty chart hint ──────────────────────────────────────────────────────────

class _EmptyChartHint extends StatelessWidget {
  const _EmptyChartHint({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Start writing entries to see your weekly activity.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
