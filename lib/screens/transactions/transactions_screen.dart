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

    // Sort by date descending
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
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
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search notes or categories...",
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary,
                ),
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.accentPurple,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _selectedDateRange = null),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppTheme.accentPurple,
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
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final e = filteredExpenses[index];
                      return _buildTransactionItem(e, currencyFormat);
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedType = selected ? type : null);
        },
        selectedColor: AppTheme.primaryNavy,
        labelStyle: GoogleFonts.outfit(
          color: isSelected ? Colors.white : AppTheme.primaryNavy,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildTransactionItem(ExpenseData e, NumberFormat format) {
    final isIncome = e.type == TransactionType.incoming;
    final isInvestment = e.type == TransactionType.invested;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  (isIncome
                          ? AppTheme.primaryGreen
                          : (isInvestment
                                ? AppTheme.accentPurple
                                : AppTheme.primaryNavy))
                      .withOpacity(0.1),
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
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.note.isEmpty ? e.category : e.note,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                Text(
                  "${DateFormat('dd MMM yyyy').format(e.date)} • ${e.category}",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            "${isIncome ? "+" : "-"}${format.format(e.amount)}",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: isIncome ? AppTheme.primaryGreen : AppTheme.primaryNavy,
            ),
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
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
