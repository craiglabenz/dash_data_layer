// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TestRecord _$TestRecordFromJson(Map<String, dynamic> json) => _TestRecord(
  id: json['id'] as String,
  value: json['value'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$TestRecordToJson(_TestRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'value': instance.value,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_TestRecordMessageCreate _$TestRecordMessageCreateFromJson(
  Map<String, dynamic> json,
) => _TestRecordMessageCreate(
  value: json['value'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$TestRecordMessageCreateToJson(
  _TestRecordMessageCreate instance,
) => <String, dynamic>{'value': instance.value, 'runtimeType': instance.$type};

_TestRecordMessageUpdate _$TestRecordMessageUpdateFromJson(
  Map<String, dynamic> json,
) => _TestRecordMessageUpdate(
  value: json['value'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$TestRecordMessageUpdateToJson(
  _TestRecordMessageUpdate instance,
) => <String, dynamic>{'value': instance.value, 'runtimeType': instance.$type};
