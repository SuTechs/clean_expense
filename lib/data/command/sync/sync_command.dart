import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart'
    show GoogleSignInException, GoogleSignInExceptionCode;
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

  /// In-flight sync, so concurrent triggers await the same round trip
  /// instead of silently no-oping (the old status==syncing guard made the
  /// on-pause flush a no-op exactly when a sync was already running).
  static Future<void>? _inFlight;

  /// Bumped on every local change. The sync snapshots it before reading
  /// Hive and only clears the dirty flag if nothing changed during the
  /// (potentially slow) upload — otherwise that change would never be
  /// backed up until the next edit.
  static int _changeCounter = 0;

  // How stale the last sync must be before an open/resume pulls from Drive.
  // Kept long on purpose: every silent sign-in can flash Android's
  // Credential Manager sheet, so routine opens shouldn't trigger one.
  // Dirty local changes always sync regardless.
  static const _resumeSyncThrottle = Duration(hours: 6);

  SyncBloc get syncBloc => BaseAppCommand.blocSync;

  bool get isConfigured => GoogleAuthService.isConfigured;

  /// Loads persisted sync state into the bloc at bootstrap.
  void hydrate() {
    if (hive.getSyncEnabled) {
      syncBloc.setConnected(hive.getSyncAccountEmail, hive.getLastBackupAt);
    }
  }

  /// Interactive sign-in + first sync, reusing the just-authenticated
  /// account directly (a second silent sign-in here can re-invoke
  /// Credential Manager and hang). The merge inside doubles as the restore
  /// for fresh installs. Throws on any failure, including cancel.
  Future<void> connect() async {
    syncBloc.setSyncing();
    http.Client? client;
    try {
      final account = await GoogleAuthService().signIn();
      client = await GoogleAuthService().driveClient(
        account,
        interactive: true,
      );
      if (client == null) {
        throw const SyncException('Drive access not granted');
      }

      await hive.setSyncEnabled(true);
      await hive.setSyncAccountEmail(account.email);
      syncBloc.setConnected(account.email, hive.getLastBackupAt);

      await _syncWithClient(client);
    } catch (e) {
      debugPrint('SyncCommand.connect: $e');
      if (hive.getSyncEnabled) {
        syncBloc.setError('Sync failed, please try again');
      } else {
        syncBloc.setDisconnected();
      }
      rethrow;
    } finally {
      client?.close();
    }
  }

  /// [connect] for UI callers: false when the user cancelled sign-in,
  /// true on success, throws (with a readable message) on real failures.
  Future<bool> connectInteractive() async {
    try {
      await connect();
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      throw SyncException('Sign-in failed (${e.code.name})');
    } on SocketException {
      throw const SyncException('No internet connection');
    }
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
    _changeCounter++;
    if (!hive.getSyncEnabled) return;
    hive.setSyncDirty(true);
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => syncNow());
  }

  /// Records that [id] was deleted locally so the deletion propagates to
  /// other devices instead of being resurrected by the next merge.
  /// Recorded even while sync is off: deletes made before (re)connecting
  /// would otherwise be resurrected by the first merge.
  Future<void> recordTombstone(String id) async {
    final tombstones = hive.getTombstones();
    tombstones[id] = TimeUtils.nowMillis;
    await hive.setTombstones(tombstones);
  }

  /// Uploads immediately if a change is pending (app going to background).
  /// Awaits an in-flight sync first; if changes landed during it, runs one
  /// more round so nothing is left un-backed-up.
  Future<void> flushPending() async {
    if (!hive.getSyncEnabled || !hive.getSyncDirty) return;
    _debounce?.cancel();
    await syncNow();
    if (hive.getSyncDirty) await syncNow();
  }

  /// Called on app resume: sync when dirty or when the last sync is stale.
  Future<void> syncOnResume() async {
    if (!hive.getSyncEnabled) return;
    final last = hive.getLastBackupAt ?? 0;
    final stale =
        TimeUtils.nowMillis - last > _resumeSyncThrottle.inMilliseconds;
    if (hive.getSyncDirty || stale) await syncNow();
  }

  /// Full download → merge → upload round trip. Always UI-less: it runs on
  /// the persisted authorization grant alone, so it can never pop a sign-in
  /// sheet — when the grant is gone the user reconnects from the profile.
  /// Concurrent calls share the in-flight round trip.
  Future<void> syncNow() {
    if (!hive.getSyncEnabled) return Future.value();

    final existing = _inFlight;
    if (existing != null) return existing;

    final run = _runSync().whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  Future<void> _runSync() async {
    syncBloc.setSyncing();
    http.Client? client;
    try {
      client = await GoogleAuthService().silentDriveClient();
      if (client == null) {
        syncBloc.setError('Drive access expired, please reconnect');
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
            ? 'Drive access revoked, please reconnect'
            : 'Drive error (${e.status})',
      );
    } catch (e) {
      debugPrint('SyncCommand.syncNow: $e');
      syncBloc.setError('Sync failed, please try again');
    } finally {
      client?.close();
    }
  }

  /// Remote-wins restore (explicit user action from the profile screen).
  /// Returns false when no backup exists. Any failure (including cancelled
  /// sign-in) restores the bloc state — leaving it stuck in `syncing` would
  /// make the status guard silently disable all future syncs.
  Future<bool> restoreNow() async {
    // Don't interleave a remote-wins replace with an in-flight merge.
    final inFlight = _inFlight;
    if (inFlight != null) await inFlight;

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
    } catch (e) {
      debugPrint('SyncCommand.restoreNow: $e');
      if (hive.getSyncEnabled) {
        syncBloc.setConnected(hive.getSyncAccountEmail, hive.getLastBackupAt);
      } else {
        syncBloc.setDisconnected();
      }
      rethrow;
    } finally {
      client?.close();
    }
  }

  Future<void> _syncWithClient(http.Client client) async {
    final changesAtStart = _changeCounter;
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

    // Only clear the dirty flag if nothing changed while we were uploading;
    // a change made mid-upload isn't in the backup we just wrote and must
    // trigger another round (the debounce timer it armed is still running).
    if (_changeCounter == changesAtStart) {
      await hive.setSyncDirty(false);
    }

    final now = TimeUtils.nowMillis;
    await hive.setLastBackupAt(now);
    syncBloc.setSynced(now);
  }

  void _guardSchema(BackupData remote) {
    if (remote.schemaVersion > BackupData.currentSchemaVersion) {
      throw const SyncException(
        'Backup was made by a newer app version, please update the app',
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

  /// Adopts profile/settings from the backup. During a normal merge the
  /// newer profile wins (by UserData.updatedAt) so a rename on device A
  /// propagates to device B instead of being overwritten by B's next
  /// upload; [force] (restore) always takes the remote values.
  Future<void> _adoptRemoteProfile(
    BackupData remote, {
    bool force = false,
  }) async {
    final remoteName = remote.user.name.trim();
    final localIsDefault = appBloc.currentUser.name == 'Guest';
    final remoteIsNewer = remote.user.updatedAt > appBloc.currentUser.updatedAt;
    if (remoteName.isNotEmpty &&
        remoteName != 'Guest' &&
        (force || localIsDefault || remoteIsNewer)) {
      await SetCurrentUserCommand().run(
        appBloc.currentUser.copyWith(
          name: remoteName,
          // Carry the ORIGIN's edit time: stamping "now" would make every
          // adopting device claim to be newest and ping-pong the profile.
          updatedAt: remote.user.updatedAt,
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
