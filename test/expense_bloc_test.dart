import 'package:expense/data/bloc/expense_bloc.dart';
import 'package:expense/data/data/expense/expense.dart';
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
  test(
    'addExpense works after refresh with an unmodifiable list (restore path)',
    () {
      // Regression: restoreNow() passes BackupData.expenses — freezed makes
      // it unmodifiable — and the next addExpense crashed with
      // "Cannot add to an unmodifiable list".
      final bloc = ExpenseBloc();
      bloc.refresh(List.unmodifiable([_expense('a')]));

      bloc.addExpense(_expense('b'));
      bloc.updateExpense(_expense('a').copyWith(amount: 200));
      bloc.deleteExpense('b');

      expect(bloc.expenses.length, 1);
      expect(bloc.expenses.single.amount, 200);
    },
  );
}
