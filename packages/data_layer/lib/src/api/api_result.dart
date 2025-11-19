import 'package:data_layer/data_layer.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_result.freezed.dart';

/// Typed-container for the response payload for an [ApiResult].
@Freezed()
sealed class ApiResultBody with _$ApiResultBody {
  /// Container for a response body that came with the "text/html" content type.
  const factory ApiResultBody.html(String html) = HtmlApiResultBody;

  /// Container for a response body that came with the "application/json"
  /// content type.
  const factory ApiResultBody.json(Json data) = JsonApiResultBody;

  /// Container for a response body that came with the "text/plain" content type.
  const factory ApiResultBody.plainText(String text) = PlainTextApiResultBody;
}

/// Success/failure-aware container for the response from an [ApiRequest].
@Freezed()
sealed class ApiResult with _$ApiResult {
  /// Container for the response from an [ApiRequest] that did not encounter any
  /// errors.
  const factory ApiResult.success({
    required ApiResultBody body,
    required int statusCode,
    required Duration responseTime,
    required String url,
  }) = ApiSuccess;

  const ApiResult._();

  /// Container for the response from an [ApiRequest] that encountered errors.
  const factory ApiResult.error({
    required ErrorMessage error,
    required int statusCode,
    required Duration responseTime,
    required String url,
  }) = ApiError;

  /// Test-friendly constructor for synthetic [ApiResult] instances.
  factory ApiResult.fake({
    Map<String, dynamic>? body,
    int? statusCode,
    Duration? responseTime,
    String? url,
  }) => ApiResult.success(
    body: ApiResultBody.json(body ?? <String, dynamic>{}),
    statusCode: statusCode ?? 200,
    url: url ?? 'https://fake.com',
    responseTime: responseTime ?? const Duration(milliseconds: 1),
  );

  /// True if this [ApiResult] is an [ApiSuccess].
  bool get isSuccess => this is ApiSuccess;

  /// Returns the [Json] from an [ApiResult], or raises if it was unavailable.
  /// Usage of this computed property should only verifiying [isSuccess] is
  /// true.
  Json get jsonOrRaise => switch (this) {
    ApiSuccess(:final body) => switch (body) {
      HtmlApiResultBody() => throw Exception(
        'Received HTML, expected JSON for $url',
      ),
      JsonApiResultBody() => body.data,
      PlainTextApiResultBody() => throw Exception(
        'Received text, expected JSON for $url',
      ),
    },
    ApiError() => throw Exception('Error response for $url'),
  };

  /// Returns the error from an [ApiResult], or raises if the result was
  /// successful. Usage of this computed property should only verifiying
  /// [isSuccess] is false.
  String get errorString => switch (this) {
    ApiSuccess() => throw Exception('No error string for successful response'),
    ApiError(:final error) => '$statusCode $url :: ${error.plain}',
  };
}

/// Utility to unpack error strings from either a plain string (which is
/// straightforward), or from a map where we assume that the value is the error.
@Freezed()
sealed class ErrorMessage with _$ErrorMessage {
  const ErrorMessage._();

  /// Pass-thru container for a string.
  const factory ErrorMessage.fromString(String message) = ErrorString;

  /// Unpacks an [ErrorMessage] from a [Json] map.
  const factory ErrorMessage.fromMap(Json message) = ErrorMap;

  /// Extracts the raw string from this [ErrorMessage].
  String get plain => switch (this) {
    ErrorString(:final message) => message,
    ErrorMap(:final message) =>
      '${message.keys.first}: ${message[message.keys.first]}',
  };
}
