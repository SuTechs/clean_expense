import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/bloc/expense_bloc.dart';
import '../../data/command/export/export_command.dart';
import '../../data/data/expense/expense.dart';
import '../../theme.dart';

enum _ExportPeriod { thisMonth, lastMonth, last3Months, thisYear, all, custom }

enum _ExportFormat { csv, pdf }

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  _ExportPeriod _period = _ExportPeriod.thisMonth;
  DateTimeRange? _customRange;
  TransactionType? _type;
  _ExportFormat _format = _ExportFormat.pdf;
  bool _isExporting = false;

  /// Key on the export button so the iPad share popover can anchor to it.
  final GlobalKey _exportButtonKey = GlobalKey();

  DateTimeRange? get _range {
    final now = DateTime.now();
    switch (_period) {
      case _ExportPeriod.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case _ExportPeriod.lastMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0),
        );
      case _ExportPeriod.last3Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: now,
        );
      case _ExportPeriod.thisYear:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case _ExportPeriod.all:
        return null;
      case _ExportPeriod.custom:
        return _customRange;
    }
  }

  String get _periodLabel {
    final range = _range;
    final now = DateTime.now();
    switch (_period) {
      case _ExportPeriod.thisMonth:
        return DateFormat('MMMM yyyy').format(now);
      case _ExportPeriod.lastMonth:
        return DateFormat(
          'MMMM yyyy',
        ).format(DateTime(now.year, now.month - 1, 1));
      case _ExportPeriod.last3Months:
        return 'Last 3 months';
      case _ExportPeriod.thisYear:
        return '${now.year}';
      case _ExportPeriod.all:
        return 'All time';
      case _ExportPeriod.custom:
        if (range == null) return 'Custom range';
        final fmt = DateFormat('MMM d, yyyy');
        return '${fmt.format(range.start)} – ${fmt.format(range.end)}';
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = _ExportPeriod.custom;
      });
    }
  }

  Future<void> _export(List<ExpenseData> expenses) async {
    if (_isExporting || expenses.isEmpty) return;
    setState(() => _isExporting = true);

    final command = ExportCommand();
    final label = command.fileLabel(_range);

    // Anchor the iPad share popover to the export button.
    Rect? origin;
    final box =
        _exportButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }

    try {
      switch (_format) {
        case _ExportFormat.csv:
          await command.exportCsv(
            expenses: expenses,
            fileLabel: label,
            sharePositionOrigin: origin,
          );
          break;
        case _ExportFormat.pdf:
          await command.exportPdf(
            expenses: expenses,
            periodLabel: _periodLabel,
            fileLabel: label,
            sharePositionOrigin: origin,
          );
          break;
      }
    } catch (e) {
      _showError("Export failed: $e");
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _saveToDevice(List<ExpenseData> expenses) async {
    if (_isExporting || expenses.isEmpty) return;
    setState(() => _isExporting = true);

    final command = ExportCommand();

    try {
      final path = await command.saveToDevice(
        expenses: expenses,
        asPdf: _format == _ExportFormat.pdf,
        periodLabel: _periodLabel,
        fileLabel: command.fileLabel(_range),
      );
      // Null means the user cancelled the save dialog — not an error.
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("File saved"),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError("Save failed: $e");
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.dangerRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild the live count when transactions change.
    context.watch<ExpenseBloc>();
    final expenses = ExportCommand().filterExpenses(
      range: _range,
      type: _type,
    );

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          "Export Data",
          style: GoogleFonts.outfit(
            color: AppTheme.primaryNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.primaryNavy,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _sectionLabel("PERIOD"),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _periodChip("This month", _ExportPeriod.thisMonth),
              _periodChip("Last month", _ExportPeriod.lastMonth),
              _periodChip("Last 3 months", _ExportPeriod.last3Months),
              _periodChip("This year", _ExportPeriod.thisYear),
              _periodChip("All time", _ExportPeriod.all),
              _customRangeChip(),
            ],
          ),
          const SizedBox(height: 24),
          _sectionLabel("TYPE"),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _typeChip("All", null),
              _typeChip("Expense", TransactionType.outgoing),
              _typeChip("Income", TransactionType.incoming),
              _typeChip("Invest", TransactionType.invested),
            ],
          ),
          const SizedBox(height: 24),
          _sectionLabel("FORMAT"),
          Row(
            children: [
              Expanded(
                child: _formatCard(
                  _ExportFormat.pdf,
                  Icons.picture_as_pdf_rounded,
                  "PDF Report",
                  "Branded summary + tables",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _formatCard(
                  _ExportFormat.csv,
                  Icons.table_chart_rounded,
                  "CSV",
                  "Opens in Excel / Sheets",
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              expenses.isEmpty
                  ? "No transactions in this selection"
                  : "${expenses.length} transaction${expenses.length == 1 ? '' : 's'} · $_periodLabel",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: _exportButtonKey,
              onPressed: expenses.isEmpty || _isExporting
                  ? null
                  : () => _export(expenses),
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.ios_share_rounded, size: 20),
              label: Text(
                _isExporting
                    ? "Preparing…"
                    : "Share ${_format == _ExportFormat.pdf ? 'PDF' : 'CSV'}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: expenses.isEmpty || _isExporting
                  ? null
                  : () => _saveToDevice(expenses),
              icon: const Icon(Icons.save_alt_rounded, size: 20),
              label: const Text(
                "Save to device",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryNavy,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryNavy : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryNavy : AppTheme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(String label, _ExportPeriod period) {
    return _chip(
      label: label,
      selected: _period == period,
      onTap: () => setState(() => _period = period),
    );
  }

  Widget _customRangeChip() {
    final selected = _period == _ExportPeriod.custom;
    return _chip(
      label: selected ? _periodLabel : "Custom",
      selected: selected,
      icon: Icons.calendar_month_rounded,
      onTap: _pickCustomRange,
    );
  }

  Widget _typeChip(String label, TransactionType? type) {
    return _chip(
      label: label,
      selected: _type == type,
      onTap: () => setState(() => _type = type),
    );
  }

  Widget _formatCard(
    _ExportFormat format,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final selected = _format == format;
    return GestureDetector(
      onTap: () => setState(() => _format = format),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryNavy : AppTheme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 26,
              color: selected ? AppTheme.primaryNavy : AppTheme.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
