import '../../data/expense/expense.dart';

/// Builds RFC-4180 compliant CSV from transactions. Pure function so it can
/// run in an isolate via `compute()`.
class CsvExporter {
  CsvExporter._();

  static String buildCsv(List<ExpenseData> expenses) {
    final buffer = StringBuffer('id,date,type,category,amount,note\r\n');

    for (final e in expenses) {
      buffer.writeAll([
        _escape(e.id),
        _escape(e.date.toIso8601String()),
        _escape(e.type.name),
        _escape(e.category),
        _escape(
          e.amount % 1 == 0 ? e.amount.toStringAsFixed(0) : e.amount.toString(),
        ),
        _escape(e.note),
      ], ',');
      buffer.write('\r\n');
    }

    return buffer.toString();
  }

  /// Quotes a field when it contains a comma, quote or line break and
  /// doubles any inner quotes (RFC 4180).
  static String _escape(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
