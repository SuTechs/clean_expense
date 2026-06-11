import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/data/ai/ai_message.dart';
import '../../../theme.dart';

const _palette = [
  AppTheme.accentBlue,
  AppTheme.primaryGreen,
  AppTheme.accentPurple,
  Color(0xFFF2994A), // orange
  AppTheme.dangerRed,
  AppTheme.primaryNavyLight,
];

/// Renders the gen-UI payload of an assistant message.
class AiWidgetRenderer extends StatelessWidget {
  final AiWidgetSpec spec;

  const AiWidgetRenderer({super.key, required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spec.title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          switch (spec.type) {
            AiWidgetType.statCard => _StatCard(spec: spec),
            AiWidgetType.pie => _Pie(spec: spec),
            AiWidgetType.bar => _Bar(spec: spec),
            AiWidgetType.line => _Line(spec: spec),
          },
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final AiWidgetSpec spec;
  const _StatCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spec.value ?? '',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNavy,
          ),
        ),
        if (spec.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            spec.subtitle!,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _Pie extends StatelessWidget {
  final AiWidgetSpec spec;
  const _Pie({required this.spec});

  @override
  Widget build(BuildContext context) {
    final segments = spec.segments ?? const [];
    if (segments.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 28,
              sections: [
                for (var i = 0; i < segments.length; i++)
                  PieChartSectionData(
                    value: segments[i].value,
                    color: _palette[i % _palette.length],
                    radius: 30,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < segments.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '#${segments[i].label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${(segments[i].percent * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final AiWidgetSpec spec;
  const _Bar({required this.spec});

  @override
  Widget build(BuildContext context) {
    final values = spec.values ?? const [];
    final labels = spec.labels ?? const [];
    if (values.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[i],
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                    color: AppTheme.accentBlue,
                  ),
                ],
              ),
          ],
          barTouchData: const BarTouchData(enabled: false),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final AiWidgetSpec spec;
  const _Line({required this.spec});

  @override
  Widget build(BuildContext context) {
    final values = spec.values ?? const [];
    final labels = spec.labels ?? const [];
    if (values.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length || labels[i].isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[i],
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i]),
              ],
              isCurved: true,
              curveSmoothness: 0.3,
              barWidth: 2.5,
              color: AppTheme.primaryGreen,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
