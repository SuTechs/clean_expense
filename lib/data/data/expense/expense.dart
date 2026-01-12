import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

enum TransactionType { incoming, outgoing, invested }

@freezed
abstract class ExpenseData with _$ExpenseData {
  const ExpenseData._();

  const factory ExpenseData({
    required String id,
    required double amount,
    required String category,
    required DateTime date,
    required TransactionType type,
    required String note,
  }) = _ExpenseData;

  factory ExpenseData.fromJson(Map<String, dynamic> json) =>
      _$ExpenseDataFromJson(json);
}
