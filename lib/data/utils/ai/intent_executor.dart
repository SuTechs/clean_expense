import 'package:intl/intl.dart';

import '../../data/ai/ai_intent.dart';
import '../../data/ai/ai_message.dart';
import '../../data/expense/expense.dart';
import '../statistics_helper.dart';

class AiAnswer {
  final String text;
  final AiWidgetSpec? widget;

  const AiAnswer({required this.text, this.widget});
}

/// Executes an [AiIntent] against the user's transactions and composes the
/// answer text + gen-UI widget from templates. Every number shown to the
/// user comes from here — never from the model.
class IntentExecutor {
  final List<ExpenseData> expenses;
  final String currency;
  final DateTime now;

  IntentExecutor({
    required this.expenses,
    required this.currency,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  static final _amountFormat = NumberFormat('#,##0.##');

  String _money(double v) => '$currency${_amountFormat.format(v)}';

  AiAnswer execute(AiIntent intent) {
    final reference = _referenceDate(intent.period, intent.dateOffset);
    final filtered = intent.category == null
        ? expenses
        : expenses.where((e) => e.category == intent.category).toList();

    final stats = StatisticsHelper(
      filtered,
      period: intent.period,
      referenceDate: reference,
    );

    final when = _periodPhrase(intent.period, intent.dateOffset);
    final inCategory =
        intent.category == null ? '' : ' on #${intent.category}';

    switch (intent.metric) {
      case AiMetric.totalSpending:
        final total = stats.totalSpending;
        return AiAnswer(
          text: total == 0
              ? "You didn't spend anything$inCategory $when."
              : "You spent ${_money(total)}$inCategory $when"
                    "${stats.transactionCount > 1 ? " across ${stats.transactionCount} transactions" : ""}.",
          widget: AiWidgetSpec.statCard(
            title: 'Spending$inCategory',
            value: _money(total),
            subtitle: _titleCase(when),
          ),
        );

      case AiMetric.totalIncome:
        final total = stats.totalIncome;
        return AiAnswer(
          text: total == 0
              ? "No income recorded $when."
              : "You earned ${_money(total)} $when.",
          widget: AiWidgetSpec.statCard(
            title: 'Income',
            value: _money(total),
            subtitle: _titleCase(when),
          ),
        );

      case AiMetric.totalInvested:
        final total = stats.totalInvested;
        return AiAnswer(
          text: total == 0
              ? "No investments recorded $when."
              : "You invested ${_money(total)} $when.",
          widget: AiWidgetSpec.statCard(
            title: 'Invested',
            value: _money(total),
            subtitle: _titleCase(when),
          ),
        );

      case AiMetric.totalSaved:
        final saved = stats.totalSaved;
        return AiAnswer(
          text: saved >= 0
              ? "You saved ${_money(saved)} $when "
                    "(${_money(stats.totalIncome)} in, ${_money(stats.totalSpending)} out)."
              : "You spent ${_money(saved.abs())} more than you earned $when.",
          widget: AiWidgetSpec.statCard(
            title: 'Saved',
            value: _money(saved),
            subtitle:
                '${_money(stats.totalIncome)} in · ${_money(stats.totalSpending)} out',
          ),
        );

      case AiMetric.savingsRate:
        if (stats.totalIncome == 0) {
          return AiAnswer(
            text: "No income recorded $when, so I can't compute a "
                "savings rate.",
          );
        }
        final rate = stats.savingsRate;
        return AiAnswer(
          text:
              "Your savings rate $when is ${rate.toStringAsFixed(1)}%, you "
              "kept ${_money(stats.totalSaved)} of ${_money(stats.totalIncome)} earned.",
          widget: AiWidgetSpec.statCard(
            title: 'Savings rate',
            value: '${rate.toStringAsFixed(1)}%',
            subtitle: 'of ${_money(stats.totalIncome)} income',
          ),
        );

      case AiMetric.topCategory:
        final top = stats.topCategory;
        if (top == null) {
          return AiAnswer(text: "No spending recorded $when.");
        }
        // Guard the share: zero-amount transactions make topCategory
        // non-null while totalSpending is 0 (0/0 -> "NaN% of the total").
        final sharePart = stats.totalSpending > 0
            ? " (${(top.value / stats.totalSpending * 100).toStringAsFixed(0)}% of the total)"
            : "";
        return AiAnswer(
          text:
              "Your biggest spending category $when is #${top.key} at "
              "${_money(top.value)}$sharePart.",
          widget: _categoryPie(stats, intent.topN, when),
        );

      case AiMetric.categoryBreakdown:
        final cats = stats.categoryStats;
        if (cats.isEmpty) {
          return AiAnswer(text: "No spending recorded $when.");
        }
        final top3 = cats
            .take(3)
            .map((c) => '#${c.category} ${_money(c.totalAmount)}')
            .join(', ');
        return AiAnswer(
          text: "Here's where your money went $when: $top3"
              "${cats.length > 3 ? ' and more below.' : '.'}",
          widget: _categoryPie(stats, intent.topN, when),
        );

      case AiMetric.largestExpense:
        final largest = stats.largestSingleExpense;
        if (largest == null) {
          return AiAnswer(text: "No expenses recorded$inCategory $when.");
        }
        final note = largest.note.isEmpty ? '' : ' ("${largest.note}")';
        return AiAnswer(
          text:
              "Your largest expense$inCategory $when was ${_money(largest.amount)}"
              "$note in #${largest.category} on "
              "${DateFormat('MMM d').format(largest.date)}.",
          widget: AiWidgetSpec.statCard(
            title: 'Largest expense$inCategory',
            value: _money(largest.amount),
            subtitle:
                '#${largest.category} · ${DateFormat('MMM d').format(largest.date)}',
          ),
        );

      case AiMetric.averageDailySpend:
        final avg = stats.averageDailySpend;
        return AiAnswer(
          text: avg == 0
              ? "No spending recorded$inCategory $when."
              : "On days you spend, you average ${_money(avg)} per day"
                    "$inCategory $when.",
          widget: AiWidgetSpec.statCard(
            title: 'Average daily spend',
            value: _money(avg),
            subtitle: _titleCase(when),
          ),
        );

      case AiMetric.mostFrequentCategory:
        final cat = stats.mostFrequentCategory;
        if (cat == null) {
          return AiAnswer(text: "No transactions recorded $when.");
        }
        return AiAnswer(
          text: "Your most frequent category $when is #$cat.",
          widget: AiWidgetSpec.statCard(
            title: 'Most frequent category',
            value: '#$cat',
            subtitle: _titleCase(when),
          ),
        );

      case AiMetric.spendingTrend:
        final data = stats.getGraphData();
        if (data.every((v) => v == 0)) {
          return AiAnswer(text: "No spending recorded$inCategory $when.");
        }
        return AiAnswer(
          text:
              "Here's your spending trend$inCategory $when: "
              "${_money(stats.totalSpending)} total.",
          widget: AiWidgetSpec.line(
            title: 'Spending trend · ${_titleCase(when)}',
            labels: _trendLabels(intent.period, reference, data.length),
            values: data,
          ),
        );

      case AiMetric.dayOfWeek:
        if (stats.totalSpending == 0) {
          return AiAnswer(text: "No spending recorded $when.");
        }
        // Bucket only the asked-for period: the chart used to show
        // all-time weekday totals under a "this month" answer.
        final buckets = List.generate(7, (_) => 0.0);
        for (final e in filtered.where(
          (e) =>
              e.type == TransactionType.outgoing &&
              _inPeriod(e.date, intent.period, reference),
        )) {
          buckets[e.date.weekday - 1] += e.amount;
        }
        return AiAnswer(
          text:
              "You spend the most on ${stats.highestSpendingDayOfWeek}s $when.",
          widget: AiWidgetSpec.bar(
            title: 'Spending by weekday',
            labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            values: buckets,
          ),
        );

      case AiMetric.projection:
        final projected = stats.projectedMonthlySpending;
        return AiAnswer(
          text: projected == 0
              ? "Not enough spending data to project yet."
              : "At your current pace you're on track to spend about "
                    "${_money(projected)} this month.",
          widget: AiWidgetSpec.statCard(
            title: 'Projected monthly spending',
            value: _money(projected),
            subtitle: 'Based on your daily average',
          ),
        );

      case AiMetric.transactionCount:
        final all = StatisticsHelper(
          intent.type == null
              ? filtered
              : filtered.where((e) => e.type == intent.type).toList(),
          period: intent.period,
          referenceDate: reference,
        );
        return AiAnswer(
          text: "You recorded ${all.transactionCount} transaction"
              "${all.transactionCount == 1 ? '' : 's'}$inCategory $when.",
          widget: AiWidgetSpec.statCard(
            title: 'Transactions',
            value: '${all.transactionCount}',
            subtitle: _titleCase(when),
          ),
        );

      case AiMetric.listTransactions:
        final matches =
            filtered
                .where(
                  (e) =>
                      _inPeriod(e.date, intent.period, reference) &&
                      (intent.type == null || e.type == intent.type),
                )
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

        if (matches.isEmpty) {
          return AiAnswer(text: "No transactions recorded$inCategory $when.");
        }

        const maxRows = 10;
        final shown = matches.take(maxRows).toList();
        final spent = matches
            .where((e) => e.type == TransactionType.outgoing)
            .fold(0.0, (sum, e) => sum + e.amount);
        final spentPart = spent == 0 ? "" : " (${_money(spent)} spent)";
        final morePart = matches.length > maxRows
            ? " Showing the latest $maxRows."
            : "";

        return AiAnswer(
          text:
              "You have ${matches.length} transaction"
              "${matches.length == 1 ? '' : 's'}$inCategory $when"
              "$spentPart.$morePart",
          widget: AiWidgetSpec.transactionList(
            title: 'Transactions$inCategory · ${_titleCase(when)}',
            rows: [
              for (final e in shown)
                AiTransactionRow(
                  title: e.note.isEmpty ? '#${e.category}' : e.note,
                  subtitle:
                      '#${e.category} · ${DateFormat('MMM d, h:mm a').format(e.date)}',
                  amount: switch (e.type) {
                    TransactionType.incoming => '+${_money(e.amount)}',
                    TransactionType.outgoing => '-${_money(e.amount)}',
                    TransactionType.invested => _money(e.amount),
                  },
                  isIncome: e.type == TransactionType.incoming,
                ),
            ],
          ),
        );
    }
  }

  /// Whether [date] falls in the same period window as [reference] —
  /// mirrors StatisticsHelper's filtering for raw-transaction listing.
  bool _inPeriod(DateTime date, String period, DateTime reference) {
    switch (period) {
      case 'D':
        return date.year == reference.year &&
            date.month == reference.month &&
            date.day == reference.day;
      case 'W':
        final start = DateTime(
          reference.year,
          reference.month,
          reference.day,
        ).subtract(Duration(days: reference.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return !date.isBefore(start) && date.isBefore(end);
      case 'M':
        return date.year == reference.year && date.month == reference.month;
      case 'Y':
        return date.year == reference.year;
      default:
        return true;
    }
  }

  AiWidgetSpec _categoryPie(StatisticsHelper stats, int topN, String when) {
    final cats = stats.categoryStats.take(topN).toList();
    return AiWidgetSpec.pie(
      title: 'Spending by category · ${_titleCase(when)}',
      segments: [
        for (final c in cats)
          AiChartSegment(
            label: c.category,
            value: c.totalAmount,
            percent: c.percent,
          ),
      ],
    );
  }

  DateTime _referenceDate(String period, int offset) {
    if (offset == 0) return now;
    switch (period) {
      case 'D':
        return now.add(Duration(days: offset));
      case 'W':
        return now.add(Duration(days: 7 * offset));
      case 'M':
        return DateTime(now.year, now.month + offset, 1);
      case 'Y':
        return DateTime(now.year + offset, now.month, now.day);
      default:
        return now;
    }
  }

  String _periodPhrase(String period, int offset) {
    switch (period) {
      case 'D':
        if (offset == 0) return 'today';
        if (offset == -1) return 'yesterday';
        return '${-offset} days ago';
      case 'W':
        if (offset == 0) return 'this week';
        if (offset == -1) return 'last week';
        return '${-offset} weeks ago';
      case 'M':
        if (offset == 0) return 'this month';
        if (offset == -1) return 'last month';
        return 'in ${DateFormat('MMMM yyyy').format(DateTime(now.year, now.month + offset, 1))}';
      case 'Y':
        if (offset == 0) return 'this year';
        if (offset == -1) return 'last year';
        return 'in ${now.year + offset}';
      default:
        return 'overall';
    }
  }

  String _titleCase(String phrase) => phrase.isEmpty
      ? phrase
      : phrase[0].toUpperCase() + phrase.substring(1);

  List<String> _trendLabels(String period, DateTime reference, int count) {
    switch (period) {
      case 'D':
        return [for (var h = 0; h < count; h++) h % 6 == 0 ? '${h}h' : ''];
      case 'W':
        return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 'M':
        return [
          for (var d = 1; d <= count; d++)
            d == 1 || d % 7 == 0 ? '$d' : '',
        ];
      case 'Y':
        return const [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
      default:
        return List.filled(count, '');
    }
  }
}
