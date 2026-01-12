import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/utils/statistics_helper.dart';
import '../../../data/utils/string_utils.dart';
import '../../../theme.dart';
import 'analysis_tile.dart';

class DeepAnalysisSection extends StatelessWidget {
  final StatisticsHelper stats;
  final String currency;

  const DeepAnalysisSection({
    super.key,
    required this.stats,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
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

        AnalysisTile(
          title: "Top Spending Category",
          value: stats.topCategory != null
              ? StringUtils.titleCase(stats.topCategory!.key)
              : "N/A",
          subtitle: stats.topCategory != null
              ? "$currency${stats.topCategory!.value.toStringAsFixed(0)}"
              : "",
          icon: Icons.category_rounded,
          color: Colors.orangeAccent,
        ),

        AnalysisTile(
          title: "Daily Average Spend",
          value: "$currency${stats.averageDailySpend.toStringAsFixed(0)}",
          subtitle: "Per active day",
          icon: Icons.calendar_today_rounded,
          color: Colors.blueAccent,
        ),

        AnalysisTile(
          title: "Largest Single Expense",
          value: stats.largestSingleExpense?.note.isNotEmpty == true
              ? StringUtils.titleCase(stats.largestSingleExpense!.note)
              : (stats.largestSingleExpense != null
                    ? StringUtils.titleCase(
                        stats.largestSingleExpense!.category,
                      )
                    : "N/A"),
          subtitle: stats.largestSingleExpense != null
              ? "$currency${stats.largestSingleExpense!.amount.toStringAsFixed(0)}"
              : "",
          icon: Icons.local_offer_rounded,
          color: Colors.redAccent,
        ),

        AnalysisTile(
          title: "Most Frequent Category",
          value: stats.mostFrequentCategory != null
              ? StringUtils.titleCase(stats.mostFrequentCategory!)
              : "N/A",
          subtitle: "By transaction count",
          icon: Icons.repeat_rounded,
          color: Colors.purpleAccent,
        ),

        AnalysisTile(
          title: "Busiest Day",
          value: stats.highestSpendingDayOfWeek,
          subtitle: "Highest spending day",
          icon: Icons.calendar_view_week_rounded,
          color: Colors.teal,
        ),
      ],
    );
  }
}
