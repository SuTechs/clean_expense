import 'package:flutter/material.dart';

import '../../../theme.dart';

class SpendingSummary extends StatelessWidget {
  const SpendingSummary({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data
    final List<Map<String, dynamic>> items = [
      {'label': 'Personal', 'amount': 28468, 'percent': 0.8}, // 80% width
      {'label': 'Food & Drinks', 'amount': 1689, 'percent': 0.15},
      {'label': 'Groceries', 'amount': 368, 'percent': 0.05},
      {'label': 'Subscription', 'amount': 79, 'percent': 0.02},
      {'label': 'Untagged', 'amount': 57905, 'percent': 1.0}, // Max width
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
              Icon(Icons.more_horiz, color: AppTheme.primaryNavy),
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
                const Text(
                  "JAN 2026",
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),

                // Generate List Items
                ...items.map(
                  (item) => _buildProgressRow(
                    context,
                    item['label'],
                    item['amount'],
                    item['percent'],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
    BuildContext context,
    String label,
    int amount,
    double percent,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          // Calculate the width of the background bar based on percentage
          // Min width 0, Max width = parent width
          final barWidth = maxWidth * percent;

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

              // The Amount
              Text(
                "-₹${amount.toString()}",
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
