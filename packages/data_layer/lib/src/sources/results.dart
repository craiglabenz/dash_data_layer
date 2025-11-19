import 'dart:io';

import 'package:data_layer/data_layer.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:matcher/matcher.dart';

part 'results.freezed.dart';

final _log = Logger('Results');

//////////////////
/// WRITE RESULTS
//////////////////

/// Explanations for why a write request may have failed.
enum FailureReason {
  /// Write request failed because of a problem on the server.
  serverError,

  /// Write request failed because of a problem with the client's request.
  badRequest,
}

/// {@template WriteResult}
/// {@endtemplate}
@Freezed()
sealed class WriteResult<T> with _$WriteResult<T> {
  const WriteResult._();

  /// {@template WriteSuccess}
  /// Container for a single object write request which did not encounter any
  /// errors.
  /// {@endtemplate}
  const factory WriteResult.success(T item, {required RequestDetails details}) =
      WriteSuccess;

  /// {@template RequestFailure}
  /// Represents a failure with the write, resulting from either an unexpected
  /// problem on the server or the server rejecting the client's request.
  /// The `message` property should be suitable for showing the user.
  /// {@endtemplate}
  const factory WriteResult.failure(
    FailureReason reason,
    String message,
  ) = WriteFailure;

  /// {@template fromApiError}
  /// Builder for a failed write attemped, derived from its [ApiError].
  /// {@endtemplate}
  factory WriteResult.fromApiError(ApiError e) {
    if (e.statusCode >= HttpStatus.badRequest &&
        e.statusCode < HttpStatus.internalServerError) {
      return WriteFailure(FailureReason.badRequest, e.error.plain);
    } else if (e.statusCode >= HttpStatus.internalServerError) {
      return WriteFailure(FailureReason.serverError, e.error.plain);
    }
    // TODO(craiglabenz): Log `e.errorString`
    return WriteFailure(
      FailureReason.serverError,
      'Unexpected error: ${e.statusCode} ${e.error.plain}',
    );
  }

  /// Helper to extract expected [WriteSuccess] objects or throw in the case of
  /// an unexpected [WriteFailure].
  WriteSuccess<T> getOrRaise() => switch (this) {
    WriteSuccess<T>() => this as WriteSuccess<T>,
    WriteFailure<T>() => throw Exception('Unexpected $runtimeType'),
  };

  /// Helper to extract expected [WriteFailure] objects or throw in the case of
  /// an unexpected [WriteSuccess].
  WriteFailure<T> errorOrRaise() => switch (this) {
    WriteSuccess<T>() => throw Exception('Unexpected $runtimeType'),
    WriteFailure<T>() => this as WriteFailure<T>,
  };
}

/// {@template WriteListResult}
/// {@endtemplate}
@Freezed()
sealed class WriteListResult<T> with _$WriteListResult<T> {
  const WriteListResult._();

  /// {@template BulkWriteSuccess}
  /// Container for a bulk write request which did not encounter any errors.
  /// {@endtemplate}
  const factory WriteListResult.success(
    Iterable<T> items, {
    required RequestDetails details,
  }) = WriteListSuccess;

  /// {@macro RequestFailure}
  const factory WriteListResult.failure(
    FailureReason reason,
    String message,
  ) = WriteListFailure;

  /// {@macro fromApiError}
  factory WriteListResult.fromApiError(ApiError e) {
    if (e.statusCode >= HttpStatus.badRequest &&
        e.statusCode < HttpStatus.internalServerError) {
      return WriteListFailure(FailureReason.badRequest, e.error.plain);
    } else if (e.statusCode >= HttpStatus.internalServerError) {
      return WriteListFailure(FailureReason.serverError, e.error.plain);
    }
    // TODO(craiglabenz): Log `e.errorString`
    return WriteListFailure(
      FailureReason.serverError,
      'Unexpected error: ${e.statusCode} ${e.error.plain}',
    );
  }

  /// Helper to extract expected [WriteListSuccess] objects or throw in the case
  /// of an unexpected [WriteListFailure].
  WriteListSuccess<T> getOrRaise() => switch (this) {
    WriteListSuccess() => this as WriteListSuccess<T>,
    WriteListFailure() => throw Exception('Unexpected $runtimeType'),
  };

  /// Helper to extract expected [WriteListFailure] objects or throw in the case
  /// of an unexpected [WriteListSuccess].
  WriteListFailure<T> errorOrRaise() => switch (this) {
    WriteListSuccess() => throw Exception('Unexpected $runtimeType'),
    WriteListFailure() => this as WriteListFailure<T>,
  };
}

