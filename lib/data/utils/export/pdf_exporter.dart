import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/expense/expense.dart';

/// Everything [PdfExporter.buildPdf] needs, bundled so the build can hop to
/// an isolate via `compute()`. Font bytes must be loaded with rootBundle
/// BEFORE the isolate hop (rootBundle is unavailable in isolates).
class PdfExportInput {
  final List<ExpenseData> expenses;
  final String periodLabel;
  final String generatedOn;
  final String currency;
  final Uint8List regularFont;
  final Uint8List boldFont;

  const PdfExportInput({
    required this.expenses,
    required this.periodLabel,
    required this.generatedOn,
    required this.currency,
    required this.regularFont,
    required this.boldFont,
  });
}

/// Builds the branded PDF report. Pure function — safe for `compute()`.
class PdfExporter {
  PdfExporter._();

  static const _navy = PdfColor.fromInt(0xFF2D3250);
  static const _green = PdfColor.fromInt(0xFF2ECC71);
  static const _grey = PdfColor.fromInt(0xFF9095A1);
  static const _zebra = PdfColor.fromInt(0xFFF3F4F7);

  static Future<Uint8List> buildPdf(PdfExportInput input) async {
    final base = pw.Font.ttf(ByteData.sublistView(input.regularFont));
    final bold = pw.Font.ttf(ByteData.sublistView(input.boldFont));

    double income = 0, spending = 0, invested = 0;
    final byCategory = <String, double>{};
    for (final e in input.expenses) {
      switch (e.type) {
        case TransactionType.incoming:
          income += e.amount;
          break;
        case TransactionType.outgoing:
          spending += e.amount;
          byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
          break;
        case TransactionType.invested:
          invested += e.amount;
          break;
      }
    }
    final categoryRows = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final dateFormat = DateFormat('MMM d, yyyy');
    final amountFormat = NumberFormat('#,##0.##');
    String money(double v) => '${input.currency}${amountFormat.format(v)}';

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: base, bold: bold),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: _grey),
          ),
        ),
        build: (context) => [
          _header(input),
          pw.SizedBox(height: 20),
          _summaryRow(
            money: money,
            income: income,
            spending: spending,
            invested: invested,
            saved: income - spending,
          ),
          pw.SizedBox(height: 24),
          _sectionTitle('Transactions (${input.expenses.length})'),
          pw.SizedBox(height: 8),
          _transactionsTable(input, dateFormat, money),
          if (categoryRows.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            _sectionTitle('Spending by category'),
            pw.SizedBox(height: 8),
            _categoryTable(categoryRows, spending, money),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(PdfExportInput input) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Clean Expense',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Expense Report · ${input.periodLabel}',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          pw.Text(
            'Generated ${input.generatedOn}',
            style: pw.TextStyle(
              color: PdfColors.white.shade(0.3),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow({
    required String Function(double) money,
    required double income,
    required double spending,
    required double invested,
    required double saved,
  }) {
    pw.Widget cell(String label, double value, PdfColor color) {
      return pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 4),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _zebra,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: const pw.TextStyle(fontSize: 9, color: _grey),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                money(value),
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        cell('Income', income, _green),
        cell('Spending', spending, _navy),
        cell('Invested', invested, _navy),
        cell('Saved', saved, saved >= 0 ? _green : const PdfColor.fromInt(0xFFEB5757)),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: _navy,
      ),
    );
  }

  static String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.incoming:
        return 'Income';
      case TransactionType.outgoing:
        return 'Expense';
      case TransactionType.invested:
        return 'Invest';
    }
  }

  static pw.Widget _transactionsTable(
    PdfExportInput input,
    DateFormat dateFormat,
    String Function(double) money,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Type', 'Category', 'Note', 'Amount'],
      data: [
        for (final e in input.expenses)
          [
            dateFormat.format(e.date),
            _typeLabel(e.type),
            '#${e.category}',
            e.note,
            money(e.amount),
          ],
      ],
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(color: _navy),
      oddRowDecoration: const pw.BoxDecoration(color: _zebra),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(1.6),
        1: const pw.FlexColumnWidth(1.1),
        2: const pw.FlexColumnWidth(1.4),
        3: const pw.FlexColumnWidth(2.6),
        4: const pw.FlexColumnWidth(1.3),
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      border: null,
    );
  }

  static pw.Widget _categoryTable(
    List<MapEntry<String, double>> rows,
    double totalSpending,
    String Function(double) money,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: ['Category', 'Amount', 'Share'],
      data: [
        for (final entry in rows)
          [
            '#${entry.key}',
            money(entry.value),
            totalSpending > 0
                ? '${(entry.value / totalSpending * 100).toStringAsFixed(1)}%'
                : '-',
          ],
      ],
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(color: _navy),
      oddRowDecoration: const pw.BoxDecoration(color: _zebra),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      border: null,
    );
  }
}
