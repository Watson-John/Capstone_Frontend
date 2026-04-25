import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/widgets/app_page_header.dart';
import '../data/expense_service.dart';
import '../domain/models/budget.dart';
import '../domain/models/expense.dart';
import '../domain/models/receipt_line_item.dart';
import 'receipt_detail_page.dart';
import 'widgets/budget_dialog.dart';
import 'widgets/expense_fab_menu.dart';
import 'widgets/expense_filter_pills.dart';
import 'widgets/expense_summary_page_view.dart';
import 'widgets/expense_transactions_section.dart';
import 'widgets/scan_source_sheet.dart';
import 'widgets/scanning_overlay.dart';

// ── Page ──────────────────────────────────────────────────────────────────────

class ExpenseTrackerPage extends StatefulWidget {
  const ExpenseTrackerPage({super.key});

  @override
  State<ExpenseTrackerPage> createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage>
    with SingleTickerProviderStateMixin {
  final _service = ExpenseService();
  final _imagePicker = ImagePicker();

  List<Expense> _expenses = [];
  Budget? _budget;
  int _budgetThresholdPct = 20;
  bool _isScanning = false;
  bool _isLoading = true;
  double _scanProgress = 0.0;
  ReceiptScanStage _scanStage = ReceiptScanStage.uploading;
  Timer? _scanProgressTimer;

  FilterPeriod _selectedFilter = FilterPeriod.all;
  bool _showAll = false;
  List<ReceiptLineItem> _allLineItems = [];
  Map<int, Set<String>> _categoriesByExpenseId = {};

  static const Duration _scanProgressTick = Duration(milliseconds: 80);

  late AnimationController _scanAnim;

  // ── Computed ────────────────────────────────────────────────────────────────

  List<Expense> get _filteredExpenses {
    final now = DateTime.now();
    return _expenses.where((e) {
      final logged = DateTime.tryParse(e.createdAt);
      if (logged == null) return false;
      switch (_selectedFilter) {
        case FilterPeriod.all:
          return true;
        case FilterPeriod.daily:
          return logged.year == now.year &&
              logged.month == now.month &&
              logged.day == now.day;
        case FilterPeriod.weekly:
          final monday = now.subtract(Duration(days: now.weekday - 1));
          final weekStart =
              DateTime(monday.year, monday.month, monday.day);
          return !logged.isBefore(weekStart);
      }
    }).toList();
  }

  double get _filteredSpent =>
      _filteredExpenses.fold(0.0, (s, e) => s + e.amount);

  List<MapEntry<String, double>> get _categorySpending {
    final filteredIds = _filteredExpenses
        .map((e) => e.id)
        .whereType<int>()
        .toSet();
    // Build a lookup from expense id → expense category for fallback.
    final expenseCategoryById = <int, String>{
      for (final e in _filteredExpenses)
        if (e.id != null) e.id!: e.category,
    };
    final map = <String, double>{};
    final expensesWithLineItems = <int>{};
    for (final item in _allLineItems) {
      if (item.expenseId != null && filteredIds.contains(item.expenseId)) {
        expensesWithLineItems.add(item.expenseId!);
        // Use expense's own category when line item is UNCATEGORIZED.
        final cat = item.category == 'UNCATEGORIZED'
            ? (expenseCategoryById[item.expenseId!] ?? item.category)
            : item.category;
        map[cat] = (map[cat] ?? 0.0) + item.price;
      }
    }
    for (final expense in _filteredExpenses) {
      if (expense.id != null && !expensesWithLineItems.contains(expense.id)) {
        map[expense.category] =
            (map[expense.category] ?? 0.0) + expense.amount;
      }
    }
    return map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _loadAll();
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _scanProgressTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final db = DatabaseHelper();
    final prefs = await SharedPreferences.getInstance();
    final results = await Future.wait([db.getExpenses(), db.getBudget()]);
    if (!mounted) return;
    final expenses = results[0] as List<Expense>;
    final budget = results[1] as Budget?;
    final expenseIds = expenses.map((e) => e.id).whereType<int>().toList();
    final lineItems = await db.getLineItemsForExpenses(expenseIds);
    if (!mounted) return;
    final catMap = <int, Set<String>>{};
    for (final item in lineItems) {
      if (item.expenseId != null) {
        catMap.putIfAbsent(item.expenseId!, () => {}).add(item.category);
      }
    }
    final thresholdPct = prefs.getInt(kBudgetThresholdKey) ?? 20;
    setState(() {
      _expenses = expenses;
      _budget = budget;
      _allLineItems = lineItems;
      _categoriesByExpenseId = catMap;
      _budgetThresholdPct = thresholdPct;
      _isLoading = false;
    });
    _checkBudgetThreshold();
  }

  Future<void> _checkBudgetThreshold() async {
    try {
      final budget = _budget;
      if (budget == null || budget.limitAmount <= 0) return;
      final now = DateTime.now();
      final periodStart = budget.currentPeriodStart(now);
      final periodSpent = _expenses.where((e) {
        final d = DateTime.tryParse(e.createdAt);
        return d != null && !d.isBefore(periodStart);
      }).fold(0.0, (s, e) => s + e.amount);
      final remaining = budget.limitAmount - periodSpent;
      final remainingPct = (remaining / budget.limitAmount * 100).round();
      debugPrint(
          'budgetCheck: remainingPct=$remainingPct threshold=$_budgetThresholdPct');
      if (remainingPct > _budgetThresholdPct) {
        await LocalNotificationService.instance.resetBudgetAboveThreshold();
        return;
      }
      await LocalNotificationService.instance.showBudgetThresholdNotification(
        spent: periodSpent,
        limitAmount: budget.limitAmount,
      );
    } catch (e) {
      debugPrint('budgetCheck: error — $e');
    }
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

      final now = DateTime.now();
      final expense = Expense(
        amount: result.amount ?? 0.0,
        date: result.date ?? now.toIso8601String().substring(0, 10),
        vendor: result.vendor ?? 'Unknown Vendor',
        category: result.veryfiCategory ?? 'OTHER',
        veryfiDocumentId: result.veryfiDocumentId,
        createdAt: now.toIso8601String(),
      );

      final saved = await _service.saveExpenseWithLineItems(
        expense: expense,
        rawLineItems: result.lineItems,
      );

      if (!mounted) return;
      _loadAll();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptDetailPage(expense: saved),
        ),
      );
      if (mounted) _loadAll();
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
    if (_scanProgress < minimum) _setScanProgress(minimum);
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

