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
  /// doubles any inner quotes (RFC 4180). Fields starting with a formula
  /// trigger (= + - @ tab) are prefixed with a quote character so Excel/
  /// Sheets render them as text instead of executing them (CSV injection).
  static String _escape(String field) {
    var value = field;
    if (value.isNotEmpty && '=+-@\t\r'.contains(value[0])) {
      value = "'$value";
    }
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
