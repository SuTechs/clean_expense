import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/utils/statistics_helper.dart';
import '../../../theme.dart';

class CategoryPieChart extends StatefulWidget {
  final List<CategoryStat> categoryStats;

  const CategoryPieChart({super.key, required this.categoryStats});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryStats.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    final sections = _generatingSections();

    return Row(
      children: [
        // 1. The Chart
        SizedBox(
          height: 180,
          width: 180,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(width: 24),

        // 2. The Legend (Custom List) - Limit to top 5
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.categoryStats.take(5).toList().asMap().entries.map(
              (e) {
                final index = e.key;
                final stat = e.value;
                final color = _getColor(index);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _buildLegendItem(
                    color,
                    stat.category,
                    "${(stat.percent * 100).toStringAsFixed(1)}%",
                  ),
                );
              },
            ).toList(),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generatingSections() {
    return List.generate(widget.categoryStats.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 0.0;
      final radius = isTouched ? 60.0 : 50.0;
      final stat = widget.categoryStats[i];
      final color = _getColor(i);

      return PieChartSectionData(
        color: color,
        value: stat.percent * 100,
        title: '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLegendItem(Color color, String label, String percent) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppTheme.primaryNavy,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          percent,
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getColor(int index) {
    const colors = [
      AppTheme.primaryNavy,
      AppTheme.primaryGreen,
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.teal,
      Colors.blueAccent,
    ];
    return colors[index % colors.length];
  }
}
