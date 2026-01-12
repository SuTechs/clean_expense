import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/utils/statistics_helper.dart';
import '../../../theme.dart';
import 'expense_line_chart.dart';
import 'period_comparison_chart.dart';
import 'chart_toggle_btn.dart';

class ComparisonChartSection extends StatelessWidget {
  final StatisticsHelper stats;
  final StatisticsHelper prevStats;
  final String selectedPeriod; // 'W' for weekly check
  final int chartIndex;
  final ValueChanged<int> onToggleChart;

  const ComparisonChartSection({
    super.key,
    required this.stats,
    required this.prevStats,
    required this.selectedPeriod,
    required this.chartIndex,
    required this.onToggleChart,
  });

  @override
  Widget build(BuildContext context) {
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
                          ChartToggleBtn(
                            label: "Spending",
                            isSelected: chartIndex == 0,
                            onTap: () => onToggleChart(0),
                          ),
                          ChartToggleBtn(
                            label: "Overview",
                            isSelected: chartIndex == 1,
                            onTap: () => onToggleChart(1),
                          ),
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
                      chartIndex == 0
                          ? Colors.redAccent
                          : AppTheme.primaryGreen,
                      "Current",
                    ),
                    const SizedBox(width: 12),
                    _buildLegendDot(
                      AppTheme.textSecondary.withValues(alpha: 0.3),
                      "Previous",
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: chartIndex == 0
                ? ExpenseLineChart(
                    currentData: stats.getGraphData(),
                    previousData: prevStats.getGraphData(),
                    isWeekly: selectedPeriod == 'W',
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
}
