/// UPI Payment request model (NPCI spec compliant)
class UpiPayment {
  /// Payee UPI VPA (e.g., "merchant@upi") — REQUIRED
  final String payeeVpa;

  /// Payee display name — REQUIRED
  final String payeeName;

  /// Transaction amount in INR — Optional (user fills if null)
  final double? amount;

  /// Short transaction note shown in UPI app
  final String? transactionNote;

  /// Unique merchant transaction reference ID
  final String? transactionRefId;

  /// Merchant Category Code
  final String? merchantCode;

  const UpiPayment({
    required this.payeeVpa,
    required this.payeeName,
    this.amount,
    this.transactionNote,
    this.transactionRefId,
    this.merchantCode,
  });
}
