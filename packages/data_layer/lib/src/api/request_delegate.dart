import 'dart:convert';
import 'package:data_layer/api.dart';
import 'package:http/http.dart' as http;

/// {@template UnexpectedRequest}
/// Exception which indicates that a [RequestDelegate] received an [ApiRequest]
/// with an unexpected http verb.
/// {@endtemplate}
class UnexpectedRequest implements Exception {
  /// {@macro UnexpectedRequest}
  UnexpectedRequest(this.message);

  /// Explanation of this error.
  final String message;

  @override
  String toString() => 'UnexpectedRequest($message)';
}

/// GET typedef
/// Represents all requests that lack a `body` component.
typedef ReadHandler =
    Future<http.Response> Function(Uri url, {Map<String, String>? headers});

/// POST/PUT/PATCH/DELETE typedef
/// Represents all requests that have a `body` component.
typedef WriteRequestHandler =
    Future<http.Response> Function(
      Uri url, {
      Map<String, String>? headers,
      Object? body,
      Encoding? encoding,
    });

/// Category of function which can convert an actual [http.Response] object
/// into a domain-logic equivalent, [ApiResult].
typedef ResponseProcessor = ApiResult Function(DateTime, http.Response);

Future<http.Response> _unexpectedGet(Uri url, {Map<String, String>? headers}) =>
    throw UnexpectedRequest('Unexpected GET $url');
