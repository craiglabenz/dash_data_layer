import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// {@template repo}
/// Data abstraction most likely to be exposed to other layers of the
/// application. Subclasses of this are where domain-specific logic should live.
/// {@endtemplate}
class Repository<T> with ReadinessMixin<void> {
  /// {@macro repo}
  Repository(
    this.sourceList, {
    String? loggerName,
    DateTime Function()? getTime,
  }) : getTime = getTime ?? _defaultGetTime,
       _log = Logger(loggerName ?? 'Repository<$T>') {
    sourceList.getTime = this.getTime;
  }

  /// Data loader within a [Repository] which can cascade through a list of data
  /// sources, treating each as a write-through cache.
  final SourceList<T> sourceList;

  late final Logger _log;

  /// Generates a unique operation ID, which defaults to v7 to preserve
  /// chronological ordering for logging and debugging purposes.
  String generateOperationId() => const Uuid().v7();

  /// Fallback for getting the current time, which defaults to the current
  /// time in UTC. Override this by passing `getTime` to the constructor to
  /// control the clock in tests.
  static DateTime _defaultGetTime() => DateTime.now().toUtc();

  /// {@template Repository.getTime}
  /// Reads the wall clock to annotate operations.
  /// {@endtemplate}
  final DateTime Function() getTime;

  /// {@template Repository.getById}
  /// Loads an item by the given [id] if it exists.
  /// {@endtemplate}
  Future<T?> getById(String id, {RequestDetails? details}) async {
    await ready;
    final result = await sourceList.getById(
      ReadOperation<T>(
        operationId: generateOperationId(),
        itemId: id,
        details: details ?? RequestDetails.read(),
        createdAt: getTime(),
      ),
    );
    switch (result) {
      case ReadSuccess<T>():
        return result.itemOrRaise();
      case ReadFailure<T>():
        _log.info('Failed to read $T with Id $id :: $result.error');
        return null;
    }
  }

  /// {@template Repository.watch}
  /// Opens a live stream for the item with the given [id].
  /// {@endtemplate}
  Stream<T?> watch(String id, {RequestDetails? details}) async* {
    await ready;
    yield* sourceList
        .watch(
          WatchOperation<T>(
            operationId: generateOperationId(),
            itemId: id,
            details: details ?? RequestDetails.read(),
            createdAt: getTime(),
          ),
        )
        .map((result) {
          switch (result) {
            case ReadSuccess<T>():
              return result.itemOrRaise();
            case ReadFailure<T>():
              _log.info('Failed to read $T with Id $id :: $result.error');
              return null;
          }
        });
  }

  /// {@template Repository.getByIds}
  /// Loads all items in the given Id set. If any Ids were not fulfilled, they
  /// are included in `missingIds`.
  /// {@endtemplate}
  Future<(List<T> items, Set<String> missingIds)> getByIds(
    Set<String> ids, {
    RequestDetails? details,
  }) async {
    await ready;
    final result = await sourceList.getByIds(
      ReadByIdsOperation<T>(
        operationId: generateOperationId(),
        itemIds: ids,
        details: details ?? RequestDetails.read(),
        createdAt: getTime(),
      ),
    );
    switch (result) {
      case ReadListSuccess<T>():
        final success = result.getOrRaise();
        return (success.items.toList(), success.missingItemIds);
      case ReadListFailure<T>():
        _log.info(
          'Failed to load $T with Ids $ids :: ${result.errorOrRaise()}',
        );
        return (<T>[], ids);
    }
  }

  /// Opens a live stream for all items in the given Id set.
  Stream<(List<T> items, Set<String> missingIds)> watchByIds(
    Set<String> ids, {
    RequestDetails? details,
  }) async* {
    await ready;
    yield* sourceList
        .watchByIds(
          WatchByIdsOperation<T>(
            operationId: generateOperationId(),
            itemIds: ids,
            details: details ?? RequestDetails.read(),
            createdAt: getTime(),
          ),
        )
        .map((result) {
          switch (result) {
            case ReadListSuccess<T>():
              final success = result.getOrRaise();
              return (success.items.toList(), success.missingItemIds);
            case ReadListFailure<T>():
              _log.info(
                'Failed to load $T with Ids $ids :: ${result.errorOrRaise()}',
              );
              return (<T>[], ids);
          }
        });
  }

