import 'package:flutter/material.dart';

import '../../theme.dart';
import 'components/chat_bubble.dart';
import 'components/smart_input_field.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Dummy Initial Data
  final List<ChatBubble> _messages = [
    ChatBubble(
      note: "Salary Credited",
      amount: 45000,
      category: "salary",
      date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      type: TransactionType.income,
    ),
    ChatBubble(
      note: "Lunch at KFC",
      amount: 540,
      category: "food",
      date: DateTime.now().subtract(const Duration(hours: 4)),
      type: TransactionType.expense,
    ),
  ];

  final ScrollController _scrollController = ScrollController();

  void _addTransaction(
    String note,
    double amount,
    String category,
    TransactionType type,
  ) {
    setState(() {
      _messages.add(
        ChatBubble(
          note: note,
          amount: amount,
          category: category,
          date: DateTime.now(),
          type: type,
        ),
      );
    });

    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
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
              // TODO: Open Category Manager
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Chat List Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 20, top: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                // Show Date Header if needed logic here...
                return _messages[index];
              },
            ),
          ),

          // 2. Smart Input Area
          SmartInputField(onSend: _addTransaction),
        ],
      ),
    );
  }
}