Future<http.Response> _unexpectedPost(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => throw UnexpectedRequest('Unexpected POST $url');
Future<http.Response> _unexpectedPut(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => throw UnexpectedRequest('Unexpected PUT $url');
Future<http.Response> _unexpectedPatch(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => throw UnexpectedRequest('Unexpected PATCH $url');
Future<http.Response> _unexpectedDelete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) => throw UnexpectedRequest('Unexpected DELETE $url');

/// {@template RequestDelegate}
/// Utility which can read and write data via the network.
///
/// [RequestDelegate] instances accept a function for each http verb, making
/// them wrappers for the actual [http] library that are suitable for dependency
/// injection and tests.
/// {@endtemplate}
class RequestDelegate {
  /// {@macro RequestDelegate}
  const RequestDelegate._({
    required this.readHandler,
    required this.postHandler,
    required this.putHandler,
    required this.patchHandler,
    required this.deleteHandler,
    required this.responseProcessor,
  });

  /// Live [RequestDelegate] which uses the [http] library to make real
  /// network requests.
  const factory RequestDelegate.live() = _LiveRequestDelegate;

  /// Fake [RequestDelegate] which uses stubs to fake network requests. Omitting
  /// a value for some of the http verbs will cause this fake to throw an
  /// exception if those verbs are invoked, which helps with testing.
  factory RequestDelegate.fake({
    ReadHandler? readHandler,
    WriteRequestHandler? postHandler,
    WriteRequestHandler? putHandler,
    WriteRequestHandler? patchHandler,
    WriteRequestHandler? deleteHandler,
    ResponseProcessor? responseProcessor,
  }) => RequestDelegate._(
    readHandler: readHandler ?? _unexpectedGet,
    postHandler: postHandler ?? _unexpectedPost,
    putHandler: putHandler ?? _unexpectedPut,
    patchHandler: patchHandler ?? _unexpectedPatch,
    deleteHandler: deleteHandler ?? _unexpectedDelete,
    responseProcessor: responseProcessor ?? RequestDelegate.processResponse,
  );

  /// Method to execute GET requests.
  final ReadHandler readHandler;

  /// Method to execute POST requests.
  final WriteRequestHandler postHandler;

  /// Method to execute PUT requests.
  final WriteRequestHandler putHandler;

  /// Method to execute PATCH requests.
  final WriteRequestHandler patchHandler;

  /// Method to execute DELETE requests.
  final WriteRequestHandler deleteHandler;

  /// Method which converts [http.Response] objects into [ApiResult] objects.
  final ResponseProcessor responseProcessor;

  /// Executes a GET request via [readHandler].
  Future<ApiResult> get(
    String url, {
    required Map<String, String> headers,
  }) async => responseProcessor(
    DateTime.now(),
    await readHandler(Uri.parse(url), headers: headers),
  );

  /// Executes a DELETE request via [deleteHandler].
  Future<ApiResult> delete(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async => responseProcessor(
    DateTime.now(),
    await deleteHandler(
      Uri.parse(url),
      headers: headers,
      body: body,
      encoding: encoding,
    ),
  );

  /// Executes a PATCH request via [patchHandler].
  Future<ApiResult> patch(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async => responseProcessor(
    DateTime.now(),
    await patchHandler(
      Uri.parse(url),
      headers: headers,
      body: body,
      encoding: encoding,
    ),
  );

  /// Executes a POST request via [postHandler].
  Future<ApiResult> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return responseProcessor(
      DateTime.now(),
      await postHandler(
        Uri.parse(url),
        headers: headers,
        body: body,
        encoding: encoding,
      ),
    );
  }

  /// Executes a PUT request via [putHandler].
  Future<ApiResult> put(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async => responseProcessor(
    DateTime.now(),
    await putHandler(
      Uri.parse(url),
      headers: headers,
      body: body,
      encoding: encoding,
    ),
  );

  static const _shouldPrint = false;

  static void _print(String msg) {
    if (!RequestDelegate._shouldPrint) return;
    // This is the logging wrapper.
    // ignore: avoid_print
    print(msg);
  }

  /// Unpacks an [http.Response] object into an [ApiResult].
  static ApiResult processResponse(DateTime sentAt, http.Response resp) {
    final responseTime = DateTime.now().difference(sentAt);
    final statusCode = resp.statusCode;
    final is200 = (statusCode - 300) < 0;
    final is300 = !is200 && ((statusCode - 400) < 0);
    final is400 = !is200 && !is300 && (statusCode - 500) < 0;
    final is500 = !is200 && !is300 && !is400 && (statusCode - 500) >= 0;

    final rawResponseBody = utf8.decoder.convert(resp.bodyBytes);
    final contentType =
        resp.headers['content-type'] ?? resp.headers['Content-Type'];
    assert(contentType != null, 'contentType must have a value');

    ApiResultBody? body;

    if (rawResponseBody.isNotEmpty) {
      if (contentType != null) {
        if (contentType.contains('json')) {
          if (rawResponseBody.startsWith('{') ||
              rawResponseBody.startsWith('[')) {
            body = ApiResultBody.json(
              jsonDecode(rawResponseBody) as Map<String, dynamic>,
            );
          } else {
            body = ApiResultBody.plainText(rawResponseBody);
          }
        } else if (contentType.contains('html')) {
          body = ApiResultBody.html(rawResponseBody);
        } else if (contentType.contains('text')) {
          try {
            body = ApiResultBody.json(
              jsonDecode(rawResponseBody) as Map<String, dynamic>,
            );
          } on Exception catch (_) {
            body = ApiResultBody.plainText(rawResponseBody);
          }
        }
      }
    } else {
      // Empty response?
      body = !is200
          ? ApiResultBody.json(<String, dynamic>{
              'error': 'Unknown $statusCode Error',
            })
          : const ApiResultBody.json(<String, dynamic>{});
    }

    assert(body != null, 'body must not be null');

    if (is500) {
      _print('500!');
      _print(resp.body);
    }

    if (is200) {
      return ApiResult.success(
        body: body!,
        responseTime: responseTime,
        statusCode: resp.statusCode,
        url: resp.request?.url.toString() ?? '',
      );
    }

    // Error time!
    final errorMessage = switch (body!) {
      HtmlApiResultBody(:final html) => ErrorMessage.fromString(html),
      JsonApiResultBody(:final data) => ErrorMessage.fromMap(data),
      PlainTextApiResultBody(:final text) => ErrorMessage.fromString(text),
    };

    // Application.shared.logEvent(
    //   '${resp.statusCode} API Error to ${resp.request.url}: ${error.plain}',
    // );
    return ApiResult.error(
      error: errorMessage,
      responseTime: responseTime,
      statusCode: resp.statusCode,
      url: resp.request?.url.toString() ?? '',
    );
  }
}

class _LiveRequestDelegate extends RequestDelegate {
  const _LiveRequestDelegate()
    : super._(
        readHandler: http.get,
        postHandler: http.post,
        putHandler: http.put,
        patchHandler: http.patch,
        deleteHandler: http.delete,
        responseProcessor: RequestDelegate.processResponse,
      );
}
