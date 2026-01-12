import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/bloc/app_bloc.dart';
import '../../data/bloc/expense_bloc.dart';
import '../../data/data/expense/expense.dart';
import '../../theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = "";
  TransactionType? _selectedType;
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final expenseBloc = context.watch<ExpenseBloc>();
    final appBloc = context.watch<AppBloc>();
    final currencyFormat = NumberFormat.currency(
      symbol: appBloc.currency,
      decimalDigits: 0,
    );

    final filteredExpenses = expenseBloc.expenses.where((e) {
      final matchesSearch =
          e.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _selectedType == null || e.type == _selectedType;
      final matchesDate =
          _selectedDateRange == null ||
          (e.date.isAfter(_selectedDateRange!.start) &&
              e.date.isBefore(
                _selectedDateRange!.end.add(const Duration(days: 1)),
              ));

      return matchesSearch && matchesType && matchesDate;
    }).toList();

    // Group expenses by month and year
    final groupedExpenses = <String, List<ExpenseData>>{};
    for (var e in filteredExpenses) {
      final key = DateFormat('MMMM yyyy').format(e.date);
      groupedExpenses.putIfAbsent(key, () => []).add(e);
    }

    final monthKeys = groupedExpenses.keys.toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.primaryNavy,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Transactions",
          style: GoogleFonts.outfit(
            color: AppTheme.primaryNavy,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month_rounded,
              color: _selectedDateRange != null
                  ? AppTheme.accentPurple
                  : AppTheme.primaryNavy,
            ),
            onPressed: _showDateRangePicker,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.inputFill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.outfit(color: AppTheme.primaryNavy),
                decoration: InputDecoration(
                  hintText: "Search transactions...",
                  hintStyle: GoogleFonts.outfit(
                    color: AppTheme.primaryNavy,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryNavy,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(null, "All"),
                _buildFilterChip(TransactionType.incoming, "Incoming"),
                _buildFilterChip(TransactionType.outgoing, "Outgoing"),
                _buildFilterChip(TransactionType.invested, "Invested"),
              ],
            ),
          ),

          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentPurple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDateRange = null),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppTheme.accentPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Transactions List
          Expanded(
            child: filteredExpenses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: monthKeys.length,
                    itemBuilder: (context, monthIndex) {
                      final monthKey = monthKeys[monthIndex];
                      final monthExpenses = groupedExpenses[monthKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  monthKey,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryNavy,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  "${monthExpenses.length} transactions",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...monthExpenses.map(
                            (e) => _buildTransactionItem(e, currencyFormat),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(TransactionType? type, String label) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = isSelected ? null : type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryNavy : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: AppTheme.primaryNavy.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(ExpenseData e, NumberFormat format) {
    final isIncome = e.type == TransactionType.incoming;
    final isInvestment = e.type == TransactionType.invested;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  (isIncome
                          ? AppTheme.primaryGreen
                          : (isInvestment
                                ? AppTheme.accentPurple
                                : AppTheme.textSecondary))
                      .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome
                  ? Icons.add_rounded
                  : (isInvestment
                        ? Icons.trending_up_rounded
                        : Icons.remove_rounded),
              color: isIncome
                  ? AppTheme.primaryGreen
                  : (isInvestment
                        ? AppTheme.accentPurple
                        : AppTheme.primaryNavy),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.note.isEmpty ? e.category : e.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${DateFormat('dd MMM yyyy').format(e.date)} • ${e.category}",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isIncome ? "+" : "-"}${format.format(e.amount)}",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isIncome
                      ? AppTheme.primaryGreen
                      : AppTheme.primaryNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: AppTheme.inputFill,
          ),
          const SizedBox(height: 16),
          Text(
            "No transactions found",
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    final expenses = context.read<ExpenseBloc>().expenses;
    final firstDate = expenses.isEmpty
        ? DateTime.now()
        : expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryNavy,
              onPrimary: Colors.white,
              onSurface: AppTheme.primaryNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }
}
