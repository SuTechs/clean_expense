import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../../api/google_drive/drive_backup_service.dart';
import '../../api/google_drive/google_auth_service.dart';
import '../../api/hive/service_extension.dart';
import '../../bloc/sync_bloc.dart';
import '../../data/backup/backup.dart';
import '../../utils/sync_merge.dart';
import '../../utils/time_utils.dart';
import '../app/set_current_user_command.dart';
import '../commands.dart';

/// Google Drive backup/sync.
///
/// Transport is a single backup.json (full-file replace — years of expenses
/// stay well under 1MB), but the merge is per-record: union by id with the
/// newer `updatedAt` winning, and tombstones so deletions propagate instead
/// of resurrecting. A fresh install therefore "restores" simply by merging
/// an empty local set with the remote backup.
class SyncCommand extends BaseAppCommand {
  static Timer? _debounce;
  static const _debounceDelay = Duration(seconds: 30);
  static const _resumeSyncThrottle = Duration(minutes: 5);

  SyncBloc get syncBloc => BaseAppCommand.blocSync;

  bool get isConfigured => GoogleAuthService.isConfigured;

  /// Loads persisted sync state into the bloc at bootstrap.
  void hydrate() {
    if (hive.getSyncEnabled) {
      syncBloc.setConnected(hive.getSyncAccountEmail, hive.getLastBackupAt);
    }
  }

  /// Interactive sign-in + first sync. The merge inside [syncNow] doubles as
  /// the restore for fresh installs. Throws on failure (including cancel).
  Future<void> connect() async {
    final account = await GoogleAuthService().signIn();
    await hive.setSyncEnabled(true);
    await hive.setSyncAccountEmail(account.email);
    syncBloc.setConnected(account.email, hive.getLastBackupAt);

    await syncNow(interactive: true);
  }

  /// Signs out and stops syncing. Local data is kept.
  Future<void> disconnect() async {
    _debounce?.cancel();
    try {
      await GoogleAuthService().signOut();
    } catch (e) {
      debugPrint('SyncCommand.disconnect: $e');
    }
    await hive.setSyncEnabled(false);
    await hive.setSyncAccountEmail(null);
    await hive.setSyncFileId(null);
    syncBloc.setDisconnected();
  }

