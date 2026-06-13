import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/data/expense/expense.dart';
import '../../../theme.dart';

/// Danger confirmation sheet for deleting a transaction.
/// Returns true when the user confirms the deletion.
class DeleteTransactionSheet {
  DeleteTransactionSheet._();

  static Future<bool?> show(
    BuildContext context,
    ExpenseData expense,
    String currency,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Delete this transaction?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _TransactionSummary(expense: expense, currency: currency),
              const SizedBox(height: 12),
              const Text(
                "This can't be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text("Delete"),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TransactionSummary extends StatelessWidget {
  final ExpenseData expense;
  final String currency;

  const _TransactionSummary({required this.expense, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.note.isEmpty ? "#${expense.category}" : expense.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "#${expense.category} · ${DateFormat('MMM d, h:mm a').format(expense.date)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "$currency${expense.amount % 1 == 0 ? expense.amount.toStringAsFixed(0) : expense.amount}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}
