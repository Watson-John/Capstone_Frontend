enum BudgetPeriod { monthly, biweekly }

class Budget {
  const Budget({
    this.id,
    required this.limitAmount,
    required this.period,
    required this.createdAt,
  });

  final int? id;
  final double limitAmount;
  final BudgetPeriod period;
  final String createdAt;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'limit_amount': limitAmount,
        'period': period.name,
        'created_at': createdAt,
      };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'] as int?,
        limitAmount: (map['limit_amount'] as num).toDouble(),
        period: BudgetPeriod.values.firstWhere((e) => e.name == map['period']),
        createdAt: map['created_at'] as String,
      );

  /// Returns the start of the current budget period relative to [now].
  DateTime currentPeriodStart(DateTime now) {
    if (period == BudgetPeriod.monthly) {
      return DateTime(now.year, now.month, 1);
    }
    return now.day <= 15
        ? DateTime(now.year, now.month, 1)
        : DateTime(now.year, now.month, 16);
  }

  String periodLabel(DateTime now) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (period == BudgetPeriod.monthly) {
      return '${months[now.month - 1]} ${now.year}';
    }
    if (now.day <= 15) {
      return '${months[now.month - 1]} 1\u201315';
    }
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return '${months[now.month - 1]} 16\u2013$lastDay';
  }
}
