import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/data/expense/expense.dart';
import '../../data/expense_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final theme = Theme.of(context);

    // Dummy data for chart if empty, real data otherwise
    // Implementation details for chart to follow expense history

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildBalanceCard(context, provider),
              const SizedBox(height: 24),
              _buildSpendingSummaryHeader(context),
              const SizedBox(height: 16),
              _buildTransactionList(context, provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFE0E0FF),
              child: Text(
                "S",
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              // In real app, load user image or avatar
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sumit",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "9+ unread updates",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.black87,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.book_outlined, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, ExpenseProvider provider) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.remove_red_eye_outlined,
                size: 20,
                color: Color(0xFF3F3D56),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormatter.format(provider.totalBalance),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  Text(
                    "Balance",
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Chart Placeholder
          SizedBox(
            height: 120, // Reduced height for cleaner look
            child: LineChart(_mainData(provider)),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                "INCOMING",
                provider.totalIncoming,
                Colors.grey.shade600,
              ),
              _buildStatItem(
                "OUTGOING",
                provider.totalOutgoing,
                Colors.grey.shade600,
              ),
              _buildStatItem(
                "INVESTED",
                provider.totalInvested,
                Colors.grey.shade600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          amount > 0
              ? "+${currencyFormatter.format(amount)}"
              : currencyFormatter.format(amount),
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingSummaryHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.pie_chart_outline, size: 20, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              "Recent Transactions",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(
                  0xFF6C63F8,
                ).withOpacity(0.8), // Using a variation of primary
              ),
            ),
          ],
        ),
        Icon(Icons.more_horiz, color: Colors.grey),
      ],
    );
  }

  Widget _buildTransactionList(BuildContext context, ExpenseProvider provider) {
    final expenses = provider.expenses.take(10).toList();
    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "No transactions yet.\nAdd one with the + button!",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return _buildTransactionItem(expense);
      },
    );
  }

  Widget _buildTransactionItem(Expense expense) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    );
    final isNegative =
        expense.type == TransactionType.outgoing ||
        expense.type == TransactionType.invested;
    final color = isNegative ? const Color(0xFF2D2D2D) : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: const Color(0xFF3F3D56),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                if (expense.note.isNotEmpty)
                  Text(
                    expense.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Text(
            "${isNegative ? '-' : '+'}${currencyFormatter.format(expense.amount)}",
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('food')) return Icons.restaurant;
    if (cat.contains('drink')) return Icons.local_cafe;
    if (cat.contains('travel') || cat.contains('transport'))
      return Icons.directions_car;
    if (cat.contains('shop')) return Icons.shopping_bag;
    if (cat.contains('bill')) return Icons.receipt;
    if (cat.contains('invest')) return Icons.trending_up;
    return Icons.category;
  }

  LineChartData _mainData(ExpenseProvider provider) {
    // Generate some points based on history or dummy if empty
    // For simplicity, using dummy trend or flattened history

    // Creating a mock trend for visualization if real data is sparse
    List<FlSpot> spots = [
      const FlSpot(0, 3),
      const FlSpot(1, 1),
      const FlSpot(2, 4),
      const FlSpot(3, 2),
      const FlSpot(4, 5),
      const FlSpot(5, 1),
      const FlSpot(6, 4),
    ];

    // If we have expenses, we could map them. But for "clean UI" demo, keeping it smooth.
    // In real app, map provider.expenses to spots.

    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        show: false, // Clean look
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true, // Smooth curves
          color: const Color(0xFF00C853), // Green graph
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            // gradient: LinearGradient(
            //   colors: [
            //     const Color(0xFF00C853).withOpacity(0.2),
            //     const Color(0xFF00C853).withOpacity(0.0),
            //   ],
            //   begin: Alignment.topCenter,
            //   end: Alignment.bottomCenter,
            // ),
            color: const Color(0xFF00C853).withOpacity(0.1),
          ),
        ),
      ],
    );
  }
}
