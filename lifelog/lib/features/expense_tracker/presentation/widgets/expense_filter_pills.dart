import 'package:flutter/material.dart';

enum FilterPeriod { all, daily, weekly }

class ExpenseFilterPills extends StatelessWidget {
  const ExpenseFilterPills({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final FilterPeriod selectedFilter;
  final ValueChanged<FilterPeriod> onFilterChanged;

  static const _buttonStyle = ButtonStyle(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: WidgetStatePropertyAll(Size(0, 40)),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24)),
    shape: WidgetStatePropertyAll(StadiumBorder()),
    textStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    ),
  );

  Widget _filterBtn(FilterPeriod period, String label) {
    final isSelected = selectedFilter == period;
    void onPressed() => onFilterChanged(period);
    return isSelected
        ? FilledButton(onPressed: onPressed, style: _buttonStyle, child: Text(label))
        : OutlinedButton(onPressed: onPressed, style: _buttonStyle, child: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _filterBtn(FilterPeriod.all, 'All'),
        const SizedBox(width: 4),
        _filterBtn(FilterPeriod.daily, 'Daily'),
        const SizedBox(width: 4),
        _filterBtn(FilterPeriod.weekly, 'Weekly'),
      ],
    );
  }
}
