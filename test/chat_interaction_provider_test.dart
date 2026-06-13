import 'package:expense/data/data/expense/expense.dart';
import 'package:expense/screens/chat/state/chat_interaction_provider.dart';
import 'package:flutter_test/flutter_test.dart';

ExpenseData _expense(String id) => ExpenseData(
  id: id,
  amount: 100,
  category: 'food',
  date: DateTime(2026, 6, 1),
  type: TransactionType.outgoing,
  note: 'test',
);

void main() {
  group('ChatInteractionProvider', () {
    test('select highlights and exposes selection', () {
      final provider = ChatInteractionProvider();
      provider.select(_expense('a'));

      expect(provider.hasSelection, isTrue);
      expect(provider.isHighlighted('a'), isTrue);
      expect(provider.isHighlighted('b'), isFalse);
    });

    test('toggle clears same bubble and moves to another', () {
      final provider = ChatInteractionProvider();
      provider.select(_expense('a'));

      provider.toggle(_expense('b'));
      expect(provider.selected?.id, 'b');

      provider.toggle(_expense('b'));
      expect(provider.hasSelection, isFalse);
    });

    test('startEditing moves selection to editing and keeps highlight', () {
      final provider = ChatInteractionProvider();
      provider.select(_expense('a'));
      provider.startEditing();

      expect(provider.hasSelection, isFalse);
      expect(provider.isEditing, isTrue);
      expect(provider.editing?.id, 'a');
      expect(provider.isHighlighted('a'), isTrue);
    });

    test('select and toggle are ignored while editing (edit is modal)', () {
      final provider = ChatInteractionProvider();
      provider.select(_expense('a'));
      provider.startEditing();

      provider.select(_expense('b'));
      provider.toggle(_expense('b'));

      expect(provider.hasSelection, isFalse);
      expect(provider.editing?.id, 'a');
    });

    test('cancelEditing clears edit mode', () {
      final provider = ChatInteractionProvider();
      provider.select(_expense('a'));
      provider.startEditing();
      provider.cancelEditing();

      expect(provider.isEditing, isFalse);
      expect(provider.isHighlighted('a'), isFalse);
    });

    test('onExpenseDeleted clears matching selection and edit state', () {
      final provider = ChatInteractionProvider();
      provider.select(_expense('a'));
      provider.onExpenseDeleted('a');
      expect(provider.hasSelection, isFalse);

      provider.select(_expense('b'));
      provider.startEditing();
      provider.onExpenseDeleted('b');
      expect(provider.isEditing, isFalse);
    });

    test('notifies listeners only on real changes', () {
      final provider = ChatInteractionProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.clearSelection(); // no-op
      provider.cancelEditing(); // no-op
      provider.onExpenseDeleted('x'); // no-op
      expect(notifications, 0);

      provider.select(_expense('a'));
      provider.select(_expense('a')); // same id, no-op
      expect(notifications, 1);
    });
  });
}
