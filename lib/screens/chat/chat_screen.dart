import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/bloc/expense_bloc.dart';
import '../../data/command/expense/expense_command.dart';
import '../../data/data/expense/expense.dart';
import '../../theme.dart';
import '../category/manage_category_screen.dart';
import 'components/chat_bubble.dart';
import 'components/smart_input_field.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = const Uuid();

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(context),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.scaffoldBackground, // Start with your theme bg
                Color(0xFFEFF1F5), // Very subtle darker shift at bottom
              ],
            ),
          ),
          child: Column(
            children: [
              // 1. CHAT AREA
              Expanded(
                child: Consumer<ExpenseBloc>(
                  builder: (context, bloc, child) {
                    final expenses = bloc.expenses.toList()
                      ..sort((a, b) => b.date.compareTo(a.date));

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 20,
                      ),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        final isLastItem = index == expenses.length - 1;

                        bool showDateHeader = false;
                        if (isLastItem) {
                          showDateHeader = true;
                        } else {
                          final nextExpense = expenses[index + 1];
                          if (!_isSameDay(expense.date, nextExpense.date)) {
                            showDateHeader = true;
                          }
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showDateHeader) _buildDateHeader(expense.date),
                            ChatBubble(
                              note: expense.note,
                              amount: expense.amount,
                              category: expense.category,
                              date: expense.date,
                              type: expense.type,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // 2. INPUT AREA (Suggestions + Field)
              // We pass the list of existing categories to the input field for auto-complete
              Consumer<ExpenseBloc>(
                builder: (context, bloc, child) {
                  // Extract unique category names from existing expenses for suggestions
                  final categories = bloc.expenses
                      .map((e) => e.category)
                      .toSet()
                      .toList();

                  return SmartInputField(onSend: _addTransaction);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.scaffoldBackground,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18), // Smaller icon
        color: AppTheme.primaryNavy,
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Add Transactions",
        style: TextStyle(
          color: AppTheme.primaryNavy,
          fontSize: 17, // Smaller font
          fontWeight: FontWeight.w600, // Less bold (was bold/w700)
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 22),
          color: AppTheme.primaryNavy,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageCategoryScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = "Today";
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = "Yesterday";
    } else {
      label = DateFormat('MMMM d, y').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6), // Glassy look
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
