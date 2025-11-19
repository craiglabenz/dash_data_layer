import 'dart:convert';
import 'dart:io';

import 'package:data_layer/api.dart';
import 'package:data_layer/src/types.dart';
import 'package:logging/logging.dart';

/// {@template HeadersBuilder}
/// Function to return the necessary headers for a given request. The
/// "Content-Type" and authorization headers are handled automatically, so this
/// function should only build any *other* headers.
/// {@endtemplate}
typedef HeadersBuilder = Headers Function();

/// {@template restApi}
/// Handler for RESTful external communications. Applications will need a unique
/// [RestApi] instane for every different API with which they communicate.
/// {@endtemplate}
class RestApi {
  /// {@macro restApi}
  RestApi({
    required this.apiBaseUrl,
    required this.headersBuilder,
    RequestDelegate? delegate,
    this.forceEndingSlash = false,
    this.logLevel = Level.FINER,
  }) : _delegate = delegate ?? const RequestDelegate.live();

  final _log = Logger('RestApi');

  final RequestDelegate _delegate;

  /// {@macro HeadersBuilder}
  final HeadersBuilder headersBuilder;

  /// Root of this API's url. Should include the scheme, optional subdomain,
  /// domain, and TLD.
  final String apiBaseUrl;

  /// Whether to force a trailing slash on the end of the final Uri.
  final bool forceEndingSlash;

  /// Logging level for this instance.
  final Level logLevel;

  /// Builds default headers for all network requests.
  Map<String, String> getDefaultHeaders({String? contentType, String? accept}) {
    final headers = headersBuilder();
    if (contentType != null) {
      headers[HttpHeaders.contentTypeHeader] = contentType;
    }
    if (accept != null) {
      headers[HttpHeaders.acceptHeader] = accept;
    }
    return headers;
  }

  String _finishUrl(ApiRequest request) {
    String url = '$apiBaseUrl/${request.url.value}';
    if (forceEndingSlash && !url.endsWith('/')) {
      url = '$url/';
    }
    if (request is ReadApiRequest &&
        request.params != null &&
        request.params!.isNotEmpty) {
      url = '$url${Uri(queryParameters: request.params)}';
    }
    return url;
  }

  /// Sends a DELETE request via the [RequestDelegate].
  Future<ApiResult> delete(WriteApiRequest request) async {
    final headers = getDefaultHeaders()..addAll(request.headers);

    final result = await _delegate.delete(
      _finishUrl(request),
      headers: headers,
    );
    _log.log(
      logLevel,
      '${result.statusCode} (${result.responseTime}) :: $request',
    );
    return result;
  }

  /// Sends a GET request via the [RequestDelegate].
  Future<ApiResult> get(ReadApiRequest request) async {
    final headers = getDefaultHeaders()..addAll(request.headers);

    final url = _finishUrl(request);
    final result = await _delegate.get(url, headers: headers);
    _log.log(
      logLevel,
      '${result.statusCode} (${result.responseTime}) :: $request',
    );
    return result;
  }

  /// Sends a POST request via the [RequestDelegate].
  Future<ApiResult> post(WriteApiRequest request) async {
    final headers = getDefaultHeaders()..addAll(request.headers);

    final result = await _delegate.post(
      _finishUrl(request),
      body: request.body is! String ? jsonEncode(request.body) : request.body,
      headers: headers,
    );
    _log.log(
      logLevel,
      '${result.statusCode} (${result.responseTime}) :: $request',
    );
    return result;
  }

  /// Sends a PUT or PATCH request via the [RequestDelegate].
  Future<ApiResult> update(
    WriteApiRequest request, {
    bool partial = false,
  }) async {
    final headers = getDefaultHeaders()..addAll(request.headers);

    final fn = partial ? _delegate.patch : _delegate.put;

    final result = await fn(
      _finishUrl(request),
      body: request.body,
      headers: headers,
    );
    _log.log(
      logLevel,
      '${result.statusCode} (${result.responseTime}) :: $request',
    );
    return result;
  }
}
