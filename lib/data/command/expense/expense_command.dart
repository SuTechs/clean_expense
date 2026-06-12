import 'package:expense/data/command/commands.dart';
import 'package:flutter/foundation.dart';

import '../../api/hive/service_extension.dart';
import '../../data/expense/expense.dart';
import '../../utils/time_utils.dart';
import '../sync/sync_command.dart';
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
    // Stamp for per-record merge during Drive sync.
    expense = expense.copyWith(updatedAt: TimeUtils.nowMillis);

    // 1. Optimistic Update
    expenseBloc.addExpense(expense);

    try {
      // 2. Persist
      await hive.addExpense(expense);
      SyncCommand().scheduleBackup();
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
      await SyncCommand().recordTombstone(id);
      SyncCommand().scheduleBackup();
    } catch (e) {
      // 3. Rollback
      expenseBloc.addExpense(expenseToDelete);
      debugPrint("Error deleting expense: $e");
      rethrow;
    }
  }

  /// Renames a category across all transactions, persisting each change
  /// with a fresh updatedAt stamp. The bloc-only version of this lost the
  /// rename on restart and the next sync merge reverted it in the UI.
  Future<void> renameCategory(String oldName, String newName) async {
    final affected = expenseBloc.expenses
        .where((e) => e.category == oldName)
        .toList();
    if (affected.isEmpty) return;

    final now = TimeUtils.nowMillis;
    for (final e in affected) {
      final updated = e.copyWith(category: newName, updatedAt: now);
      expenseBloc.updateExpense(updated);
      await hive.updateExpense(updated);
    }
    SyncCommand().scheduleBackup();
  }

  /// Deletes a category: permanently removes its transactions (with
  /// tombstones so other devices don't resurrect them) or, with
  /// [deleteTransactions] false, relabels them as "deleted".
  Future<void> deleteCategory(
    String name, {
    required bool deleteTransactions,
  }) async {
    if (!deleteTransactions) {
      await renameCategory(name, 'deleted');
      return;
    }

    final affected = expenseBloc.expenses
        .where((e) => e.category == name)
        .toList();
    if (affected.isEmpty) return;

    for (final e in affected) {
      expenseBloc.deleteExpense(e.id);
      await hive.deleteExpense(e.id);
      await SyncCommand().recordTombstone(e.id);
    }
    SyncCommand().scheduleBackup();
  }

  /// update expense
  Future<void> updateExpense(ExpenseData expense) async {
    // Stamp for per-record merge during Drive sync.
    expense = expense.copyWith(updatedAt: TimeUtils.nowMillis);

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
      SyncCommand().scheduleBackup();
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