  /// Marks local state dirty and schedules a debounced upload. Called from
  /// ExpenseCommand after every add/update/delete.
  void scheduleBackup() {
    if (!hive.getSyncEnabled) return;
    hive.setSyncDirty(true);
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => syncNow());
  }

  /// Records that [id] was deleted locally so the deletion propagates to
  /// other devices instead of being resurrected by the next merge.
  Future<void> recordTombstone(String id) async {
    if (!hive.getSyncEnabled) return;
    final tombstones = hive.getTombstones();
    tombstones[id] = TimeUtils.nowMillis;
    await hive.setTombstones(tombstones);
  }

  /// Uploads immediately if a change is pending (app going to background).
  Future<void> flushPending() async {
    if (!hive.getSyncEnabled || !hive.getSyncDirty) return;
    _debounce?.cancel();
    await syncNow();
  }

  /// Called on app resume: sync when dirty or when the last sync is stale.
  Future<void> syncOnResume() async {
    if (!hive.getSyncEnabled) return;
    final last = hive.getLastBackupAt ?? 0;
    final stale =
        TimeUtils.nowMillis - last > _resumeSyncThrottle.inMilliseconds;
    if (hive.getSyncDirty || stale) await syncNow();
  }

  /// Full download → merge → upload round trip.
  Future<void> syncNow({bool interactive = false}) async {
    if (!hive.getSyncEnabled) return;
    if (syncBloc.status == SyncStatus.syncing) return;

    syncBloc.setSyncing();
    http.Client? client;
    try {
      final account = await GoogleAuthService().signInSilently();
      if (account == null) {
        syncBloc.setError('Sign-in expired — reconnect Google Drive');
        return;
      }

      client = await GoogleAuthService().driveClient(
        account,
        interactive: interactive,
      );
      if (client == null) {
        syncBloc.setError('Drive access not granted — reconnect');
        return;
      }

      await _syncWithClient(client);
    } on SocketException {
      syncBloc.setOffline();
    } on http.ClientException {
      syncBloc.setOffline();
    } on drive.DetailedApiRequestError catch (e) {
      syncBloc.setError(
        e.status == 401 || e.status == 403
            ? 'Drive access revoked — reconnect'
            : 'Drive error (${e.status})',
      );
    } catch (e) {
      debugPrint('SyncCommand.syncNow: $e');
      syncBloc.setError('Sync failed: $e');
    } finally {
      client?.close();
    }
  }

  /// Remote-wins restore (explicit user action from the profile screen).
  /// Returns false when no backup exists.
  Future<bool> restoreNow() async {
    http.Client? client;
    try {
      syncBloc.setSyncing();
      final account = await GoogleAuthService().signIn();
      client = await GoogleAuthService().driveClient(
        account,
        interactive: true,
      );
      if (client == null) {
        throw const SyncException('Drive access not granted');
      }

      final service = DriveBackupService(client);
      final fileId = await service.findBackupFileId();
      if (fileId == null) {
        syncBloc.setSynced(hive.getLastBackupAt ?? TimeUtils.nowMillis);
        return false;
      }

      final remote = await service.download(fileId);
      _guardSchema(remote);

      await hive.replaceAllExpenses(remote.expenses);
      await hive.setTombstones(remote.tombstones);
      expenseBloc.refresh(remote.expenses);
      await _adoptRemoteProfile(remote, force: true);

      await hive.setSyncFileId(fileId);
      await hive.setSyncDirty(false);
      final now = TimeUtils.nowMillis;
      await hive.setLastBackupAt(now);
      syncBloc.setSynced(now);
      return true;
    } finally {
      client?.close();
    }
  }

  Future<void> _syncWithClient(http.Client client) async {
    final service = DriveBackupService(client);

    var fileId = hive.getSyncFileId ?? await service.findBackupFileId();

    BackupData? remote;
    if (fileId != null) {
      try {
        remote = await service.download(fileId);
      } on drive.DetailedApiRequestError catch (e) {
        // Cached file id can go stale (e.g. user revoked + reconnected).
        if (e.status == 404) {
          fileId = await service.findBackupFileId();
          remote = fileId == null ? null : await service.download(fileId);
        } else {
          rethrow;
        }
      }
      if (remote != null) _guardSchema(remote);
    }

    final merged = await _merge(remote);

    final newFileId = await service.upload(merged, existingFileId: fileId);
    await hive.setSyncFileId(newFileId);
    await hive.setSyncDirty(false);
    final now = TimeUtils.nowMillis;
    await hive.setLastBackupAt(now);
    syncBloc.setSynced(now);
  }

  void _guardSchema(BackupData remote) {
    if (remote.schemaVersion > BackupData.currentSchemaVersion) {
      throw const SyncException(
        'Backup was made by a newer app version — please update the app',
      );
    }
  }

  /// Merges the remote backup into local state, persists the result and
  /// returns the new backup to upload.
  Future<BackupData> _merge(BackupData? remote) async {
    final result = SyncMerge.merge(
      localExpenses: hive.getAllExpenses(),
      localTombstones: hive.getTombstones(),
      remoteExpenses: remote?.expenses ?? const [],
      remoteTombstones: remote?.tombstones ?? const {},
      nowMillis: TimeUtils.nowMillis,
    );

    // Persist merged state locally.
    await hive.replaceAllExpenses(result.expenses);
    await hive.setTombstones(result.tombstones);
    expenseBloc.refresh(result.expenses);
    if (remote != null) await _adoptRemoteProfile(remote);

    return BackupData(
      schemaVersion: BackupData.currentSchemaVersion,
      app: BackupData.appName,
      lastModified: TimeUtils.nowMillis,
      user: appBloc.currentUser,
      settings: {'currency': appBloc.currency},
      tombstones: result.tombstones,
      expenses: result.expenses,
    );
  }

  /// Adopts profile/settings from the backup. During a normal merge this
  /// only fills local defaults (fresh install); [force] (restore) always
  /// takes the remote values.
  Future<void> _adoptRemoteProfile(
    BackupData remote, {
    bool force = false,
  }) async {
    final remoteName = remote.user.name.trim();
    final localIsDefault = appBloc.currentUser.name == 'Guest';
    if (remoteName.isNotEmpty &&
        remoteName != 'Guest' &&
        (force || localIsDefault)) {
      await SetCurrentUserCommand().run(
        appBloc.currentUser.copyWith(
          name: remoteName,
          updatedAt: TimeUtils.nowMillis,
        ),
      );
    }

    final remoteCurrency = remote.settings['currency'];
    if (remoteCurrency != null &&
        remoteCurrency.isNotEmpty &&
        (force || hive.getCurrency == null)) {
      appBloc.currency = remoteCurrency;
    }
  }
}
