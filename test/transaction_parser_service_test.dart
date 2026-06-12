import 'package:expense/data/utils/transaction_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = TransactionParserService();

  group('parse', () {
    test('extracts note, category and amount in any order', () {
      final result = parser.parse('dinner #food 500');
      expect(result.category, 'food');
      expect(result.amount, 500);
      expect(result.notes, 'dinner');
      expect(result.isValid, isTrue);
    });

    test('takes the last number as amount', () {
      final result = parser.parse('2 burgers #food 500');
      expect(result.amount, 500);
      expect(result.notes, '2 burgers');
    });

    test('is invalid without category or amount', () {
      expect(parser.parse('lunch 200').isValid, isFalse);
      expect(parser.parse('lunch #food').isValid, isFalse);
    });
  });

  group('reconstruct', () {
    test('builds "note #category amount"', () {
      final text = parser.reconstruct(
        note: 'dinner',
        category: 'food',
        amount: 500,
      );
      expect(text, 'dinner #food 500');
    });

    test('omits empty note', () {
      final text = parser.reconstruct(note: '', category: 'food', amount: 500);
      expect(text, '#food 500');
    });

    test('strips .0 on whole amounts and keeps real decimals', () {
      expect(
        parser.reconstruct(note: 'a', category: 'c', amount: 120.0),
        'a #c 120',
      );
      expect(
        parser.reconstruct(note: 'a', category: 'c', amount: 120.5),
        'a #c 120.5',
      );
    });

    test('round-trips through parse, including numeric notes', () {
      const cases = [
        ('dinner', 'food', 500.0),
        ('2 burgers', 'food', 500.0),
        ('', 'salary', 50000.0),
        ('uber to airport', 'transport', 349.5),
        // Note containing a hashtag: category must still round-trip
        // (regression: saving an untouched edit used to flip the category
        // to the note's tag).
        ('Lunch #work', 'food', 150.0),
      ];

      for (final (note, category, amount) in cases) {
        final text = parser.reconstruct(
          note: note,
          category: category,
          amount: amount,
        );
        final result = parser.parse(text);
        expect(result.isValid, isTrue, reason: 'failed for "$text"');
        expect(result.category, category, reason: 'failed for "$text"');
        expect(result.amount, amount, reason: 'failed for "$text"');
        expect(result.notes ?? '', note, reason: 'failed for "$text"');
      }
    });
  });
}
