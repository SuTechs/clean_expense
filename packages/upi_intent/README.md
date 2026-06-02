# upi_intent 💸

[![pub.dev](https://img.shields.io/pub/v/upi_intent.svg)](https://pub.dev/packages/upi_intent)
[![pub points](https://img.shields.io/pub/points/upi_intent)](https://pub.dev/packages/upi_intent/score)
[![popularity](https://img.shields.io/pub/popularity/upi_intent)](https://pub.dev/packages/upi_intent/score)
[![likes](https://img.shields.io/pub/likes/upi_intent)](https://pub.dev/packages/upi_intent/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![platform](https://img.shields.io/badge/platform-android%20%7C%20ios-green)](https://pub.dev/packages/upi_intent)

A **modern, production-ready** Flutter plugin for UPI payments — with a beautiful built-in app picker, NPCI-compliant URL construction, typed response parsing, and active maintenance.

> 🚀 The only UPI package with a **built-in Material 3 app picker**. Replaces outdated packages like `upi_pay` (abandoned 2+ years ago).

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 🎨 **Beautiful App Picker** | Built-in Material 3 bottom sheet — no extra code needed |
| 🔒 **NPCI-Compliant URLs** | Correct `upi://pay` format per official NPCI spec |
| ✅ **VPA Validator** | Client-side format validation before initiating payment |
| 📱 **Android + iOS** | Full cross-platform support |
| 🤖 **Android 11+ Ready** | Required `<queries>` manifest block included |
| 🌙 **Auto Dark Mode** | App picker adapts to system theme automatically |
| 🧪 **Null-safe & Typed** | Full null-safety with typed `UpiResponse` model |
| 📦 **Zero bloat** | No unnecessary dependencies |

---

## 📸 Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/Yash-Dodani/Yash-Dodani/main/super%20ss.png" alt="UPI Intent Example & App Picker" width="600"/>
</p>

---

## 🚀 Installation

### Step 1 — Add dependency

```yaml
# pubspec.yaml
dependencies:
  upi_intent: ^1.0.0
```

Then run:
```bash
flutter pub get
```

---

### Step 2 — Android Setup ⚠️ Required!

Open your app's `android/app/src/main/AndroidManifest.xml` and add the `<queries>` block:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

  <!-- ✅ Required for Android 11+ (API 30+) to detect UPI apps -->
  <queries>
    <intent>
      <action android:name="android.intent.action.VIEW" />
      <data android:scheme="upi" />
    </intent>
  </queries>

  <application
    android:label="your_app"
    ...>
    ...
  </application>

</manifest>
```

> ❌ **Without this block, zero UPI apps will be detected on Android 11 and above!**

---

### Step 3 — iOS Setup (Optional)

Open `ios/Runner/Info.plist` and add URL scheme whitelist:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>gpay</string>
  <string>phonepe</string>
  <string>paytmmp</string>
  <string>bhim</string>
  <string>upi</string>
</array>
```

> ℹ️ iOS Note: Due to platform restrictions, iOS cannot return detailed transaction data. Always verify payment on your backend server.

---

## 💡 Usage

### Basic Payment (with Built-in App Picker)

```dart
import 'package:upi_intent/upi_intent.dart';

// Call inside an async function that has access to BuildContext
Future<void> makePayment(BuildContext context) async {
  try {
    final UpiResponse? response = await UpiIntent.pay(
      context: context,
      payment: UpiPayment(
        payeeVpa: 'merchant@upi',         // ← Payee's UPI ID (required)
        payeeName: 'My Online Store',     // ← Payee name (required)
        amount: 299.00,                   // ← Amount in INR (optional)
        transactionNote: 'Order #1234',   // ← Payment note (optional)
        transactionRefId: 'TXN_001',      // ← Your reference ID (optional)
      ),
    );

    if (response == null) {
      // User dismissed the app picker without selecting
      print('User cancelled');
      return;
    }

    if (response.isSuccess) {
      // ✅ Payment marked successful by UPI app
      print('Payment successful!');
      print('Transaction ID: ${response.transactionId}');

      // ⚠️ IMPORTANT: Always verify on backend before confirming order!
      await verifyOnBackend(response.transactionId!);
    } else {
      // ❌ Payment failed or pending
      print('Payment status: ${response.status}');
    }

  } on UpiException catch (e) {
    // Plugin-level errors (invalid VPA, no UPI apps found, etc.)
    print('UPI Error: ${e.message}');
  }
}
```

---

### Pay with a Specific App (Skip the Picker)

```dart
// Get all installed UPI apps
final List<UpiApp> apps = await UpiIntent.getInstalledApps();

// Find a specific app
final googlePay = apps.firstWhereOrNull(
  (app) => app.packageName == 'com.google.android.apps.nbu.paisa.user',
);

if (googlePay == null) {
  print('Google Pay is not installed');
  return;
}

// Pay directly with that app
final response = await UpiIntent.payWithApp(
  payment: UpiPayment(
    payeeVpa: 'merchant@upi',
    payeeName: 'My Shop',
    amount: 99.00,
  ),
  app: googlePay,
);
```

---

### Validate a VPA Before Payment

```dart
// Validate format before calling pay()
final String vpa = 'user@okicici';

if (!UpiValidator.isValidVpa(vpa)) {
  showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('Invalid VPA'),
    content: const Text('Please enter a valid UPI ID (e.g. name@upi)'),
  ));
  return;
}

// Now safe to proceed with payment
await UpiIntent.pay(context: context, payment: UpiPayment(payeeVpa: vpa, ...));
```

---

### Get List of Installed UPI Apps

```dart
final List<UpiApp> apps = await UpiIntent.getInstalledApps();

for (final app in apps) {
  print('${app.name} → ${app.packageName}');
}

// Example output:
// Google Pay → com.google.android.apps.nbu.paisa.user
// PhonePe → com.phonepe.app
// Amazon Pay → in.amazon.mShop.android.shopping
```

---

### Build UPI URL (for QR Codes)

```dart
final String upiUrl = UpiIntent.buildUpiUrl(
  UpiPayment(
    payeeVpa: 'merchant@upi',
    payeeName: 'My Shop',
    amount: 199.00,
    transactionNote: 'Online order',
  ),
);

// Result: upi://pay?pa=merchant@upi&pn=My+Shop&am=199.00&cu=INR&tn=Online+order
print(upiUrl); // Use this URL in a QR code widget
```

---

## 📋 API Reference

### `UpiPayment` — Payment Parameters

| Parameter | Type | Required | Description |
|-----------|------|:--------:|-------------|
| `payeeVpa` | `String` | ✅ | Payee's UPI Virtual Payment Address (e.g. `name@upi`) |
| `payeeName` | `String` | ✅ | Name of the payee / merchant |
| `amount` | `double?` | ❌ | Amount in INR. Leave null to let user enter amount |
| `transactionNote` | `String?` | ❌ | Short description shown in UPI app |
| `transactionRefId` | `String?` | ❌ | Your order/transaction reference ID |
| `merchantCode` | `String?` | ❌ | Merchant Category Code (MCC) for business payments |

---

### `UpiResponse` — Payment Response

| Property | Type | Description |
|----------|------|-------------|
| `status` | `UpiTransactionStatus` | Outcome of the transaction |
| `isSuccess` | `bool` | `true` only when status is `success` |
| `transactionId` | `String?` | UPI network transaction ID (`txnId`) |
| `approvalRefNo` | `String?` | Bank approval reference number |
| `responseCode` | `String?` | Raw response code from bank |

---

### `UpiTransactionStatus` Enum

| Value | Meaning | What to do |
|-------|---------|-----------|
| `success` | UPI app reported success | ✅ Verify `transactionId` on backend |
| `failure` | Payment failed | ❌ Show error, let user retry |
| `submitted` | Submitted to bank, pending | ⏳ Check backend after a few seconds |
| `unknown` | Status unclear | 🔍 Always verify via backend |

---

### `UpiApp` — Installed App Info

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Display name (e.g. "Google Pay") |
| `packageName` | `String` | Android package name |
| `icon` | `List<int>?` | App icon as raw bytes (for custom UI) |

---

### `UpiValidator` — Static Helpers

```dart
// Check if a VPA has valid format (user@handle)
bool UpiValidator.isValidVpa(String vpa)

// Check if amount is within NPCI limits (₹1 – ₹1,00,000)
bool UpiValidator.isValidAmount(double amount)
```

---

## 🏦 Supported UPI Apps

| App | Android | iOS |
|-----|:-------:|:---:|
| Google Pay | ✅ | ✅ |
| PhonePe | ✅ | ✅ |
| Paytm | ✅ | ✅ |
| Amazon Pay | ✅ | ✅ |
| WhatsApp Pay | ✅ | ❌ |
| BHIM | ✅ | ✅ |
| FreeCharge | ✅ | ❌ |
| MobiKwik | ✅ | ❌ |
| Airtel Thanks | ✅ | ❌ |
| YONO SBI | ✅ | ❌ |
| iMobile ICICI | ✅ | ❌ |
| **Any other UPI app** | ✅ | ⚠️ |

> **iOS Note**: Only apps with registered URL schemes can be detected on iOS.

---

## ⚠️ Security — Important!

> **Never trust client-side UPI responses alone.**

A malicious user could fake a `success` response. Always verify the `transactionId` on your server:

```dart
// ❌ WRONG — Do NOT do this
if (response.isSuccess) {
  confirmOrder(); // Dangerous!
}

// ✅ CORRECT — Always verify on backend
if (response.isSuccess && response.transactionId != null) {
  final verified = await myBackend.verifyUpiTransaction(
    txnId: response.transactionId!,
    amount: 299.00,
    vpa: 'merchant@upi',
  );
  if (verified) confirmOrder();
}
```

---

## 🛠️ Troubleshooting

**❓ No UPI apps detected on Android 11+?**
→ Add the `<queries>` block to your `AndroidManifest.xml` — see [Android Setup](#step-2--android-setup-️-required).

**❓ `UpiException: Invalid UPI VPA` thrown?**
→ Validate the VPA first using `UpiValidator.isValidVpa(vpa)`.

**❓ Payment works but response is `null`?**
→ User dismissed the app picker. Handle the null case gracefully.

**❓ Works on physical device but not emulator?**
→ Expected behavior. UPI apps are not available on emulators. Test on a real device.

**❓ iOS showing `submitted` status always?**
→ iOS cannot return detailed transaction data due to platform restrictions. Verify on backend.

**❓ `Lost connection to device` during testing?**
→ Normal! The Flutter app goes to background when UPI app opens. Debug connection drops. Payment still works — press the back button and check result.

---

## 📄 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## 📜 License

```
MIT License — Copyright (c) 2025 Yash Dodani
```

See [LICENSE](LICENSE) for full details.

---

## 🙏 Contributing

PRs are welcome! Please open an issue first to discuss what you'd like to change.

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -m 'Add my feature'`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request

---

<p align="center">Made with ❤️ by <a href="https://github.com/your-username">Yash Dodani</a></p>
