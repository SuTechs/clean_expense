/// Custom exception for UPI-related errors
class UpiException implements Exception {
  /// Human-readable error message
  final String message;

  /// Optional error code
  final String? code;

  const UpiException(this.message, {this.code});

  @override
  String toString() => 'UpiException: $message${code != null ? ' (code: $code)' : ''}';
}
