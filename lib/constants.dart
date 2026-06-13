import 'package:flutter/material.dart';

/// App version
const kAppVersion = "1.0.0+1";

const kGreenSeedColor = Color(0xFF22C55E);

/// Google OAuth client IDs for Drive backup (see docs/google-drive-sync-setup.md).
///
/// Injected at build time so they never live in the repo:
///   flutter run --dart-define-from-file=env.json
///   flutter build apk --dart-define-from-file=env.json
/// Copy env.example.json to env.json (gitignored) and fill in your own IDs.
/// While these are empty the backup feature shows as "not configured".
///
/// Web application client ID — required as serverClientId on Android.
const kGoogleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

/// iOS client ID — also requires the reversed-client-id URL scheme in
/// ios/Runner/Info.plist (add it locally; see the setup doc).
const kGoogleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
