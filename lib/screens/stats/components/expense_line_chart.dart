import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme.dart';

class ExpenseLineChart extends StatelessWidget {
  final List<double> currentData;
  final List<double> previousData;
  final bool isWeekly; // To optimize labels if needed

  const ExpenseLineChart({
    super.key,
    required this.currentData,
    required this.previousData,
    this.isWeekly = false,
  });

  @override
  Widget build(BuildContext context) {
    // Normalize logic
    final allValues = [...currentData, ...previousData];
    double maxY = allValues.isNotEmpty
        ? allValues.reduce((a, b) => a > b ? a : b)
        : 0;
    if (maxY == 0) maxY = 100;
    maxY *= 1.2;

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => AppTheme.cardBackground,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                return LineTooltipItem(
                  flSpot.y.toStringAsFixed(0),
                  const TextStyle(
                    color: AppTheme.primaryNavy,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ), // Keep it clean for multiple periods
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (currentData.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          // Previous Period (Greyed out)
          LineChartBarData(
            spots: previousData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value);
            }).toList(),
            isCurved: true,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Current Period (Colored)
          LineChartBarData(
            spots: currentData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value);
            }).toList(),
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.redAccent.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
