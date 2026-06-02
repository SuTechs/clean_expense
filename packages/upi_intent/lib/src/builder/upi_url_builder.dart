import '../models/upi_payment.dart';

/// Builds NPCI-spec compliant UPI payment URLs
///
/// Format: `upi://pay?pa=VPA&pn=NAME&am=AMOUNT&cu=INR&...`
class UpiUrlBuilder {
  UpiUrlBuilder._();

  /// Build a UPI payment URL from [UpiPayment]
  static String build(UpiPayment payment) {
    final params = <String, String>{
      'pa': payment.payeeVpa,
      'pn': Uri.encodeComponent(payment.payeeName),
      'cu': 'INR',
    };

    if (payment.amount != null && payment.amount! > 0) {
      params['am'] = payment.amount!.toStringAsFixed(2);
    }

    if (payment.transactionNote != null &&
        payment.transactionNote!.isNotEmpty) {
      params['tn'] = Uri.encodeComponent(payment.transactionNote!);
    }

    if (payment.transactionRefId != null &&
        payment.transactionRefId!.isNotEmpty) {
      params['tr'] = payment.transactionRefId!;
    }

    if (payment.merchantCode != null && payment.merchantCode!.isNotEmpty) {
      params['mc'] = payment.merchantCode!;
    }

    final query =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');

    return 'upi://pay?$query';
  }
}
