// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExpenseData _$ExpenseDataFromJson(Map<String, dynamic> json) => _ExpenseData(
  id: json['id'] as String,
  amount: (json['amount'] as num).toDouble(),
  category: json['category'] as String,
  date: DateTime.parse(json['date'] as String),
  type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
  note: json['note'] as String,
);

Map<String, dynamic> _$ExpenseDataToJson(_ExpenseData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'category': instance.category,
      'date': instance.date.toIso8601String(),
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'note': instance.note,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.incoming: 'incoming',
  TransactionType.outgoing: 'outgoing',
  TransactionType.invested: 'invested',
};
