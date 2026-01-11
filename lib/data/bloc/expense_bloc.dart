import '../data/expense/expense.dart';
import 'abstract.dart';

class ExpenseBloc extends AbstractBloc {
  List<ExpenseData> _expenses = [];

  List<ExpenseData> get expenses => _expenses;

  /// refresh - update expenses
  void refresh(List<ExpenseData> newExpenses) {
    _expenses = newExpenses;
    notifyListeners();
  }

  /// add expense
  void addExpense(ExpenseData expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  /// delete expense
  void deleteExpense(ExpenseData expense) {
    _expenses.removeWhere((e) => e.id == expense.id);
    notifyListeners();
  }

  /// ------------------ Stats ------------------

  double get totalBalance {
    // Balance = Incoming - Outgoing - Invested
    double balance = 0;

    for (final e in _expenses) {
      if (e.type == TransactionType.incoming) {
        balance += e.amount;
      } else {
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

  /// ----------------- Category Breakdown ------------------

  List<String> get allCategories {
    return _expenses.map((e) => e.category).toSet().toList();
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
