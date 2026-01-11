import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Row: Eye Icon & Balance ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle Visibility Button
                InkWell(
                  onTap: () => setState(() => _isVisible = !_isVisible),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      _isVisible
                          ? Icons.remove_red_eye_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.primaryNavy,
                      size: 20,
                    ),
                  ),
                ),

                // Balance Display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _isVisible ? "₹1,407" : "(¬_¬)", // The hidden face
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                        letterSpacing: _isVisible
                            ? -1
                            : 2, // Space out the face
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Current Balance",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- Graph Area ---
          SizedBox(
            height: 120,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 10,
                minY: 0,
                maxY: 6,
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 4),
                      FlSpot(2, 3),
                      FlSpot(3, 3.5),
                      FlSpot(4, 3.0),
                      FlSpot(5, 3.8),
                      FlSpot(6, 3.2),
                      FlSpot(7, 3.6),
                      FlSpot(8, 6), // The big spike
                      FlSpot(9, 3.5),
                      FlSpot(10, 3.8),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.primaryGreen,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: AppTheme.greenGraphGradient,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Expanded(child: Divider(color: AppTheme.dividerColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "Last 90 days",
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppTheme.dividerColor)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Bottom Stats Row ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem("INCOMING", "+₹15,237"),
                _buildStatItem("OUTGOING", "-₹1,50,237"),
                _buildStatItem("INVESTED", "₹1,407"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    Color labelColor = AppTheme.primaryNavy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isVisible ? value : "*****",
          style: TextStyle(
            color: labelColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