  /// {@template Repository.getItems}
  /// Loads all items that match the given request [details], or the default
  /// [RequestDetails.read] object if not given.
  /// {@endtemplate}
  Future<List<T>> getItems({RequestDetails? details}) async {
    await ready;
    final result = await sourceList.getItems(
      ReadListOperation(
        operationId: generateOperationId(),
        details: details ?? RequestDetails.read(),
        createdAt: getTime(),
      ),
    );
    switch (result) {
      case ReadListSuccess<T>():
        return result.itemsOrRaise();
      case ReadListFailure<T>():
        return <T>[];
    }
  }

  /// {@template Repository.watchList}
  /// Opens a live stream for all items that match the given request [details],
  /// or the default [RequestDetails.read] object if not given.
  /// {@endtemplate}
  Stream<List<T>> watchList({RequestDetails? details}) async* {
    await ready;
    yield* sourceList
        .watchList(
          WatchListOperation<T>(
            operationId: generateOperationId(),
            details: details ?? RequestDetails.read(),
            createdAt: getTime(),
          ),
        )
        .map((result) {
          switch (result) {
            case ReadListSuccess<T>():
              return result.itemsOrRaise();
            case ReadListFailure<T>():
              return <T>[];
          }
        });
  }

  /// Persists the given item and returns the saved value if the write was
  /// successful.
  Future<T?> setItem(T item, {RequestDetails? details}) async {
    await ready;
    final result = await sourceList.setItem(
      WriteOperation<T>(
        operationId: generateOperationId(),
        item: item,
        details: details ?? RequestDetails.write(),
        createdAt: getTime(),
      ),
    );
    switch (result) {
      case WriteSuccess<T>():
        return result.item;
      case WriteFailure<T>():
        return null;
    }
  }

  /// Persists all [items].
  Future<List<T>> setItems(Iterable<T> items, {RequestDetails? details}) async {
    await ready;
    final result = await sourceList.setItems(
      WriteListOperation<T>(
        operationId: generateOperationId(),
        items: items,
        details: details ?? RequestDetails.write(),
        createdAt: getTime(),
      ),
    );
    switch (result) {
      case WriteListSuccess<T>():
        return result.items.toList();
      case WriteListFailure<T>():
        return <T>[];
    }
  }

  /// Removes the item associated with the given [id] from persistence.
  Future<void> delete(String id, {RequestDetails? details}) async {
    await ready;
    await sourceList.delete(
      DeleteOperation<T>(
        operationId: generateOperationId(),
        itemId: id,
        details: details ?? RequestDetails.write(),
        createdAt: getTime(),
      ),
    );
  }

  /// Clears all local data. Does not delete anything from any remote sources.
  Future<void> clear() async {
    await ready;
    await sourceList.clear();
  }

  /// Clears all local data cached against this request.
  Future<void> clearForRequest(RequestDetails details) async {
    await ready;
    await sourceList.clearForRequest(details);
  }

  /// Releases any open resources like stream subscriptions.
  @mustCallSuper
  void close() {}

  @override
  @mustCallSuper
  FutureOr<void> performInitialization() async {
    await sourceList.ready;
    markReady(null);
  }

  @override
  String toString() => 'Repository<$T>';
}

/// {@template MessageRepository}
/// A highly-typed adapter for a [Repository] that cleanly handles discrete
/// message/patch types (e.g. Freezed unions) for sending creation or update
/// operations securely over an untyped boundary, before being transformed into
/// the principal [T] object.
/// {@endtemplate}
class MessageRepository<T, M> extends Repository<T> {
  /// {@macro MessageRepository}
  MessageRepository(
    super.sourceList, {
    required this.messageBindings,
    super.loggerName,
    super.getTime,
  });

  /// The strongly-typed bindings detailing how your custom message serializes
  /// itself before being sent to the server.
  final Bindings<M> messageBindings;

  /// Sends a generic message structure which serves as either a creation
  /// or update depending on the evaluated presence of [targetId].
  Future<T?> sendMessage(
    M message, {
    String? targetId,
    RequestDetails? details,
  }) async {
    await ready;
    final result = await sourceList.sendMessage(
      SendMessageOperation<T>(
        operationId: generateOperationId(),
        message: MessagePayload<M>(message, messageBindings),
        targetId: targetId,
        details: details ?? RequestDetails.write(),
        createdAt: getTime(),
      ),
    );
    switch (result) {
      case WriteSuccess<T?>():
        return result.item;
      case WriteFailure<T?>():
        return null;
    }
  }
}
