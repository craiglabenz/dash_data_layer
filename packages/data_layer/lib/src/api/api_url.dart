/// @docImport 'rest_api.dart';
library;

/// {@template ApiUrl}
/// Container for locating resources on the server.
///
/// The [ApiUrl] class has no concept of the server's base URL. It is up to the
/// [RestApi] to provide that.
///
/// Usage:
/// ```dart
///  class LoginUrl extends ApiUrl {
///    const LoginUrl() : super(path: 'users/login/');
///  }
///
///  class DynamicUrl extends ApiUrl {
///    const DynamicUrl(this.token) : super(path: 'users/{{token}}/');
///  }
///
///  class RegisterUrl extends ApiUrl {
///    const RegisterUrl() : super(path: 'users/register/');
///  }
///
///  class LogoutUrl extends ApiUrl {
///    const LogoutUrl() : super(path: 'users/logout/');
///  }
/// ```
///
///  Can construct with placeholders and contexts, like so:
///
/// Usage:
/// ```dart
///   final url = ApiUrl(
///     path: "some/{{key}}/",
///     context: <String, String>{"key": "value"},
///     base: "api/v1",
///   );
///   url.value  # api/v1/some/value/
/// ```
/// {@endtemplate}
class ApiUrl {
  /// {@macro ApiUrl}
  const ApiUrl({required this.path, this.context = _empty, this.basePath});

  /// Optional versioning chunk for this Url. Subtypes can override this.
  final String? basePath;

  /// Chunk of the URL between the host and a possible querystring. May contain
  /// placeholders of the form {{placeholder}} that are hydrated by [context].
  ///
  /// Combined with baseUrl in the RestApi.
  ///
  final String path;

  /// Map of values used to fill placeholders in [uri].
  final Map<String, Object?> context;

  /// Computed value which flattens the [ApiUrl] into a plain string.
  String get value {
    var url = <String>[
      if (basePath != null && basePath != '') basePath!,
      path,
    ].join('/');
    for (final key in context.keys) {
      if (url.contains('{{$key}}')) {
        url = url.replaceAll('{{$key}}', context[key]! as String);
      }
    }
    return url;
  }

  /// Computed property which flattens the [ApiUrl] into a plain string, and
  /// then hydrates that into a [Uri].
  Uri get uri => Uri.parse(value);
}

/// {@template ApiUrl}
/// [ApiUrl] with an "api/v1" leading namespace.
///
/// This is merely an example.
/// {@endtemplate}
class ApiV1Url extends ApiUrl {
  /// {@macro ApiUrl}
  const ApiV1Url({required super.path, super.context = _empty})
    : super(basePath: 'api/v1');
}

/// Useful for tests.
class StubUrl extends ApiUrl {
  /// Constructor.
  const StubUrl() : super(path: '/');
}

const _empty = <String, Object?>{};
