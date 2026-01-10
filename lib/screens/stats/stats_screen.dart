import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/expense_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final theme = Theme.of(context);

    final categoryStats = provider.categoryBreakdown;
    final totalOutgoing = provider.totalOutgoing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Spending Stats",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: categoryStats.isEmpty
          ? Center(
              child: Text(
                "No expenses yet",
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Pie Chart Configuration
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: _generateSections(
                          categoryStats,
                          totalOutgoing,
                        ),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Detailed List
                  ...categoryStats.entries.map(
                    (e) {
                      final percentage = totalOutgoing == 0
                          ? 0.0
                          : (e.value / totalOutgoing);
                      final color = _getColorForCategory(e.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: color,
                                      radius: 6,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      e.key,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "₹${e.value.toStringAsFixed(0)}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey.shade200,
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "${(percentage * 100).toStringAsFixed(1)}%",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ), // .toList() is not needed with spread operator if usage is correct, but map returns Iterable.
                ],
              ),
            ),
    );
  }

  List<PieChartSectionData> _generateSections(
    Map<String, double> stats,
    double total,
  ) {
    return stats.entries.map((e) {
      final percentage = total == 0 ? 0.0 : (e.value / total);
      final color = _getColorForCategory(e.key);
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '${(percentage * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getColorForCategory(String category) {
    // Deterministic colors based on string hash or simple logic
    final colors = [
      Color(0xFF6C63FF),
      Color(0xFF00C853),
      Color(0xFFFFD600),
      Color(0xFFE53935),
      Color(0xFF29B6F6),
      Color(0xFFAB47BC),
      Color(0xFFFF7043),
    ];
    return colors[category.hashCode.abs() % colors.length];
  }
}
