import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/bloc/app_bloc.dart';
import '../../../data/bloc/expense_bloc.dart';
import '../../../theme.dart';

class SpendingSummary extends StatelessWidget {
  const SpendingSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<ExpenseBloc>();
    final breakdown = bloc.monthlyCategoryBreakdown;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    // Calculate total amount for share-of-total percentage
    double totalAmount = 0;
    double maxAmount = 0;
    breakdown.forEach((category, amount) {
      totalAmount += amount;
      if (amount > maxAmount) maxAmount = amount;
    });

    final items = breakdown.entries.map((e) {
      return {
        'label': e.key,
        'amount': e.value,
        'percent': totalAmount > 0 ? e.value / totalAmount : 0.0,
        'visualRatio': maxAmount > 0 ? e.value / maxAmount : 0.0,
      };
    }).toList();

    // Sort items by amount descending
    items.sort(
      (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
    );

    final now = DateTime.now();
    final monthYear = DateFormat('MMM yyyy').format(now).toUpperCase();

    final appBloc = context.watch<AppBloc>();
    final showPercentage = appBloc.showPercentage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Spending Summary",
                    style: TextStyle(
                      color: AppTheme.primaryNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _showOptions(context, appBloc),
                icon: const Icon(Icons.more_horiz, color: AppTheme.primaryNavy),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthYear,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),

                if (items.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "No spending this month",
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),

                // Generate List Items
                ...items.map(
                  (item) => _buildProgressRow(
                    context,
                    item['label'] as String,
                    item['amount'] as double,
                    item['percent'] as double,
                    item['visualRatio'] as double,
                    currencyFormat,
                    showPercentage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, AppBloc appBloc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Show Value"),
                trailing: !appBloc.showPercentage
                    ? const Icon(Icons.check, color: AppTheme.accentPurple)
                    : null,
                onTap: () {
                  appBloc.showPercentage = false;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Show Percentage"),
                trailing: appBloc.showPercentage
                    ? const Icon(Icons.check, color: AppTheme.accentPurple)
                    : null,
                onTap: () {
                  appBloc.showPercentage = true;
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressRow(
    BuildContext context,
    String label,
    double amount,
    double percent,
    double visualRatio,
    NumberFormat currencyFormat,
    bool showPercentage,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth - 100; // Leave room for amount
          // Calculate the width of the background bar based on visualRatio
          final barWidth = maxWidth * visualRatio;

          return Row(
            children: [
              // The Category Name with Dynamic Background
              Expanded(
                child: Stack(
                  children: [
                    // 1. The Background Bar
                    Container(
                      width: barWidth < 60 ? 60 : barWidth,
                      // Min width to hold text if needed
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.inputFill, // Light grey from theme
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),

                    // 2. The Text
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppTheme.primaryNavy,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // The Amount or Percentage
              Text(
                showPercentage
                    ? "${(percent * 100).toStringAsFixed(0)}%"
                    : "-${currencyFormat.format(amount)}",
                style: const TextStyle(
                  color: AppTheme.primaryNavy,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
