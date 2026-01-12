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

    _expenses = copyList(_expenses);
    notifyListeners();
  }

  /// delete expense
  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);

    _expenses = copyList(_expenses);
    notifyListeners();
  }

  void updateExpense(ExpenseData expense) {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;

      _expenses = copyList(_expenses);
      notifyListeners();
    }
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

  /// Default expense categories (single lowercase words)
  static const List<String> expenseCategories = [
    'food',
    'groceries',
    'transport',
    'fuel',
    'bills',
    'utilities',
    'rent',
    'shopping',
    'clothing',
    'electronics',
    'entertainment',
    'movies',
    'games',
    'subscriptions',
    'health',
    'medicine',
    'fitness',
    'gym',
    'education',
    'books',
    'courses',
    'travel',
    'vacation',
    'insurance',
    'repairs',
    'maintenance',
    'gifts',
    'donations',
    'personal',
    'beauty',
    'pets',
    'kids',
    'family',
    'taxes',
    'fees',
    'dining',
    'coffee',
    'snacks',
    'alcohol',
    'internet',
    'phone',
    'streaming',
    'parking',
    'laundry',
    'household',
  ];

  /// Default income categories
  static const List<String> incomeCategories = [
    'salary',
    'bonus',
    'freelance',
    'consulting',
    'commission',
    'tips',
    'refund',
    'cashback',
    'gift',
    'dividend',
    'interest',
    'rental',
    'royalty',
    'sales',
    'reimbursement',
    'allowance',
    'pension',
    'lottery',
  ];

  /// Default investment categories
  static const List<String> investmentCategories = [
    'stocks',
    'crypto',
    'mutual',
    'bonds',
    'gold',
    'silver',
    'property',
    'realestate',
    'ppf',
    'nps',
    'fd',
    'rd',
    'sip',
    'etf',
    'futures',
    'options',
    'commodities',
    'retirement',
    'savings',
  ];

  /// Get suggested categories for a transaction type
  List<String> getSuggestionsForType(TransactionType type) {
    final usedForType = _expenses
        .where((e) => e.type == type)
        .map((e) => e.category.toLowerCase())
        .toSet();

    List<String> defaults;
    switch (type) {
      case TransactionType.incoming:
        defaults = incomeCategories;
        break;
      case TransactionType.outgoing:
        defaults = expenseCategories;
        break;
      case TransactionType.invested:
        defaults = investmentCategories;
        break;
    }

    // Combine used + defaults, prioritizing used ones
    final combined = <String>{...usedForType, ...defaults};
    return combined.toList()..sort();
  }

  List<String> get allCategories {
    final used = _expenses.map((e) => e.category.toLowerCase()).toSet();
    used.addAll(expenseCategories);
    used.addAll(incomeCategories);
    used.addAll(investmentCategories);
    final sorted = used.toList()..sort();
    return sorted;
  }

  List<String> get usedCategories {
    return _expenses.map((e) => e.category.toLowerCase()).toSet().toList()
      ..sort();
  }

  Map<TransactionType, List<String>> get categoriesByType {
    final map = <TransactionType, Set<String>>{
      TransactionType.incoming: {},
      TransactionType.outgoing: {},
      TransactionType.invested: {},
    };

    for (final e in _expenses) {
      if (e.category.toLowerCase() != "deleted") {
        map[e.type]?.add(e.category.toLowerCase());
      }
    }

    return map.map((key, value) => MapEntry(key, value.toList()..sort()));
  }

  void renameCategory(String oldName, String newName) {
    bool changed = false;
    for (int i = 0; i < _expenses.length; i++) {
      if (_expenses[i].category == oldName) {
        _expenses[i] = _expenses[i].copyWith(category: newName);
        changed = true;
      }
    }

    if (changed) {
      _expenses = copyList(_expenses);
      notifyListeners();
    }
  }

  void deleteCategory(String categoryName, {required bool deleteTransactions}) {
    if (deleteTransactions) {
      _expenses.removeWhere((e) => e.category == categoryName);
    } else {
      // Mark as deleted (rename to "deleted")
      for (int i = 0; i < _expenses.length; i++) {
        if (_expenses[i].category == categoryName) {
          _expenses[i] = _expenses[i].copyWith(category: "deleted");
        }
      }
    }
    _expenses = copyList(_expenses);
    notifyListeners();
  }

  int getCategoryCount(String categoryName) {
    return _expenses.where((e) => e.category == categoryName).length;
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

  Map<String, double> get monthlyCategoryBreakdown {
    final now = DateTime.now();
    final map = <String, double>{};
    for (var e in _expenses) {
      if (e.type == TransactionType.outgoing &&
          e.date.month == now.month &&
          e.date.year == now.year) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
    }
    return map;
  }

  /// returns daily cumulative balance for last [days], starting from the first entry found
  MapEntry<int, List<double>> getBalanceHistory(int totalDays) {
    if (_expenses.isEmpty) return const MapEntry(0, []);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limitDate = today.subtract(Duration(days: totalDays - 1));

    // Find the earliest relevant expense date
    DateTime? firstDate;
    for (final e in _expenses) {
      if (e.date.isAfter(limitDate) || e.date.isAtSameMomentAs(limitDate)) {
        if (firstDate == null || e.date.isBefore(firstDate)) {
          firstDate = e.date;
        }
      }
    }

    if (firstDate == null) return const MapEntry(0, []);

    // Start from the beginning of that first day or the limitDate, whichever is later
    final actualStart =
        DateTime(
          firstDate.year,
          firstDate.month,
          firstDate.day,
        ).isBefore(limitDate)
        ? limitDate
        : DateTime(firstDate.year, firstDate.month, firstDate.day);

    final daysToShow = today.difference(actualStart).inDays + 1;
    final history = <double>[];

    for (int i = 0; i < daysToShow; i++) {
      final date = actualStart.add(Duration(days: i));
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      double balance = 0;
      for (final e in _expenses) {
        if (e.date.isBefore(endOfDay)) {
          if (e.type == TransactionType.incoming) {
            balance += e.amount;
          } else {
            balance -= e.amount;
          }
        }
      }
      history.add(balance);
    }
    return MapEntry(daysToShow, history);
  }
}
