/// UPI transaction result status
enum UpiTransactionStatus {
  /// Payment completed successfully
  success,

  /// Payment failed
  failure,

  /// Payment submitted but not yet confirmed
  submitted,

  /// Status unknown (network/timeout issues)
  unknown,
}

/// Result of a UPI payment transaction
class UpiResponse {
  /// Final transaction status
  final UpiTransactionStatus status;

  /// UPI transaction ID assigned by PSP
  final String? transactionId;

  /// NPCI response code
  final String? responseCode;

  /// Bank approval reference number
  final String? approvalRefNo;

  /// Full raw response string from UPI app
  final String rawResponse;

  const UpiResponse({
    required this.status,
    required this.rawResponse,
    this.transactionId,
    this.responseCode,
    this.approvalRefNo,
  });

  /// Parse raw UPI response string into [UpiResponse]
  factory UpiResponse.fromResponseString(String response) {
    final params = Uri.splitQueryString(response);
    final statusStr = params['Status']?.toLowerCase() ??
        params['status']?.toLowerCase();

    final status = switch (statusStr) {
      'success' => UpiTransactionStatus.success,
      'failure' => UpiTransactionStatus.failure,
      'submitted' => UpiTransactionStatus.submitted,
      _ => UpiTransactionStatus.unknown,
    };

    return UpiResponse(
      rawResponse: response,
      status: status,
      transactionId: params['txnId'] ?? params['txnid'],
      responseCode: params['responseCode'],
      approvalRefNo: params['ApprovalRefNo'],
    );
  }

  /// Whether payment was successful
  bool get isSuccess => status == UpiTransactionStatus.success;

  /// Whether payment failed
  bool get isFailure => status == UpiTransactionStatus.failure;

  @override
  String toString() =>
      'UpiResponse(status: $status, txnId: $transactionId)';
}
