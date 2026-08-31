// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operations.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
Operation<T> _$OperationFromJson<T>(
  Map<String, dynamic> json,T Function(Object?) fromJsonT
) {
        switch (json['runtimeType']) {
                  case 'getItem':
          return ReadOperation<T>.fromJson(
            json,fromJsonT
          );
                case 'getItems':
          return ReadListOperation<T>.fromJson(
            json,fromJsonT
          );
                case 'getByIds':
          return ReadByIdsOperation<T>.fromJson(
            json,fromJsonT
          );
                case 'setItem':
          return WriteOperation<T>.fromJson(
            json,fromJsonT
          );
                case 'setItems':
          return WriteListOperation<T>.fromJson(
            json,fromJsonT
          );
                case 'delete':
          return DeleteOperation<T>.fromJson(
            json,fromJsonT
          );
                case 'deleteItems':
          return DeleteListOperation<T>.fromJson(
            json,fromJsonT
          );
                case 'sendMessage':
          return SendMessageOperation<T>.fromJson(
            json,fromJsonT
          );
                case 'watch':
          return WatchOperation<T>.fromJson(
            json,fromJsonT
          );
                case 'watchList':
          return WatchListOperation<T>.fromJson(
            json,fromJsonT
          );
                case 'watchByIds':
          return WatchByIdsOperation<T>.fromJson(
            json,fromJsonT
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'Operation',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$Operation<T> {

 String get operationId;@RequestDetailsConverter() RequestDetails get details;// required List<Json> data,
 DateTime get createdAt; int get attemptNumber;
/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationCopyWith<T, Operation<T>> get copyWith => _$OperationCopyWithImpl<T, Operation<T>>(this as Operation<T>, _$identity);

  /// Serializes this Operation to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT);


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Operation<T>&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,details,createdAt,attemptNumber);

@override
String toString() {
  return 'Operation<$T>(operationId: $operationId, details: $details, createdAt: $createdAt, attemptNumber: $attemptNumber)';
}


}

/// @nodoc
abstract mixin class $OperationCopyWith<T,$Res>  {
  factory $OperationCopyWith(Operation<T> value, $Res Function(Operation<T>) _then) = _$OperationCopyWithImpl;
@useResult
$Res call({
 String operationId,@RequestDetailsConverter() RequestDetails details, DateTime createdAt, int attemptNumber
});




}
/// @nodoc
class _$OperationCopyWithImpl<T,$Res>
    implements $OperationCopyWith<T, $Res> {
  _$OperationCopyWithImpl(this._self, this._then);

  final Operation<T> _self;
  final $Res Function(Operation<T>) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? operationId = null,Object? details = null,Object? createdAt = null,Object? attemptNumber = null,}) {
  return _then(_self.copyWith(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as RequestDetails,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Operation].
extension OperationPatterns<T> on Operation<T> {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReadOperation<T> value)?  getItem,TResult Function( ReadListOperation<T> value)?  getItems,TResult Function( ReadByIdsOperation<T> value)?  getByIds,TResult Function( WriteOperation<T> value)?  setItem,TResult Function( WriteListOperation<T> value)?  setItems,TResult Function( DeleteOperation<T> value)?  delete,TResult Function( DeleteListOperation<T> value)?  deleteItems,TResult Function( SendMessageOperation<T> value)?  sendMessage,TResult Function( WatchOperation<T> value)?  watch,TResult Function( WatchListOperation<T> value)?  watchList,TResult Function( WatchByIdsOperation<T> value)?  watchByIds,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReadOperation() when getItem != null:
return getItem(_that);case ReadListOperation() when getItems != null:
return getItems(_that);case ReadByIdsOperation() when getByIds != null:
return getByIds(_that);case WriteOperation() when setItem != null:
return setItem(_that);case WriteListOperation() when setItems != null:
return setItems(_that);case DeleteOperation() when delete != null:
return delete(_that);case DeleteListOperation() when deleteItems != null:
return deleteItems(_that);case SendMessageOperation() when sendMessage != null:
return sendMessage(_that);case WatchOperation() when watch != null:
return watch(_that);case WatchListOperation() when watchList != null:
return watchList(_that);case WatchByIdsOperation() when watchByIds != null:
return watchByIds(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReadOperation<T> value)  getItem,required TResult Function( ReadListOperation<T> value)  getItems,required TResult Function( ReadByIdsOperation<T> value)  getByIds,required TResult Function( WriteOperation<T> value)  setItem,required TResult Function( WriteListOperation<T> value)  setItems,required TResult Function( DeleteOperation<T> value)  delete,required TResult Function( DeleteListOperation<T> value)  deleteItems,required TResult Function( SendMessageOperation<T> value)  sendMessage,required TResult Function( WatchOperation<T> value)  watch,required TResult Function( WatchListOperation<T> value)  watchList,required TResult Function( WatchByIdsOperation<T> value)  watchByIds,}){
final _that = this;
switch (_that) {
case ReadOperation():
return getItem(_that);case ReadListOperation():
return getItems(_that);case ReadByIdsOperation():
return getByIds(_that);case WriteOperation():
return setItem(_that);case WriteListOperation():
return setItems(_that);case DeleteOperation():
return delete(_that);case DeleteListOperation():
return deleteItems(_that);case SendMessageOperation():
return sendMessage(_that);case WatchOperation():
return watch(_that);case WatchListOperation():
return watchList(_that);case WatchByIdsOperation():
return watchByIds(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReadOperation<T> value)?  getItem,TResult? Function( ReadListOperation<T> value)?  getItems,TResult? Function( ReadByIdsOperation<T> value)?  getByIds,TResult? Function( WriteOperation<T> value)?  setItem,TResult? Function( WriteListOperation<T> value)?  setItems,TResult? Function( DeleteOperation<T> value)?  delete,TResult? Function( DeleteListOperation<T> value)?  deleteItems,TResult? Function( SendMessageOperation<T> value)?  sendMessage,TResult? Function( WatchOperation<T> value)?  watch,TResult? Function( WatchListOperation<T> value)?  watchList,TResult? Function( WatchByIdsOperation<T> value)?  watchByIds,}){
final _that = this;
switch (_that) {
case ReadOperation() when getItem != null:
return getItem(_that);case ReadListOperation() when getItems != null:
return getItems(_that);case ReadByIdsOperation() when getByIds != null:
return getByIds(_that);case WriteOperation() when setItem != null:
return setItem(_that);case WriteListOperation() when setItems != null:
return setItems(_that);case DeleteOperation() when delete != null:
return delete(_that);case DeleteListOperation() when deleteItems != null:
return deleteItems(_that);case SendMessageOperation() when sendMessage != null:
return sendMessage(_that);case WatchOperation() when watch != null:
return watch(_that);case WatchListOperation() when watchList != null:
return watchList(_that);case WatchByIdsOperation() when watchByIds != null:
return watchByIds(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String operationId,  String itemId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  getItem,TResult Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  getItems,TResult Function( String operationId,  Set<String> itemIds, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  getByIds,TResult Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  T item,  DateTime createdAt,  int attemptNumber)?  setItem,TResult Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  Iterable<T> items,  DateTime createdAt,  int attemptNumber)?  setItems,TResult Function( String operationId,  String itemId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  delete,TResult Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  deleteItems,TResult Function( String operationId,  Object message, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  String? targetId,  int attemptNumber)?  sendMessage,TResult Function( String operationId,  String itemId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  watch,TResult Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  watchList,TResult Function( String operationId,  Set<String> itemIds, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  watchByIds,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReadOperation() when getItem != null:
return getItem(_that.operationId,_that.itemId,_that.details,_that.createdAt,_that.attemptNumber);case ReadListOperation() when getItems != null:
return getItems(_that.operationId,_that.details,_that.createdAt,_that.attemptNumber);case ReadByIdsOperation() when getByIds != null:
return getByIds(_that.operationId,_that.itemIds,_that.details,_that.createdAt,_that.attemptNumber);case WriteOperation() when setItem != null:
return setItem(_that.operationId,_that.details,_that.item,_that.createdAt,_that.attemptNumber);case WriteListOperation() when setItems != null:
return setItems(_that.operationId,_that.details,_that.items,_that.createdAt,_that.attemptNumber);case DeleteOperation() when delete != null:
return delete(_that.operationId,_that.itemId,_that.details,_that.createdAt,_that.attemptNumber);case DeleteListOperation() when deleteItems != null:
return deleteItems(_that.operationId,_that.details,_that.createdAt,_that.attemptNumber);case SendMessageOperation() when sendMessage != null:
return sendMessage(_that.operationId,_that.message,_that.details,_that.createdAt,_that.targetId,_that.attemptNumber);case WatchOperation() when watch != null:
return watch(_that.operationId,_that.itemId,_that.details,_that.createdAt,_that.attemptNumber);case WatchListOperation() when watchList != null:
return watchList(_that.operationId,_that.details,_that.createdAt,_that.attemptNumber);case WatchByIdsOperation() when watchByIds != null:
return watchByIds(_that.operationId,_that.itemIds,_that.details,_that.createdAt,_that.attemptNumber);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String operationId,  String itemId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)  getItem,required TResult Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)  getItems,required TResult Function( String operationId,  Set<String> itemIds, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)  getByIds,required TResult Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  T item,  DateTime createdAt,  int attemptNumber)  setItem,required TResult Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  Iterable<T> items,  DateTime createdAt,  int attemptNumber)  setItems,required TResult Function( String operationId,  String itemId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)  delete,required TResult Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)  deleteItems,required TResult Function( String operationId,  Object message, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  String? targetId,  int attemptNumber)  sendMessage,required TResult Function( String operationId,  String itemId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)  watch,required TResult Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)  watchList,required TResult Function( String operationId,  Set<String> itemIds, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)  watchByIds,}) {final _that = this;
switch (_that) {
case ReadOperation():
return getItem(_that.operationId,_that.itemId,_that.details,_that.createdAt,_that.attemptNumber);case ReadListOperation():
return getItems(_that.operationId,_that.details,_that.createdAt,_that.attemptNumber);case ReadByIdsOperation():
return getByIds(_that.operationId,_that.itemIds,_that.details,_that.createdAt,_that.attemptNumber);case WriteOperation():
return setItem(_that.operationId,_that.details,_that.item,_that.createdAt,_that.attemptNumber);case WriteListOperation():
return setItems(_that.operationId,_that.details,_that.items,_that.createdAt,_that.attemptNumber);case DeleteOperation():
return delete(_that.operationId,_that.itemId,_that.details,_that.createdAt,_that.attemptNumber);case DeleteListOperation():
return deleteItems(_that.operationId,_that.details,_that.createdAt,_that.attemptNumber);case SendMessageOperation():
return sendMessage(_that.operationId,_that.message,_that.details,_that.createdAt,_that.targetId,_that.attemptNumber);case WatchOperation():
return watch(_that.operationId,_that.itemId,_that.details,_that.createdAt,_that.attemptNumber);case WatchListOperation():
return watchList(_that.operationId,_that.details,_that.createdAt,_that.attemptNumber);case WatchByIdsOperation():
return watchByIds(_that.operationId,_that.itemIds,_that.details,_that.createdAt,_that.attemptNumber);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String operationId,  String itemId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  getItem,TResult? Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  getItems,TResult? Function( String operationId,  Set<String> itemIds, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  getByIds,TResult? Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  T item,  DateTime createdAt,  int attemptNumber)?  setItem,TResult? Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  Iterable<T> items,  DateTime createdAt,  int attemptNumber)?  setItems,TResult? Function( String operationId,  String itemId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  delete,TResult? Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  deleteItems,TResult? Function( String operationId,  Object message, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  String? targetId,  int attemptNumber)?  sendMessage,TResult? Function( String operationId,  String itemId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  watch,TResult? Function( String operationId, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  watchList,TResult? Function( String operationId,  Set<String> itemIds, @RequestDetailsConverter()  RequestDetails details,  DateTime createdAt,  int attemptNumber)?  watchByIds,}) {final _that = this;
switch (_that) {
case ReadOperation() when getItem != null:
return getItem(_that.operationId,_that.itemId,_that.details,_that.createdAt,_that.attemptNumber);case ReadListOperation() when getItems != null:
return getItems(_that.operationId,_that.details,_that.createdAt,_that.attemptNumber);case ReadByIdsOperation() when getByIds != null:
return getByIds(_that.operationId,_that.itemIds,_that.details,_that.createdAt,_that.attemptNumber);case WriteOperation() when setItem != null:
return setItem(_that.operationId,_that.details,_that.item,_that.createdAt,_that.attemptNumber);case WriteListOperation() when setItems != null:
return setItems(_that.operationId,_that.details,_that.items,_that.createdAt,_that.attemptNumber);case DeleteOperation() when delete != null:
return delete(_that.operationId,_that.itemId,_that.details,_that.createdAt,_that.attemptNumber);case DeleteListOperation() when deleteItems != null:
return deleteItems(_that.operationId,_that.details,_that.createdAt,_that.attemptNumber);case SendMessageOperation() when sendMessage != null:
return sendMessage(_that.operationId,_that.message,_that.details,_that.createdAt,_that.targetId,_that.attemptNumber);case WatchOperation() when watch != null:
return watch(_that.operationId,_that.itemId,_that.details,_that.createdAt,_that.attemptNumber);case WatchListOperation() when watchList != null:
return watchList(_that.operationId,_that.details,_that.createdAt,_that.attemptNumber);case WatchByIdsOperation() when watchByIds != null:
return watchByIds(_that.operationId,_that.itemIds,_that.details,_that.createdAt,_that.attemptNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class ReadOperation<T> extends Operation<T> {
  const ReadOperation({required this.operationId, required this.itemId, @RequestDetailsConverter() required this.details, required this.createdAt, this.attemptNumber = 0, final  String? $type}): $type = $type ?? 'getItem',super._();
  factory ReadOperation.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$ReadOperationFromJson(json,fromJsonT);

@override final  String operationId;
 final  String itemId;
@override@RequestDetailsConverter() final  RequestDetails details;
@override final  DateTime createdAt;
@override@JsonKey() final  int attemptNumber;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadOperationCopyWith<T, ReadOperation<T>> get copyWith => _$ReadOperationCopyWithImpl<T, ReadOperation<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$ReadOperationToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadOperation<T>&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,itemId,details,createdAt,attemptNumber);

@override
String toString() {
  return 'Operation<$T>.getItem(operationId: $operationId, itemId: $itemId, details: $details, createdAt: $createdAt, attemptNumber: $attemptNumber)';
}


}

/// @nodoc
abstract mixin class $ReadOperationCopyWith<T,$Res> implements $OperationCopyWith<T, $Res> {
  factory $ReadOperationCopyWith(ReadOperation<T> value, $Res Function(ReadOperation<T>) _then) = _$ReadOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId, String itemId,@RequestDetailsConverter() RequestDetails details, DateTime createdAt, int attemptNumber
});




}
/// @nodoc
class _$ReadOperationCopyWithImpl<T,$Res>
    implements $ReadOperationCopyWith<T, $Res> {
  _$ReadOperationCopyWithImpl(this._self, this._then);

  final ReadOperation<T> _self;
  final $Res Function(ReadOperation<T>) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? itemId = null,Object? details = null,Object? createdAt = null,Object? attemptNumber = null,}) {
  return _then(ReadOperation<T>(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as RequestDetails,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class ReadListOperation<T> extends Operation<T> {
  const ReadListOperation({required this.operationId, @RequestDetailsConverter() required this.details, required this.createdAt, this.attemptNumber = 0, final  String? $type}): $type = $type ?? 'getItems',super._();
  factory ReadListOperation.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$ReadListOperationFromJson(json,fromJsonT);

@override final  String operationId;
@override@RequestDetailsConverter() final  RequestDetails details;
@override final  DateTime createdAt;
@override@JsonKey() final  int attemptNumber;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadListOperationCopyWith<T, ReadListOperation<T>> get copyWith => _$ReadListOperationCopyWithImpl<T, ReadListOperation<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$ReadListOperationToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadListOperation<T>&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,details,createdAt,attemptNumber);

@override
String toString() {
  return 'Operation<$T>.getItems(operationId: $operationId, details: $details, createdAt: $createdAt, attemptNumber: $attemptNumber)';
}


}

/// @nodoc
abstract mixin class $ReadListOperationCopyWith<T,$Res> implements $OperationCopyWith<T, $Res> {
  factory $ReadListOperationCopyWith(ReadListOperation<T> value, $Res Function(ReadListOperation<T>) _then) = _$ReadListOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId,@RequestDetailsConverter() RequestDetails details, DateTime createdAt, int attemptNumber
});




}
/// @nodoc
class _$ReadListOperationCopyWithImpl<T,$Res>
    implements $ReadListOperationCopyWith<T, $Res> {
  _$ReadListOperationCopyWithImpl(this._self, this._then);

  final ReadListOperation<T> _self;
  final $Res Function(ReadListOperation<T>) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? details = null,Object? createdAt = null,Object? attemptNumber = null,}) {
  return _then(ReadListOperation<T>(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as RequestDetails,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class ReadByIdsOperation<T> extends Operation<T> {
  const ReadByIdsOperation({required this.operationId, required final  Set<String> itemIds, @RequestDetailsConverter() required this.details, required this.createdAt, this.attemptNumber = 0, final  String? $type}): _itemIds = itemIds,$type = $type ?? 'getByIds',super._();
  factory ReadByIdsOperation.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$ReadByIdsOperationFromJson(json,fromJsonT);

@override final  String operationId;
 final  Set<String> _itemIds;
 Set<String> get itemIds {
  if (_itemIds is EqualUnmodifiableSetView) return _itemIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_itemIds);
}

@override@RequestDetailsConverter() final  RequestDetails details;
@override final  DateTime createdAt;
@override@JsonKey() final  int attemptNumber;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadByIdsOperationCopyWith<T, ReadByIdsOperation<T>> get copyWith => _$ReadByIdsOperationCopyWithImpl<T, ReadByIdsOperation<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$ReadByIdsOperationToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadByIdsOperation<T>&&(identical(other.operationId, operationId) || other.operationId == operationId)&&const DeepCollectionEquality().equals(other._itemIds, _itemIds)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,const DeepCollectionEquality().hash(_itemIds),details,createdAt,attemptNumber);

@override
String toString() {
  return 'Operation<$T>.getByIds(operationId: $operationId, itemIds: $itemIds, details: $details, createdAt: $createdAt, attemptNumber: $attemptNumber)';
}


}

/// @nodoc
abstract mixin class $ReadByIdsOperationCopyWith<T,$Res> implements $OperationCopyWith<T, $Res> {
  factory $ReadByIdsOperationCopyWith(ReadByIdsOperation<T> value, $Res Function(ReadByIdsOperation<T>) _then) = _$ReadByIdsOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId, Set<String> itemIds,@RequestDetailsConverter() RequestDetails details, DateTime createdAt, int attemptNumber
});




}
/// @nodoc
class _$ReadByIdsOperationCopyWithImpl<T,$Res>
    implements $ReadByIdsOperationCopyWith<T, $Res> {
  _$ReadByIdsOperationCopyWithImpl(this._self, this._then);

  final ReadByIdsOperation<T> _self;
  final $Res Function(ReadByIdsOperation<T>) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? itemIds = null,Object? details = null,Object? createdAt = null,Object? attemptNumber = null,}) {
  return _then(ReadByIdsOperation<T>(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,itemIds: null == itemIds ? _self._itemIds : itemIds // ignore: cast_nullable_to_non_nullable
as Set<String>,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as RequestDetails,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class WriteOperation<T> extends Operation<T> {
  const WriteOperation({required this.operationId, @RequestDetailsConverter() required this.details, required this.item, required this.createdAt, this.attemptNumber = 0, final  String? $type}): $type = $type ?? 'setItem',super._();
  factory WriteOperation.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$WriteOperationFromJson(json,fromJsonT);

@override final  String operationId;
@override@RequestDetailsConverter() final  RequestDetails details;
// required Json data,
 final  T item;
@override final  DateTime createdAt;
@override@JsonKey() final  int attemptNumber;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WriteOperationCopyWith<T, WriteOperation<T>> get copyWith => _$WriteOperationCopyWithImpl<T, WriteOperation<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$WriteOperationToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WriteOperation<T>&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.details, details) || other.details == details)&&const DeepCollectionEquality().equals(other.item, item)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,details,const DeepCollectionEquality().hash(item),createdAt,attemptNumber);

@override
String toString() {
  return 'Operation<$T>.setItem(operationId: $operationId, details: $details, item: $item, createdAt: $createdAt, attemptNumber: $attemptNumber)';
}


}

