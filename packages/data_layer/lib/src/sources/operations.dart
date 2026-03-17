import 'package:crypt/crypt.dart';
import 'package:data_layer/data_layer.dart'
    show RequestDetails, RequestDetailsConverter;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'operations.freezed.dart';
part 'operations.g.dart';

/// {@template Operation}
/// Carrier for all information required to describe a data operation.
///
/// This is source-independent, which means it does not contain details like
/// which URLs might return the requested data. That information is contained
/// by the sources to which these objects are passed.
/// {@endtemplate}
@Freezed(genericArgumentFactories: true)
sealed class Operation<T> with _$Operation<T> {
  const Operation._();

  /// A single item read operation that failed.
  const factory Operation.getItem({
    required String operationId,
    required String itemId,
    @RequestDetailsConverter() //
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = ReadOperation;

  /// A multi-item read operation that failed.
  const factory Operation.getItems({
    required String operationId,
    @RequestDetailsConverter() //
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = ReadListOperation;

  /// A multi-item read-by-ids operation that failed.
  const factory Operation.getByIds({
    required String operationId,
    required Set<String> itemIds,
    @RequestDetailsConverter() //
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = ReadByIdsOperation;

  /// A single item write operation that failed.
  const factory Operation.setItem({
    required String operationId,
    @RequestDetailsConverter() //
    required RequestDetails details,
    // required Json data,
    required T item,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = WriteOperation;

  /// A multi-item write operation that failed.
  const factory Operation.setItems({
    required String operationId,
    @RequestDetailsConverter() //
    required RequestDetails details,
    required Iterable<T> items,
    // required List<Json> data,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = WriteListOperation;

  /// A single item delete operation that failed.
  const factory Operation.delete({
    required String operationId,
    required String itemId,

    @RequestDetailsConverter() //
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = DeleteOperation;

  factory Operation.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$OperationFromJson(json, fromJsonT);

  /// Increments the retry count of this operation.
  R retry<R>() => copyWith(attemptNumber: attemptNumber + 1) as R;

  /// True if this operation is a read.
  bool get isRead => switch (this) {
    ReadOperation<T>() ||
    ReadListOperation<T>() ||
    ReadByIdsOperation<T>() => true,
    WriteOperation<T>() ||
    WriteListOperation<T>() ||
    DeleteOperation<T>() => false,
  };

  /// The cache key for this operation. This is used to deduplicate operations
  /// which are requesting the same data; specifically for watch operations
  /// which can reuse the same streams if they are requesting the exact same
  /// data.
  String get cacheKey {
    switch (this) {
      case ReadOperation<T>(:final itemId, :final details):
        return Crypt.sha256(
          '$itemId-${details.cacheKey}',
          rounds: 1,
          salt: 'read-op',
        ).toString();
      case WriteOperation<T>(:final item, :final details):
        return Crypt.sha256(
          '${item.hashCode}-${details.cacheKey}',
          rounds: 1,
          salt: 'write-op',
        ).toString();
      case DeleteOperation<T>(:final itemId, :final details):
        return Crypt.sha256(
          '$itemId-${details.cacheKey}',
          rounds: 1,
          salt: 'delete-op',
        ).toString();
      case ReadListOperation<T>():
        // [details.cacheKey] contains all relevant information for this
        // operation, including pagination and filters.
        return Crypt.sha256(
          details.cacheKey,
          rounds: 1,
          salt: 'read-list-op',
        ).toString();
      case WriteListOperation<T>(:final items, :final details):
        final sortedHashes = items.map((e) => e.hashCode).toList()..sort();
        return Crypt.sha256(
          '${sortedHashes.join('-')}-${details.cacheKey}',
          rounds: 1,
          salt: 'write-list-op',
        ).toString();
      case ReadByIdsOperation<T>(:final itemIds, :final details):
        final sortedIds = itemIds.toList()..sort();
        return Crypt.sha256(
          '${sortedIds.join('-')}-${details.cacheKey}',
          rounds: 1,
          salt: 'read-ids-op',
        ).toString();
    }
  }

  /// True if this operation is a write.
  bool get isWrite => !isRead;
}
