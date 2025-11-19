// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ApiResultBody {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiResultBody);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ApiResultBody()';
}


}

/// @nodoc
class $ApiResultBodyCopyWith<$Res>  {
$ApiResultBodyCopyWith(ApiResultBody _, $Res Function(ApiResultBody) __);
}


/// Adds pattern-matching-related methods to [ApiResultBody].
extension ApiResultBodyPatterns on ApiResultBody {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HtmlApiResultBody value)?  html,TResult Function( JsonApiResultBody value)?  json,TResult Function( PlainTextApiResultBody value)?  plainText,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HtmlApiResultBody() when html != null:
return html(_that);case JsonApiResultBody() when json != null:
return json(_that);case PlainTextApiResultBody() when plainText != null:
return plainText(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HtmlApiResultBody value)  html,required TResult Function( JsonApiResultBody value)  json,required TResult Function( PlainTextApiResultBody value)  plainText,}){
final _that = this;
switch (_that) {
case HtmlApiResultBody():
return html(_that);case JsonApiResultBody():
return json(_that);case PlainTextApiResultBody():
return plainText(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HtmlApiResultBody value)?  html,TResult? Function( JsonApiResultBody value)?  json,TResult? Function( PlainTextApiResultBody value)?  plainText,}){
final _that = this;
switch (_that) {
case HtmlApiResultBody() when html != null:
return html(_that);case JsonApiResultBody() when json != null:
return json(_that);case PlainTextApiResultBody() when plainText != null:
return plainText(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String html)?  html,TResult Function( Json data)?  json,TResult Function( String text)?  plainText,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HtmlApiResultBody() when html != null:
return html(_that.html);case JsonApiResultBody() when json != null:
return json(_that.data);case PlainTextApiResultBody() when plainText != null:
return plainText(_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String html)  html,required TResult Function( Json data)  json,required TResult Function( String text)  plainText,}) {final _that = this;
switch (_that) {
case HtmlApiResultBody():
return html(_that.html);case JsonApiResultBody():
return json(_that.data);case PlainTextApiResultBody():
return plainText(_that.text);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String html)?  html,TResult? Function( Json data)?  json,TResult? Function( String text)?  plainText,}) {final _that = this;
switch (_that) {
case HtmlApiResultBody() when html != null:
return html(_that.html);case JsonApiResultBody() when json != null:
return json(_that.data);case PlainTextApiResultBody() when plainText != null:
return plainText(_that.text);case _:
  return null;

}
}

}

/// @nodoc


class HtmlApiResultBody implements ApiResultBody {
  const HtmlApiResultBody(this.html);
  

 final  String html;

/// Create a copy of ApiResultBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HtmlApiResultBodyCopyWith<HtmlApiResultBody> get copyWith => _$HtmlApiResultBodyCopyWithImpl<HtmlApiResultBody>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HtmlApiResultBody&&(identical(other.html, html) || other.html == html));
}


@override
int get hashCode => Object.hash(runtimeType,html);

@override
String toString() {
  return 'ApiResultBody.html(html: $html)';
}


}

/// @nodoc
abstract mixin class $HtmlApiResultBodyCopyWith<$Res> implements $ApiResultBodyCopyWith<$Res> {
  factory $HtmlApiResultBodyCopyWith(HtmlApiResultBody value, $Res Function(HtmlApiResultBody) _then) = _$HtmlApiResultBodyCopyWithImpl;
@useResult
$Res call({
 String html
});




}
/// @nodoc
class _$HtmlApiResultBodyCopyWithImpl<$Res>
    implements $HtmlApiResultBodyCopyWith<$Res> {
  _$HtmlApiResultBodyCopyWithImpl(this._self, this._then);

  final HtmlApiResultBody _self;
  final $Res Function(HtmlApiResultBody) _then;

/// Create a copy of ApiResultBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? html = null,}) {
  return _then(HtmlApiResultBody(
null == html ? _self.html : html // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class JsonApiResultBody implements ApiResultBody {
  const JsonApiResultBody(final  Json data): _data = data;
  

 final  Json _data;
 Json get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}


/// Create a copy of ApiResultBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JsonApiResultBodyCopyWith<JsonApiResultBody> get copyWith => _$JsonApiResultBodyCopyWithImpl<JsonApiResultBody>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JsonApiResultBody&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'ApiResultBody.json(data: $data)';
}


}