/// @nodoc
abstract mixin class $WriteOperationCopyWith<T,$Res> implements $OperationCopyWith<T, $Res> {
  factory $WriteOperationCopyWith(WriteOperation<T> value, $Res Function(WriteOperation<T>) _then) = _$WriteOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId,@RequestDetailsConverter() RequestDetails details, T item, DateTime createdAt, int attemptNumber
});




}
/// @nodoc
class _$WriteOperationCopyWithImpl<T,$Res>
    implements $WriteOperationCopyWith<T, $Res> {
  _$WriteOperationCopyWithImpl(this._self, this._then);

  final WriteOperation<T> _self;
  final $Res Function(WriteOperation<T>) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? details = null,Object? item = freezed,Object? createdAt = null,Object? attemptNumber = null,}) {
  return _then(WriteOperation<T>(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as RequestDetails,item: freezed == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as T,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class WriteListOperation<T> extends Operation<T> {
  const WriteListOperation({required this.operationId, @RequestDetailsConverter() required this.details, required this.items, required this.createdAt, this.attemptNumber = 0, final  String? $type}): $type = $type ?? 'setItems',super._();
  factory WriteListOperation.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$WriteListOperationFromJson(json,fromJsonT);

@override final  String operationId;
@override@RequestDetailsConverter() final  RequestDetails details;
 final  Iterable<T> items;
// required List<Json> data,
@override final  DateTime createdAt;
@override@JsonKey() final  int attemptNumber;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WriteListOperationCopyWith<T, WriteListOperation<T>> get copyWith => _$WriteListOperationCopyWithImpl<T, WriteListOperation<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$WriteListOperationToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WriteListOperation<T>&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.details, details) || other.details == details)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,details,const DeepCollectionEquality().hash(items),createdAt,attemptNumber);

@override
String toString() {
  return 'Operation<$T>.setItems(operationId: $operationId, details: $details, items: $items, createdAt: $createdAt, attemptNumber: $attemptNumber)';
}


}

