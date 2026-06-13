import 'dart:convert';

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
  bool getIsShowOnboarding() => boolBox.get('isShowOnboarding') ?? true;

  Future<void> setOnboardingComplete() =>
      boolBox.put('isShowOnboarding', false);

  bool get getHasSeenTypeSelectorHint =>
      boolBox.get('hasSeenTypeSelectorHint') ?? false;
  Future<void> setHasSeenTypeSelectorHint(bool value) =>
      boolBox.put('hasSeenTypeSelectorHint', value);

  /// AI: which registry model is installed on this device (null = none).
  String? get getAiInstalledModelId => stringBox.get('ai.installedModelId');
  Future<void> setAiInstalledModelId(String? id) => id == null
      ? stringBox.delete('ai.installedModelId')
      : stringBox.put('ai.installedModelId', id);

  /// Insights: the "your money" feed, stored as a JSON array string. Local
  /// only — deliberately NOT part of the Drive backup.
  String? get getInsightsFeed => stringBox.get('insights.feed');
  Future<void> setInsightsFeed(String json) =>
      stringBox.put('insights.feed', json);

  /// Settings
  String? get getCurrency => stringBox.get('currency');
  Future<void> setCurrency(String currency) =>
      stringBox.put('currency', currency);

  bool get getShowPercentage => boolBox.get('showPercentage') ?? false;
  Future<void> setShowPercentage(bool value) =>
      boolBox.put('showPercentage', value);

  bool get getIsBalanceVisible => boolBox.get('isBalanceVisible') ?? true;
  Future<void> setIsBalanceVisible(bool value) =>
      boolBox.put('isBalanceVisible', value);
}

/// Google Drive sync metadata.
extension SyncHiveService on HiveService {
  bool get getSyncEnabled => boolBox.get('sync.enabled') ?? false;
  Future<void> setSyncEnabled(bool value) => boolBox.put('sync.enabled', value);

  String? get getSyncAccountEmail => stringBox.get('sync.accountEmail');
  Future<void> setSyncAccountEmail(String? email) => email == null
      ? stringBox.delete('sync.accountEmail')
      : stringBox.put('sync.accountEmail', email);

  String? get getSyncFileId => stringBox.get('sync.fileId');
  Future<void> setSyncFileId(String? id) => id == null
      ? stringBox.delete('sync.fileId')
      : stringBox.put('sync.fileId', id);

  int? get getLastBackupAt =>
      int.tryParse(stringBox.get('sync.lastBackupAt') ?? '');
  Future<void> setLastBackupAt(int millis) =>
      stringBox.put('sync.lastBackupAt', '$millis');

  /// Set when a local change hasn't been uploaded yet, so a missed
  /// (offline/killed) backup retries on the next launch or resume.
  bool get getSyncDirty => boolBox.get('sync.dirty') ?? false;
  Future<void> setSyncDirty(bool value) => boolBox.put('sync.dirty', value);

  /// Deleted expense ids -> epoch millis, kept out-of-band so queries over
  /// the expense box never have to filter deleted records.
  Map<String, int> getTombstones() {
    final raw = stringBox.get('sync.tombstones');
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, int>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> setTombstones(Map<String, int> tombstones) =>
      stringBox.put('sync.tombstones', jsonEncode(tombstones));
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

  /// Replace the whole box in one go (used by sync merge/restore).
  Future<void> replaceAllExpenses(List<ExpenseData> expenses) async {
    await expenseBox.clear();
    await expenseBox.putAll({for (final e in expenses) e.id: e});
  }
}
