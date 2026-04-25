// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadOperation<T> _$ReadOperationFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ReadOperation<T>(
  operationId: json['operationId'] as String,
  itemId: json['itemId'] as String,
  details: const RequestDetailsConverter().fromJson(
    json['details'] as Map<String, Object?>,
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
  attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 0,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$ReadOperationToJson<T>(
  ReadOperation<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'operationId': instance.operationId,
  'itemId': instance.itemId,
  'details': const RequestDetailsConverter().toJson(instance.details),
  'createdAt': instance.createdAt.toIso8601String(),
  'attemptNumber': instance.attemptNumber,
  'runtimeType': instance.$type,
};

ReadListOperation<T> _$ReadListOperationFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ReadListOperation<T>(
  operationId: json['operationId'] as String,
  details: const RequestDetailsConverter().fromJson(
    json['details'] as Map<String, Object?>,
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
  attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 0,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$ReadListOperationToJson<T>(
  ReadListOperation<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'operationId': instance.operationId,
  'details': const RequestDetailsConverter().toJson(instance.details),
  'createdAt': instance.createdAt.toIso8601String(),
  'attemptNumber': instance.attemptNumber,
  'runtimeType': instance.$type,
};

ReadByIdsOperation<T> _$ReadByIdsOperationFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ReadByIdsOperation<T>(
  operationId: json['operationId'] as String,
  itemIds: (json['itemIds'] as List<dynamic>).map((e) => e as String).toSet(),
  details: const RequestDetailsConverter().fromJson(
    json['details'] as Map<String, Object?>,
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
  attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 0,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$ReadByIdsOperationToJson<T>(
  ReadByIdsOperation<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'operationId': instance.operationId,
  'itemIds': instance.itemIds.toList(),
  'details': const RequestDetailsConverter().toJson(instance.details),
  'createdAt': instance.createdAt.toIso8601String(),
  'attemptNumber': instance.attemptNumber,
  'runtimeType': instance.$type,
};

WriteOperation<T> _$WriteOperationFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => WriteOperation<T>(
  operationId: json['operationId'] as String,
  details: const RequestDetailsConverter().fromJson(
    json['details'] as Map<String, Object?>,
  ),
  item: fromJsonT(json['item']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 0,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$WriteOperationToJson<T>(
  WriteOperation<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'operationId': instance.operationId,
  'details': const RequestDetailsConverter().toJson(instance.details),
  'item': toJsonT(instance.item),
  'createdAt': instance.createdAt.toIso8601String(),
  'attemptNumber': instance.attemptNumber,
  'runtimeType': instance.$type,
};

WriteListOperation<T> _$WriteListOperationFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => WriteListOperation<T>(
  operationId: json['operationId'] as String,
  details: const RequestDetailsConverter().fromJson(
    json['details'] as Map<String, Object?>,
  ),
  items: (json['items'] as List<dynamic>).map(fromJsonT),
  createdAt: DateTime.parse(json['createdAt'] as String),
  attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 0,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$WriteListOperationToJson<T>(
  WriteListOperation<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'operationId': instance.operationId,
  'details': const RequestDetailsConverter().toJson(instance.details),
  'items': instance.items.map(toJsonT).toList(),
  'createdAt': instance.createdAt.toIso8601String(),
  'attemptNumber': instance.attemptNumber,
  'runtimeType': instance.$type,
};

DeleteOperation<T> _$DeleteOperationFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => DeleteOperation<T>(
  operationId: json['operationId'] as String,
  itemId: json['itemId'] as String,
  details: const RequestDetailsConverter().fromJson(
    json['details'] as Map<String, Object?>,
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
  attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 0,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$DeleteOperationToJson<T>(
  DeleteOperation<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'operationId': instance.operationId,
  'itemId': instance.itemId,
  'details': const RequestDetailsConverter().toJson(instance.details),
  'createdAt': instance.createdAt.toIso8601String(),
  'attemptNumber': instance.attemptNumber,
  'runtimeType': instance.$type,
};

SendMessageOperation<T> _$SendMessageOperationFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => SendMessageOperation<T>(
  operationId: json['operationId'] as String,
  message: json['message'] as Object,
  details: const RequestDetailsConverter().fromJson(
    json['details'] as Map<String, Object?>,
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
  targetId: json['targetId'] as String?,
  attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 0,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$SendMessageOperationToJson<T>(
  SendMessageOperation<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'operationId': instance.operationId,
  'message': instance.message,
  'details': const RequestDetailsConverter().toJson(instance.details),
  'createdAt': instance.createdAt.toIso8601String(),
  'targetId': instance.targetId,
  'attemptNumber': instance.attemptNumber,
  'runtimeType': instance.$type,
};
