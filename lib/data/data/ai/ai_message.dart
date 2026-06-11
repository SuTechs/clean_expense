enum AiMessageRole { user, assistant }

enum AiMessageStatus { pending, done, error }

enum AiWidgetType { statCard, pie, bar, line }

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

  const AiWidgetSpec.statCard({
    required this.title,
    required String this.value,
    this.subtitle,
  }) : type = AiWidgetType.statCard,
       segments = null,
       labels = null,
       values = null;

  const AiWidgetSpec.pie({
    required this.title,
    required List<AiChartSegment> this.segments,
  }) : type = AiWidgetType.pie,
       value = null,
       subtitle = null,
       labels = null,
       values = null;

  const AiWidgetSpec.bar({
    required this.title,
    required List<String> this.labels,
    required List<double> this.values,
  }) : type = AiWidgetType.bar,
       value = null,
       subtitle = null,
       segments = null;

  const AiWidgetSpec.line({
    required this.title,
    required List<String> this.labels,
    required List<double> this.values,
  }) : type = AiWidgetType.line,
       value = null,
       subtitle = null,
       segments = null;
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
