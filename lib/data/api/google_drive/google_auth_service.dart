import 'dart:io';

import 'package:googleapis/drive/v3.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;

import '../../../constants.dart';

class SyncException implements Exception {
  final String message;
  const SyncException(this.message);

  @override
  String toString() => message;
}

/// Thin wrapper around the google_sign_in v7 singleton API, requesting only
/// the hidden appDataFolder scope.
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._();

  static const scopes = [DriveApi.driveAppdataScope];

  bool _initialized = false;

  /// Whether OAuth client IDs are present in this build (see constants.dart).
  static bool get isConfigured => Platform.isIOS
      ? kGoogleIosClientId.isNotEmpty
      : kGoogleWebClientId.isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (!isConfigured) {
      throw const SyncException(
        "Google Drive backup isn't configured in this build",
      );
    }

    await GoogleSignIn.instance.initialize(
      clientId: kGoogleIosClientId.isEmpty ? null : kGoogleIosClientId,
      serverClientId: kGoogleWebClientId.isEmpty ? null : kGoogleWebClientId,
    );
    _initialized = true;
  }

  /// UI-less Drive client for background syncs, built from the persisted
  /// authorization grant (like Firebase session restore). Crucially this is
  /// pure AUTHORIZATION — re-AUTHENTICATING (even "lightweight") goes
  /// through Android's Credential Manager, which flashes its bottom sheet
  /// on every new process. Null when the grant is gone and the user must
  /// reconnect interactively. The caller must close the client.
  Future<http.Client?> silentDriveClient() async {
    await _ensureInitialized();
    final authorization = await GoogleSignIn.instance.authorizationClient
        .authorizationForScopes(scopes);
    return authorization?.authClient(scopes: scopes);
  }

  /// Interactive sign-in. Throws [GoogleSignInException] (e.g. canceled).
  Future<GoogleSignInAccount> signIn() async {
    await _ensureInitialized();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const SyncException(
        'Google sign-in is not supported on this platform',
      );
    }
    return GoogleSignIn.instance.authenticate(scopeHint: scopes);
  }

  /// Returns an authorized HTTP client for Drive calls, or null when the
  /// scope isn't granted and [interactive] is false. The caller must close
  /// the client.
  Future<http.Client?> driveClient(
    GoogleSignInAccount account, {
    required bool interactive,
  }) async {
    var authorization = await account.authorizationClient
        .authorizationForScopes(scopes);

    if (authorization == null && interactive) {
      authorization = await account.authorizationClient.authorizeScopes(
        scopes,
      );
    }

    return authorization?.authClient(scopes: scopes);
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }

  /// Also revokes granted scopes (stronger than signOut).
  Future<void> disconnect() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.disconnect();
  }
}
