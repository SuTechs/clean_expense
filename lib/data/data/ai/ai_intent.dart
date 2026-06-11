import '../expense/expense.dart';

/// What the user is asking for. The on-device model only ever produces this
/// (via a single `query_stats` tool call); all numbers are computed by app
/// code from it.
enum AiMetric {
  totalSpending,
  totalIncome,
  totalInvested,
  totalSaved,
  savingsRate,
  topCategory,
  categoryBreakdown,
  largestExpense,
  averageDailySpend,
  mostFrequentCategory,
  spendingTrend,
  dayOfWeek,
  projection,
  transactionCount,
}

class AiIntent {
  final AiMetric metric;

  /// Maps 1:1 to StatisticsHelper periods: D, W, M, Y, All.
  final String period;

  /// 0 = current period, -1 = previous, etc.
  final int dateOffset;
  final TransactionType? type;
  final String? category;
  final int topN;

  const AiIntent({
    required this.metric,
    this.period = 'M',
    this.dateOffset = 0,
    this.type,
    this.category,
    this.topN = 5,
  });

  static const _metricNames = {
    'total_spending': AiMetric.totalSpending,
    'total_income': AiMetric.totalIncome,
    'total_invested': AiMetric.totalInvested,
    'total_saved': AiMetric.totalSaved,
    'savings_rate': AiMetric.savingsRate,
    'top_category': AiMetric.topCategory,
    'category_breakdown': AiMetric.categoryBreakdown,
    'largest_expense': AiMetric.largestExpense,
    'average_daily_spend': AiMetric.averageDailySpend,
    'most_frequent_category': AiMetric.mostFrequentCategory,
    'spending_trend': AiMetric.spendingTrend,
    'day_of_week': AiMetric.dayOfWeek,
    'projection': AiMetric.projection,
    'transaction_count': AiMetric.transactionCount,
  };

  static const _periodNames = {
    'd': 'D', 'day': 'D', 'today': 'D',
    'w': 'W', 'week': 'W',
    'm': 'M', 'month': 'M',
    'y': 'Y', 'year': 'Y',
    'all': 'All', 'all_time': 'All',
  };

  /// Validates tool-call args from the model into a typed intent.
  /// Returns null when the metric is unusable; other slots fall back to
  /// safe defaults (small models get enums mostly-right, not always-right).
  static AiIntent? fromToolArgs(
    Map<String, dynamic> args, {
    required List<String> knownCategories,
  }) {
    final metric = _metricNames[args['metric']?.toString().toLowerCase()];
    if (metric == null) return null;

    final period =
        _periodNames[args['period']?.toString().toLowerCase()] ?? 'M';

    final rawOffset = args['date_offset'];
    final dateOffset = (rawOffset is num ? rawOffset.toInt() : 0).clamp(
      -24,
      0,
    );

    TransactionType? type;
    switch (args['type']?.toString().toLowerCase()) {
      case 'outgoing' || 'expense':
        type = TransactionType.outgoing;
      case 'incoming' || 'income':
        type = TransactionType.incoming;
      case 'invested' || 'invest':
        type = TransactionType.invested;
    }

    final rawTopN = args['top_n'];
    final topN = (rawTopN is num ? rawTopN.toInt() : 5).clamp(1, 10);

    return AiIntent(
      metric: metric,
      period: period,
      dateOffset: dateOffset,
      type: type,
      category: matchCategory(
        args['category']?.toString(),
        knownCategories,
      ),
      topN: topN,
    );
  }

  /// Fuzzy-matches a model-provided category against the user's actual
  /// categories: exact, then prefix, then contains.
  static String? matchCategory(String? raw, List<String> known) {
    if (raw == null) return null;
    final needle = raw.toLowerCase().replaceAll('#', '').trim();
    if (needle.isEmpty || needle == 'null') return null;

    if (known.contains(needle)) return needle;
    for (final c in known) {
      if (c.startsWith(needle) || needle.startsWith(c)) return c;
    }
    for (final c in known) {
      if (c.contains(needle) || needle.contains(c)) return c;
    }
    return null;
  }
}
