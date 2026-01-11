import 'package:flutter/material.dart';
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

    // Use Command to add expense (handles Hive/Bloc/Server)
    await ExpenseCommand().addExpense(newExpense);

    // Scroll effect handled by reverse list usually, but if we want to ensure visibility:
    // With reverse: true, adding item puts it at bottom (index 0).
    // It should auto-animate if we are already at bottom?
    // Actually standard ListView with reverse:true sticks to bottom.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppTheme.primaryNavy,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Add Transactions"),
        centerTitle: true,
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune), // Settings slider icon
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
      ),
      body: Column(
        children: [
          // 1. Chat List Area
          Expanded(
            child: Consumer<ExpenseBloc>(
              builder: (context, bloc, child) {
                // Assuming expenses are stored chronologically (oldest -> newest)
                // We want newest at bottom. ListView(reverse: true) expects first item to be bottom.
                // So we reverse the chronological list: [newest, ..., oldest]
                final expenses = bloc.expenses.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return ChatBubble(
                      note: expense.note,
                      amount: expense.amount,
                      category: expense.category,
                      date: expense.date,
                      type: expense.type,
                    );
                  },
                );
              },
            ),
          ),

          // 2. Smart Input Area
          Consumer<ExpenseBloc>(
            builder: (context, bloc, child) {
              return SmartInputField(onSend: _addTransaction);
            },
          ),
        ],
      ),
    );
  }
}
