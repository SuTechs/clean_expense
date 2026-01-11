import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../data/expense/expense.dart';
import '../../data/hive/hive_registrar.g.dart';
import '../../data/user/user.dart';
import 'hive_service.dart';

class NativeHiveService extends HiveService {
  @override
  Future<void> init() async {
    /// init hive
    await Hive.initFlutter();

    /// register adapters
    Hive.registerAdapters();

    /// open box
    await _openBox();
  }

  /// open box for all custom data types and hive objets
  static Future<void> _openBox() async {
    await Hive.openBox<String>('String');
    await Hive.openBox<bool>("bool");

    await Hive.openBox<UserData>('UserData');
    await Hive.openBox<ExpenseData>('Expense');

    // add more boxes here
  }

  /// get opened box
  @override
  Box<T> box<T>() {
    return Hive.box<T>(T.toString());
  }

  // reset hive
  @override
  void reset() {
    // clear user data
    box<UserData>().clear();

    boolBox.clear();
    stringBox.clear();
    expenseBox.clear();
  }

  @override
  Box<String> get stringBox => box<String>();

  @override
  Box<bool> get boolBox => box<bool>();

  @override
  Box<ExpenseData> get expenseBox => box<ExpenseData>();
}
