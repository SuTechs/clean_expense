
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/command/expense/expense_command.dart';
import '../../data/data/expense/expense.dart';
import 'components/glass_app_bar.dart';
import 'components/chat_background.dart';

import 'components/smart_input_field.dart';
import 'components/transaction_list.dart';
import 'theme/chat_theme_provider.dart';

/// Main chat screen for adding and viewing transactions.
/// Wrapped with ChatThemeProvider for theme management.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  /// Navigate to ChatScreen with slide-up + fade animation
  static void animateGo(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ChatScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.15);
          const end = Offset.zero;
          final slideTween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          final fadeTween = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(
            position: animation.drive(slideTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = const Uuid();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addTransaction(
    String note,
    double amount,
    String category,
    TransactionType type,
  ) async {
    final newExpense = ExpenseData(
      id: _uuid.v4(),
      amount: amount,
      category: category.toLowerCase(),
      date: DateTime.now(),
      type: type,
      note: note,
    );

    await ExpenseCommand().addExpense(newExpense);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatThemeProvider(),
      child: Consumer<ChatThemeProvider>(
        builder: (context, themeProvider, _) {
          final theme = themeProvider.theme;
          final isDark = theme.id == 'midnight';

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Scaffold(
              body: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Stack(
                  children: [
                    // 1. Animated Background
                    Positioned.fill(child: ChatBackground(theme: theme)),

                    // 2. Main Content
                    Column(
                      children: [
                        // Fixed App Bar with glass effect
                        GlassAppBar(themeProvider: themeProvider),

                        // Scrollable Transaction List
                        Expanded(
                          child: CustomScrollView(
                            controller: _scrollController,
                            reverse: true,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: const [
                              TransactionList(),
                              SliverPadding(padding: EdgeInsets.only(top: 8)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // 3. Fixed Bottom Input Field
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SmartInputField(onSend: _addTransaction),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
