
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/bloc/app_bloc.dart';
import '../../data/command/expense/expense_command.dart';
import '../../data/data/expense/expense.dart';
import 'components/glass_app_bar.dart';
import 'components/chat_background.dart';

import 'components/delete_transaction_sheet.dart';
import 'components/selection_app_bar.dart';
import 'components/smart_input_field.dart';
import 'components/transaction_list.dart';
import 'state/chat_interaction_provider.dart';
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
  final ChatInteractionProvider _interaction = ChatInteractionProvider();

  @override
  void dispose() {
    _scrollController.dispose();
    _interaction.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(
    String note,
    double amount,
    String category,
    TransactionType type,
  ) async {
    final editing = _interaction.editing;
    if (editing != null) {
      // copyWith keeps id and date, so the bubble stays at its original
      // place in history and stats periods are unaffected.
      final updated = editing.copyWith(
        note: note,
        amount: amount,
        category: category.toLowerCase(),
        type: type,
      );

      await ExpenseCommand().updateExpense(updated);
      _interaction.cancelEditing();
      return;
    }

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

  Future<void> _deleteSelected() async {
    final expense = _interaction.selected;
    if (expense == null) return;

    final currency = context.read<AppBloc>().currency;
    final confirmed = await DeleteTransactionSheet.show(
      context,
      expense,
      currency,
    );
    if (confirmed != true) return;

    try {
      await ExpenseCommand().deleteExpense(expense.id);
      // Clear selection only after the delete sticks: on failure the
      // command rolls the expense back and it should stay selected.
      _interaction.onExpenseDeleted(expense.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete transaction: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatThemeProvider()),
        ChangeNotifierProvider.value(value: _interaction),
      ],
      child: Consumer2<ChatThemeProvider, ChatInteractionProvider>(
        builder: (context, themeProvider, interaction, _) {
          final theme = themeProvider.theme;
          final isDark = theme.id == 'midnight';

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: PopScope(
              // Back press first clears selection / cancels edit, then pops.
              canPop: !interaction.hasSelection && !interaction.isEditing,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                if (_interaction.isEditing) {
                  _interaction.cancelEditing();
                } else {
                  _interaction.clearSelection();
                }
              },
              child: Scaffold(
                body: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    _interaction.clearSelection();
                  },
                  child: Stack(
                    children: [
                      // 1. Animated Background
                      Positioned.fill(child: ChatBackground(theme: theme)),

                      // 2. Main Content
                      Column(
                        children: [
                          // Fixed App Bar with glass effect; swaps to the
                          // contextual bar while a bubble is selected
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: interaction.hasSelection
                                ? SelectionAppBar(
                                    key: const ValueKey('selection'),
                                    theme: theme,
                                    onClose: _interaction.clearSelection,
                                    onEdit: _interaction.startEditing,
                                    onDelete: _deleteSelected,
                                  )
                                : GlassAppBar(
                                    key: const ValueKey('default'),
                                    themeProvider: themeProvider,
                                  ),
                          ),

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
                                SliverPadding(
                                  padding: EdgeInsets.only(top: 8),
                                ),
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
                        child: SmartInputField(onSend: _handleSubmit),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
