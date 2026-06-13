import 'dart:math';

import '../data/expense/expense.dart';

class SyncMergeResult {
  final List<ExpenseData> expenses;
  final Map<String, int> tombstones;

  const SyncMergeResult({required this.expenses, required this.tombstones});
}

/// Pure per-record merge used by Drive sync — kept free of Hive/bloc
/// dependencies so it can be unit tested.
class SyncMerge {
  SyncMerge._();

  static const tombstoneRetention = Duration(days: 90);

  /// Union by id with the newer `updatedAt` winning; tombstones delete a
  /// record unless it was edited after the deletion. Records from before
  /// sync existed (`updatedAt == null`) lose to any explicit edit.
  static SyncMergeResult merge({
    required List<ExpenseData> localExpenses,
    required Map<String, int> localTombstones,
    required List<ExpenseData> remoteExpenses,
    required Map<String, int> remoteTombstones,
    required int nowMillis,
  }) {
    // Union tombstones, newest deletion wins.
    final tombstones = Map<String, int>.from(localTombstones);
    remoteTombstones.forEach((id, ts) {
      tombstones[id] = max(tombstones[id] ?? 0, ts);
    });

    // Union records by id; newer updatedAt wins.
    final byId = {for (final e in localExpenses) e.id: e};
    for (final r in remoteExpenses) {
      final local = byId[r.id];
      if (local == null || (r.updatedAt ?? 0) > (local.updatedAt ?? 0)) {
        byId[r.id] = r;
      }
    }

    // A tombstone deletes the record unless the record was edited after it.
    tombstones.forEach((id, ts) {
      final e = byId[id];
      if (e != null && ts > (e.updatedAt ?? 0)) byId.remove(id);
    });

    // Drop ancient tombstones so the backup doesn't grow forever.
    final cutoff = nowMillis - tombstoneRetention.inMilliseconds;
    tombstones.removeWhere((_, ts) => ts < cutoff);

    final merged = byId.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return SyncMergeResult(expenses: merged, tombstones: tombstones);
  }
}
