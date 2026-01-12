/// Result of parsing a transaction input string.
class TransactionParserResult {
  /// Extracted category from #tag (without the #)
  final String? category;

  /// Extracted amount (first/last number found)
  final double? amount;

  /// Remaining text after removing category and amount
  final String? notes;

  /// True if both category and amount were found
  bool get isValid => category != null && amount != null;

  const TransactionParserResult({this.category, this.amount, this.notes});

  @override
  String toString() =>
      'TransactionParserResult(category: $category, amount: $amount, notes: $notes, isValid: $isValid)';
}

/// Service for parsing user input into structured transaction data.
///
/// Currently supports simple format: any combination of #category, amount, and notes.
/// Example inputs:
/// - "Lunch #food 150" -> category: food, amount: 150, notes: Lunch
/// - "#shopping 500 New shoes" -> category: shopping, amount: 500, notes: New shoes
/// - "200 #bills Electricity" -> category: bills, amount: 200, notes: Electricity
///
/// Future: Can be extended to use AI for natural language parsing.
class TransactionParserService {
  // Singleton pattern for easy access
  static final TransactionParserService _instance =
      TransactionParserService._internal();
  factory TransactionParserService() => _instance;
  TransactionParserService._internal();

  /// Regex to find numbers (integers or decimals)
  static final RegExp _amountRegex = RegExp(r'\b(\d+(?:\.\d+)?)\b');

  /// Regex to find hashtag categories
  static final RegExp _categoryRegex = RegExp(r'#(\w+)');

  /// Parses the input string to extract category, amount, and notes.
  ///
  /// The input can be in any order:
  /// - Category: starts with # (e.g., #food, #shopping)
  /// - Amount: any number (e.g., 150, 200.50)
  /// - Notes: remaining text after removing category and amount
  TransactionParserResult parse(String input) {
    if (input.trim().isEmpty) {
      return const TransactionParserResult();
    }

    String workingText = input;

    // 1. Extract category (first #tag found)
    String? category;
    final categoryMatch = _categoryRegex.firstMatch(workingText);
    if (categoryMatch != null) {
      category = categoryMatch.group(1)?.toLowerCase();
      // Remove the matched category from working text
      workingText = workingText.replaceFirst(categoryMatch.group(0)!, '');
    }

    // 2. Extract amount (last number found - heuristic: amounts usually come after quantity)
    // Example: "2 Burgers 500" -> amount is 500, not 2
    double? amount;
    final allNumbers = _amountRegex.allMatches(workingText).toList();
    if (allNumbers.isNotEmpty) {
      // Take the last number as the amount
      final amountMatch = allNumbers.last;
      amount = double.tryParse(amountMatch.group(1)!);
      // Remove the matched amount from working text
      workingText = workingText.replaceRange(
        amountMatch.start,
        amountMatch.end,
        '',
      );
    }

    // 3. Clean up remaining text as notes
    String? notes = _cleanNotes(workingText);

    return TransactionParserResult(
      category: category,
      amount: amount,
      notes: notes,
    );
  }

  /// Cleans up the notes string by removing extra whitespace.
  String? _cleanNotes(String text) {
    // Remove extra whitespace and trim
    String cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}
