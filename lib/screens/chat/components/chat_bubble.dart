import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/data/expense/expense.dart';
import '../../../../theme.dart';

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
    // Logic:
    // Income -> Incoming Money -> Left Alignment (Like receiving a message)
    // Expense -> Outgoing Money -> Right Alignment (Like sending a message)
    // Investment -> Asset Building -> Right Alignment (User action) but distinct style

    final isIncoming = type == TransactionType.incoming;
    final alignment = isIncoming ? Alignment.centerLeft : Alignment.centerRight;

    // Colors
    Color bubbleColor;
    Color textColor;
    Color amountColor;

    switch (type) {
      case TransactionType.incoming:
        bubbleColor = Colors.white;
        textColor = AppTheme.primaryNavy;
        amountColor = AppTheme.primaryGreen;
        break;
      case TransactionType.outgoing:
        bubbleColor = AppTheme.primaryNavy;
        textColor = Colors.white;
        amountColor = Colors.white;
        break;
      case TransactionType.invested:
        bubbleColor = AppTheme.accentPurple; // Distinct purple for investing
        textColor = Colors.white;
        amountColor = Colors.white;
        break;
    }

    final borderRadius = isIncoming
        ? const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount and Category Row
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "${type == TransactionType.incoming
                      ? '+'
                      : type == TransactionType.outgoing
                      ? '-'
                      : ''}₹${amount.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isIncoming
                        ? AppTheme.primaryNavy.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "#$category",
                    style: TextStyle(
                      color: isIncoming
                          ? AppTheme.primaryNavy.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            if (note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 4),

            // Time
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('h:mm a').format(date),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