//////////??///////
/// DELETE RESULTS
////////////??/////

/// {@template WriteResult}
/// {@endtemplate}
@Freezed()
sealed class DeleteResult<T> with _$DeleteResult<T> {
  const DeleteResult._();

  /// {@template BulkWriteSuccess}
  /// Container for a bulk write request which did not encounter any errors.
  /// {@endtemplate}
  const factory DeleteResult.success(RequestDetails details) = DeleteSuccess;

  /// {@macro RequestFailure}
  const factory DeleteResult.failure(
    FailureReason reason,
    String message,
  ) = DeleteFailure;

  /// {@macro fromApiError}
  factory DeleteResult.fromApiError(ApiError e) {
    if (e.statusCode >= HttpStatus.badRequest &&
        e.statusCode < HttpStatus.internalServerError) {
      return DeleteFailure(FailureReason.badRequest, e.error.plain);
    } else if (e.statusCode >= HttpStatus.internalServerError) {
      return DeleteFailure(FailureReason.serverError, e.error.plain);
    }
    // TODO(craiglabenz): Log `e.errorString`
    return DeleteFailure(
      FailureReason.serverError,
      'Unexpected error: ${e.statusCode} ${e.error.plain}',
    );
  }

  /// Helper to extract expected [DeleteSuccess] objects or throw in the case
  /// of an unexpected [DeleteFailure].
  DeleteSuccess<T> getOrRaise() => switch (this) {
    DeleteSuccess() => this as DeleteSuccess<T>,
    DeleteFailure() => throw Exception('Unexpected $runtimeType'),
  };

  /// Helper to extract expected [DeleteFailure] objects or throw in the case
  /// of an unexpected [DeleteSuccess].
  DeleteFailure<T> errorOrRaise() => switch (this) {
    DeleteSuccess() => throw Exception('Unexpected $runtimeType'),
    DeleteFailure() => this as DeleteFailure<T>,
  };
}

/////////////////
/// READ RESULTS
/////////////////

/// {@template ReadResult}
/// {@endtemplate}
@Freezed()
sealed class ReadResult<T> with _$ReadResult<T> {
  /// Container for the results of a single object read that did not encounter
  /// any errors. Note that the requested object may be null, which is not an
  /// error.
  const factory ReadResult.success(
    T? item, {
    required RequestDetails details,
  }) = ReadSuccess;

  /// {@macro RequestFailure}
  const factory ReadResult.failure(
    FailureReason reason,
    String message,
  ) = ReadFailure;

  const ReadResult._();

  /// {@macro fromApiError}
  factory ReadResult.fromApiError(ApiError e) {
    if (e.statusCode >= HttpStatus.badRequest &&
        e.statusCode < HttpStatus.internalServerError) {
      return ReadFailure(FailureReason.badRequest, e.error.plain);
    } else if (e.statusCode >= HttpStatus.internalServerError) {
      return ReadFailure(FailureReason.serverError, e.error.plain);
    }
    return ReadFailure(
      FailureReason.serverError,
      'Unexpected error: ${e.statusCode} ${e.error.plain}',
    );
  }

  /// Helper to extract expected [ReadSuccess] objects or throw in the case
  /// of an unexpected [ReadFailure].
  ReadSuccess<T> getOrRaise() => switch (this) {
    ReadSuccess() => this as ReadSuccess<T>,
    ReadFailure() => throw Exception('Unexpected $runtimeType'),
  };

  /// Helper to extract expected [ReadFailure] objects or throw in the case
  /// of an unexpected [ReadSuccess].
  ReadFailure<T> errorOrRaise() => switch (this) {
    ReadSuccess() => throw Exception('Unexpected $runtimeType'),
    ReadFailure() => this as ReadFailure<T>,
  };

  /// Helper to extract expected [T?] objects or throw in the case of
  /// an unexpected [ReadFailure].
  ///
  /// Note that this will return `null` without throwing, as that is part of the
  /// contract of a [ReadSuccess]. This merely unwraps the possible
  /// [ReadFailure] which should have already been ruled out.
  T? itemOrRaise() => switch (this) {
    ReadSuccess<T>() => (this as ReadSuccess<T>).item,
    ReadFailure<T>() => throw Exception('Unexpected $runtimeType'),
  };
}

