import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import 'data/expense/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  static const String boxName = 'Expense';

  Box<Expense>? _box;
  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  ExpenseProvider() {
    _init();
  }

  Future<void> _init() async {
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box<Expense>(boxName);
    } else {
      // It should be opened in HiveService, but just in case
      // _box = await Hive.openBox<Expense>(boxName);
      // For now we assume the service opens it or we wait.
    }

    // Retry getting box if not immediately available (though HiveService should handle it)
    int retries = 0;
    while (!Hive.isBoxOpen(boxName) && retries < 5) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box<Expense>(boxName);
      _expenses = _box!.values.toList();
      _expenses.sort((a, b) => b.date.compareTo(a.date)); // Sort by date desc
    }

    _isLoading = false;
    notifyListeners();
  }

  void refresh() {
    if (_box != null) {
      _expenses = _box!.values.toList();
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  Future<void> addExpense({
    required double amount,
    required String category,
    required TransactionType type,
    String note = '',
    DateTime? date,
  }) async {
    if (_box == null) return;

    final expense = Expense(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      date: date ?? DateTime.now(),
      type: type,
      note: note,
    );

    await _box!.add(expense);
    // Hive objects might need save? add() generally saves to box.
    // Also we can just reload or add to local list.
    _expenses.insert(0, expense);
    notifyListeners();
  }

  Future<void> deleteExpense(Expense expense) async {
    await expense.delete();
    _expenses.remove(expense);
    notifyListeners();
  }

  // Stats
  double get totalBalance {
    double balance = 0;
    for (var e in _expenses) {
      if (e.type == TransactionType.incoming) {
        balance += e.amount;
      } else if (e.type == TransactionType.outgoing) {
        balance -= e.amount;
      }
      // Invested usually implies money moved out to asset, so creates a debit in cash,
      // but strictly speaking for "Net Worth" it might be asset.
      // User asked: "Incoming, Outgoing, Invested".
      // Balance usually means available cash?
      // Let's assume Balance = Incoming - Outgoing - Invested
      else if (e.type == TransactionType.invested) {
        balance -= e.amount;
      }
    }
    return balance;
  }

  double get totalIncoming {
    return _expenses
        .where((e) => e.type == TransactionType.incoming)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalOutgoing {
    return _expenses
        .where((e) => e.type == TransactionType.outgoing)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalInvested {
    return _expenses
        .where((e) => e.type == TransactionType.invested)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> get categoryBreakdown {
    final map = <String, double>{};
    for (var e in _expenses) {
      if (e.type == TransactionType.outgoing) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
    }
    return map;
  }
}