/// @nodoc
abstract mixin class $JsonApiResultBodyCopyWith<$Res> implements $ApiResultBodyCopyWith<$Res> {
  factory $JsonApiResultBodyCopyWith(JsonApiResultBody value, $Res Function(JsonApiResultBody) _then) = _$JsonApiResultBodyCopyWithImpl;
@useResult
$Res call({
 Json data
});




}
/// @nodoc
class _$JsonApiResultBodyCopyWithImpl<$Res>
    implements $JsonApiResultBodyCopyWith<$Res> {
  _$JsonApiResultBodyCopyWithImpl(this._self, this._then);

  final JsonApiResultBody _self;
  final $Res Function(JsonApiResultBody) _then;

/// Create a copy of ApiResultBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(JsonApiResultBody(
null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Json,
  ));
}


}

/// @nodoc


class PlainTextApiResultBody implements ApiResultBody {
  const PlainTextApiResultBody(this.text);
  

 final  String text;

/// Create a copy of ApiResultBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlainTextApiResultBodyCopyWith<PlainTextApiResultBody> get copyWith => _$PlainTextApiResultBodyCopyWithImpl<PlainTextApiResultBody>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlainTextApiResultBody&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'ApiResultBody.plainText(text: $text)';
}


}

/// @nodoc
abstract mixin class $PlainTextApiResultBodyCopyWith<$Res> implements $ApiResultBodyCopyWith<$Res> {
  factory $PlainTextApiResultBodyCopyWith(PlainTextApiResultBody value, $Res Function(PlainTextApiResultBody) _then) = _$PlainTextApiResultBodyCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$PlainTextApiResultBodyCopyWithImpl<$Res>
    implements $PlainTextApiResultBodyCopyWith<$Res> {
  _$PlainTextApiResultBodyCopyWithImpl(this._self, this._then);

  final PlainTextApiResultBody _self;
  final $Res Function(PlainTextApiResultBody) _then;

/// Create a copy of ApiResultBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(PlainTextApiResultBody(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ApiResult {

 int get statusCode; Duration get responseTime; String get url;
/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiResultCopyWith<ApiResult> get copyWith => _$ApiResultCopyWithImpl<ApiResult>(this as ApiResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiResult&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.responseTime, responseTime) || other.responseTime == responseTime)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,statusCode,responseTime,url);

@override
String toString() {
  return 'ApiResult(statusCode: $statusCode, responseTime: $responseTime, url: $url)';
}


}

/// @nodoc
abstract mixin class $ApiResultCopyWith<$Res>  {
  factory $ApiResultCopyWith(ApiResult value, $Res Function(ApiResult) _then) = _$ApiResultCopyWithImpl;
@useResult
$Res call({
 int statusCode, Duration responseTime, String url
});




}
/// @nodoc
class _$ApiResultCopyWithImpl<$Res>
    implements $ApiResultCopyWith<$Res> {
  _$ApiResultCopyWithImpl(this._self, this._then);

  final ApiResult _self;
  final $Res Function(ApiResult) _then;

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? statusCode = null,Object? responseTime = null,Object? url = null,}) {
  return _then(_self.copyWith(
statusCode: null == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int,responseTime: null == responseTime ? _self.responseTime : responseTime // ignore: cast_nullable_to_non_nullable
as Duration,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiResult].
extension ApiResultPatterns on ApiResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ApiSuccess value)?  success,TResult Function( ApiError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ApiSuccess() when success != null:
return success(_that);case ApiError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ApiSuccess value)  success,required TResult Function( ApiError value)  error,}){
final _that = this;
switch (_that) {
case ApiSuccess():
return success(_that);case ApiError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ApiSuccess value)?  success,TResult? Function( ApiError value)?  error,}){
final _that = this;
switch (_that) {
case ApiSuccess() when success != null:
return success(_that);case ApiError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ApiResultBody body,  int statusCode,  Duration responseTime,  String url)?  success,TResult Function( ErrorMessage error,  int statusCode,  Duration responseTime,  String url)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ApiSuccess() when success != null:
return success(_that.body,_that.statusCode,_that.responseTime,_that.url);case ApiError() when error != null:
return error(_that.error,_that.statusCode,_that.responseTime,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ApiResultBody body,  int statusCode,  Duration responseTime,  String url)  success,required TResult Function( ErrorMessage error,  int statusCode,  Duration responseTime,  String url)  error,}) {final _that = this;
switch (_that) {
case ApiSuccess():
return success(_that.body,_that.statusCode,_that.responseTime,_that.url);case ApiError():
return error(_that.error,_that.statusCode,_that.responseTime,_that.url);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ApiResultBody body,  int statusCode,  Duration responseTime,  String url)?  success,TResult? Function( ErrorMessage error,  int statusCode,  Duration responseTime,  String url)?  error,}) {final _that = this;
switch (_that) {
case ApiSuccess() when success != null:
return success(_that.body,_that.statusCode,_that.responseTime,_that.url);case ApiError() when error != null:
return error(_that.error,_that.statusCode,_that.responseTime,_that.url);case _:
  return null;

}
}

}

