import '../../data/expense/expense.dart';
import '../../data/user/user.dart';
import 'hive_service.dart';

extension AppHiveService on HiveService {
  Future<void> saveUser(UserData user) async {
    await box<UserData>().put('currentUser', user);
  }

  UserData? get getSavedUserData => box<UserData>().get('currentUser');

  // Clearing the box on log out so not needed
  // Future<void> logOut() async {
  //   await box<UserData>().delete('currentUser');
  // }

  /// get is show onboarding
  bool getIsShowOnboarding() {
    final showOnboarding = box<bool>().get('isShowOnboarding') ?? true;

    if (showOnboarding) box<bool>().put('isShowOnboarding', false);

    return showOnboarding;
  }

  /// Settings
  String? get getCurrency => stringBox.get('currency');
  Future<void> setCurrency(String currency) =>
      stringBox.put('currency', currency);

  bool get getShowPercentage => boolBox.get('showPercentage') ?? false;
  Future<void> setShowPercentage(bool value) =>
      boolBox.put('showPercentage', value);
}

/// Extension methods for expense data class
extension ExpenseDataExtension on HiveService {
  /// Add expense
  Future<void> addExpense(ExpenseData expense) async {
    await expenseBox.put(expense.id, expense);
  }

  /// Delete expense
  Future<void> deleteExpense(String id) async {
    await expenseBox.delete(id);
  }

  /// Update expense
  Future<void> updateExpense(ExpenseData expense) async {
    await expenseBox.put(expense.id, expense);
  }

  /// Read expenses
  List<ExpenseData> getAllExpenses() {
    return expenseBox.values.toList();
  }
}
