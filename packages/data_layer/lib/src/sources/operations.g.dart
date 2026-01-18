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
  details: RequestDetails.fromJson(json['details'] as Map<String, dynamic>),
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
  'details': instance.details,
  'createdAt': instance.createdAt.toIso8601String(),
  'attemptNumber': instance.attemptNumber,
  'runtimeType': instance.$type,
};

ReadListOperation<T> _$ReadListOperationFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ReadListOperation<T>(
  operationId: json['operationId'] as String,
  details: RequestDetails.fromJson(json['details'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 0,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$ReadListOperationToJson<T>(
  ReadListOperation<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'operationId': instance.operationId,
  'details': instance.details,
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
  details: RequestDetails.fromJson(json['details'] as Map<String, dynamic>),
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
  'details': instance.details,
  'createdAt': instance.createdAt.toIso8601String(),
  'attemptNumber': instance.attemptNumber,
  'runtimeType': instance.$type,
};

WriteOperation<T> _$WriteOperationFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => WriteOperation<T>(
  operationId: json['operationId'] as String,
  details: RequestDetails.fromJson(json['details'] as Map<String, dynamic>),
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
  'details': instance.details,
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
  details: RequestDetails.fromJson(json['details'] as Map<String, dynamic>),
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
  'details': instance.details,
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
  details: RequestDetails.fromJson(json['details'] as Map<String, dynamic>),
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
  'details': instance.details,
  'createdAt': instance.createdAt.toIso8601String(),
  'attemptNumber': instance.attemptNumber,
  'runtimeType': instance.$type,
};
