import 'dart:typed_data';

/// A UPI-enabled app installed on the device
class UpiApp {
  /// Display name (e.g., "Google Pay")
  final String name;

  /// Android package name (e.g., "com.google.android.apps.nbu.paisa.user")
  final String packageName;

  /// App icon as raw bytes (PNG)
  final Uint8List? icon;

  const UpiApp({
    required this.name,
    required this.packageName,
    this.icon,
  });

  @override
  String toString() => 'UpiApp(name: $name, package: $packageName)';
}

/// Well-known UPI app package names
class KnownUpiApps {
  KnownUpiApps._();

  static const String googlePay =
      'com.google.android.apps.nbu.paisa.user';
  static const String phonePe = 'com.phonepe.app';
  static const String paytm = 'net.one97.paytm';
  static const String amazonPay = 'in.amazon.mshop.android.shopping';
  static const String bhim = 'in.org.npci.upiapp';
  static const String airtelPay = 'com.airtel.india.payments';
  static const String whatsApp = 'com.whatsapp';
  static const String jioMoney = 'com.jio.jiopaymcp';
  static const String iMobile = 'com.csam.icici.bank.imobile';
  static const String yono = 'com.sbi.SBIFreedomPlus';
}
