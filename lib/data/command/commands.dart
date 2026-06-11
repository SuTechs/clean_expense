import 'dart:developer';

import '../api/hive/hive_service.dart';
import '../bloc/ai_bloc.dart';
import '../bloc/app_bloc.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/sync_bloc.dart';
import 'expense/expense_command.dart';
import 'sync/sync_command.dart';

abstract class BaseAppCommand {
  static bool _init = false;

  static late final HiveService _hive;

  static final blocApp = AppBloc(_hive);

  static final blocExpense = ExpenseBloc();

  static final blocSync = SyncBloc();

  static final blocAi = AiBloc();

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

    // Fetch and sync expenses
    ExpenseCommand().refresh(loadDummy: false);

    // Restore sync state and pull remote changes (never blocks bootstrap)
    SyncCommand().hydrate();
    SyncCommand().syncOnResume();

    blocApp.hasBootstrapped = true;
    log("BootstrapCommand - Complete");
    _init = true;
  }
}
