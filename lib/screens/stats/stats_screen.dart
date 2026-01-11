import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/bloc/app_bloc.dart';
import '../../data/bloc/expense_bloc.dart';
import '../../data/utils/statistics_helper.dart';
import '../../theme.dart';
import 'components/category_pie_chart.dart';
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
            // 1. Period Selector (Day, Week, Month, Year)
            _buildPeriodSelector(),
            const SizedBox(height: 16),

            // 2. Date Navigator
            _buildDateNavigator(),
            const SizedBox(height: 24),

            // 3. Comparison Graphs (Toggleable or stacked)
            // User asked for "1st comparison is just expense... before current comparison graph or give option to toggle"
            // I'll implement a simple toggle header
            Container(
              height: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Toggle Buttons
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.inputFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildChartToggleBtn("Spending", 0),
                            _buildChartToggleBtn("Overview", 1),
                          ],
                        ),
                      ),

                      // Legend (Dynamic)
                      Row(
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
                  const SizedBox(height: 24),
                  Expanded(
                    child: _chartIndex == 0
                        ? ExpenseLineChart(
                            currentData: stats.getGraphData(),
                            previousData: prevStats.getGraphData(),
                            isWeekly: _selectedPeriod == 'W',
                          )
                        : PeriodComparisonChart(
                            currentIncome: stats.totalIncome,
                            previousIncome: prevStats.totalIncome,
                            currentExpense: stats.totalSpending,
                            previousExpense: prevStats.totalSpending,
                            currentSavings: stats.totalSaved,
                            previousSavings: prevStats.totalSaved,
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Highlight Cards (Income vs Expense)
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
            // Savings Card
            _buildHighlightCard(
              "Total Savings",
              stats.totalSaved,
              AppTheme.accentPurple,
              currency,
              Icons.savings_outlined,
              fullWidth: true,
            ),

            const SizedBox(height: 24),

            // 5. Analysis Grid (10+ Sections Mix)
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

            _buildAnalysisTile(
              "Savings Rate",
              "${stats.savingsRate.toStringAsFixed(1)}%",
              "Of total income",
              Icons.percent_rounded,
              AppTheme.primaryGreen,
            ),

            _buildAnalysisTile(
              "Cash Flow",
              stats.cashFlowStatus,
              stats.totalIncome > stats.totalSpending
                  ? "Healthy"
                  : "Attention needed",
              Icons.monitor_heart_outlined,
              stats.totalIncome > stats.totalSpending
                  ? AppTheme.primaryGreen
                  : Colors.red,
            ),

            _buildAnalysisTile(
              "Total Invested",
              "$currency${stats.totalInvested.toStringAsFixed(0)}",
              "For future growth",
              Icons.show_chart_rounded,
              AppTheme.accentPurple,
            ),

            const SizedBox(height: 24),

            // 6. Pie
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Category Distribution",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  SizedBox(height: 24),
                  CategoryPieChart(categoryStats: stats.categoryStats),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 7. Detailed Category Breakdown (New - Progress Bar Style)
            Text(
              "Category Details",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),

            // Replicating Spending Summary Style
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  if (stats.categoryStats.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("No expenses for this period"),
                    )
                  else
                    ...stats.categoryStats.map((cat) {
                      // Find max for visual ratio?
                      // stats.categoryStats is typically sorted by amount, so first is max.
                      double max = 0;
                      if (stats.categoryStats.isNotEmpty) {
                        max = stats.categoryStats.first.totalAmount;
                      }
                      double visualRatio = max == 0 ? 0 : cat.totalAmount / max;

                      return _buildCategoryProgressRow(
                        cat,
                        currency,
                        visualRatio,
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods ---

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

  Widget _buildCategoryProgressRow(
    CategoryStat stat,
    String currency,
    double visualRatio,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth - 100; // room for amount
          final barWidth = maxWidth * visualRatio;

          return Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // Background Bar
                    Container(
                      width: barWidth < 60 ? 60 : barWidth,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.inputFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Content
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            stat.category,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryNavy,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$currency${stat.totalAmount.toStringAsFixed(0)}",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  Text(
                    "${(stat.percent * 100).toStringAsFixed(1)}%",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
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
}
