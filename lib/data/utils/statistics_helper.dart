import 'package:collection/collection.dart';

import '../data/expense/expense.dart';

class StatisticsHelper {
  final List<ExpenseData> _expenses;
  late final List<ExpenseData> _filteredExpenses;
  final String period;
  final DateTime date;

  StatisticsHelper(
    this._expenses, {
    this.period = 'M', // D, W, M, Y, All
    DateTime? referenceDate,
  }) : date = referenceDate ?? DateTime.now() {
    _filteredExpenses = _filterExpensesByPeriod(_expenses, period, date);
  }

  // --- Filtering Logic ---
  List<ExpenseData> _filterExpensesByPeriod(
    List<ExpenseData> all,
    String period,
    DateTime date,
  ) {
    return all.where((e) {
      if (period == 'D') {
        return _isSameDay(e.date, date);
      } else if (period == 'W') {
        return _isSameWeek(e.date, date);
      } else if (period == 'M') {
        return e.date.year == date.year && e.date.month == date.month;
      } else if (period == 'Y') {
        return e.date.year == date.year;
      }
      return true; // All
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    // Basic week calc: start of week (Monday) to end of week
    final startOfWeek = b.subtract(Duration(days: b.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    // Reset times
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final end = DateTime(
      endOfWeek.year,
      endOfWeek.month,
      endOfWeek.day,
      23,
      59,
      59,
    );
    return a.isAfter(start.subtract(const Duration(seconds: 1))) &&
        a.isBefore(end.add(const Duration(seconds: 1)));
  }

  // --- Core Metrics ---

  double get totalSpending => _filteredExpenses
      .where((e) => e.type == TransactionType.outgoing)
      .map((e) => e.amount)
      .sum;

  double get totalIncome => _filteredExpenses
      .where((e) => e.type == TransactionType.incoming)
      .map((e) => e.amount)
      .sum;

  double get totalSaved => totalIncome - totalSpending;

  // --- Advanced Analysis (10 sections) ---

  // 1. Top Spending Category
  MapEntry<String, double>? get topCategory {
    final breakdown = <String, double>{};
    for (var e in _filteredExpenses.where(
      (e) => e.type == TransactionType.outgoing,
    )) {
      breakdown[e.category] = (breakdown[e.category] ?? 0) + e.amount;
    }
    if (breakdown.isEmpty) return null;
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first;
  }

  // 2. Average Daily Spend
  double get averageDailySpend {
    if (_filteredExpenses.isEmpty) return 0;
    if (_filteredExpenses
        .where((e) => e.type == TransactionType.outgoing)
        .isEmpty) {
      return 0;
    }

    // Naively count days with at least one transaction?
    // Or just divide total by days in period?
    // Let's divide total outgoing by number of active spending days for accuracy
    final uniqueDays = _filteredExpenses
        .where((e) => e.type == TransactionType.outgoing)
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet()
        .length;

    if (uniqueDays == 0) return 0;
    return totalSpending / uniqueDays;
  }

  // 3. Largest Single Expense
  ExpenseData? get largestSingleExpense {
    final outgoing = _filteredExpenses
        .where((e) => e.type == TransactionType.outgoing)
        .toList();
    if (outgoing.isEmpty) return null;
    outgoing.sort((a, b) => b.amount.compareTo(a.amount));
    return outgoing.first;
  }

  // 4. Most Frequent Transaction (Category)
  String? get mostFrequentCategory {
    final counts = <String, int>{};
    for (var e in _filteredExpenses) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  // 5. Total Transactions Count
  int get transactionCount => _filteredExpenses.length;

  // 6. Incoming vs Outgoing Ratio
  double get savingsRate {
    if (totalIncome == 0) return 0;
    return (totalSaved / totalIncome) * 100;
  }

  // 7. Day of Week Analysis (which day has highest spending)
  String get highestSpendingDayOfWeek {
    final days = <int, double>{}; // 1 = Mon, 7 = Sun
    for (var e in _filteredExpenses.where(
      (e) => e.type == TransactionType.outgoing,
    )) {
      days[e.date.weekday] = (days[e.date.weekday] ?? 0) + e.amount;
    }
    if (days.isEmpty) return "N/A";

    final sorted = days.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final weekday = sorted.first.key;

    const map = {
      1: "Monday",
      2: "Tuesday",
      3: "Wednesday",
      4: "Thursday",
      5: "Friday",
      6: "Saturday",
      7: "Sunday",
    };
    return map[weekday] ?? "N/A";
  }

  // 8. Projection (Simple linear projection for Month)
  double get projectedMonthlySpending {
    // Only valid if period is Month and current month
    // final now = DateTime.now();
    // Simplified logic: average daily * days in month
    // This is just a placeholder for advanced logic
    return averageDailySpend * 30;
  }

  // 9. Investment Amount
  double get totalInvested => _filteredExpenses
      .where((e) => e.type == TransactionType.invested)
      .map((e) => e.amount)
      .sum;

  // 10. Cash Flow Status
  String get cashFlowStatus {
    if (totalIncome > totalSpending) return "Positive";
    if (totalIncome < totalSpending) return "Negative";
    return "Neutral";
  }

  // Graph Data Helper
  List<double> getGraphData() {
    // Prepare data buckets based on period
    if (_filteredExpenses.isEmpty) return List.generate(7, (_) => 0.0);

    if (period == 'D') {
      // Hourly buckets (0-23)
      final buckets = List.generate(24, (_) => 0.0);
      for (var e in _filteredExpenses.where(
        (e) => e.type == TransactionType.outgoing,
      )) {
        buckets[e.date.hour] += e.amount;
      }
      return buckets;
    } else if (period == 'W') {
      // Daily buckets (0-6, Mon-Sun)
      final buckets = List.generate(7, (_) => 0.0);
      for (var e in _filteredExpenses.where(
        (e) => e.type == TransactionType.outgoing,
      )) {
        // weekday is 1-7, map to 0-6
        buckets[e.date.weekday - 1] += e.amount;
      }
      return buckets;
    } else if (period == 'M') {
      // Daily buckets (1-31)
      // Find number of days in month
      final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
      final buckets = List.generate(daysInMonth, (_) => 0.0);
      for (var e in _filteredExpenses.where(
        (e) => e.type == TransactionType.outgoing,
      )) {
        buckets[e.date.day - 1] += e.amount;
      }
      return buckets;
    } else if (period == 'Y') {
      // Monthly buckets (0-11, Jan-Dec)
      final buckets = List.generate(12, (_) => 0.0);
      for (var e in _filteredExpenses.where(
        (e) => e.type == TransactionType.outgoing,
      )) {
        buckets[e.date.month - 1] += e.amount;
      }
      return buckets;
    }

    return List.generate(7, (_) => 0.0);
  }

  // 11. Detailed Category Stats
  List<CategoryStat> get categoryStats {
    final map = <String, List<ExpenseData>>{};
    for (var e in _filteredExpenses.where(
      (e) => e.type == TransactionType.outgoing,
    )) {
      map.putIfAbsent(e.category, () => []).add(e);
    }

    final total = totalSpending;
    if (total == 0) return [];

    final list = map.entries.map((e) {
      final catTotal = e.value.map((e) => e.amount).sum;
      return CategoryStat(
        category: e.key,
        totalAmount: catTotal,
        percent: catTotal / total,
        transactionCount: e.value.length,
      );
    }).toList();

    // Sort by amount descending
    list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return list;
  }
}

class CategoryStat {
  final String category;
  final double totalAmount;
  final double percent;
  final int transactionCount;

  CategoryStat({
    required this.category,
    required this.totalAmount,
    required this.percent,
    required this.transactionCount,
  });
}
