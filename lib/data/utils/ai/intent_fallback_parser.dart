import '../../data/ai/ai_intent.dart';
import '../../data/expense/expense.dart';

/// Keyword fallback when the model fails to produce a usable tool call —
/// same spirit as TransactionParserService. Works directly on the USER's
/// text, so a flaky model never blocks common questions.
class IntentFallbackParser {
  IntentFallbackParser._();

  static AiIntent? parse(String input, {required List<String> categories}) {
    final text = input.toLowerCase();

    final metric = _metric(text);
    if (metric == null) return null;

    final (period, offset) = _period(text);

    return AiIntent(
      metric: metric,
      period: period,
      dateOffset: offset,
      type: _type(text, metric),
      category: _category(text, categories),
    );
  }

  static AiMetric? _metric(String text) {
    bool has(Pattern p) => text.contains(p);

    if (has(RegExp(r'biggest|largest|most expensive'))) {
      return has(RegExp(r'categor'))
          ? AiMetric.topCategory
          : AiMetric.largestExpense;
    }
    if (has(RegExp(r'spending most|spend the most|where.*(money|spend)'))) {
      return AiMetric.topCategory;
    }
    if (has(RegExp(r'breakdown|by category|split'))) {
      return AiMetric.categoryBreakdown;
    }
    // Day-of-week before the listing check: "which day do I make the most
    // purchases" is a weekday question, not a listing.
    if (has(RegExp(r'which day|what day|weekday'))) return AiMetric.dayOfWeek;
    // Counting/listing checks come BEFORE the income/invest/saved metrics so
    // "income transactions" lists income instead of summing it.
    if (has(RegExp(r'how many|count|number of'))) {
      return AiMetric.transactionCount;
    }
    if (has(RegExp(r'transactions?|purchases|what did i buy|list my'))) {
      return AiMetric.listTransactions;
    }
    if (has(RegExp(r'savings? rate'))) return AiMetric.savingsRate;
    if (has(RegExp(r'\bsaved?\b'))) return AiMetric.totalSaved;
    if (has(RegExp(r'invest'))) return AiMetric.totalInvested;
    if (has(RegExp(r'income|earn|salary'))) return AiMetric.totalIncome;
    if (has(RegExp(r'average|per day|daily'))) {
      return AiMetric.averageDailySpend;
    }
    if (has(RegExp(r'trend|over time|chart|graph'))) {
      return AiMetric.spendingTrend;
    }
    if (has(RegExp(r'project|on track|forecast'))) return AiMetric.projection;
    if (has(RegExp(r'frequent|most often'))) {
      return AiMetric.mostFrequentCategory;
    }
    if (has(RegExp(r'sp(end|ent)|cost|expense'))) {
      return AiMetric.totalSpending;
    }
    return null;
  }

  /// Type filter for counting/listing metrics ("income transactions",
  /// "investment purchases"); other metrics imply their own type.
  static TransactionType? _type(String text, AiMetric metric) {
    if (metric != AiMetric.transactionCount &&
        metric != AiMetric.listTransactions) {
      return null;
    }
    if (RegExp(r'income|earning|salary').hasMatch(text)) {
      return TransactionType.incoming;
    }
    if (text.contains('invest')) return TransactionType.invested;
    if (RegExp(r'expense|sp(end|ent)').hasMatch(text)) {
      return TransactionType.outgoing;
    }
    return null;
  }

  static (String, int) _period(String text) {
    if (text.contains('yesterday')) return ('D', -1);
    if (text.contains('today')) return ('D', 0);
    if (text.contains('last week')) return ('W', -1);
    if (text.contains('week')) return ('W', 0);
    if (text.contains('last month')) return ('M', -1);
    if (text.contains('month')) return ('M', 0);
    if (text.contains('last year')) return ('Y', -1);
    if (text.contains('year')) return ('Y', 0);
    if (RegExp(r'all time|overall|ever|in total').hasMatch(text)) {
      return ('All', 0);
    }
    return ('M', 0); // sensible default
  }

  static String? _category(String text, List<String> categories) {
    final tag = RegExp(r'#(\w+)').firstMatch(text)?.group(1);
    if (tag != null) return AiIntent.matchCategory(tag, categories);

    // Whole-word match against the user's real categories.
    for (final c in categories) {
      if (RegExp('\\b$c\\b').hasMatch(text)) return c;
    }
    return null;
  }
}