/// @nodoc
abstract mixin class $WriteListOperationCopyWith<T,$Res> implements $OperationCopyWith<T, $Res> {
  factory $WriteListOperationCopyWith(WriteListOperation<T> value, $Res Function(WriteListOperation<T>) _then) = _$WriteListOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId,@RequestDetailsConverter() RequestDetails details, Iterable<T> items, DateTime createdAt, int attemptNumber
});




}
/// @nodoc
class _$WriteListOperationCopyWithImpl<T,$Res>
    implements $WriteListOperationCopyWith<T, $Res> {
  _$WriteListOperationCopyWithImpl(this._self, this._then);

  final WriteListOperation<T> _self;
  final $Res Function(WriteListOperation<T>) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? details = null,Object? items = null,Object? createdAt = null,Object? attemptNumber = null,}) {
  return _then(WriteListOperation<T>(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as RequestDetails,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as Iterable<T>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class DeleteOperation<T> extends Operation<T> {
  const DeleteOperation({required this.operationId, required this.itemId, @RequestDetailsConverter() required this.details, required this.createdAt, this.attemptNumber = 0, final  String? $type}): $type = $type ?? 'delete',super._();
  factory DeleteOperation.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$DeleteOperationFromJson(json,fromJsonT);

@override final  String operationId;
 final  String itemId;
@override@RequestDetailsConverter() final  RequestDetails details;
@override final  DateTime createdAt;
@override@JsonKey() final  int attemptNumber;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteOperationCopyWith<T, DeleteOperation<T>> get copyWith => _$DeleteOperationCopyWithImpl<T, DeleteOperation<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$DeleteOperationToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteOperation<T>&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,itemId,details,createdAt,attemptNumber);

@override
String toString() {
  return 'Operation<$T>.delete(operationId: $operationId, itemId: $itemId, details: $details, createdAt: $createdAt, attemptNumber: $attemptNumber)';
}


}

/// @nodoc
abstract mixin class $DeleteOperationCopyWith<T,$Res> implements $OperationCopyWith<T, $Res> {
  factory $DeleteOperationCopyWith(DeleteOperation<T> value, $Res Function(DeleteOperation<T>) _then) = _$DeleteOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId, String itemId,@RequestDetailsConverter() RequestDetails details, DateTime createdAt, int attemptNumber
});




}
/// @nodoc
class _$DeleteOperationCopyWithImpl<T,$Res>
    implements $DeleteOperationCopyWith<T, $Res> {
  _$DeleteOperationCopyWithImpl(this._self, this._then);

  final DeleteOperation<T> _self;
  final $Res Function(DeleteOperation<T>) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? itemId = null,Object? details = null,Object? createdAt = null,Object? attemptNumber = null,}) {
  return _then(DeleteOperation<T>(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as RequestDetails,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class DeleteListOperation<T> extends Operation<T> {
  const DeleteListOperation({required this.operationId, @RequestDetailsConverter() required this.details, required this.createdAt, this.attemptNumber = 0, final  String? $type}): $type = $type ?? 'deleteItems',super._();
  factory DeleteListOperation.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$DeleteListOperationFromJson(json,fromJsonT);

@override final  String operationId;
@override@RequestDetailsConverter() final  RequestDetails details;
@override final  DateTime createdAt;
@override@JsonKey() final  int attemptNumber;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteListOperationCopyWith<T, DeleteListOperation<T>> get copyWith => _$DeleteListOperationCopyWithImpl<T, DeleteListOperation<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$DeleteListOperationToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteListOperation<T>&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,details,createdAt,attemptNumber);

@override
String toString() {
  return 'Operation<$T>.deleteItems(operationId: $operationId, details: $details, createdAt: $createdAt, attemptNumber: $attemptNumber)';
}


}

/// @nodoc
abstract mixin class $DeleteListOperationCopyWith<T,$Res> implements $OperationCopyWith<T, $Res> {
  factory $DeleteListOperationCopyWith(DeleteListOperation<T> value, $Res Function(DeleteListOperation<T>) _then) = _$DeleteListOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId,@RequestDetailsConverter() RequestDetails details, DateTime createdAt, int attemptNumber
});




}
/// @nodoc
class _$DeleteListOperationCopyWithImpl<T,$Res>
    implements $DeleteListOperationCopyWith<T, $Res> {
  _$DeleteListOperationCopyWithImpl(this._self, this._then);

  final DeleteListOperation<T> _self;
  final $Res Function(DeleteListOperation<T>) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? details = null,Object? createdAt = null,Object? attemptNumber = null,}) {
  return _then(DeleteListOperation<T>(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as RequestDetails,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class SendMessageOperation<T> extends Operation<T> {
  const SendMessageOperation({required this.operationId, required this.message, @RequestDetailsConverter() required this.details, required this.createdAt, this.targetId, this.attemptNumber = 0, final  String? $type}): $type = $type ?? 'sendMessage',super._();
  factory SendMessageOperation.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$SendMessageOperationFromJson(json,fromJsonT);

@override final  String operationId;
 final  Object message;
@override@RequestDetailsConverter() final  RequestDetails details;
@override final  DateTime createdAt;
 final  String? targetId;
@override@JsonKey() final  int attemptNumber;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SendMessageOperationCopyWith<T, SendMessageOperation<T>> get copyWith => _$SendMessageOperationCopyWithImpl<T, SendMessageOperation<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$SendMessageOperationToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SendMessageOperation<T>&&(identical(other.operationId, operationId) || other.operationId == operationId)&&const DeepCollectionEquality().equals(other.message, message)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,const DeepCollectionEquality().hash(message),details,createdAt,targetId,attemptNumber);

@override
String toString() {
  return 'Operation<$T>.sendMessage(operationId: $operationId, message: $message, details: $details, createdAt: $createdAt, targetId: $targetId, attemptNumber: $attemptNumber)';
}


}

/// @nodoc
abstract mixin class $SendMessageOperationCopyWith<T,$Res> implements $OperationCopyWith<T, $Res> {
  factory $SendMessageOperationCopyWith(SendMessageOperation<T> value, $Res Function(SendMessageOperation<T>) _then) = _$SendMessageOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId, Object message,@RequestDetailsConverter() RequestDetails details, DateTime createdAt, String? targetId, int attemptNumber
});




}
/// @nodoc
class _$SendMessageOperationCopyWithImpl<T,$Res>
    implements $SendMessageOperationCopyWith<T, $Res> {
  _$SendMessageOperationCopyWithImpl(this._self, this._then);

  final SendMessageOperation<T> _self;
  final $Res Function(SendMessageOperation<T>) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? message = null,Object? details = null,Object? createdAt = null,Object? targetId = freezed,Object? attemptNumber = null,}) {
  return _then(SendMessageOperation<T>(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message ,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as RequestDetails,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,targetId: freezed == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String?,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class WatchOperation<T> extends Operation<T> {
  const WatchOperation({required this.operationId, required this.itemId, @RequestDetailsConverter() required this.details, required this.createdAt, this.attemptNumber = 0, final  String? $type}): $type = $type ?? 'watch',super._();
  factory WatchOperation.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$WatchOperationFromJson(json,fromJsonT);

@override final  String operationId;
 final  String itemId;
@override@RequestDetailsConverter() final  RequestDetails details;
@override final  DateTime createdAt;
@override@JsonKey() final  int attemptNumber;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchOperationCopyWith<T, WatchOperation<T>> get copyWith => _$WatchOperationCopyWithImpl<T, WatchOperation<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$WatchOperationToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchOperation<T>&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,itemId,details,createdAt,attemptNumber);

@override
String toString() {
  return 'Operation<$T>.watch(operationId: $operationId, itemId: $itemId, details: $details, createdAt: $createdAt, attemptNumber: $attemptNumber)';
}


}

/// @nodoc
abstract mixin class $WatchOperationCopyWith<T,$Res> implements $OperationCopyWith<T, $Res> {
  factory $WatchOperationCopyWith(WatchOperation<T> value, $Res Function(WatchOperation<T>) _then) = _$WatchOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId, String itemId,@RequestDetailsConverter() RequestDetails details, DateTime createdAt, int attemptNumber
});




}
/// @nodoc
class _$WatchOperationCopyWithImpl<T,$Res>
    implements $WatchOperationCopyWith<T, $Res> {
  _$WatchOperationCopyWithImpl(this._self, this._then);

  final WatchOperation<T> _self;
  final $Res Function(WatchOperation<T>) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? itemId = null,Object? details = null,Object? createdAt = null,Object? attemptNumber = null,}) {
  return _then(WatchOperation<T>(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as RequestDetails,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class WatchListOperation<T> extends Operation<T> {
  const WatchListOperation({required this.operationId, @RequestDetailsConverter() required this.details, required this.createdAt, this.attemptNumber = 0, final  String? $type}): $type = $type ?? 'watchList',super._();
  factory WatchListOperation.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$WatchListOperationFromJson(json,fromJsonT);

@override final  String operationId;
@override@RequestDetailsConverter() final  RequestDetails details;
@override final  DateTime createdAt;
@override@JsonKey() final  int attemptNumber;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchListOperationCopyWith<T, WatchListOperation<T>> get copyWith => _$WatchListOperationCopyWithImpl<T, WatchListOperation<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$WatchListOperationToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchListOperation<T>&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,details,createdAt,attemptNumber);

@override
String toString() {
  return 'Operation<$T>.watchList(operationId: $operationId, details: $details, createdAt: $createdAt, attemptNumber: $attemptNumber)';
}


}

/// @nodoc
abstract mixin class $WatchListOperationCopyWith<T,$Res> implements $OperationCopyWith<T, $Res> {
  factory $WatchListOperationCopyWith(WatchListOperation<T> value, $Res Function(WatchListOperation<T>) _then) = _$WatchListOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId,@RequestDetailsConverter() RequestDetails details, DateTime createdAt, int attemptNumber
});




}
/// @nodoc
class _$WatchListOperationCopyWithImpl<T,$Res>
    implements $WatchListOperationCopyWith<T, $Res> {
  _$WatchListOperationCopyWithImpl(this._self, this._then);

  final WatchListOperation<T> _self;
  final $Res Function(WatchListOperation<T>) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? details = null,Object? createdAt = null,Object? attemptNumber = null,}) {
  return _then(WatchListOperation<T>(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as RequestDetails,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class WatchByIdsOperation<T> extends Operation<T> {
  const WatchByIdsOperation({required this.operationId, required final  Set<String> itemIds, @RequestDetailsConverter() required this.details, required this.createdAt, this.attemptNumber = 0, final  String? $type}): _itemIds = itemIds,$type = $type ?? 'watchByIds',super._();
  factory WatchByIdsOperation.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$WatchByIdsOperationFromJson(json,fromJsonT);

@override final  String operationId;
 final  Set<String> _itemIds;
 Set<String> get itemIds {
  if (_itemIds is EqualUnmodifiableSetView) return _itemIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_itemIds);
}

@override@RequestDetailsConverter() final  RequestDetails details;
@override final  DateTime createdAt;
@override@JsonKey() final  int attemptNumber;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchByIdsOperationCopyWith<T, WatchByIdsOperation<T>> get copyWith => _$WatchByIdsOperationCopyWithImpl<T, WatchByIdsOperation<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$WatchByIdsOperationToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchByIdsOperation<T>&&(identical(other.operationId, operationId) || other.operationId == operationId)&&const DeepCollectionEquality().equals(other._itemIds, _itemIds)&&(identical(other.details, details) || other.details == details)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptNumber, attemptNumber) || other.attemptNumber == attemptNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,const DeepCollectionEquality().hash(_itemIds),details,createdAt,attemptNumber);

@override
String toString() {
  return 'Operation<$T>.watchByIds(operationId: $operationId, itemIds: $itemIds, details: $details, createdAt: $createdAt, attemptNumber: $attemptNumber)';
}


}

