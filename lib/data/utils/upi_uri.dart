/// Lightweight parser for UPI deep-link QR codes.
///
/// A UPI QR encodes a string like:
///   upi://pay?pa=merchant@bank&pn=Merchant%20Name&am=100.00&cu=INR&tn=Order
///
/// We only need the payee address (`pa`), an optional display name (`pn`)
/// and an optional pre-filled amount (`am`). Everything else is ignored — we
/// rebuild a fresh intent at pay time with the user-entered amount.
class UpiQrData {
  /// Payee VPA / UPI ID (the `pa` parameter). Always present.
  final String vpa;

  /// Payee display name (the `pn` parameter), if the QR provided one.
  final String? name;

  /// Pre-filled amount (the `am` parameter), if the QR provided one.
  final double? amount;

  const UpiQrData({required this.vpa, this.name, this.amount});

  /// Parse a scanned string into [UpiQrData].
  ///
  /// Returns `null` when the string is not a usable UPI QR — i.e. it isn't a
  /// `upi://` link or it lacks a payee address. Callers should treat `null`
  /// as "not a UPI QR" and let the user rescan.
  static UpiQrData? tryParse(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (uri.scheme.toLowerCase() != 'upi') return null;

    final params = uri.queryParameters;
    final pa = params['pa']?.trim();
    if (pa == null || pa.isEmpty) return null;

    final pn = params['pn']?.trim();

    double? amount;
    final am = params['am']?.trim();
    if (am != null && am.isNotEmpty) {
      final parsed = double.tryParse(am);
      if (parsed != null && parsed > 0) amount = parsed;
    }

    return UpiQrData(
      vpa: pa,
      name: (pn != null && pn.isNotEmpty) ? pn : null,
      amount: amount,
    );
  }
}
