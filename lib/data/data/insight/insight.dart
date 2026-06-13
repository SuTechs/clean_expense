/// A model-free "your money" message shown in the chat thread. Generated
/// deterministically from StatisticsHelper (no AI model needed), persisted
/// in its own lightweight JSON feed, and NEVER added to ExpenseData or the
/// Drive backup.
enum InsightKind { dailyRecap, categoryMilestone, topCategoryWeek, savings }

/// One labelled bar in an insight's mini chart (fraction is 0..1 of the max).
class InsightBar {
  final String label;
  final double fraction;

  const InsightBar(this.label, this.fraction);

  Map<String, dynamic> toJson() => {'l': label, 'f': fraction};

  factory InsightBar.fromJson(Map<String, dynamic> json) => InsightBar(
    json['l'] as String? ?? '',
    (json['f'] as num?)?.toDouble() ?? 0,
  );
}

class InsightData {
  final String id;
  final int createdAt; // epoch millis
  final InsightKind kind;
  final String text;
  final List<InsightBar> bars;
  final String? category;

  const InsightData({
    required this.id,
    required this.createdAt,
    required this.kind,
    required this.text,
    this.bars = const [],
    this.category,
  });

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(createdAt);

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt,
    'kind': kind.name,
    'text': text,
    if (bars.isNotEmpty) 'bars': bars.map((b) => b.toJson()).toList(),
    if (category != null) 'category': category,
  };

  factory InsightData.fromJson(Map<String, dynamic> json) => InsightData(
    id: json['id'] as String,
    createdAt: json['createdAt'] as int,
    kind: InsightKind.values.firstWhere(
      (k) => k.name == json['kind'],
      orElse: () => InsightKind.dailyRecap,
    ),
    text: json['text'] as String? ?? '',
    bars:
        (json['bars'] as List?)
            ?.map((e) => InsightBar.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    category: json['category'] as String?,
  );
}
