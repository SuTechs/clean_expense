import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/data/expense/expense.dart';
import '../../data/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // To show chat history/preview
  final List<Map<String, dynamic>> _messages = [
    {"isUser": false, "text": "Hi Sumit! How much did you spend?"},
  ];

  void _processInput(String input) {
    if (input.trim().isEmpty) return;

    setState(() {
      _messages.add({"isUser": true, "text": input});
    });

    _controller.clear();

    // Parse Logic
    // Pattern: #Category Amount (or Amount #Category)
    // Example: #Food 240

    // Simple parser
    double? amount;
    String? category;

    final parts = input.split(' ');
    for (var part in parts) {
      if (part.startsWith('#')) {
        category = part.substring(1);
      } else {
        final parsed = double.tryParse(part);
        if (parsed != null) {
          amount = parsed;
        }
      }
    }

    if (amount != null) {
      // Default category if missing
      category ??= "General";

      // Capitalize first letter
      category =
          category[0].toUpperCase() + category.substring(1).toLowerCase();

      // Add to Provider
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      provider.addExpense(
        amount: amount,
        category: category,
        type: TransactionType.outgoing, // Default to outgoing/expense for now
        // Could enable "Credit" keyword parsing too
        note: input, // Save raw input as note
      );

      // Bot response
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _messages.add({
            "isUser": false,
            "text":
                "Got it! Recorded ₹${amount!.toStringAsFixed(0)} for $category.",
          });
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });

        // Close sheet after brief delay? Or keep open for more?
        // Let's keep open for "Chat with friends" feel.
      });
    } else {
      // Error / Clarification
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _messages.add({
            "isUser": false,
            "text": "I didn't catch the amount. Try saying '#Food 100'.",
          });
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      });
    }
    // Scroll to bottom
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
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Expense",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Chat Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;
                  final text = msg['text'] as String;
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isUser
                              ? const Radius.circular(16)
                              : const Radius.circular(4),
                          bottomRight: isUser
                              ? const Radius.circular(4)
                              : const Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        text,
                        style: GoogleFonts.outfit(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input Area
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "Type #Category Amount...",
                            border: InputBorder.none,
                            hintStyle: GoogleFonts.outfit(color: Colors.grey),
                          ),
                          onSubmitted: _processInput,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: const Color(0xFF6C63FF),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => _processInput(_controller.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
