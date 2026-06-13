import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/bloc/app_bloc.dart';
import 'data/command/ai/ai_model_command.dart';
import 'data/command/commands.dart';
import 'data/command/insight/insight_command.dart';
import 'data/command/sync/sync_command.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app command before running the app
  // Sets up Supabase, Firebase, Hive, Blocs, etc.
  await BaseAppCommand.init();

  // Run the app
  runApp(
    MultiProvider(
      providers: [
        // AppBloc - Stores data related to global settings and app
        ChangeNotifierProvider.value(value: BaseAppCommand.blocApp),

        // Expense Bloc - Handle expense related data
        ChangeNotifierProvider.value(value: BaseAppCommand.blocExpense),

        // Sync Bloc - Google Drive backup status
        ChangeNotifierProvider.value(value: BaseAppCommand.blocSync),

        // AI Bloc - on-device assistant state
        ChangeNotifierProvider.value(value: BaseAppCommand.blocAi),

        // Insight Bloc - "your money" thread messages
        ChangeNotifierProvider.value(value: BaseAppCommand.blocInsight),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Flush pending backups and free AI model memory when the app goes to
  /// background; pull remote changes when it comes back.
  // Constructed eagerly in initState: a lazy `late final` field initializer
  // only runs on first read, which used to be dispose() — meaning the
  // listener never existed while the app ran.
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        SyncCommand().flushPending();
        AiModelCommand().unload();
      },
      onResume: () {
        SyncCommand().syncOnResume();
        InsightCommand().maybeGenerate();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clean Expense',
      theme: AppTheme.lightTheme,
      home: const _AppBootstrapper(),
    );
  }
}

class _AppBootstrapper extends StatelessWidget {
  const _AppBootstrapper();

  @override
  Widget build(BuildContext context) {
    final showOnboarding = context.select(
      (AppBloc bloc) => bloc.isShowOnboarding,
    );

    // First launch: onboarding completes via OnboardingCommand, which flips
    // the flag and rebuilds this widget into MainScreen.
    if (showOnboarding) {
      return OnboardingScreen(
        // Connecting runs a merge, which on a fresh install IS the restore.
        // Returns false on cancel; throws (readable message) on failure so
        // the onboarding screen can show it.
        onRestoreBackup: SyncCommand().isConfigured
            ? (context) => SyncCommand().connectInteractive()
            : null,
      );
    }

    return const MainScreen();
  }
}
