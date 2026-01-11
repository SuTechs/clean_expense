import 'dart:developer';

import '../api/hive/hive_service.dart';
import '../bloc/app_bloc.dart';
import '../bloc/expense_bloc.dart';

abstract class BaseAppCommand {
  static bool _init = false;

  static late final HiveService _hive;

  static final blocApp = AppBloc(_hive);

  static final blocExpense = ExpenseBloc();

  /// add other blocs here

  HiveService get hive => _hive;

  AppBloc get appBloc => blocApp;

  ExpenseBloc get expenseBloc => blocExpense;

  /// init

  static Future<void> init() async {
    if (_init) return;

    final futures = <Future>[
      HiveFactory.create().then((value) => _hive = value),
    ];

    await Future.wait(futures);

    ///

    log("Bootstrap Started, v${AppBloc.kVersion}");
    // Load AppBloc ASAP
    // appBloc.load();

    log("BootstrapCommand - Init services");
    // Init services

    blocApp.hasBootstrapped = true;
    log("BootstrapCommand - Complete");
    _init = true;
  }
}
