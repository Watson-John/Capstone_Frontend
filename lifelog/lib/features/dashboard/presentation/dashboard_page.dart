import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dashboard_prefs.dart';
import '../domain/models/dashboard_widget_type.dart';
import 'widgets/dashboard_budget_card.dart';
import 'widgets/dashboard_quick_stats_card.dart';
import 'widgets/dashboard_quote_card.dart';
import 'widgets/dashboard_streak_card.dart';
import 'widgets/dashboard_today_prompt_card.dart';
import 'widgets/dashboard_todo_stats_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final _prefs = DashboardPrefs();

  String _userName = '';
  bool _isEditMode = false;
  List<DashboardWidgetType> _activeWidgets = [];
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> refresh() async {
    await _loadConfig();
    setState(() => _refreshKey++);
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final order = await _prefs.loadOrder();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _activeWidgets = order;
    });
  }

  // ── Widget management ──────────────────────────────────────────────────────

  List<DashboardWidgetType> get _availableWidgets => DashboardWidgetType.values
      .where((t) => !_activeWidgets.contains(t))
      .toList();

  void _addWidget(DashboardWidgetType type) {
    if (_activeWidgets.length >= 5) return;
    setState(() => _activeWidgets.add(type));
    _prefs.saveOrder(_activeWidgets);
  }

  void _removeWidget(DashboardWidgetType type) {
    setState(() => _activeWidgets.remove(type));
    _prefs.saveOrder(_activeWidgets);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _activeWidgets.removeAt(oldIndex);
      _activeWidgets.insert(newIndex, item);
    });
    _prefs.saveOrder(_activeWidgets);
  }

  void _toggleEditMode() => setState(() => _isEditMode = !_isEditMode);

  // ── Card builder ───────────────────────────────────────────────────────────

  Widget _buildCard(DashboardWidgetType type) {
    return switch (type) {
      DashboardWidgetType.quickStats =>
        DashboardQuickStatsCard(key: ValueKey('quickStats-$_refreshKey')),
      DashboardWidgetType.quoteOfDay =>
        DashboardQuoteCard(key: ValueKey('quote-$_refreshKey')),
      DashboardWidgetType.todoStats =>
        DashboardTodoStatsCard(key: ValueKey('todo-$_refreshKey')),
      DashboardWidgetType.budgetOverview =>
        DashboardBudgetCard(key: ValueKey('budget-$_refreshKey')),
      DashboardWidgetType.gratitudeStreak =>
        DashboardStreakCard(key: ValueKey('streak-$_refreshKey')),
      DashboardWidgetType.gratitudePrompt =>
        DashboardTodayPromptCard(key: ValueKey('prompt-$_refreshKey')),
    };
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Sticky header (greeting / widget picker) ──────────────
            _DashboardHeader(
              userName: _userName,
              isEditMode: _isEditMode,
              availableWidgets: _availableWidgets,
              isFull: _activeWidgets.length >= 5,
              onWidgetAdd: _addWidget,
              onEditToggle: _toggleEditMode,
            ),

            // ── Scrollable dashboard content ──────────────────────────
            Expanded(
              child: _isEditMode ? _buildEditBody() : _buildViewBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        for (final type in _activeWidgets) ...[
          _buildCard(type),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildEditBody() {
    if (_activeWidgets.isEmpty) {
      return _EmptyDashboardHint(
        availableWidgets: _availableWidgets,
        onAddWidget: _addWidget,
      );
    }

    return ReorderableListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) => Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(24),
        shadowColor: Colors.black26,
        child: child,
      ),
      children: [
        for (final type in _activeWidgets)
          _EditableCardWrapper(
            key: ValueKey(type),
            onDelete: () => _removeWidget(type),
            child: _buildCard(type),
          ),
      ],
    );
  }
}

// ── Dashboard header ──────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.userName,
    required this.isEditMode,
    required this.availableWidgets,
    required this.isFull,
    required this.onWidgetAdd,
    required this.onEditToggle,
  });

  final String userName;
  final bool isEditMode;
  final List<DashboardWidgetType> availableWidgets;
  final bool isFull;
  final void Function(DashboardWidgetType) onWidgetAdd;
  final VoidCallback onEditToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState:
          isEditMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: _buildGreeting(context),
      secondChild: _buildPicker(context),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEditToggle,
            tooltip: 'Customise dashboard',
            icon: Icon(
              Icons.edit_outlined,
              color: cs.onSurfaceVariant,
              size: 22,
            ),
            style: IconButton.styleFrom(
              backgroundColor: cs.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  'Customise Dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onEditToggle,
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          if (availableWidgets.isEmpty && isFull)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Dashboard is full (max 5). Remove a card to add another.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            )
          else
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: availableWidgets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final type = availableWidgets[index];
                  return _WidgetChip(
                    type: type,
                    enabled: !isFull,
                    onTap: isFull ? null : () => onWidgetAdd(type),
                  );
                },
              ),
            ),
          Divider(height: 1, thickness: 1, color: cs.outlineVariant),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Long-press cards below to reorder',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Widget chip (in picker) ───────────────────────────────────────────────────

class _WidgetChip extends StatelessWidget {
  const _WidgetChip({
    required this.type,
    required this.enabled,
    required this.onTap,
  });

  final DashboardWidgetType type;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, size: 22, color: cs.primary),
              const SizedBox(height: 6),
              Text(
                type.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Editable card wrapper (edit mode overlay) ─────────────────────────────────

class _EditableCardWrapper extends StatelessWidget {
  const _EditableCardWrapper({
    super.key,
    required this.child,
    required this.onDelete,
  });

  final Widget child;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty dashboard hint ──────────────────────────────────────────────────────

class _EmptyDashboardHint extends StatelessWidget {
  const _EmptyDashboardHint({
    required this.availableWidgets,
    required this.onAddWidget,
  });

  final List<DashboardWidgetType> availableWidgets;
  final void Function(DashboardWidgetType) onAddWidget;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_outlined, size: 56, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'Your dashboard is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a widget above to add it.',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
