enum AiMessageRole { user, assistant }

enum AiMessageStatus { pending, done, error }

enum AiWidgetType { statCard, pie, bar, line, transactionList }

class AiChartSegment {
  final String label;
  final double value;
  final double percent;

  const AiChartSegment({
    required this.label,
    required this.value,
    required this.percent,
  });
}

/// One row of a transaction-list widget, pre-formatted by the executor.
class AiTransactionRow {
  final String title;
  final String subtitle;

  /// Pre-signed, pre-formatted amount, e.g. "-₹500" / "+₹50,000".
  final String amount;
  final bool isIncome;

  const AiTransactionRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
  });
}

/// Generative-UI payload attached to an assistant message. Built entirely by
/// app code from computed stats — never by the model.
class AiWidgetSpec {
  final AiWidgetType type;
  final String title;

  // statCard
  final String? value;
  final String? subtitle;

  // pie
  final List<AiChartSegment>? segments;

  // bar / line
  final List<String>? labels;
  final List<double>? values;

  // transactionList
  final List<AiTransactionRow>? rows;

  const AiWidgetSpec.statCard({
    required this.title,
    required String this.value,
    this.subtitle,
  }) : type = AiWidgetType.statCard,
       segments = null,
       labels = null,
       values = null,
       rows = null;

  const AiWidgetSpec.pie({
    required this.title,
    required List<AiChartSegment> this.segments,
  }) : type = AiWidgetType.pie,
       value = null,
       subtitle = null,
       labels = null,
       values = null,
       rows = null;

  const AiWidgetSpec.bar({
    required this.title,
    required List<String> this.labels,
    required List<double> this.values,
  }) : type = AiWidgetType.bar,
       value = null,
       subtitle = null,
       segments = null,
       rows = null;

  const AiWidgetSpec.line({
    required this.title,
    required List<String> this.labels,
    required List<double> this.values,
  }) : type = AiWidgetType.line,
       value = null,
       subtitle = null,
       segments = null,
       rows = null;

  const AiWidgetSpec.transactionList({
    required this.title,
    required List<AiTransactionRow> this.rows,
  }) : type = AiWidgetType.transactionList,
       value = null,
       subtitle = null,
       segments = null,
       labels = null,
       values = null;
}

class AiMessage {
  final String id;
  final AiMessageRole role;
  final String text;
  final AiWidgetSpec? widget;
  final AiMessageStatus status;

  const AiMessage({
    required this.id,
    required this.role,
    required this.text,
    this.widget,
    this.status = AiMessageStatus.done,
  });

  AiMessage copyWith({
    String? text,
    AiWidgetSpec? widget,
    AiMessageStatus? status,
  }) {
    return AiMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      widget: widget ?? this.widget,
      status: status ?? this.status,
    );
  }
}
