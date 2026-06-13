import 'package:expense/data/data/expense/expense.dart';
import 'package:expense/data/utils/sync_merge.dart';
import 'package:flutter_test/flutter_test.dart';

ExpenseData _expense(String id, {int? updatedAt, String note = 'note'}) =>
    ExpenseData(
      id: id,
      amount: 100,
      category: 'food',
      date: DateTime(2026, 6, 1),
      type: TransactionType.outgoing,
      note: note,
      updatedAt: updatedAt,
    );

void main() {
  final now = DateTime(2026, 6, 11).millisecondsSinceEpoch;

  group('SyncMerge', () {
    test('fresh install: empty local adopts all remote records (restore)', () {
      final result = SyncMerge.merge(
        localExpenses: [],
        localTombstones: {},
        remoteExpenses: [_expense('a'), _expense('b')],
        remoteTombstones: {},
        nowMillis: now,
      );
      expect(result.expenses.length, 2);
    });

    test('union keeps records unique to each side', () {
      final result = SyncMerge.merge(
        localExpenses: [_expense('local-only')],
        localTombstones: {},
        remoteExpenses: [_expense('remote-only')],
        remoteTombstones: {},
        nowMillis: now,
      );
      expect(result.expenses.map((e) => e.id),
          containsAll(['local-only', 'remote-only']));
    });

    test('newer updatedAt wins on conflicting edits', () {
      final result = SyncMerge.merge(
        localExpenses: [_expense('a', updatedAt: 100, note: 'old local')],
        localTombstones: {},
        remoteExpenses: [_expense('a', updatedAt: 200, note: 'newer remote')],
        remoteTombstones: {},
        nowMillis: now,
      );
      expect(result.expenses.single.note, 'newer remote');

      final reversed = SyncMerge.merge(
        localExpenses: [_expense('a', updatedAt: 300, note: 'newer local')],
        localTombstones: {},
        remoteExpenses: [_expense('a', updatedAt: 200, note: 'old remote')],
        remoteTombstones: {},
        nowMillis: now,
      );
      expect(reversed.expenses.single.note, 'newer local');
    });

    test('pre-sync records (null updatedAt) lose to explicit edits', () {
      final result = SyncMerge.merge(
        localExpenses: [_expense('a', note: 'legacy')],
        localTombstones: {},
        remoteExpenses: [_expense('a', updatedAt: 1, note: 'edited')],
        remoteTombstones: {},
        nowMillis: now,
      );
      expect(result.expenses.single.note, 'edited');
    });

    test('remote tombstone deletes local record (no resurrection)', () {
      final deletedAt = now - const Duration(days: 1).inMilliseconds;
      final result = SyncMerge.merge(
        localExpenses: [_expense('a', updatedAt: 100)],
        localTombstones: {},
        remoteExpenses: [],
        remoteTombstones: {'a': deletedAt},
        nowMillis: now,
      );
      expect(result.expenses, isEmpty);
      expect(result.tombstones['a'], deletedAt);
    });

    test('edit after deletion wins over the tombstone', () {
      final result = SyncMerge.merge(
        localExpenses: [_expense('a', updatedAt: 300, note: 'revived')],
        localTombstones: {},
        remoteExpenses: [],
        remoteTombstones: {'a': 200},
        nowMillis: now,
      );
      expect(result.expenses.single.note, 'revived');
    });

    test('two-device convergence: merging both directions gives same set', () {
      final deviceA = [
        _expense('a', updatedAt: 100),
        _expense('shared', updatedAt: 150, note: 'A edit'),
      ];
      final deviceB = [
        _expense('b', updatedAt: 120),
        _expense('shared', updatedAt: 180, note: 'B edit'),
      ];

      final aMergesB = SyncMerge.merge(
        localExpenses: deviceA,
        localTombstones: {},
        remoteExpenses: deviceB,
        remoteTombstones: {},
        nowMillis: now,
      );
      final bMergesA = SyncMerge.merge(
        localExpenses: deviceB,
        localTombstones: {},
        remoteExpenses: deviceA,
        remoteTombstones: {},
        nowMillis: now,
      );

      Map<String, String> snapshot(SyncMergeResult r) => {
        for (final e in r.expenses) e.id: e.note,
      };
      expect(snapshot(aMergesB), snapshot(bMergesA));
      expect(snapshot(aMergesB)['shared'], 'B edit');
    });

    test('ancient tombstones are pruned, recent ones kept', () {
      final old = now - const Duration(days: 91).inMilliseconds;
      final recent = now - const Duration(days: 5).inMilliseconds;

      final result = SyncMerge.merge(
        localExpenses: [],
        localTombstones: {'old': old, 'recent': recent},
        remoteExpenses: [],
        remoteTombstones: {},
        nowMillis: now,
      );
      expect(result.tombstones.containsKey('old'), isFalse);
      expect(result.tombstones.containsKey('recent'), isTrue);
    });
  });
}
