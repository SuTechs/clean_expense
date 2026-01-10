import 'package:hive_ce/hive.dart';

enum TransactionType {
  incoming, // Credit

  outgoing, // Debit

  invested, // Investment
}

class Expense extends HiveObject {
  final String id;

  final double amount;

  final String category;

  final DateTime date;

  final TransactionType type;

  final String note;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    required this.note,
  });
}
