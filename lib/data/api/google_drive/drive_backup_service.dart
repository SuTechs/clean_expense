import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../../data/backup/backup.dart';

/// Reads/writes the single backup.json in the Drive appDataFolder.
/// The folder is invisible to the user and scoped to this app only.
class DriveBackupService {
  static const fileName = 'backup.json';

  final drive.DriveApi _api;

  DriveBackupService(http.Client client) : _api = drive.DriveApi(client);

  /// Finds the backup file, self-healing duplicates: two devices doing
  /// their first-ever sync concurrently can each create a backup.json,
  /// after which each forever updates its own copy and they never
  /// converge. Keep the newest, best-effort delete the rest.
  Future<String?> findBackupFileId() async {
    final result = await _api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$fileName' and trashed = false",
      orderBy: 'modifiedTime desc',
      $fields: 'files(id, modifiedTime)',
    );
    final files = result.files;
    if (files == null || files.isEmpty) return null;

    for (final duplicate in files.skip(1)) {
      final id = duplicate.id;
      if (id == null) continue;
      try {
        await _api.files.delete(id);
      } catch (_) {
        // Best effort; the newest file is still authoritative.
      }
    }
    return files.first.id;
  }

  Future<BackupData> download(String fileId) async {
    final media =
        await _api.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final bytes = await media.stream.fold<List<int>>(
      [],
      (all, chunk) => all..addAll(chunk),
    );
    return BackupData.fromJson(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
    );
  }

  /// Full-file replace; returns the file id for caching.
  Future<String> upload(BackupData backup, {String? existingFileId}) async {
    final bytes = utf8.encode(jsonEncode(backup.toJson()));
    drive.Media media() => drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );

    if (existingFileId != null) {
      final updated = await _api.files.update(
        drive.File(name: fileName),
        existingFileId,
        uploadMedia: media(),
      );
      return updated.id ?? existingFileId;
    }

    final created = await _api.files.create(
      drive.File(name: fileName, parents: const ['appDataFolder']),
      uploadMedia: media(),
    );
    return created.id!;
  }
}
