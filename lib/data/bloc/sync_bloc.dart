import 'abstract.dart';

enum SyncStatus { disabled, idle, syncing, offline, error }

class SyncBloc extends AbstractBloc {
  SyncStatus _status = SyncStatus.disabled;
  String? _accountEmail;
  int? _lastSyncedAt;
  String? _errorMessage;

  SyncStatus get status => _status;
  String? get accountEmail => _accountEmail;
  int? get lastSyncedAt => _lastSyncedAt;
  String? get errorMessage => _errorMessage;

  bool get isConnected => _status != SyncStatus.disabled;

  void setConnected(String? email, int? lastSyncedAt) => notify(() {
    _accountEmail = email;
    _lastSyncedAt = lastSyncedAt;
    _status = SyncStatus.idle;
    _errorMessage = null;
  });

  void setDisconnected() => notify(() {
    _status = SyncStatus.disabled;
    _accountEmail = null;
    _lastSyncedAt = null;
    _errorMessage = null;
  });

  void setSyncing() => notify(() {
    _status = SyncStatus.syncing;
    _errorMessage = null;
  });

  void setSynced(int at) => notify(() {
    _status = SyncStatus.idle;
    _lastSyncedAt = at;
    _errorMessage = null;
  });

  void setOffline() => notify(() => _status = SyncStatus.offline);

  void setError(String message) => notify(() {
    _status = SyncStatus.error;
    _errorMessage = message;
  });
}