/// @nodoc
abstract mixin class $WatchByIdsOperationCopyWith<T,$Res> implements $OperationCopyWith<T, $Res> {
  factory $WatchByIdsOperationCopyWith(WatchByIdsOperation<T> value, $Res Function(WatchByIdsOperation<T>) _then) = _$WatchByIdsOperationCopyWithImpl;
@override @useResult
$Res call({
 String operationId, Set<String> itemIds,@RequestDetailsConverter() RequestDetails details, DateTime createdAt, int attemptNumber
});




}
/// @nodoc
class _$WatchByIdsOperationCopyWithImpl<T,$Res>
    implements $WatchByIdsOperationCopyWith<T, $Res> {
  _$WatchByIdsOperationCopyWithImpl(this._self, this._then);

  final WatchByIdsOperation<T> _self;
  final $Res Function(WatchByIdsOperation<T>) _then;

/// Create a copy of Operation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? itemIds = null,Object? details = null,Object? createdAt = null,Object? attemptNumber = null,}) {
  return _then(WatchByIdsOperation<T>(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,itemIds: null == itemIds ? _self._itemIds : itemIds // ignore: cast_nullable_to_non_nullable
as Set<String>,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as RequestDetails,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,attemptNumber: null == attemptNumber ? _self.attemptNumber : attemptNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
