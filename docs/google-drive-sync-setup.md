# Google Drive Backup — One-time Setup

The Drive backup feature ships disabled until OAuth client IDs are configured.
Everything below happens in [Google Cloud Console](https://console.cloud.google.com)
— no Firebase, no backend, no cost.

## 1. Create a project & enable the Drive API

1. Create a Google Cloud project (e.g. `clean-expense`).
2. **APIs & Services → Library** → enable **Google Drive API**.

## 2. OAuth consent screen

1. **APIs & Services → OAuth consent screen** → User type **External**.
2. Fill app name, support email, developer email.
3. **Scopes** → add `https://www.googleapis.com/auth/drive.appdata`.
4. Add yourself (and testers) under **Test users**.

> ⚠️ `drive.appdata` is a *sensitive* scope. The app works immediately for up
> to 100 test users. Before a public production release, submit the app for
> Google's verification (requires a privacy policy URL and a short
> justification — "user-controlled backup of their own data to their own
> Drive" is the standard wording).

## 3. Create THREE OAuth client IDs

**APIs & Services → Credentials → Create credentials → OAuth client ID**

| Client type | Settings | Where it goes |
|---|---|---|
| **Android** | Package name `com.sutechs.expense` + SHA-1 fingerprints (see below) | Nowhere — Google matches by package+SHA |
| **iOS** | The Runner bundle id from Xcode | `kGoogleIosClientId` in `lib/constants.dart` + reversed id in `ios/Runner/Info.plist` |
| **Web application** | No redirect URIs needed | `kGoogleWebClientId` in `lib/constants.dart` (Android requires it as `serverClientId`) |

### Android SHA-1 fingerprints (add ALL of these)

```bash
# Debug keystore
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android | grep SHA1

# Upload/release keystore
keytool -list -v -alias <alias> -keystore <your-release-keystore> | grep SHA1
```

Plus, if the app uses **Play App Signing** (it almost certainly does):
Play Console → your app → **Setup → App integrity → App signing key
certificate** → copy that SHA-1 too. *Missing this one is the #1 cause of
sign-in working in debug but failing in the Play Store build.*

## 4. Wire the IDs into the app

The IDs are injected at build time and never committed:

1. Copy `env.example.json` (repo root) to `env.json` — it's gitignored —
   and fill in your IDs:

   ```json
   {
     "GOOGLE_WEB_CLIENT_ID": "1234-abc.apps.googleusercontent.com",
     "GOOGLE_IOS_CLIENT_ID": "1234-def.apps.googleusercontent.com"
   }
   ```

2. Run and build with the define file:

   ```bash
   flutter run --dart-define-from-file=env.json
   flutter build apk --dart-define-from-file=env.json
   flutter build ipa --dart-define-from-file=env.json
   ```

3. **iOS only**: copy `ios/Flutter/Secrets.xcconfig.example` to
   `ios/Flutter/Secrets.xcconfig` (gitignored) and set the reversed iOS
   client id:

   ```
   GOOGLE_REVERSED_CLIENT_ID = com.googleusercontent.apps.1234-def
   ```

   Info.plist references it as `$(GOOGLE_REVERSED_CLIENT_ID)`, so nothing
   is committed. In CI, write this file from a repo secret before building.

Without `env.json` the app still builds and runs; the Drive backup feature
simply shows as "not configured". (Strictly speaking OAuth client IDs are
public identifiers — security comes from the package-name/SHA-1 and
bundle-id binding — but keeping them out of the repo prevents strangers'
builds from impersonating the official app's consent screen.)

## 5. Verify

- Fresh install → Settings → Profile & Backup → **Connect Google Drive** →
  account picker appears → status chip shows **Synced**.
- Add an expense, wait ~30s (debounce), check "Last synced" updates.
- Uninstall → reinstall → onboarding → **Restore from Google Drive** →
  data comes back.
- Test with the **release** build on Android (App-Signing SHA-1 path).

## How it works (for contributors)

- Single `backup.json` in Drive's hidden `appDataFolder` (only this app can
  see it; deleted automatically if the user removes the app's Drive access).
- Per-record merge on every sync: union by expense id, newer `updatedAt`
  wins, deletions propagate via tombstones — two devices converge without a
  server.
- Sync triggers: 30s debounce after any change, app pause (flush), app
  resume/launch (pull), manual Backup/Restore in the profile screen.
