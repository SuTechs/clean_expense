/// Validates UPI payment fields before launching an intent
class UpiValidator {
  UpiValidator._();

  /// UPI VPA regex: alphanumeric/dot/dash/underscore @ 3+ alpha chars
  static final _vpaRegex = RegExp(r'^[a-zA-Z0-9._\-]+@[a-zA-Z]{3,}$');

  /// Validates a UPI Virtual Payment Address (VPA)
  ///
  /// Examples of valid VPAs:
  /// - `user@upi`
  /// - `9876543210@paytm`
  /// - `john.doe@oksbi`
  static bool isValidVpa(String vpa) {
    if (vpa.trim().isEmpty) return false;
    return _vpaRegex.hasMatch(vpa.trim());
  }

  /// Validates a payment amount
  ///
  /// Rules:
  /// - Must be positive
  /// - Must not exceed ₹1,00,000 (per NPCI limit)
  static bool isValidAmount(double amount) {
    if (amount <= 0) return false;
    if (amount > 100000) return false;
    return true;
  }

  /// Converts a 10-digit phone number to a UPI ID
  ///
  /// Example: `phoneToVpa("9876543210", "paytm")` → `"9876543210@paytm"`
  static String phoneToVpa(String phone, String bankHandle) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 10) {
      throw ArgumentError('Phone number must be exactly 10 digits');
    }
    return '$clean@$bankHandle';
  }

  /// Extracts bank handle from VPA
  ///
  /// Example: `bankHandle("user@oksbi")` → `"oksbi"`
  static String? bankHandle(String vpa) {
    final parts = vpa.split('@');
    return parts.length == 2 ? parts[1] : null;
  }
}
