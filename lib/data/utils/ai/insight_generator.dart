import 'package:intl/intl.dart';

import '../../data/expense/expense.dart';
import '../../data/insight/insight.dart';
import '../statistics_helper.dart';

/// Produces the single most relevant "your money" insight for *now*, computed
/// entirely from [StatisticsHelper] — no AI model involved, so it works for
/// every user. Returns null when there's nothing worth saying. Pure and
/// deterministic (id is keyed to kind + day) so it's unit-testable and
/// dedupes to one insight per day.
class InsightGenerator {
  InsightGenerator._();

  static InsightData? generate({
    required List<ExpenseData> expenses,
    required DateTime now,
    required String currency,
  }) {
    if (expenses.isEmpty) return null;
    final fmt = NumberFormat('#,##0.##');
    String money(double v) => '$currency${fmt.format(v)}';
    final dayKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    InsightData make(InsightKind kind, String text,
            {List<InsightBar> bars = const [], String? category}) =>
        InsightData(
          id: '${kind.name}_$dayKey',
          createdAt: now.millisecondsSinceEpoch,
          kind: kind,
          text: text,
          bars: bars,
          category: category,
        );

    // 1. Yesterday recap — only once there's been activity.
    final yesterday = now.subtract(const Duration(days: 1));
    final yStats = StatisticsHelper(expenses, period: 'D', referenceDate: yesterday);
    if (yStats.totalSpending > 0) {
      final top = yStats.topCategory;
      final tail = top != null ? ", mostly #${top.key}" : "";
      return make(
        InsightKind.dailyRecap,
        "Yesterday you spent ${money(yStats.totalSpending)}$tail.",
        category: top?.key,
      );
    }

    // 2. Category milestone — this month already passed last month's total.
    final monthStats = StatisticsHelper(expenses, period: 'M', referenceDate: now);
    final lastMonth = DateTime(now.year, now.month - 1, 15);
    final lastMonthStats =
        StatisticsHelper(expenses, period: 'M', referenceDate: lastMonth);
    final lastByCat = {
      for (final c in lastMonthStats.categoryStats) c.category: c.totalAmount,
    };
    for (final c in monthStats.categoryStats) {
      final prev = lastByCat[c.category] ?? 0;
      if (prev > 0 && c.totalAmount > prev) {
        return make(
          InsightKind.categoryMilestone,
          "You've already spent more on #${c.category} this month "
          "(${money(c.totalAmount)}) than all of last month (${money(prev)}).",
          category: c.category,
        );
      }
    }

    // 3. Top category this week, with a mini chart.
    final weekStats = StatisticsHelper(expenses, period: 'W', referenceDate: now);
    final weekCats = weekStats.categoryStats;
    if (weekStats.totalSpending > 0 && weekCats.isNotEmpty) {
      final top = weekCats.first;
      final max = top.totalAmount;
      final bars = [
        for (final c in weekCats.take(3))
          InsightBar(c.category, max == 0 ? 0 : c.totalAmount / max),
      ];
      final pct = weekStats.totalSpending == 0
          ? 0
          : (top.totalAmount / weekStats.totalSpending * 100).round();
      return make(
        InsightKind.topCategoryWeek,
        "This week #${top.category} is your top category at "
        "${money(top.totalAmount)} ($pct% of spending).",
        bars: bars,
        category: top.category,
      );
    }

    // 4. Positive savings note for the month.
    if (monthStats.totalIncome > 0 && monthStats.savingsRate >= 20) {
      return make(
        InsightKind.savings,
        "You've saved ${monthStats.savingsRate.round()}% of your income "
        "this month — ${money(monthStats.totalSaved)} kept. Nice.",
      );
    }

    return null;
  }
}
