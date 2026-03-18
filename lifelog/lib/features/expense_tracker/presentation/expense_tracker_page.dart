import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/expressive_squiggle_progress_bar.dart';
import '../../../core/widgets/app_page_header.dart';
import '../data/expense_service.dart';
import '../domain/models/budget.dart';
import '../domain/models/expense.dart';
import 'receipt_detail_page.dart';

// ── Stub receipt (always-visible demo entry) ──────────────────────────────────

const _kStubExpense = Expense(
  id: null,
  amount: 147.83,
  date: 'March 14, 2026',
  vendor: 'Walmart',
  category: 'GROCERY',
  veryfiDocumentId: 'stub-walmart-demo',
  createdAt: '2026-03-14T00:00:00.000',
);

// ── Filter period ─────────────────────────────────────────────────────────────

enum _FilterPeriod { all, daily, weekly }

// ── Page ──────────────────────────────────────────────────────────────────────

class ExpenseTrackerPage extends StatefulWidget {
  const ExpenseTrackerPage({super.key});

  @override
  State<ExpenseTrackerPage> createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage>
    with TickerProviderStateMixin {
  final _service = ExpenseService();
  final _imagePicker = ImagePicker();

  List<Expense> _expenses = [];
  Budget? _budget;
  bool _isScanning = false;
  bool _isLoading = true;
  bool _isFabMenuOpen = false;
  double _scanProgress = 0.0;
  ReceiptScanStage _scanStage = ReceiptScanStage.uploading;
  Timer? _scanProgressTimer;

  _FilterPeriod _selectedFilter = _FilterPeriod.all;
  bool _showAll = false;

  static const double _fabMenuGap = 12;
  static const Duration _fabAnimDuration = Duration(milliseconds: 420);
  static const Duration _scanProgressTick = Duration(milliseconds: 80);

  late AnimationController _fabAnim;
  late AnimationController _scanAnim;
  // Add Manually appears first (bottom item), Scan Receipt appears second (top item)
  late CurvedAnimation _fabAnimAdd;
  late CurvedAnimation _fabAnimScan;

  // ── Computed ────────────────────────────────────────────────────────────────

  List<Expense> get _filteredExpenses {
    final now = DateTime.now();
    return _expenses.where((e) {
      final logged = DateTime.tryParse(e.createdAt);
      if (logged == null) return false;
      switch (_selectedFilter) {
        case _FilterPeriod.all:
          return true;
        case _FilterPeriod.daily:
          return logged.year == now.year &&
              logged.month == now.month &&
              logged.day == now.day;
        case _FilterPeriod.weekly:
          final monday = now.subtract(Duration(days: now.weekday - 1));
          final weekStart =
              DateTime(monday.year, monday.month, monday.day);
          return !logged.isBefore(weekStart);
      }
    }).toList();
  }

  double get _filteredSpent =>
      _filteredExpenses.fold(0.0, (s, e) => s + e.amount);

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(vsync: this, duration: _fabAnimDuration);
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    // Bottom action (Add Manually) leads the entrance; top action (Scan) follows.
    _fabAnimAdd = CurvedAnimation(
      parent: _fabAnim,
      curve: const Interval(0.0, 0.82, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeInCubic,
    );
    _fabAnimScan = CurvedAnimation(
      parent: _fabAnim,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeInCubic,
    );
    _loadAll();
  }

  @override
  void dispose() {
    _fabAnimAdd.dispose();
    _fabAnimScan.dispose();
    _fabAnim.dispose();
    _scanAnim.dispose();
    _scanProgressTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final db = DatabaseHelper();
    final results = await Future.wait([db.getExpenses(), db.getBudget()]);
    if (!mounted) return;
    final expenses = results[0] as List<Expense>;
    final budget = results[1] as Budget?;
    setState(() {
      _expenses = expenses;
      _budget = budget;
      _isLoading = false;
    });
  }

  // ── Image picking / scanning ─────────────────────────────────────────────

  Future<XFile?> _pickAndCompress(ImageSource source) async {
    XFile? image = await _imagePicker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (image == null) return null;
    const maxBytes = 20 * 1024 * 1024;
    const minBytes = 250;
    int size = await File(image.path).length();
    if (size > maxBytes) {
      final recompressed = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 60,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (recompressed != null) {
        image = recompressed;
        size = await File(image.path).length();
      }
    }
    if (!mounted) return null;
    if (size < minBytes) {
      _showSnack('Image is too small to process.');
      return null;
    }
    if (size > maxBytes) {
      _showSnack('Image is too large. Try a smaller photo.');
      return null;
    }
    return image;
  }

  Future<void> _onImageCaptured(XFile image) async {
    setState(() {
      _isScanning = true;
      _scanStage = ReceiptScanStage.uploading;
      _scanProgress = 0.0;
    });
    _startScanProgressTicker();
    try {
      final result = await _service.scanReceipt(
        File(image.path),
        onStageChanged: _handleScanStageChanged,
        onReceiveProgress: _handleScanReceiveProgress,
      );
      _setScanProgress(1.0);
      if (!mounted) return;
      final saved = await Navigator.of(context).pushNamed(
        AppRoutes.addExpense,
        arguments: result,
      );
      if (saved == true) _loadAll();
    } on ExpenseScanException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
      debugPrint('[ExpenseTrackerPage] scan error: $e');
    } finally {
      if (mounted) {
        _scanProgressTimer?.cancel();
        setState(() {
          _isScanning = false;
          _scanProgress = 0.0;
          _scanStage = ReceiptScanStage.uploading;
        });
      }
    }
  }

