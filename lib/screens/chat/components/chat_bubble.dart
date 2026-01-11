import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme.dart';

enum TransactionType { expense, income, investment }

class ChatBubble extends StatelessWidget {
  final String note;
  final double amount;
  final String category;
  final DateTime date;
  final TransactionType type;

  const ChatBubble({
    super.key,
    required this.note,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isUser =
        type == TransactionType.expense || type == TransactionType.investment;

    // Style configurations based on Type
    final backgroundColor = type == TransactionType.income
        ? const Color(0xFFD1FAE5) // Light Green
        : const Color(0xFFFFE4E6); // Light Red

    final textColor = type == TransactionType.income
        ? const Color(0xFF065F46) // Dark Green
        : const Color(0xFF9F1239); // Dark Red

    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
            topRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Note
            if (note.isNotEmpty)
              Text(
                note,
                style: TextStyle(
                  color: AppTheme.primaryNavy,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),

            const SizedBox(height: 4),

            // Tag
            Text(
              "#$category",
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Amount
            Text(
              "${type == TransactionType.income ? '+' : ''}₹${amount.toStringAsFixed(0)}",
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),

            const SizedBox(height: 4),

            // Time
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('h:mm a').format(date),
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
