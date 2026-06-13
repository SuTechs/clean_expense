import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange, Rect;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/expense/expense.dart';
import '../../utils/export/csv_exporter.dart';
import '../../utils/export/pdf_exporter.dart';
import '../commands.dart';

class ExportCommand extends BaseAppCommand {
  /// Filters the in-memory expenses by an inclusive day range and optional
  /// type, newest first (same predicate shape as the transactions screen).
  List<ExpenseData> filterExpenses({
    DateTimeRange? range,
    TransactionType? type,
  }) {
    DateTime? start, endExclusive;
    if (range != null) {
      start = DateTime(range.start.year, range.start.month, range.start.day);
      endExclusive = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
      ).add(const Duration(days: 1));
    }

    return expenseBloc.expenses.where((e) {
        final matchesType = type == null || e.type == type;
        final matchesDate =
            range == null ||
            (!e.date.isBefore(start!) && e.date.isBefore(endExclusive!));
        return matchesType && matchesDate;
      }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// File-name label for the exported file, e.g. "2026-06-01_2026-06-30".
  String fileLabel(DateTimeRange? range) {
    final day = DateFormat('yyyy-MM-dd');
    if (range == null) return 'all_${day.format(DateTime.now())}';
    return '${day.format(range.start)}_${day.format(range.end)}';
  }

  Future<void> exportCsv({
    required List<ExpenseData> expenses,
    required String fileLabel,
    Rect? sharePositionOrigin,
  }) async {
    debugPrint('ExportCommand.exportCsv: building ${expenses.length} rows');
    final csv = await compute(CsvExporter.buildCsv, expenses);
    final file = await _writeTempFile(
      'clean_expense_$fileLabel.csv',
      utf8.encode(csv),
    );
    debugPrint('ExportCommand.exportCsv: wrote ${file.path}, sharing');

    await _shareFile(file.path, 'text/csv', sharePositionOrigin);
  }

  Future<void> exportPdf({
    required List<ExpenseData> expenses,
    required String periodLabel,
    required String fileLabel,
    Rect? sharePositionOrigin,
  }) async {
    // Fonts must be loaded before the isolate hop — rootBundle is
    // unavailable inside compute().
    final regular = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Inter-Bold.ttf');

    final input = PdfExportInput(
      expenses: expenses,
      periodLabel: periodLabel,
      generatedOn: DateFormat('MMM d, yyyy').format(DateTime.now()),
      currency: appBloc.currency,
      regularFont: regular.buffer.asUint8List(),
      boldFont: bold.buffer.asUint8List(),
    );

    debugPrint('ExportCommand.exportPdf: building ${expenses.length} rows');
    final bytes = await compute(PdfExporter.buildPdf, input);
    final file = await _writeTempFile('clean_expense_$fileLabel.pdf', bytes);
    debugPrint('ExportCommand.exportPdf: wrote ${file.path}, sharing');

    await _shareFile(file.path, 'application/pdf', sharePositionOrigin);
  }

  /// Opens the share sheet. The result future resolves when the user picks
  /// an action or dismisses the sheet — but some OEM share sheets never
  /// report back, so don't let the caller's spinner hang on it forever.
  Future<void> _shareFile(
    String path,
    String mimeType,
    Rect? sharePositionOrigin,
  ) async {
    final result = await SharePlus.instance
        .share(
          ShareParams(
            files: [XFile(path, mimeType: mimeType)],
            sharePositionOrigin: sharePositionOrigin,
          ),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => const ShareResult(
            'timed out waiting for share sheet',
            ShareResultStatus.unavailable,
          ),
        );
    debugPrint('ExportCommand._shareFile: share result ${result.status}');
  }

  /// Builds the export and opens the system "save file" dialog (SAF on
  /// Android, document picker on iOS) so the user picks a visible location
  /// like Downloads. Returns the saved path, or null when cancelled.
  Future<String?> saveToDevice({
    required List<ExpenseData> expenses,
    required bool asPdf,
    required String periodLabel,
    required String fileLabel,
  }) async {
    final Uint8List bytes;
    final String name;

    if (asPdf) {
      final regular = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
      final bold = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
      bytes = await compute(
        PdfExporter.buildPdf,
        PdfExportInput(
          expenses: expenses,
          periodLabel: periodLabel,
          generatedOn: DateFormat('MMM d, yyyy').format(DateTime.now()),
          currency: appBloc.currency,
          regularFont: regular.buffer.asUint8List(),
          boldFont: bold.buffer.asUint8List(),
        ),
      );
      name = 'clean_expense_$fileLabel.pdf';
    } else {
      final csv = await compute(CsvExporter.buildCsv, expenses);
      bytes = Uint8List.fromList(utf8.encode(csv));
      name = 'clean_expense_$fileLabel.csv';
    }

    debugPrint('ExportCommand.saveToDevice: opening save dialog for $name');
    final path = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(data: bytes, fileName: name),
    );
    debugPrint('ExportCommand.saveToDevice: saved to $path');
    return path;
  }

  Future<File> _writeTempFile(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    return file.writeAsBytes(bytes, flush: true);
  }
}
