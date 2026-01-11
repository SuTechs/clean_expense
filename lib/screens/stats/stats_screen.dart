import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/bloc/app_bloc.dart';
import '../../data/bloc/expense_bloc.dart';
import '../../data/utils/statistics_helper.dart';
import '../../theme.dart';
import 'components/category_breakdown.dart';
import 'components/expense_line_chart.dart';
import 'components/period_comparison_chart.dart';
import 'export_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = "M"; // D, W, M, Y
  DateTime _currentDate = DateTime.now();
  int _chartIndex =
      0; // 0 = Bar Logic (Income/Ex/Sav), 1 = Line Logic (Trending)

  @override
  Widget build(BuildContext context) {
    final expenseBloc = context.watch<ExpenseBloc>();
    final appBloc = context.watch<AppBloc>();
    final currency = NumberFormat.simpleCurrency(
      name: appBloc.currency,
    ).currencySymbol;

    // Helper for Current Period
    final stats = StatisticsHelper(
      expenseBloc.expenses,
      period: _selectedPeriod,
      referenceDate: _currentDate,
    );
    // ... (rest of logic)

    // Helper for Previous Period (Comparison)
    final prevDate = _getPreviousDate();
    final prevStats = StatisticsHelper(
      expenseBloc.expenses,
      period: _selectedPeriod,
      referenceDate: prevDate,
    );

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        // ... (existing AppBar)
        title: Text(
          "Statistics",
          style: GoogleFonts.outfit(
            color: AppTheme.primaryNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            color: AppTheme.primaryNavy,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExportScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (Period Selector, Date Navigator, Comparison Graphs, Highlight Cards, Deep Analysis - unchanged)
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            _buildDateNavigator(),
            const SizedBox(height: 24),
            _buildComparisonChart(stats, prevStats),
            const SizedBox(height: 24),
            _buildHighlightCards(stats, currency),
            const SizedBox(height: 24),
            _buildDeepAnalysis(stats, currency),
            const SizedBox(height: 24),

            // 6. Detailed Category Breakdown (Pie + List)
            CategoryBreakdown(
              categoryStats: stats.categoryStats,
              currency: currency,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- extracted build methods for cleaner code ---
  // (Assuming existing code is largely preserved, simplified here for replacement context)

  Widget _buildComparisonChart(
    StatisticsHelper stats,
    StatisticsHelper prevStats,
  ) {
    // ... existing Comparison Chart Container code ...
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 10,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildChartToggleBtn("Spending", 0),
                          _buildChartToggleBtn("Overview", 1),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildLegendDot(
                      _chartIndex == 0
                          ? Colors.redAccent
                          : AppTheme.primaryGreen,
                      "Current",
                    ),
                    const SizedBox(width: 12),
                    _buildLegendDot(
                      AppTheme.textSecondary.withOpacity(0.3),
                      "Previous",
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _chartIndex == 0
                ? ExpenseLineChart(
                    currentData: stats.getGraphData(),
                    previousData: prevStats.getGraphData(),
                    isWeekly: _selectedPeriod == 'W',
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PeriodComparisonChart(
                      currentIncome: stats.totalIncome,
                      previousIncome: prevStats.totalIncome,
                      currentExpense: stats.totalSpending,
                      previousExpense: prevStats.totalSpending,
                      currentSavings: stats.totalSaved,
                      previousSavings: prevStats.totalSaved,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHighlightCards(StatisticsHelper stats, String currency) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHighlightCard(
                "Income",
                stats.totalIncome,
                AppTheme.primaryGreen,
                currency,
                Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHighlightCard(
                "Expense",
                stats.totalSpending,
                Colors.redAccent,
                currency,
                Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildHighlightCard(
          "Total Savings",
          stats.totalSaved,
          AppTheme.accentPurple,
          currency,
          Icons.savings_outlined,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildDeepAnalysis(StatisticsHelper stats, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Deep Analysis",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNavy,
          ),
        ),
        const SizedBox(height: 16),

        _buildAnalysisTile(
          "Top Spending Category",
          stats.topCategory?.key ?? "N/A",
          stats.topCategory != null
              ? "$currency${stats.topCategory!.value.toStringAsFixed(0)}"
              : "",
          Icons.category_rounded,
          Colors.orangeAccent,
        ),
        // ... Add back all other tiles here if needed, or just keep them inline.
        // For brevity in THIS replace block, I am re-structuring the build method
        // heavily. It might be better to keep the inline calls if I don't want to re-copy all tiles.
        // Let's assume for this specific edit I am REPLACING the whole body.
        _buildAnalysisTile(
          "Daily Average Spend",
          "$currency${stats.averageDailySpend.toStringAsFixed(0)}",
          "Per active day",
          Icons.calendar_today_rounded,
          Colors.blueAccent,
        ),

        _buildAnalysisTile(
          "Largest Single Expense",
          stats.largestSingleExpense?.note.isNotEmpty == true
              ? stats.largestSingleExpense!.note
              : (stats.largestSingleExpense?.category ?? "N/A"),
          stats.largestSingleExpense != null
              ? "$currency${stats.largestSingleExpense!.amount.toStringAsFixed(0)}"
              : "",
          Icons.local_offer_rounded,
          Colors.redAccent,
        ),

        _buildAnalysisTile(
          "Most Frequent Category",
          stats.mostFrequentCategory ?? "N/A",
          "By transaction count",
          Icons.repeat_rounded,
          Colors.purpleAccent,
        ),

        _buildAnalysisTile(
          "Busiest Day",
          stats.highestSpendingDayOfWeek,
          "Highest spending day",
          Icons.calendar_view_week_rounded,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildAnalysisTile(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ), // Darker label
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: AppTheme.primaryNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ), // Darker label
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard(
    String title,
    double amount,
    Color color,
    String currency,
    IconData icon, {
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fullWidth ? color.withOpacity(0.1) : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: fullWidth ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (fullWidth)
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!fullWidth)
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600, // Bolder
                color: AppTheme.textSecondary, // Removed opacity
              ),
            ),
          if (!fullWidth) const SizedBox(height: 4),
          Text(
            "$currency${NumberFormat.currency(symbol: '', decimalDigits: 0).format(amount)}",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDateNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => setState(() => _adjustDate(-1)),
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: AppTheme.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatDateRange(),
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryNavy,
            ),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _adjustDate(1)),
          icon: const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
  // --- Restored Helper Methods ---

  Widget _buildChartToggleBtn(String label, int index) {
    final isSelected = _chartIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _chartIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  DateTime _getPreviousDate() {
    if (_selectedPeriod == 'D') {
      return _currentDate.subtract(const Duration(days: 1));
    } else if (_selectedPeriod == 'W') {
      return _currentDate.subtract(const Duration(days: 7));
    } else if (_selectedPeriod == 'M') {
      return DateTime(
        _currentDate.year,
        _currentDate.month - 1,
        _currentDate.day,
      );
    } else if (_selectedPeriod == 'Y') {
      return DateTime(
        _currentDate.year - 1,
        _currentDate.month,
        _currentDate.day,
      );
    }
    return _currentDate;
  }

  void _adjustDate(int delta) {
    DateTime newDate = _currentDate;
    if (_selectedPeriod == 'D') {
      newDate = _currentDate.add(Duration(days: delta));
    } else if (_selectedPeriod == 'W') {
      newDate = _currentDate.add(Duration(days: delta * 7));
    } else if (_selectedPeriod == 'M') {
      newDate = DateTime(
        _currentDate.year,
        _currentDate.month + delta,
        _currentDate.day,
      );
    } else if (_selectedPeriod == 'Y') {
      newDate = DateTime(
        _currentDate.year + delta,
        _currentDate.month,
        _currentDate.day,
      );
    }

    // Prevent future dates
    if (newDate.isAfter(DateTime.now())) {
      // Optional: Shake or snackbar
      return;
    }
    _currentDate = newDate;
  }

  String _formatDateRange() {
    if (_selectedPeriod == 'D') {
      return DateFormat('d MMM yyyy').format(_currentDate);
    } else if (_selectedPeriod == 'W') {
      final startOfWeek = _currentDate.subtract(
        Duration(days: _currentDate.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return "${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM').format(endOfWeek)}";
    } else if (_selectedPeriod == 'M') {
      return DateFormat('MMMM yyyy').format(_currentDate);
    } else if (_selectedPeriod == 'Y') {
      return DateFormat('yyyy').format(_currentDate);
    }
    return "All Time";
  }

  Widget _buildPeriodSelector() {
    final periods = ["D", "W", "M", "Y"];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: periods.map((p) {
          final isSelected = _selectedPeriod == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.cardBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  p,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppTheme.primaryNavy
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
