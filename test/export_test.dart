import 'dart:io';

import 'package:expense/data/data/expense/expense.dart';
import 'package:expense/data/utils/export/csv_exporter.dart';
import 'package:expense/data/utils/export/pdf_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

ExpenseData _expense({
  String id = 'id-1',
  double amount = 500,
  String category = 'food',
  TransactionType type = TransactionType.outgoing,
  String note = 'dinner',
}) => ExpenseData(
  id: id,
  amount: amount,
  category: category,
  date: DateTime(2026, 6, 1, 12, 30),
  type: type,
  note: note,
);

void main() {
  group('CsvExporter', () {
    test('builds header and rows', () {
      final csv = CsvExporter.buildCsv([_expense()]);
      final lines = csv.trim().split('\r\n');
      expect(lines.first, 'id,date,type,category,amount,note');
      expect(lines[1], 'id-1,2026-06-01T12:30:00.000,outgoing,food,500,dinner');
    });

    test('escapes commas, quotes and newlines per RFC 4180', () {
      final csv = CsvExporter.buildCsv([
        _expense(note: 'pizza, extra "cheese"\nwith friends'),
      ]);
      expect(csv, contains('"pizza, extra ""cheese""\nwith friends"'));
    });

    test('handles emoji and unicode notes', () {
      final csv = CsvExporter.buildCsv([_expense(note: 'café ☕ 🍕')]);
      expect(csv, contains('café ☕ 🍕'));
    });

    test('neutralizes formula injection in notes', () {
      final csv = CsvExporter.buildCsv([
        _expense(note: '=HYPERLINK("http://evil","x")'),
      ]);
      // Prefixed with a quote so spreadsheets treat it as text.
      expect(csv, contains("'=HYPERLINK"));
      expect(csv, isNot(contains(',=HYPERLINK')));
    });
  });

  group('PdfExporter', () {
    test('builds a valid PDF with ₹/€ currency and many rows', () async {
      final regular = File(
        'assets/fonts/Inter-Regular.ttf',
      ).readAsBytesSync();
      final bold = File('assets/fonts/Inter-Bold.ttf').readAsBytesSync();

      final expenses = [
        for (var i = 0; i < 200; i++)
          _expense(
            id: 'id-$i',
            amount: 100.0 + i,
            category: i % 3 == 0 ? 'food' : 'transport',
            type: TransactionType.values[i % 3],
            note: 'note $i with € symbol',
          ),
      ];

      final bytes = await PdfExporter.buildPdf(
        PdfExportInput(
          expenses: expenses,
          periodLabel: 'June 2026',
          generatedOn: 'Jun 11, 2026',
          currency: '₹',
          regularFont: regular,
          boldFont: bold,
        ),
      );

      expect(bytes.length, greaterThan(1000));
      // %PDF magic header
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('handles an empty expense list', () async {
      final regular = File(
        'assets/fonts/Inter-Regular.ttf',
      ).readAsBytesSync();
      final bold = File('assets/fonts/Inter-Bold.ttf').readAsBytesSync();

      final bytes = await PdfExporter.buildPdf(
        PdfExportInput(
          expenses: const [],
          periodLabel: 'All time',
          generatedOn: 'Jun 11, 2026',
          currency: r'$',
          regularFont: regular,
          boldFont: bold,
        ),
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
