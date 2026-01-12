import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';
import '../../../data/utils/statistics_helper.dart';
import '../../../data/utils/string_utils.dart';

class CategoryBreakdown extends StatefulWidget {
  final List<CategoryStat> categoryStats;
  final String currency;

  const CategoryBreakdown({
    super.key,
    required this.categoryStats,
    required this.currency,
  });

  @override
  State<CategoryBreakdown> createState() => _CategoryBreakdownState();
}

class _CategoryBreakdownState extends State<CategoryBreakdown> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: Text("No expenses for this period")),
      );
    }

    return Container(
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
              const Text(
                "Category Distribution",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryNavy,
                ),
              ),
              if (_touchedIndex != -1)
                GestureDetector(
                  onTap: () => setState(() => _touchedIndex = -1),
                  child: Text(
                    "Clear Selection",
                    style: GoogleFonts.outfit(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),

          // 1. Interactive Pie Chart (Centered & Large)
          SizedBox(
            height: 220, // Increased height
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      if (event is FlTapUpEvent) {
                        setState(() => _touchedIndex = -1);
                      }
                      return;
                    }
                    final index =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                    if (event is FlTapUpEvent && index >= 0) {
                      setState(() => _touchedIndex = index);
                    }
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 50, // Larger donut hole
                sections: _generatingSections(),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 2. Detailed Category List with Color Indicators
          ...widget.categoryStats.asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value;
            final isSelected = _touchedIndex == index;
            final color = _getColor(index);

            // Calculate max for visual ratio
            double max = widget.categoryStats.first.totalAmount;
            double visualRatio = max == 0 ? 0 : cat.totalAmount / max;

            return GestureDetector(
              onTap: () =>
                  setState(() => _touchedIndex = isSelected ? -1 : index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(isSelected ? 12 : 0),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.inputFill : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(
                          color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                        )
                      : null,
                ),
                child: _buildCategoryRow(
                  cat,
                  widget.currency,
                  visualRatio,
                  isSelected,
                  color,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    CategoryStat stat,
    String currency,
    double visualRatio,
    bool isSelected,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Available width for the bar
          // Subtract indicator (12+12) + Amount text (~80)
          final maxWidth = constraints.maxWidth - 120;
          final barWidth = maxWidth * visualRatio;

          return Row(
            children: [
              // Color Indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Bar & Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StringUtils.titleCase(stat.category),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryNavy,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Progress Bar
                    Container(
                      height: 8,
                      width: barWidth < 10 ? 10 : barWidth,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 8,
                        width: isSelected
                            ? barWidth
                            : 0, // Animate fill on select? Or just keep it static sized?
                        // User said "animate it better".
                        // Maybe keeps static size but highlights.
                        // Let's make the background opaque on select.
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Amount & Percent
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

  List<PieChartSectionData> _generatingSections() {
    return List.generate(widget.categoryStats.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 70.0 : 60.0;
      final stat = widget.categoryStats[i];
      final color = _getColor(i);

      return PieChartSectionData(
        color: color,
        value: stat.percent * 100,
        title: '${(stat.percent * 100).toStringAsFixed(0)}%',
        titlePositionPercentageOffset: 0.55,
        radius: radius,
        titleStyle: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.9),
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 2),
          ],
        ),
      );
    });
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
      Colors.indigoAccent,
      Colors.pinkAccent,
      Colors.brown,
    ];
    return colors[index % colors.length];
  }
}
