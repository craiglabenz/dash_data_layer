// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TestRecord {

 String get id; String get value; DateTime get createdAt;
/// Create a copy of TestRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TestRecordCopyWith<TestRecord> get copyWith => _$TestRecordCopyWithImpl<TestRecord>(this as TestRecord, _$identity);

  /// Serializes this TestRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TestRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.value, value) || other.value == value)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,value,createdAt);

@override
String toString() {
  return 'TestRecord(id: $id, value: $value, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TestRecordCopyWith<$Res>  {
  factory $TestRecordCopyWith(TestRecord value, $Res Function(TestRecord) _then) = _$TestRecordCopyWithImpl;
@useResult
$Res call({
 String id, String value, DateTime createdAt
});




}
/// @nodoc
class _$TestRecordCopyWithImpl<$Res>
    implements $TestRecordCopyWith<$Res> {
  _$TestRecordCopyWithImpl(this._self, this._then);

  final TestRecord _self;
  final $Res Function(TestRecord) _then;

/// Create a copy of TestRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? value = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TestRecord].
extension TestRecordPatterns on TestRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TestRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TestRecord() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TestRecord value)  $default,){
final _that = this;
switch (_that) {
case _TestRecord():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TestRecord value)?  $default,){
final _that = this;
switch (_that) {
case _TestRecord() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String value,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TestRecord() when $default != null:
return $default(_that.id,_that.value,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String value,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _TestRecord():
return $default(_that.id,_that.value,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String value,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TestRecord() when $default != null:
return $default(_that.id,_that.value,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TestRecord implements TestRecord {
  const _TestRecord({required this.id, required this.value, required this.createdAt});
  factory _TestRecord.fromJson(Map<String, dynamic> json) => _$TestRecordFromJson(json);

@override final  String id;
@override final  String value;
@override final  DateTime createdAt;

/// Create a copy of TestRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TestRecordCopyWith<_TestRecord> get copyWith => __$TestRecordCopyWithImpl<_TestRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TestRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TestRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.value, value) || other.value == value)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,value,createdAt);

@override
String toString() {
  return 'TestRecord(id: $id, value: $value, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TestRecordCopyWith<$Res> implements $TestRecordCopyWith<$Res> {
  factory _$TestRecordCopyWith(_TestRecord value, $Res Function(_TestRecord) _then) = __$TestRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String value, DateTime createdAt
});




}
/// @nodoc
class __$TestRecordCopyWithImpl<$Res>
    implements _$TestRecordCopyWith<$Res> {
  __$TestRecordCopyWithImpl(this._self, this._then);

  final _TestRecord _self;
  final $Res Function(_TestRecord) _then;

/// Create a copy of TestRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? value = null,Object? createdAt = null,}) {
  return _then(_TestRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

TestRecordMessage _$TestRecordMessageFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'create':
          return _TestRecordMessageCreate.fromJson(
            json
          );
                case 'update':
          return _TestRecordMessageUpdate.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'TestRecordMessage',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$TestRecordMessage {

 String? get value;
/// Create a copy of TestRecordMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TestRecordMessageCopyWith<TestRecordMessage> get copyWith => _$TestRecordMessageCopyWithImpl<TestRecordMessage>(this as TestRecordMessage, _$identity);

  /// Serializes this TestRecordMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TestRecordMessage&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'TestRecordMessage(value: $value)';
}


}

/// @nodoc
abstract mixin class $TestRecordMessageCopyWith<$Res>  {
  factory $TestRecordMessageCopyWith(TestRecordMessage value, $Res Function(TestRecordMessage) _then) = _$TestRecordMessageCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$TestRecordMessageCopyWithImpl<$Res>
    implements $TestRecordMessageCopyWith<$Res> {
  _$TestRecordMessageCopyWithImpl(this._self, this._then);

  final TestRecordMessage _self;
  final $Res Function(TestRecordMessage) _then;

/// Create a copy of TestRecordMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value! : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TestRecordMessage].
extension TestRecordMessagePatterns on TestRecordMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _TestRecordMessageCreate value)?  create,TResult Function( _TestRecordMessageUpdate value)?  update,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TestRecordMessageCreate() when create != null:
return create(_that);case _TestRecordMessageUpdate() when update != null:
return update(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _TestRecordMessageCreate value)  create,required TResult Function( _TestRecordMessageUpdate value)  update,}){
final _that = this;
switch (_that) {
case _TestRecordMessageCreate():
return create(_that);case _TestRecordMessageUpdate():
return update(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _TestRecordMessageCreate value)?  create,TResult? Function( _TestRecordMessageUpdate value)?  update,}){
final _that = this;
switch (_that) {
case _TestRecordMessageCreate() when create != null:
return create(_that);case _TestRecordMessageUpdate() when update != null:
return update(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String value)?  create,TResult Function( String? value)?  update,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TestRecordMessageCreate() when create != null:
return create(_that.value);case _TestRecordMessageUpdate() when update != null:
return update(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String value)  create,required TResult Function( String? value)  update,}) {final _that = this;
switch (_that) {
case _TestRecordMessageCreate():
return create(_that.value);case _TestRecordMessageUpdate():
return update(_that.value);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String value)?  create,TResult? Function( String? value)?  update,}) {final _that = this;
switch (_that) {
case _TestRecordMessageCreate() when create != null:
return create(_that.value);case _TestRecordMessageUpdate() when update != null:
return update(_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TestRecordMessageCreate extends TestRecordMessage {
  const _TestRecordMessageCreate({required this.value, final  String? $type}): $type = $type ?? 'create',super._();
  factory _TestRecordMessageCreate.fromJson(Map<String, dynamic> json) => _$TestRecordMessageCreateFromJson(json);

@override final  String value;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of TestRecordMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TestRecordMessageCreateCopyWith<_TestRecordMessageCreate> get copyWith => __$TestRecordMessageCreateCopyWithImpl<_TestRecordMessageCreate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TestRecordMessageCreateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TestRecordMessageCreate&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'TestRecordMessage.create(value: $value)';
}


}

/// @nodoc
abstract mixin class _$TestRecordMessageCreateCopyWith<$Res> implements $TestRecordMessageCopyWith<$Res> {
  factory _$TestRecordMessageCreateCopyWith(_TestRecordMessageCreate value, $Res Function(_TestRecordMessageCreate) _then) = __$TestRecordMessageCreateCopyWithImpl;
@override @useResult
$Res call({
 String value
});




}
/// @nodoc
class __$TestRecordMessageCreateCopyWithImpl<$Res>
    implements _$TestRecordMessageCreateCopyWith<$Res> {
  __$TestRecordMessageCreateCopyWithImpl(this._self, this._then);

  final _TestRecordMessageCreate _self;
  final $Res Function(_TestRecordMessageCreate) _then;

/// Create a copy of TestRecordMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_TestRecordMessageCreate(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _TestRecordMessageUpdate extends TestRecordMessage {
  const _TestRecordMessageUpdate({this.value, final  String? $type}): $type = $type ?? 'update',super._();
  factory _TestRecordMessageUpdate.fromJson(Map<String, dynamic> json) => _$TestRecordMessageUpdateFromJson(json);

@override final  String? value;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of TestRecordMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TestRecordMessageUpdateCopyWith<_TestRecordMessageUpdate> get copyWith => __$TestRecordMessageUpdateCopyWithImpl<_TestRecordMessageUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TestRecordMessageUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TestRecordMessageUpdate&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'TestRecordMessage.update(value: $value)';
}


}

/// @nodoc
abstract mixin class _$TestRecordMessageUpdateCopyWith<$Res> implements $TestRecordMessageCopyWith<$Res> {
  factory _$TestRecordMessageUpdateCopyWith(_TestRecordMessageUpdate value, $Res Function(_TestRecordMessageUpdate) _then) = __$TestRecordMessageUpdateCopyWithImpl;
@override @useResult
$Res call({
 String? value
});




}
/// @nodoc
class __$TestRecordMessageUpdateCopyWithImpl<$Res>
    implements _$TestRecordMessageUpdateCopyWith<$Res> {
  __$TestRecordMessageUpdateCopyWithImpl(this._self, this._then);

  final _TestRecordMessageUpdate _self;
  final $Res Function(_TestRecordMessageUpdate) _then;

/// Create a copy of TestRecordMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(_TestRecordMessageUpdate(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
