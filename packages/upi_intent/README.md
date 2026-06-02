# upi_intent (vendored)

A **vendored and customized copy** of the [`upi_intent`](https://pub.dev/packages/upi_intent)
package (MIT). It lives inside this repo and is consumed via a path dependency
rather than from pub.dev.

```yaml
# app pubspec.yaml
dependencies:
  upi_intent:
    path: packages/upi_intent
```

## Why it's vendored

The app needs the UPI app picker to match its own visual style, and we want to
own the dependency rather than rely on an external package's release cadence.
Vendoring lets us:

- **Theme the built-in picker** to the app's palette (see _Customizations_).
- **Pin and patch** the native code without waiting on upstream.
- Keep the payment-launch layer fully under our control.

It replaced the discontinued `upi_pay`, whose stale hardcoded app list failed to
detect modern Google Pay / PhonePe builds. This package instead discovers apps
through the live Android intent resolver, so newly released UPI apps appear
automatically.

## What it does

- Detects installed UPI apps (Android: intent resolver; iOS: URL schemes).
- Shows a bottom-sheet app picker, launches the chosen app with an
  NPCI-compliant `upi://pay?...` URL.
- On Android, reads back the transaction status via `onActivityResult`.

> **Platform note:** UPI status is unreliable by design. Google Pay frequently
> returns no status even on a successful payment, and iOS cannot return
> transaction data at all. Treat `UpiTransactionStatus.success` as the only firm
> signal and confirm with the user otherwise — the app does this with a fallback
> dialog.

## Usage

```dart
import 'package:upi_intent/upi_intent.dart';

final UpiResponse? response = await UpiIntent.pay(
  context: context,
  payment: UpiPayment(
    payeeVpa: 'merchant@upi',     // required
    payeeName: 'My Shop',         // required
    amount: 99.00,                // optional (user fills if null)
    transactionNote: 'Order #1234',
    transactionRefId: 'TXN...',
  ),
);

if (response != null && response.isSuccess) {
  // confirmed paid
}
```

Other entry points: `UpiIntent.getInstalledApps()`, `UpiIntent.payWithApp(...)`,
`UpiIntent.buildUpiUrl(...)`, and `UpiValidator`.

### Required platform setup (done in the host app)

- **Android** (`AndroidManifest.xml`): a `<queries>` block for the `upi` scheme.
  This package also declares the queries in its own manifest, which merge in.
- **iOS** (`Info.plist`): `LSApplicationQueriesSchemes` listing UPI app schemes
  (`gpay`, `phonepe`, `paytmmp`, `bhim`, `upi`, …).

## Customizations vs. upstream 1.0.1

This is not a verbatim copy. Changes made for this repo:

- **Themed picker** — `lib/src/widgets/upi_app_picker.dart` now uses
  `Theme.of(context).colorScheme.primary` instead of a hardcoded blue, so it
  adopts the host app's theme. (No dependency on app code — it only reads the
  ambient `ThemeData`.)
- **Manifest fix** — removed the deprecated `package="..."` attribute from
  `android/src/main/AndroidManifest.xml` (conflicts with the AGP 8 `namespace`).
- **Slimmed down** — removed the `example/`, unit tests, screenshots, and the
  unused `flutter create plugin` boilerplate (`lib/upi_intent_method_channel.dart`,
  `lib/upi_intent_platform_interface.dart`); the real implementation is in
  `lib/src/platform/`.
- `publish_to: "none"` — this fork is internal and must not be published.

## License

MIT, inherited from the upstream `upi_intent` package. See [LICENSE](LICENSE).
