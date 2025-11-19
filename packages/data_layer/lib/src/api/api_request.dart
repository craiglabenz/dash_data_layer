import 'package:data_layer/data_layer.dart';

/// {@template ApiRequest}
/// Container for information needed to submit a network request.
///
/// Supply [headers] to set default headers for this request. Supply
/// [headersBuilder] to build headers dynamically for this request. Note that
/// [headersBuilder] will inherit and override [headers], and so should return
/// the full map of headers and not only additions.
/// {@endtemplate}
abstract class ApiRequest {
  /// {@macro ApiRequest}
  const ApiRequest({
    required this.url,
    Headers headers = const {},
    this.user,
  }) : _headers = headers;

  /// Whatever data is needed to authenticate this request.
  final Object? user;

  /// Destination of this request.
  final ApiUrl url;

  /// Default content type header.
  String get contentType => 'application/json';

  /// Starter headers for this request.
  final Headers _headers;

  /// Finalized headers, combining starter headers with the builder method.
  Headers get headers => _buildHeaders();

  /// Returns complete map of HTTP headers for this request.
  Headers _buildHeaders() {
    final headers = Map<String, String>.from(_headers);
    if (!headers.containsKey('Content-Type')) {
      headers['Content-Type'] = contentType;
    }
    return headers;
  }
}

/// {@template ReadApiRequest}
/// Subtype of [ApiRequest] for read, or GET requests. Along with having that
/// HTTP verb, these requests also have querystrings and not request bodies.
/// {@endtemplate}
class ReadApiRequest extends ApiRequest {
  /// {@macro ReadApiRequest}
  const ReadApiRequest({
    required super.url,
    super.headers,
    super.user,
    this.params,
  });

  /// GET/querystring-style payload of this request.
  final Params? params;
}

/// {@template AuthenticatedReadApiRequest}
/// Read requests that require user authentication to complete successfully.
/// {@endtemplate}
class AuthenticatedReadApiRequest extends ReadApiRequest {
  /// {@macro AuthenticatedReadApiRequest}
  const AuthenticatedReadApiRequest({
    required super.user,
    required super.url,
    super.headers,
    super.params,
  });
}

/// {@template WriteApiRequest}
/// Subtype of [ApiRequest] for write, or POST/PATCH/PUT requests. Along with
/// having one of those HTTP verbs, these requests also have request bodies and
/// not querystrings.
/// {@endtemplate}
class WriteApiRequest extends ApiRequest {
  /// {@macro WriteApiRequest}
  const WriteApiRequest({
    required super.url,
    required this.body,
    super.user,
    super.headers,
  });

  /// Request payload in serialized JSON format.
  final Json? body;
}

/// {@template AuthenticatedReadApiRequest}
/// Read requests that require user authentication to complete successfully.
/// {@endtemplate}
class AuthenticatedWriteApiRequest extends WriteApiRequest {
  /// {@macro AuthenticatedWriteApiRequest}
  const AuthenticatedWriteApiRequest({
    required super.user,
    required super.url,
    super.headers,
    super.body,
  });
}