/// @nodoc


class ApiSuccess extends ApiResult {
  const ApiSuccess({required this.body, required this.statusCode, required this.responseTime, required this.url}): super._();
  

 final  ApiResultBody body;
@override final  int statusCode;
@override final  Duration responseTime;
@override final  String url;

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiSuccessCopyWith<ApiSuccess> get copyWith => _$ApiSuccessCopyWithImpl<ApiSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiSuccess&&(identical(other.body, body) || other.body == body)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.responseTime, responseTime) || other.responseTime == responseTime)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,body,statusCode,responseTime,url);

@override
String toString() {
  return 'ApiResult.success(body: $body, statusCode: $statusCode, responseTime: $responseTime, url: $url)';
}


}

/// @nodoc
abstract mixin class $ApiSuccessCopyWith<$Res> implements $ApiResultCopyWith<$Res> {
  factory $ApiSuccessCopyWith(ApiSuccess value, $Res Function(ApiSuccess) _then) = _$ApiSuccessCopyWithImpl;
@override @useResult
$Res call({
 ApiResultBody body, int statusCode, Duration responseTime, String url
});


$ApiResultBodyCopyWith<$Res> get body;

}
/// @nodoc
class _$ApiSuccessCopyWithImpl<$Res>
    implements $ApiSuccessCopyWith<$Res> {
  _$ApiSuccessCopyWithImpl(this._self, this._then);

  final ApiSuccess _self;
  final $Res Function(ApiSuccess) _then;

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,Object? statusCode = null,Object? responseTime = null,Object? url = null,}) {
  return _then(ApiSuccess(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as ApiResultBody,statusCode: null == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int,responseTime: null == responseTime ? _self.responseTime : responseTime // ignore: cast_nullable_to_non_nullable
as Duration,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiResultBodyCopyWith<$Res> get body {
  
  return $ApiResultBodyCopyWith<$Res>(_self.body, (value) {
    return _then(_self.copyWith(body: value));
  });
}
}

/// @nodoc


class ApiError extends ApiResult {
  const ApiError({required this.error, required this.statusCode, required this.responseTime, required this.url}): super._();
  

 final  ErrorMessage error;
@override final  int statusCode;
@override final  Duration responseTime;
@override final  String url;

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiErrorCopyWith<ApiError> get copyWith => _$ApiErrorCopyWithImpl<ApiError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiError&&(identical(other.error, error) || other.error == error)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.responseTime, responseTime) || other.responseTime == responseTime)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,error,statusCode,responseTime,url);

@override
String toString() {
  return 'ApiResult.error(error: $error, statusCode: $statusCode, responseTime: $responseTime, url: $url)';
}


}

