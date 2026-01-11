import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';

class PeriodComparisonChart extends StatelessWidget {
  final double currentIncome;
  final double previousIncome;
  final double currentExpense;
  final double previousExpense;
  final double currentSavings;
  final double previousSavings;

  const PeriodComparisonChart({
    super.key,
    required this.currentIncome,
    required this.previousIncome,
    required this.currentExpense,
    required this.previousExpense,
    required this.currentSavings,
    required this.previousSavings,
  });

  @override
  Widget build(BuildContext context) {
    // Find max value for normalization
    final maxValue = [
      currentIncome,
      previousIncome,
      currentExpense,
      previousExpense,
      currentSavings,
      previousSavings,
    ].fold(0.0, (p, c) => c > p ? c : p);

    final maxY = maxValue * 1.2; // Add some buffer

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 100 : maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (group) => AppTheme.cardBackground,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final val = rod.toY;
              return BarTooltipItem(
                val.toStringAsFixed(0),
                GoogleFonts.outfit(
                  color: AppTheme.primaryNavy,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return _buildLabel("Income");
                  case 1:
                    return _buildLabel("Expense");
                  case 2:
                    return _buildLabel("Savings");
                  default:
                    return const SizedBox();
                }
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _buildGroup(0, currentIncome, previousIncome, AppTheme.primaryGreen),
          _buildGroup(1, currentExpense, previousExpense, Colors.redAccent),
          _buildGroup(
            2,
            currentSavings,
            previousSavings,
            AppTheme.accentPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BarChartGroupData _buildGroup(
    int x,
    double current,
    double previous,
    Color color,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        // Previous Period Bar (Lighter/Greyed)
        BarChartRodData(
          toY: previous,
          color: color.withOpacity(0.3),
          width: 12,
          borderRadius: BorderRadius.circular(4),
        ),
        // Current Period Bar (Full Color)
        BarChartRodData(
          toY: current,
          color: color,
          width: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
      barsSpace: 8,
    );
  }
}
