import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/command/commands.dart';
import 'screens/main_screen.dart';
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
    // final isAuthenticated = context.select(
    //   (AppBloc bloc) => bloc.isAuthenticated,
    // );
    //
    // final isSignupCompleted = context.select(
    //   (AppBloc bloc) => bloc.isSignUpCompleted,
    // );

    // final showOnboarding = context.read<AppBloc>().isShowOnboarding;

    // // User has completed signup process
    // if (isSignupCompleted) return const Home();

    // User is authenticated but has not completed onboarding
    // if (showOnboarding) return const OnboardingScreen();

    // // User is not authenticated
    // return const LoginScreen();

    return const MainScreen();
  }
}
