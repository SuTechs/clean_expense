import 'package:freezed_annotation/freezed_annotation.dart';

import '../expense/expense.dart';
import '../user/user.dart';

part 'backup.freezed.dart';
part 'backup.g.dart';

/// The single backup.json stored in the Google Drive appDataFolder.
/// JSON-only — this is NOT a Hive type; do not add it to hive_adapters.
@freezed
abstract class BackupData with _$BackupData {
  const BackupData._();

  const factory BackupData({
    /// Bump when the backup shape changes; restore refuses newer versions.
    required int schemaVersion,
    required String app,

    /// Epoch millis when this backup was written.
    required int lastModified,
    required UserData user,

    /// App-level settings worth restoring (currency symbol, etc.).
    required Map<String, String> settings,

    /// Deleted expense ids -> epoch millis of deletion. Lets a sync delete
    /// records on other devices instead of resurrecting them.
    required Map<String, int> tombstones,
    required List<ExpenseData> expenses,
  }) = _BackupData;

  factory BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);

  static const currentSchemaVersion = 1;
  static const appName = 'clean_expense';
}
