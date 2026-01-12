import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/bloc/app_bloc.dart';
import '../../data/bloc/expense_bloc.dart';
import '../../data/utils/statistics_helper.dart';
import '../../theme.dart';
import 'components/category_breakdown.dart';

import 'components/period_selector.dart';
import 'components/date_navigator.dart';
import 'components/comparison_chart_section.dart';
import 'components/highlight_cards_section.dart';
import 'components/deep_analysis_section.dart';
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
    // ... (rest of logic)

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
        // ... (existing AppBar)
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
            // ... (Period Selector, Date Navigator, Comparison Graphs, Highlight Cards, Deep Analysis - unchanged)
            PeriodSelector(
              selectedPeriod: _selectedPeriod,
              onChanged: (p) => setState(() => _selectedPeriod = p),
            ),
            const SizedBox(height: 16),
            DateNavigator(
              label: _formatDateRange(),
              onPrevious: () => setState(() => _adjustDate(-1)),
              onNext: () => setState(() => _adjustDate(1)),
            ),
            const SizedBox(height: 24),
            ComparisonChartSection(
              stats: stats,
              prevStats: prevStats,
              selectedPeriod: _selectedPeriod,
              chartIndex: _chartIndex,
              onToggleChart: (index) => setState(() => _chartIndex = index),
            ),
            const SizedBox(height: 24),
            HighlightCardsSection(stats: stats, currency: currency),
            const SizedBox(height: 24),
            DeepAnalysisSection(stats: stats, currency: currency),
            const SizedBox(height: 24),

            // 6. Detailed Category Breakdown (Pie + List)
            CategoryBreakdown(
              categoryStats: stats.categoryStats,
              currency: currency,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- extracted build methods for cleaner code ---
  // (Assuming existing code is largely preserved, simplified here for replacement context)

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
      // Optional: Shake or snack bar
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
}
