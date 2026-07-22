import 'package:crypt/crypt.dart';
import 'package:data_layer/data_layer.dart'
    show RequestDetails, RequestDetailsConverter, Source;
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

  /// A single item read operation.
  const factory Operation.getItem({
    required String operationId,
    required String itemId,
    @RequestDetailsConverter() //
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = ReadOperation;

  /// A multi-item read operation.
  const factory Operation.getItems({
    required String operationId,
    @RequestDetailsConverter() //
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = ReadListOperation;

  /// A multi-item read-by-ids operation.
  const factory Operation.getByIds({
    required String operationId,
    required Set<String> itemIds,
    @RequestDetailsConverter() //
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = ReadByIdsOperation;

  /// A single item write operation.
  const factory Operation.setItem({
    required String operationId,
    @RequestDetailsConverter() //
    required RequestDetails details,
    // required Json data,
    required T item,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = WriteOperation;

  /// A multi-item write operation.
  const factory Operation.setItems({
    required String operationId,
    @RequestDetailsConverter() //
    required RequestDetails details,
    required Iterable<T> items,
    // required List<Json> data,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = WriteListOperation;

  /// A single item delete operation.
  const factory Operation.delete({
    required String operationId,
    required String itemId,

    @RequestDetailsConverter() //
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = DeleteOperation;

  /// A generic message operation for sending an object creation or update.
  const factory Operation.sendMessage({
    required String operationId,
    required Object message,
    @RequestDetailsConverter() //
    required RequestDetails details,
    required DateTime createdAt,
    String? targetId,
    @Default(0) int attemptNumber,
  }) = SendMessageOperation;

  /// A single item watch operation.
  const factory Operation.watch({
    required String operationId,
    required String itemId,
    @RequestDetailsConverter() //
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = WatchOperation;

  /// A multi-item watch operation.
  const factory Operation.watchList({
    required String operationId,
    @RequestDetailsConverter() //
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = WatchListOperation;

  /// A multi-item watch-by-ids operation.
  const factory Operation.watchByIds({
    required String operationId,
    required Set<String> itemIds,
    @RequestDetailsConverter() //
    required RequestDetails details,
    required DateTime createdAt,
    @Default(0) int attemptNumber,
  }) = WatchByIdsOperation;

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
    ReadByIdsOperation<T>() ||
    WatchOperation<T>() ||
    WatchListOperation<T>() ||
    WatchByIdsOperation<T>() => true,
    WriteOperation<T>() ||
    WriteListOperation<T>() ||
    DeleteOperation<T>() ||
    SendMessageOperation<T>() => false,
  };

  /// The cache key for this operation. This is used to deduplicate operations
  /// which are requesting the same data; specifically for watch operations
  /// which can reuse the same streams if they are requesting the exact same
  /// data.
  String get cacheKey {
    switch (this) {
      case ReadOperation<T>(:final itemId, :final details) ||
          WatchOperation<T>(:final itemId, :final details):
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
      case ReadListOperation<T>() || WatchListOperation<T>():
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
      case ReadByIdsOperation<T>(:final itemIds, :final details) ||
          WatchByIdsOperation<T>(:final itemIds, :final details):
        final sortedIds = itemIds.toList()..sort();
        return Crypt.sha256(
          '${sortedIds.join('-')}-${details.cacheKey}',
          rounds: 1,
          salt: 'read-ids-op',
        ).toString();
      case SendMessageOperation<T>(
        :final targetId,
        :final message,
        :final details,
      ):
        return Crypt.sha256(
          '${targetId}_${message.hashCode}-${details.cacheKey}',
          rounds: 1,
          salt: 'send-message-op',
        ).toString();
    }
  }

  /// Detects invalid configurations to warn developers of possible mistakes.
  void validate() {
    final requestType = details.requestType;
    if (isRead && details.forceInsert) {
      throw StateError(
        'Setting forceInsert to true for ReadOperations is invalid',
      );
    }
    if (requestType == .allLocal &&
        this is! ReadListOperation &&
        this is! WatchListOperation) {
      throw StateError(
        'RequestType.allLocal is only valid in getItems method. '
        'Other methods are unlikely to honor this request, as its '
        'behavior would be contradictory and undefined.',
      );
    }
    if (requestType == .refresh && isWrite) {
      throw StateError(
        'Using a requestType of .allLocal or .refresh is invalid for '
        'writes',
      );
    }
  }

  /// True if this operation is a write.
  bool get isWrite => !isRead;

  /// The [SourceOperationType] corresponding to this [Operation].
  SourceOperationType get type => switch (this) {
    ReadOperation<T>() => SourceOperationType.getById,
    ReadListOperation<T>() => SourceOperationType.getItems,
    ReadByIdsOperation<T>() => SourceOperationType.getByIds,
    WriteOperation<T>() => SourceOperationType.setItem,
    WriteListOperation<T>() => SourceOperationType.setItems,
    DeleteOperation<T>() => SourceOperationType.delete,
    SendMessageOperation<T>() => SourceOperationType.sendMessage,
    WatchOperation<T>() => SourceOperationType.watch,
    WatchListOperation<T>() => SourceOperationType.watchList,
    WatchByIdsOperation<T>() => SourceOperationType.watchByIds,
  };
}

/// Operations supported by a [Source].
enum SourceOperationType {
  /// Operation to get a single item by its ID.
  getById,

  /// Operation to get multiple items by their IDs.
  getByIds,

  /// Operation to get multiple items.
  getItems,

  /// Operation to write a single item.
  setItem,

  /// Operation to write multiple items.
  setItems,

  /// Operation to delete a single item by its ID.
  delete,

  /// Operation to send a message.
  sendMessage,

  /// Operation to watch a single item.
  watch,

  /// Operation to watch multiple items.
  watchList,

  /// Operation to watch multiple items by their IDs.
  watchByIds,
}
