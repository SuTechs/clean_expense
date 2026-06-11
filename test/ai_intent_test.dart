import 'package:expense/data/data/ai/ai_intent.dart';
import 'package:expense/data/data/ai/ai_message.dart';
import 'package:expense/data/data/expense/expense.dart';
import 'package:expense/data/utils/ai/intent_executor.dart';
import 'package:expense/data/utils/ai/intent_fallback_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const _categories = ['food', 'transport', 'salary', 'rent'];

// Fixed "now" so period filters are deterministic: June 11, 2026.
final _now = DateTime(2026, 6, 11, 12);

List<ExpenseData> _fixture() => [
  // This month: food 500 + 1250, transport 300, salary 50000 in
  ExpenseData(
    id: '1',
    amount: 500,
    category: 'food',
    date: DateTime(2026, 6, 2, 13),
    type: TransactionType.outgoing,
    note: 'dinner',
  ),
  ExpenseData(
    id: '2',
    amount: 1250,
    category: 'food',
    date: DateTime(2026, 6, 4, 20),
    type: TransactionType.outgoing,
    note: 'pizza night',
  ),
  ExpenseData(
    id: '3',
    amount: 300,
    category: 'transport',
    date: DateTime(2026, 6, 5, 9),
    type: TransactionType.outgoing,
    note: 'uber',
  ),
  ExpenseData(
    id: '4',
    amount: 50000,
    category: 'salary',
    date: DateTime(2026, 6, 1, 10),
    type: TransactionType.incoming,
    note: 'june salary',
  ),
  // Last month: rent 15000
  ExpenseData(
    id: '5',
    amount: 15000,
    category: 'rent',
    date: DateTime(2026, 5, 3, 10),
    type: TransactionType.outgoing,
    note: 'may rent',
  ),
];

IntentExecutor _executor() =>
    IntentExecutor(expenses: _fixture(), currency: '₹', now: _now);

void main() {
  group('AiIntent.fromToolArgs', () {
    test('parses a valid tool call', () {
      final intent = AiIntent.fromToolArgs({
        'metric': 'largest_expense',
        'period': 'M',
        'date_offset': -1,
        'category': 'food',
      }, knownCategories: _categories);

      expect(intent, isNotNull);
      expect(intent!.metric, AiMetric.largestExpense);
      expect(intent.period, 'M');
      expect(intent.dateOffset, -1);
      expect(intent.category, 'food');
    });

    test('rejects unknown metric, defaults bad slots', () {
      expect(
        AiIntent.fromToolArgs({
          'metric': 'made_up_metric',
          'period': 'M',
        }, knownCategories: _categories),
        isNull,
      );

      final defaulted = AiIntent.fromToolArgs({
        'metric': 'total_spending',
        'period': 'fortnight', // invalid -> defaults to M
        'date_offset': 99, // clamped to 0
        'category': 'nonexistent',
      }, knownCategories: _categories);
      expect(defaulted!.period, 'M');
      expect(defaulted.dateOffset, 0);
      expect(defaulted.category, isNull);
    });

    test('fuzzy-matches categories', () {
      expect(AiIntent.matchCategory('Food', _categories), 'food');
      expect(AiIntent.matchCategory('#transport', _categories), 'transport');
      expect(AiIntent.matchCategory('foods', _categories), 'food');
      expect(AiIntent.matchCategory('crypto', _categories), isNull);
    });
  });

  group('IntentExecutor golden queries', () {
    test('total spending this month', () {
      final answer = _executor().execute(
        const AiIntent(metric: AiMetric.totalSpending),
      );
      // 500 + 1250 + 300 — numbers computed, never model-generated
      expect(answer.text, contains('₹2,050'));
      expect(answer.widget!.type, AiWidgetType.statCard);
      expect(answer.widget!.value, '₹2,050');
    });

    test('biggest expense this month on food', () {
      final answer = _executor().execute(
        const AiIntent(metric: AiMetric.largestExpense, category: 'food'),
      );
      expect(answer.text, contains('₹1,250'));
      expect(answer.text, contains('pizza night'));
      expect(answer.text, contains('#food'));
    });

    test('where am I spending most → top category + pie widget', () {
      final answer = _executor().execute(
        const AiIntent(metric: AiMetric.topCategory),
      );
      expect(answer.text, contains('#food'));
      expect(answer.text, contains('₹1,750'));
      expect(answer.widget!.type, AiWidgetType.pie);
      expect(answer.widget!.segments!.first.label, 'food');
    });

    test('savings rate this month', () {
      final answer = _executor().execute(
        const AiIntent(metric: AiMetric.savingsRate),
      );
      // (50000 - 2050) / 50000 = 95.9%
      expect(answer.text, contains('95.9%'));
      expect(answer.widget!.type, AiWidgetType.statCard);
    });

    test('last month uses date_offset', () {
      final answer = _executor().execute(
        const AiIntent(metric: AiMetric.totalSpending, dateOffset: -1),
      );
      expect(answer.text, contains('₹15,000'));
      expect(answer.text, contains('last month'));
    });

    test('spending trend produces a line widget', () {
      final answer = _executor().execute(
        const AiIntent(metric: AiMetric.spendingTrend),
      );
      expect(answer.widget!.type, AiWidgetType.line);
      // June has 30 days -> 30 buckets; day 4 holds 1250
      expect(answer.widget!.values!.length, 30);
      expect(answer.widget!.values![3], 1250);
    });

    test('empty periods answer gracefully', () {
      final answer = _executor().execute(
        const AiIntent(metric: AiMetric.totalSpending, period: 'Y', dateOffset: -2),
      );
      expect(answer.text.toLowerCase(), contains("didn't spend"));
    });
  });

  group('IntentFallbackParser', () {
    test('parses the suggestion-chip questions without a model', () {
      final cases = {
        'What did I spend this month?': AiMetric.totalSpending,
        'Where am I spending most?': AiMetric.topCategory,
        'My biggest expense this month': AiMetric.largestExpense,
        "What's my savings rate this year?": AiMetric.savingsRate,
        'Spending trend this month': AiMetric.spendingTrend,
      };
      cases.forEach((question, metric) {
        final intent = IntentFallbackParser.parse(
          question,
          categories: _categories,
        );
        expect(intent?.metric, metric, reason: question);
      });
    });

    test('extracts period and category', () {
      final intent = IntentFallbackParser.parse(
        'how much did I spend on food last month',
        categories: _categories,
      );
      expect(intent!.metric, AiMetric.totalSpending);
      expect(intent.period, 'M');
      expect(intent.dateOffset, -1);
      expect(intent.category, 'food');
    });

    test('returns null for off-topic text', () {
      expect(
        IntentFallbackParser.parse('hello there', categories: _categories),
        isNull,
      );
    });
  });
}
