import 'package:expense/data/command/commands.dart';
import 'package:flutter/foundation.dart';

import '../../api/hive/service_extension.dart';
import '../../data/expense/expense.dart';
import 'expense_dummy_data.dart';

class ExpenseCommand extends BaseAppCommand {
  /// get expenses from hive (or server later on)
  /// ToDo: (sync local and server changes as well)
  Future<void> refresh({bool loadDummy = false}) async {
    try {
      final localExpenses = hive.getAllExpenses();

      // Fetch server one and then sync both server and local

      // load dummy data for initial testing (only allow in debug mode)
      if (loadDummy && kDebugMode) localExpenses.addAll(kDummyExpenseData);

      // update bloc
      expenseBloc.refresh(localExpenses);
    } catch (e) {
      debugPrint("Error refreshing expenses: $e");
      // Provide empty list or cached?
      // For now, don't crash the bootstrapper.
    }
  }

  /// add expense
  Future<void> addExpense(ExpenseData expense) async {
    // 1. Optimistic Update
    expenseBloc.addExpense(expense);

    try {
      // 2. Persist
      await hive.addExpense(expense);
      // save to server as well
    } catch (e) {
      // 3. Rollback on failure
      expenseBloc.deleteExpense(expense.id);
      debugPrint("Error adding expense: $e");
      rethrow; // Let UI handle it
    }
  }

  /// delete expense
  Future<void> deleteExpense(String id) async {
    // Find expense to allow rollback
    final expenseToDelete = expenseBloc.expenses
        .cast<ExpenseData?>()
        .firstWhere((e) => e?.id == id, orElse: () => null);

    if (expenseToDelete == null) return;

    // 1. Optimistic Update
    expenseBloc.deleteExpense(id);

    try {
      // 2. Persist
      await hive.deleteExpense(id);
      // delete from server as well
    } catch (e) {
      // 3. Rollback
      expenseBloc.addExpense(expenseToDelete);
      debugPrint("Error deleting expense: $e");
      rethrow;
    }
  }

  /// update expense
  Future<void> updateExpense(ExpenseData expense) async {
    // Find old to allow rollback
    final oldExpense = expenseBloc.expenses.cast<ExpenseData?>().firstWhere(
      (e) => e?.id == expense.id,
      orElse: () => null,
    );

    // 1. Optimistic Update
    expenseBloc.updateExpense(expense);

    try {
      // 2. Persist
      await hive.updateExpense(expense);
      // update to server as well
    } catch (e) {
      // 3. Rollback
      if (oldExpense != null) {
        expenseBloc.updateExpense(oldExpense);
      }
      debugPrint("Error updating expense: $e");
      rethrow;
    }
  }
}