/// @nodoc
abstract mixin class $ApiErrorCopyWith<$Res> implements $ApiResultCopyWith<$Res> {
  factory $ApiErrorCopyWith(ApiError value, $Res Function(ApiError) _then) = _$ApiErrorCopyWithImpl;
@override @useResult
$Res call({
 ErrorMessage error, int statusCode, Duration responseTime, String url
});


$ErrorMessageCopyWith<$Res> get error;

}
/// @nodoc
class _$ApiErrorCopyWithImpl<$Res>
    implements $ApiErrorCopyWith<$Res> {
  _$ApiErrorCopyWithImpl(this._self, this._then);

  final ApiError _self;
  final $Res Function(ApiError) _then;

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? error = null,Object? statusCode = null,Object? responseTime = null,Object? url = null,}) {
  return _then(ApiError(
error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as ErrorMessage,statusCode: null == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int,responseTime: null == responseTime ? _self.responseTime : responseTime // ignore: cast_nullable_to_non_nullable
as Duration,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ApiResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ErrorMessageCopyWith<$Res> get error {
  
  return $ErrorMessageCopyWith<$Res>(_self.error, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}

/// @nodoc
mixin _$ErrorMessage {

 Object get message;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorMessage&&const DeepCollectionEquality().equals(other.message, message));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(message));

@override
String toString() {
  return 'ErrorMessage(message: $message)';
}


}

/// @nodoc
class $ErrorMessageCopyWith<$Res>  {
$ErrorMessageCopyWith(ErrorMessage _, $Res Function(ErrorMessage) __);
}


/// Adds pattern-matching-related methods to [ErrorMessage].
extension ErrorMessagePatterns on ErrorMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ErrorString value)?  fromString,TResult Function( ErrorMap value)?  fromMap,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ErrorString() when fromString != null:
return fromString(_that);case ErrorMap() when fromMap != null:
return fromMap(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ErrorString value)  fromString,required TResult Function( ErrorMap value)  fromMap,}){
final _that = this;
switch (_that) {
case ErrorString():
return fromString(_that);case ErrorMap():
return fromMap(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ErrorString value)?  fromString,TResult? Function( ErrorMap value)?  fromMap,}){
final _that = this;
switch (_that) {
case ErrorString() when fromString != null:
return fromString(_that);case ErrorMap() when fromMap != null:
return fromMap(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  fromString,TResult Function( Json message)?  fromMap,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ErrorString() when fromString != null:
return fromString(_that.message);case ErrorMap() when fromMap != null:
return fromMap(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  fromString,required TResult Function( Json message)  fromMap,}) {final _that = this;
switch (_that) {
case ErrorString():
return fromString(_that.message);case ErrorMap():
return fromMap(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  fromString,TResult? Function( Json message)?  fromMap,}) {final _that = this;
switch (_that) {
case ErrorString() when fromString != null:
return fromString(_that.message);case ErrorMap() when fromMap != null:
return fromMap(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ErrorString extends ErrorMessage {
  const ErrorString(this.message): super._();
  

@override final  String message;

/// Create a copy of ErrorMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorStringCopyWith<ErrorString> get copyWith => _$ErrorStringCopyWithImpl<ErrorString>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorString&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ErrorMessage.fromString(message: $message)';
}


}

/// @nodoc
abstract mixin class $ErrorStringCopyWith<$Res> implements $ErrorMessageCopyWith<$Res> {
  factory $ErrorStringCopyWith(ErrorString value, $Res Function(ErrorString) _then) = _$ErrorStringCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ErrorStringCopyWithImpl<$Res>
    implements $ErrorStringCopyWith<$Res> {
  _$ErrorStringCopyWithImpl(this._self, this._then);

  final ErrorString _self;
  final $Res Function(ErrorString) _then;

/// Create a copy of ErrorMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ErrorString(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ErrorMap extends ErrorMessage {
  const ErrorMap(final  Json message): _message = message,super._();
  

 final  Json _message;
@override Json get message {
  if (_message is EqualUnmodifiableMapView) return _message;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_message);
}


/// Create a copy of ErrorMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorMapCopyWith<ErrorMap> get copyWith => _$ErrorMapCopyWithImpl<ErrorMap>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorMap&&const DeepCollectionEquality().equals(other._message, _message));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_message));

@override
String toString() {
  return 'ErrorMessage.fromMap(message: $message)';
}


}

/// @nodoc
abstract mixin class $ErrorMapCopyWith<$Res> implements $ErrorMessageCopyWith<$Res> {
  factory $ErrorMapCopyWith(ErrorMap value, $Res Function(ErrorMap) _then) = _$ErrorMapCopyWithImpl;
@useResult
$Res call({
 Json message
});




}
/// @nodoc
class _$ErrorMapCopyWithImpl<$Res>
    implements $ErrorMapCopyWith<$Res> {
  _$ErrorMapCopyWithImpl(this._self, this._then);

  final ErrorMap _self;
  final $Res Function(ErrorMap) _then;

/// Create a copy of ErrorMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ErrorMap(
null == message ? _self._message : message // ignore: cast_nullable_to_non_nullable
as Json,
  ));
}


}

// dart format on
