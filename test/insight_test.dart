import 'package:expense/data/data/expense/expense.dart';
import 'package:expense/data/data/insight/insight.dart';
import 'package:expense/data/utils/ai/insight_generator.dart';
import 'package:expense/data/utils/category_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ExpenseData _e(
  String id,
  double amount,
  String category,
  DateTime date, {
  TransactionType type = TransactionType.outgoing,
}) => ExpenseData(
  id: id,
  amount: amount,
  category: category,
  date: date,
  type: type,
  note: '',
);

void main() {
  group('CategoryStyle', () {
    test('known categories map to distinct icons', () {
      expect(CategoryStyle.iconFor('food'), isNot(CategoryStyle.iconFor('rent')));
      expect(CategoryStyle.iconFor('FOOD'), CategoryStyle.iconFor('food'));
    });

    test('unknown categories are deterministic', () {
      final a = CategoryStyle.iconFor('my-custom-cat');
      final b = CategoryStyle.iconFor('my-custom-cat');
      expect(a, b);
      expect(a, isA<IconData>());
    });
  });

  group('InsightGenerator', () {
    final now = DateTime(2026, 6, 12, 10);

    test('returns null with no expenses', () {
      expect(
        InsightGenerator.generate(expenses: const [], now: now, currency: '₹'),
        isNull,
      );
    });

    test('daily recap fires from yesterday spending, names top category', () {
      final yesterday = now.subtract(const Duration(days: 1));
      final insight = InsightGenerator.generate(
        expenses: [
          _e('1', 500, 'food', yesterday),
          _e('2', 120, 'transport', yesterday),
        ],
        now: now,
        currency: '₹',
      );
      expect(insight, isNotNull);
      expect(insight!.kind, InsightKind.dailyRecap);
      expect(insight.category, 'food');
      expect(insight.text, contains('620'));
      expect(insight.id, contains('20260612'));
    });

    test('falls through to top-category-week when no yesterday spend', () {
      final insight = InsightGenerator.generate(
        expenses: [
          _e('1', 800, 'food', now), // today, this week, no yesterday
          _e('2', 200, 'coffee', now),
        ],
        now: now,
        currency: '₹',
      );
      expect(insight, isNotNull);
      expect(insight!.kind, InsightKind.topCategoryWeek);
      expect(insight.bars, isNotEmpty);
    });
  });

  group('InsightData JSON', () {
    test('round-trips including bars and category', () {
      const original = InsightData(
        id: 'topCategoryWeek_20260612',
        createdAt: 1781000000000,
        kind: InsightKind.topCategoryWeek,
        text: 'This week #food is your top category.',
        bars: [InsightBar('food', 1.0), InsightBar('coffee', 0.4)],
        category: 'food',
      );
      final restored = InsightData.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.kind, original.kind);
      expect(restored.text, original.text);
      expect(restored.category, 'food');
      expect(restored.bars.length, 2);
      expect(restored.bars.first.label, 'food');
      expect(restored.bars.first.fraction, 1.0);
    });
  });
}
