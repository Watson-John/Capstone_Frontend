import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/routes/app_routes.dart';
import '../../expense_tracker/domain/models/budget.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();

  int _step = 0;
  BudgetPeriod _period = BudgetPeriod.monthly;

  Future<void> _saveNameAndNext() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      if (mounted) setState(() => _step = 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
    }
  }

  Future<void> _saveLimitAndProceed() async {
    final raw = _limitController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid spending limit')),
      );
      return;
    }
    final budget = Budget(
      limitAmount: amount,
      period: _period,
      createdAt: DateTime.now().toIso8601String(),
    );
    await DatabaseHelper().saveBudget(budget);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    }
  }

  Future<void> _skipLimit() async {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _step == 0 ? _buildNameStep(context) : _buildSpendingLimitStep(context),
        ),
      ),
    );
  }

  Widget _buildNameStep(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What should we call you by?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'What should we call you by?',
            hintText: 'Your Name',
          ),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: _saveNameAndNext,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingLimitStep(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set a Spending Limit',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'How much would you like to spend per period?',
          style: TextStyle(
            fontSize: 15,
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _limitController,
          decoration: const InputDecoration(
            labelText: 'Spending Limit',
            prefixText: '\$ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 20),
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
          selected: {_period},
          onSelectionChanged: (s) => setState(() => _period = s.first),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: _saveLimitAndProceed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _skipLimit,
          child: const Text(
            'Skip for now',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