  void _startScanProgressTicker() {
    _scanProgressTimer?.cancel();
    _scanProgressTimer = Timer.periodic(_scanProgressTick, (_) {
      if (!mounted || !_isScanning) return;
      final target = _targetProgressForStage(_scanStage);
      if (_scanProgress >= target) return;

      // Ease toward the active stage target so progress feels alive, not jumpy.
      final remaining = target - _scanProgress;
      final next = (_scanProgress + math.max(0.003, remaining * 0.14))
          .clamp(0.0, 1.0);
      _setScanProgress(next);
    });
  }

  void _handleScanStageChanged(ReceiptScanStage stage) {
    if (!mounted) return;
    setState(() => _scanStage = stage);

    final minimum = stage == ReceiptScanStage.uploading
        ? 0.02
        : stage == ReceiptScanStage.processing
            ? 0.35
            : 0.68;
    if (_scanProgress < minimum) {
      _setScanProgress(minimum);
    }
  }

  void _handleScanReceiveProgress(double value) {
    final clamped = value.clamp(0.0, 1.0);
    final mapped = (0.66 + (clamped * 0.34)).clamp(0.66, 1.0);
    _setScanProgress(mapped);
  }

  void _setScanProgress(double value) {
    if (!mounted) return;
    final next = value.clamp(0.0, 1.0);
    if ((next - _scanProgress).abs() < 0.001) return;
    setState(() => _scanProgress = next);
  }

