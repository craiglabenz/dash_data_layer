/// Replacement for `dart:io`'s [HttpStatus] for web compatibility.
class HttpStatus {
  /// 200 OK
  static const int ok = 200;

  /// 400 Bad Request
  static const int badRequest = 400;

  /// 404 Not Found
  static const int notFound = 404;

  /// 500 Internal Server Error
  static const int internalServerError = 500;
}

/// Replacement for `dart:io`'s [HttpHeaders] for web compatibility.
class HttpHeaders {
  /// "content-type"
  static const String contentTypeHeader = 'content-type';

  /// "accept"
  static const String acceptHeader = 'accept';
}
