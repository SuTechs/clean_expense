import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/hive/service_extension.dart';
import '../../data/insight/insight.dart';
import '../../utils/ai/insight_generator.dart';
import '../commands.dart';

/// Owns the persisted "your money" insight feed. Insights are generated
/// model-free from the user's data, at most one per day, pruned to a recent
/// window, and stored locally (never synced).
class InsightCommand extends BaseAppCommand {
  static const _maxFeed = 30;

  /// Loads the persisted feed into the bloc at bootstrap.
  void hydrate() {
    insightBloc.setFeed(_load());
  }

  /// Generates today's insight if one is due (nothing already created today
  /// and the generator finds something worth saying), then persists.
  Future<void> maybeGenerate({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final feed = _load();

    if (feed.any((i) => _sameDay(i.date, at))) return;

    final insight = InsightGenerator.generate(
      expenses: expenseBloc.expenses,
      now: at,
      currency: appBloc.currency,
    );
    if (insight == null) return;

    final updated = [...feed, insight];
    updated.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final pruned = updated.length > _maxFeed
        ? updated.sublist(updated.length - _maxFeed)
        : updated;

    insightBloc.setFeed(pruned);
    await hive.setInsightsFeed(
      jsonEncode(pruned.map((i) => i.toJson()).toList()),
    );
  }

  List<InsightData> _load() {
    final raw = hive.getInsightsFeed;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => InsightData.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('InsightCommand._load: $e');
      return const [];
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