/// {@template ReadListResult}
/// {@endtemplate}
@Freezed()
sealed class ReadListResult<T> with _$ReadListResult<T> {
  /// Container for the results of a list read that did not encounter any
  /// errors. Note that the list of results may be empty, which is not an error.
  const factory ReadListResult({
    required Iterable<T> items,
    required Map<String, T> itemsMap,
    required Set<String> missingItemIds,
    required RequestDetails details,
  }) = ReadListSuccess;

  const ReadListResult._();

  /// Map-friendly constructor.
  factory ReadListResult.fromMap(
    Map<String, T> map,
    RequestDetails details,
    Set<String> missingItemIds,
  ) => ReadListSuccess(
    items: map.values.toList(),
    itemsMap: map,
    missingItemIds: missingItemIds,
    details: details,
  );

  /// List-friendly constructor.
  factory ReadListResult.fromList(
    Iterable<T> items,
    RequestDetails details,
    Set<String> missingItemIds,
    String? Function(T) getId,
  ) {
    final map = <String, T>{};
    for (final item in items) {
      map[getId(item)!] = item;
    }
    return ReadListSuccess(
      items: items,
      itemsMap: map,
      details: details,
      missingItemIds: missingItemIds,
    );
  }

  factory ReadListResult.empty(
    RequestDetails details, {
    Set<String> missingItemIds = const <String>{},
  }) => ReadListResult.fromList(
    <T>[],
    details,
    missingItemIds,
    (_) => throw Exception(
      'Unexpectedly called getId from ReadListResult.empty',
    ),
  );

  /// {@macro RequestFailure}
  const factory ReadListResult.failure(
    FailureReason reason,
    String message,
  ) = ReadListFailure;

  /// {@macro fromApiError}
  factory ReadListResult.fromApiError(ApiError e) {
    if (e.statusCode >= HttpStatus.badRequest &&
        e.statusCode < HttpStatus.internalServerError) {
      return ReadListFailure(FailureReason.badRequest, e.error.plain);
    } else if (e.statusCode >= HttpStatus.internalServerError) {
      return ReadListFailure(FailureReason.serverError, e.error.plain);
    }
    // TODO(craiglabenz): Log `e.errorString`
    return ReadListFailure(
      FailureReason.serverError,
      'Unexpected error: ${e.statusCode} ${e.error.plain}',
    );
  }

  /// Helper to extract expected [ReadListSuccess] objects or throw in the case
  /// of an unexpected [ReadListFailure].
  ReadListSuccess<T> getOrRaise() => switch (this) {
    ReadListSuccess() => this as ReadListSuccess<T>,
    ReadListFailure() => throw Exception('Unexpected $runtimeType'),
  };

  /// Helper to extract expected [ReadListFailure] objects or throw in the case
  /// of an unexpected [ReadListSuccess].
  ReadListFailure<T> errorOrRaise() {
    try {
      return switch (this) {
        ReadListSuccess() => throw Exception('Unexpected $runtimeType'),
        ReadListFailure() => this as ReadListFailure<T>,
      };
    } on Exception catch (e, st) {
      _log.severe('Error with itemsOrRaise for $T', e, st);
      return ReadListFailure<T>(
        FailureReason.badRequest,
        'Failure parsing error',
      );
    }
  }

  /// Helper to extract expected [List<T>] objects or throw in the case of
  /// an unexpected [ReadListFailure].
  ///
  /// Note that this will return an empty list without throwing, as that is part
  /// of the contract of a [ReadListSuccess]. This merely unwraps the possible
  /// [ReadListFailure] which should have already been ruled out.
  List<T> itemsOrRaise() {
    try {
      return switch (this) {
        ReadListSuccess<T>() => (this as ReadListSuccess<T>).items.toList(),
        ReadListFailure<T>() => throw Exception('Unexpected $runtimeType'),
      };
    } on Exception catch (e, st) {
      _log.severe('Error with itemsOrRaise for $T', e, st);
      return [];
    }
  }
}

/// Testing matcher for whether this request was a failure.
const Matcher isFailure = _IsFailure();

class _IsFailure extends Matcher {
  const _IsFailure();
  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) =>
      item is ReadFailure ||
      item is ReadListFailure ||
      item is WriteFailure ||
      item is WriteListFailure;

  @override
  Description describe(Description description) =>
      description.add('is-failure');
}

/// Testing matcher for whether this was a success.
const Matcher isSuccess = _IsSuccess();

class _IsSuccess extends Matcher {
  const _IsSuccess();
  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) =>
      item is ReadSuccess ||
      item is ReadListSuccess ||
      item is WriteSuccess ||
      item is WriteListSuccess;

  @override
  Description describe(Description description) =>
      description.add('is-success');
}
