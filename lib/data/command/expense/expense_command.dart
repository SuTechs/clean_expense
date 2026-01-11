import 'package:expense/data/command/commands.dart';
import 'package:flutter/foundation.dart';

import '../../api/hive/service_extension.dart';
import '../../data/expense/expense.dart';
import 'expense_dummy_data.dart';

class ExpenseCommand extends BaseAppCommand {
  /// get expenses from hive (or server later on)
  /// ToDo: (sync local and server changes as well)
  Future<void> refresh({bool loadDummy = false}) async {
    final localExpenses = hive.getAllExpenses();

    // Fetch server one and then sync both server and local

    // load dummy data for initial testing (only allow in debug mode)
    if (loadDummy && kDebugMode) localExpenses.addAll(kDummyExpenseData);

    // update bloc
    expenseBloc.refresh(localExpenses);
  }

  /// add expense
  Future<void> addExpense(ExpenseData expense) async {
    expenseBloc.addExpense(expense);

    await hive.addExpense(expense);

    // save to server as well
  }

  /// delete expense
  Future<void> deleteExpense(String id) async {
    expenseBloc.deleteExpense(id);

    await hive.deleteExpense(id);

    // delete from server as well
  }

  /// update expense
  Future<void> updateExpense(ExpenseData expense) async {
    // local update
    expenseBloc.updateExpense(expense);

    await hive.updateExpense(expense);

    // update to server as well
  }
}
