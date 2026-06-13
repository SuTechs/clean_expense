// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BackupData _$BackupDataFromJson(Map<String, dynamic> json) => _BackupData(
  schemaVersion: (json['schemaVersion'] as num).toInt(),
  app: json['app'] as String,
  lastModified: (json['lastModified'] as num).toInt(),
  user: UserData.fromJson(json['user'] as Map<String, dynamic>),
  settings: Map<String, String>.from(json['settings'] as Map),
  tombstones: Map<String, int>.from(json['tombstones'] as Map),
  expenses: (json['expenses'] as List<dynamic>)
      .map((e) => ExpenseData.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BackupDataToJson(_BackupData instance) =>
    <String, dynamic>{
      'schemaVersion': instance.schemaVersion,
      'app': instance.app,
      'lastModified': instance.lastModified,
      'user': instance.user,
      'settings': instance.settings,
      'tombstones': instance.tombstones,
      'expenses': instance.expenses,
    };
