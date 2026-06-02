import 'package:flutter/material.dart';

import 'src/builder/upi_url_builder.dart';
import 'src/models/upi_app.dart';
import 'src/models/upi_exception.dart';
import 'src/models/upi_payment.dart';
import 'src/models/upi_response.dart';
import 'src/platform/upi_intent_method_channel.dart';
import 'src/platform/upi_intent_platform_interface.dart';
import 'src/validator/upi_validator.dart';
import 'src/widgets/upi_app_picker.dart';

export 'src/models/upi_app.dart';
export 'src/models/upi_exception.dart';
export 'src/models/upi_payment.dart';
export 'src/models/upi_response.dart';
export 'src/validator/upi_validator.dart';
export 'src/widgets/upi_app_picker.dart';

/// The main entry point for upi_intent plugin
///
/// Example usage:
/// ```dart
/// final response = await UpiIntent.pay(
///   context: context,
///   payment: UpiPayment(
///     payeeVpa: 'merchant@upi',
///     payeeName: 'My Shop',
///     amount: 99.00,
///     transactionNote: 'Order #1234',
///   ),
/// );
///
/// if (response != null && response.isSuccess) {
///   print('Payment successful! TxnID: ${response.transactionId}');
/// }
/// ```
class UpiIntent {
  UpiIntent._();

  static UpiIntentPlatform get _platform {
    UpiIntentPlatform.instance = MethodChannelUpiIntent();
    return UpiIntentPlatform.instance;
  }

  /// Get list of UPI apps installed on the device
  ///
  /// Returns empty list if no UPI apps are installed.
  static Future<List<UpiApp>> getInstalledApps() async {
    return _platform.getInstalledApps();
  }

  /// Launch UPI payment with a beautiful app picker
  ///
  /// Shows a bottom sheet with all installed UPI apps.
  /// Returns [UpiResponse] on completion, or null if user cancelled.
  ///
  /// Throws [UpiException] if:
  /// - VPA is invalid
  /// - Amount is invalid
  /// - No UPI apps are installed
  static Future<UpiResponse?> pay({
    required BuildContext context,
    required UpiPayment payment,
  }) async {
    // Validate inputs
    if (!UpiValidator.isValidVpa(payment.payeeVpa)) {
      throw UpiException(
        'Invalid UPI VPA: "${payment.payeeVpa}". '
        'Valid format: username@bankname (e.g., user@upi)',
      );
    }

    if (payment.amount != null &&
        !UpiValidator.isValidAmount(payment.amount!)) {
      throw UpiException(
        'Invalid amount: ${payment.amount}. '
        'Amount must be between ₹0.01 and ₹1,00,000.',
      );
    }

    // Get installed apps
    final apps = await getInstalledApps();
    if (apps.isEmpty) {
      throw UpiException(
        'No UPI apps found on this device. '
        'Please install Google Pay, PhonePe, or Paytm.',
        code: 'NO_UPI_APPS',
      );
    }

    // Show app picker
    if (!context.mounted) return null;
    final selectedApp = await UpiAppPicker.show(context, apps);
    if (selectedApp == null) return null; // User cancelled

    // Build URL and launch
    final upiUrl = UpiUrlBuilder.build(payment);
    return _platform.launchUpiApp(
      upiUrl: upiUrl,
      packageName: selectedApp.packageName,
    );
  }

  /// Pay directly with a specific UPI app (no picker shown)
  ///
  /// Use this when you already know which app the user wants.
  static Future<UpiResponse?> payWithApp({
    required UpiPayment payment,
    required UpiApp app,
  }) async {
    if (!UpiValidator.isValidVpa(payment.payeeVpa)) {
      throw UpiException('Invalid UPI VPA: "${payment.payeeVpa}"');
    }

    final upiUrl = UpiUrlBuilder.build(payment);
    return _platform.launchUpiApp(
      upiUrl: upiUrl,
      packageName: app.packageName,
    );
  }

  /// Build a raw UPI URL without launching anything
  ///
  /// Useful for QR code generation or sharing payment links.
  static String buildUpiUrl(UpiPayment payment) {
    return UpiUrlBuilder.build(payment);
  }
}