  // ── FAB callbacks ───────────────────────────────────────────────────────

  Future<void> _onAddManualTap() async {
    final saved = await Navigator.of(context)
        .pushNamed(AppRoutes.addExpense, arguments: null);
    if (saved == true) _loadAll();
  }

  void _onScanTap() {
    showScanSourceSheet(context, onSourceSelected: (source) async {
      final image = await _pickAndCompress(source);
      if (image != null && mounted) {
        await _onImageCaptured(image);
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cats = _categorySpending;
    final catTotal = cats.fold(0.0, (s, e) => s + e.value);

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: ExpenseFabMenu(
          isScanning: _isScanning,
          onAddManual: _onAddManualTap,
          onScanReceipt: _onScanTap,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
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
                        ExpenseFilterPills(
                          selectedFilter: _selectedFilter,
                          onFilterChanged: (f) => setState(() {
                            _selectedFilter = f;
                            _showAll = false;
                          }),
                        ),
                        const SizedBox(height: 16),
                        ExpenseSummaryPageView(
                          budgetAmount: _budget?.limitAmount ?? 0.0,
                          spent: _filteredSpent,
                          categorySpending: cats,
                          categoryTotal: catTotal,
                          alertThresholdPct: _budgetThresholdPct,
                          onEditBudget: () async {
                            final saved = await showBudgetDialog(context, existing: _budget);
                            if (saved == true && mounted) _loadAll();
                          },
                        ),
                        const SizedBox(height: 20),
                        ExpenseTransactionsSection(
                          expenses: _filteredExpenses,
                          showAll: _showAll,
                          onToggleShowAll: () =>
                              setState(() => _showAll = !_showAll),
                          onDelete: _deleteExpense,
                          onTap: (expense) async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReceiptDetailPage(expense: expense),
                              ),
                            );
                            if (mounted) _loadAll();
                          },
                          categoriesByExpenseId: _categoriesByExpenseId,
                        ),
                        const SizedBox(height: 96),
                      ],
                    ),
                  ),
                ),
          if (_isScanning)
            ScanningOverlay(
              progress: _scanProgress,
              scanStage: _scanStage,
              scanAnimation: _scanAnim,
            ),
        ],
      ),
    );
  }
}