  double _targetProgressForStage(ReceiptScanStage stage) {
    switch (stage) {
      case ReceiptScanStage.uploading:
        return 0.33;
      case ReceiptScanStage.processing:
        return 0.66;
      case ReceiptScanStage.receiving:
        return 0.96;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scan Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    if (expense.id == null) return;
    await DatabaseHelper().deleteExpense(expense.id!);
    _loadAll();
  }

  Future<void> _showBudgetDialog([Budget? existing]) async {
    final amountController = TextEditingController(
      text: existing != null ? existing.limitAmount.toStringAsFixed(2) : '',
    );
    var period = existing?.period ?? BudgetPeriod.monthly;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Set Spending Budget' : 'Edit Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Spending Limit',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              SegmentedButton<BudgetPeriod>(
                segments: const [
                  ButtonSegment(
                    value: BudgetPeriod.monthly,
                    label: Text('Monthly'),
                    icon: Icon(Icons.calendar_month_outlined),
                  ),
                  ButtonSegment(
                    value: BudgetPeriod.biweekly,
                    label: Text('Bi-weekly'),
                    icon: Icon(Icons.date_range_outlined),
                  ),
                ],
                selected: {period},
                onSelectionChanged: (s) =>
                    setDialogState(() => period = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final raw = amountController.text.replaceAll(',', '').trim();
                final amount = double.tryParse(raw);
                if (amount == null || amount <= 0) return;
                final newBudget = Budget(
                  id: existing?.id,
                  limitAmount: amount,
                  period: period,
                  createdAt: DateTime.now().toIso8601String(),
                );
                await DatabaseHelper().saveBudget(newBudget);
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) _loadAll();
  }

  // ── FAB actions (spring menu) ───────────────────────────────────────────

  void _toggleFabMenu() {
    if (_isScanning) return;
    setState(() => _isFabMenuOpen = !_isFabMenuOpen);
    if (_isFabMenuOpen) {
      _fabAnim.forward();
    } else {
      _fabAnim.reverse();
    }
  }

  Future<void> _onAddManualTap() async {
    _fabAnim.reverse();
    setState(() => _isFabMenuOpen = false);
    final saved = await Navigator.of(context)
        .pushNamed(AppRoutes.addExpense, arguments: null);
    if (saved == true) _loadAll();
  }

  void _onScanTap() {
    _fabAnim.reverse();
    setState(() => _isFabMenuOpen = false);
    _showScanSourceSheet();
  }

  /// Builds a single FAB action item driven by [animation].
  /// Scale originates from the right edge so items feel anchored to the main FAB.
  Widget _buildFabAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Animation<double> animation,
    required String heroTag,
  }) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animation,
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onTap,
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        shape: const StadiumBorder(),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
        extendedIconLabelSpacing: 10,
        icon: Icon(icon),
        label: Text(label),
      ),
      builder: (context, child) {
        // Clamp for opacity/pointer but allow raw value for translate so the
        // easeOutBack overshoot (values slightly > 1) creates the spring pop.
        final t = animation.value.clamp(0.0, 1.0);
        return IgnorePointer(
          ignoring: t < 0.5,
          child: Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - animation.value) * 16),
              child: Transform.scale(
                scale: 0.75 + (0.25 * t),
                alignment: Alignment.centerRight,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFabMenu() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildFabAction(
          label: 'Scan Receipt',
          icon: Icons.document_scanner_outlined,
          onTap: _onScanTap,
          animation: _fabAnimScan,
          heroTag: 'expense-fab-action-scan',
        ),
        const SizedBox(height: _fabMenuGap),
        _buildFabAction(
          label: 'Add Manually',
          icon: Icons.edit_outlined,
          onTap: _onAddManualTap,
          animation: _fabAnimAdd,
          heroTag: 'expense-fab-action-add',
        ),
        const SizedBox(height: _fabMenuGap),
        SizedBox(
          width: 78,
          height: 78,
          child: AnimatedBuilder(
            animation: _fabAnim,
            builder: (context, _) {
              final t = _fabAnim.value;
              final easedT = Curves.easeOutCubic.transform(t);
              final shape = ShapeBorder.lerp(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                const CircleBorder(),
                easedT,
              );
              return FloatingActionButton(
                heroTag: 'expense-fab-main',
                onPressed: _isScanning ? null : _toggleFabMenu,
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: shape,
                elevation: 6 - (2 * t),
                tooltip: _isFabMenuOpen ? 'Close actions' : 'Add expense',
                child: Transform.rotate(
                  angle: (math.pi / 4) * t,
                  child: const Icon(Icons.add, size: 30),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showScanSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(sheetCtx).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _AddOptionTile(
                  icon: Icons.photo_camera_outlined,
                  iconColor: Theme.of(sheetCtx).colorScheme.secondary,
                  title: 'Take Photo',
                  subtitle: 'Use camera',
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    final image =
                        await _pickAndCompress(ImageSource.camera);
                    if (image != null && mounted) {
                      await _onImageCaptured(image);
                    }
                  },
                ),
                const Divider(height: 1),
                _AddOptionTile(
                  icon: Icons.photo_library_outlined,
                  iconColor: Theme.of(sheetCtx).colorScheme.secondary,
                  title: 'Choose From Device',
                  subtitle: 'Pick from gallery',
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    final image =
                        await _pickAndCompress(ImageSource.gallery);
                    if (image != null && mounted) {
                      await _onImageCaptured(image);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildFabMenu(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          // Main scrollable content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const AppPageHeader(title: 'Expenses'),
                        const SizedBox(height: 16),
                        _buildFilterPills(),
                        const SizedBox(height: 16),
                        _buildSummaryCard(context),
                        const SizedBox(height: 20),
                        _buildTransactionsSection(context),
                        const SizedBox(height: 96),
                      ],
                    ),
                  ),
                ),

          // Scanning overlay (covers body only; FAB is naturally above)
          if (_isScanning) _buildScanningOverlay(context),
        ],
      ),
    );
  }

  // ── Scanning overlay ─────────────────────────────────────────────────────

  Widget _buildScanningOverlay(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const steps = ['Scanning receipt', 'Analyzing image', 'Extracting data'];
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        color: cs.scrim.withValues(alpha: 0.45),
        child: Center(
          child: AnimatedBuilder(
            animation: _scanAnim,
            builder: (context, _) {
              final progress = _scanProgress;
              final stepIndex = _scanStage == ReceiptScanStage.uploading
                  ? 0
                  : _scanStage == ReceiptScanStage.processing
                      ? 1
                      : 2;
              // Dots still cycle via the looping _scanAnim.
              final dotCount = (_scanAnim.value * 3).floor() % 4;
              final dots = '.' * dotCount;
              final pulse = 0.92 + 0.08 * math.sin(_scanAnim.value * 2 * math.pi);
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                color: cs.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: pulse,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.document_scanner_rounded,
                            size: 36,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 220,
                        child: ExpressiveSquiggleProgressBar(
                          value: progress,
                          color: cs.primary,
                          trackColor: cs.primaryContainer,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${steps[stepIndex]}$dots',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Filter pills ─────────────────────────────────────────────────────────

  static const _buttonStyle = ButtonStyle(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: WidgetStatePropertyAll(Size(0, 40)),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24)),
    shape: WidgetStatePropertyAll(StadiumBorder()),
    textStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    ),
  );

  Widget _buildFilterPills() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _filterBtn(_FilterPeriod.all,    'All'),
        const SizedBox(width: 4),
        _filterBtn(_FilterPeriod.daily,  'Daily'),
        const SizedBox(width: 4),
        _filterBtn(_FilterPeriod.weekly, 'Weekly'),
      ],
    );
  }

  Widget _filterBtn(_FilterPeriod period, String label) {
    final isSelected = _selectedFilter == period;
    void onPressed() => setState(() {
      _selectedFilter = period;
      _showAll = false;
    });
    return isSelected
        ? FilledButton(onPressed: onPressed, style: _buttonStyle, child: Text(label))
        : OutlinedButton(onPressed: onPressed, style: _buttonStyle, child: Text(label));
  }

  // ── Summary card ─────────────────────────────────────────────────────────

  Widget _buildSummaryCard(BuildContext context) {
    final budgetAmount = _budget?.limitAmount ?? 0.0;
    final spent = _filteredSpent;

    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Budget + Spent
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryItem(
                  label: 'Budget',
                  amount: budgetAmount,
                  dotColor: AppTheme.accentGreen,
                  onEditTap: () => _showBudgetDialog(_budget),
                ),
                const SizedBox(height: 20),
                _SummaryItem(
                  label: 'Spent',
                  amount: spent,
                  dotColor: AppTheme.accentRed,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right: Donut chart
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _DonutPainter(
                spent: spent,
                total: budgetAmount,
                spentColor: AppTheme.accentRed,
                remainColor: AppTheme.accentGreen,
                trackColor: cs.outlineVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Transactions section ─────────────────────────────────────────────────

  Widget _buildTransactionsSection(BuildContext context) {
    final all = _filteredExpenses;
    final visible = _showAll ? all : all.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (all.length > 5)
              GestureDetector(
                onTap: () => setState(() => _showAll = !_showAll),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Text(
                    _showAll ? 'Show Less' : 'See All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Demo stub entry — always shown so the detail page can be tested
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 6),
                child: Text(
                  'Demo receipt',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              _TransactionRow(
                expense: _kStubExpense,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ReceiptDetailPage(expense: _kStubExpense),
                  ),
                ),
              ),
            ],
          ),
        ),

        // List or empty state
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 52, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'No transactions',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add one',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ...visible.map(
            (expense) => Dismissible(
              key: ValueKey(expense.id ?? expense.createdAt),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.delete_outline, color: Colors.red.shade600),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete transaction?'),
                    content: Text(
                        'Remove "${expense.vendor}" from your expenses?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) => _deleteExpense(expense),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TransactionRow(
                  expense: expense,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiptDetailPage(expense: expense),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Summary item ──────────────────────────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.dotColor,
    this.onEditTap,
  });

  final String label;
  final double amount;
  final Color dotColor;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onEditTap != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onEditTap,
                child: Icon(Icons.edit_outlined,
                    size: 14, color: cs.outline),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Donut chart painter ───────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.spent,
    required this.total,
    required this.spentColor,
    required this.remainColor,
    required this.trackColor,
  });

  final double spent;
  final double total;
  final Color spentColor;
  final Color remainColor;
  final Color trackColor;

  static const _strokeWidth = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - _strokeWidth / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    if (total <= 0) {
      canvas.drawArc(
          rect, -math.pi / 2, 2 * math.pi, false, paint..color = trackColor);
      return;
    }

    final ratio = (spent / total).clamp(0.0, 1.0);
    final spentAngle = 2 * math.pi * ratio;
    final remainAngle = 2 * math.pi * (1 - ratio);

    // Track ring
    canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi, false, paint..color = trackColor);

    // Spent arc
    if (ratio > 0) {
      canvas.drawArc(
          rect, -math.pi / 2, spentAngle, false, paint..color = spentColor);
    }

    // Remaining arc
    if (ratio < 1) {
      canvas.drawArc(rect, -math.pi / 2 + spentAngle, remainAngle, false,
          paint..color = remainColor);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.spent != spent || old.total != total;
}

// ── Transaction row ───────────────────────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.expense, required this.onTap});

  final Expense expense;
  final VoidCallback onTap;

  static IconData _icon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'meals & entertainment':
        return Icons.restaurant_outlined;
      case 'salary':
      case 'income':
        return Icons.attach_money;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'shopping':
      case 'retail':
        return Icons.shopping_bag_outlined;
      case 'transport':
      case 'transportation':
        return Icons.directions_car_outlined;
      case 'utilities':
        return Icons.bolt_outlined;
      case 'health':
      case 'medical':
        return Icons.favorite_border;
      default:
        return Icons.receipt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = expense.category;
    final isScanned = expense.veryfiDocumentId != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Category badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.cardTotalBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Icon(_icon(cat), color: const Color(0xFF1C1C1C), size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Vendor + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.vendor,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expense.date,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount
                  Text(
                    '-\$${expense.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
            ),
            // Source badge — top-right corner
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isScanned
                      ? Icons.document_scanner_outlined
                      : Icons.edit_outlined,
                  size: 14,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add option tile ───────────────────────────────────────────────────────────

class _AddOptionTile extends StatelessWidget {
  const _AddOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: cs.outline),
          ],
        ),
      ),
    );
  }
}

