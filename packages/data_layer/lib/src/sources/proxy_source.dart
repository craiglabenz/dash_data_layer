import 'package:data_layer/data_layer.dart';
import 'package:logging/logging.dart';

/// Logic to activate `getById`.
typedef GetById<T> = Future<T> Function(ReadOperation<T>);

/// Logic to activate `getByIds`.
typedef GetByIds<T> = Future<List<T>> Function(ReadByIdsOperation<T>);

/// Logic to activate `getItems`.
typedef GetItems<T> = Future<List<T>> Function(ReadListOperation<T>);

/// Logic to activate `setItem`.
typedef SetItem<T> = Future<T?> Function(WriteOperation<T>);

/// Logic to activate `setItems`.
typedef SetItems<T> = Future<List<T>?> Function(WriteListOperation<T>);

/// Logic to activate `deleteItem`.
typedef DeleteItem<T> = Future<DeleteResult<T>> Function(DeleteOperation<T>);

/// Logic to activate `sendMessage`.
typedef SendMessage<T> = Future<T?> Function(SendMessageOperation<T>);

/// {@template ProxySource}
/// Source whose constructor accepts a value for each operation type.
///
/// This is a build-a-source model to adapt an arbitrary data source to the
/// pkg:data_layer system.
/// {@endtemplate}
class ProxySource<T> extends Source<T> with MessageWriteMixin<T> {
  /// {@macro ProxySource}
  ProxySource({
    required super.bindings,
    required this.sourceType,
    this.getByIdHandler,
    this.getByIdsHandler,
    this.getItemsHandler,
    this.setItemHandler,
    this.setItemsHandler,
    this.deleteHandler,
    this.sendMessageHandler,
  });

  final _log = Logger('ProxySource<T>');

  /// If supplied, used to satisfy [getById].
  final GetById<T>? getByIdHandler;

  /// If supplied, used to satisfy [getByIds].
  final GetByIds<T>? getByIdsHandler;

  /// If supplied, used to satisfy [getItems].
  final GetItems<T>? getItemsHandler;

  /// If supplied, used to satisfy [setItem].
  final SetItem<T>? setItemHandler;

  /// If supplied, used to satisfy [setItems].
  final SetItems<T>? setItemsHandler;

  /// If supplied, used to satisfy [delete].
  final DeleteItem<T>? deleteHandler;

  /// If supplied, used to satisfy [sendMessage].
  final SendMessage<T>? sendMessageHandler;

  @override
  Set<SourceOperationType> get supportedOperations => {
    if (getByIdHandler != null) SourceOperationType.getById,
    if (getByIdsHandler != null) SourceOperationType.getByIds,
    if (getItemsHandler != null) SourceOperationType.getItems,
    if (setItemHandler != null) SourceOperationType.setItem,
    if (setItemsHandler != null) SourceOperationType.setItems,
    if (deleteHandler != null) SourceOperationType.delete,
    if (sendMessageHandler != null) SourceOperationType.sendMessage,
  };

  @override
  Future<WriteResult<T>> sendMessage(
    SendMessageOperation<T> operation,
  ) async {
    if (sendMessageHandler == null) {
      throw UnimplementedError();
    }
    try {
      final obj = await sendMessageHandler!.call(operation);
      return WriteSuccess<T>(obj as T, details: operation.details);
    } on Exception catch (e) {
      _log.severe(e);
      return WriteFailure<T>(
        FailureReason.serverError,
        'Failed to send message',
      );
    }
  }

  @override
  Future<DeleteResult<T>> delete(DeleteOperation<T> operation) async {
    if (deleteHandler == null) {
      throw UnimplementedError();
    }
    try {
      return deleteHandler!.call(operation);
    } on Exception catch (e) {
      _log.severe(e);
      return DeleteFailure<T>(
        FailureReason.serverError,
        'Failed to delete $T with Id ${operation.itemId}',
      );
    }
  }

  @override
  Future<ReadResult<T>> getById(ReadOperation<T> operation) async {
    if (getByIdHandler == null) {
      throw UnimplementedError();
    }

    try {
      final obj = await getByIdHandler!.call(operation);
      return ReadSuccess<T>(obj, details: operation.details);
    } on Exception catch (e) {
      _log.severe(e);
      return ReadFailure<T>(
        FailureReason.serverError,
        'Failed to load $T with Id ${operation.itemId}',
      );
    }
  }

  @override
  Future<ReadListResult<T>> getByIds(ReadByIdsOperation<T> operation) async {
    if (getByIdsHandler == null) {
      throw UnimplementedError();
    }

    try {
      final objs = await getByIdsHandler!.call(operation);
      final loadedIds = objs.map<String>((obj) => bindings.getId(obj)!).toSet();
      return ReadListResult.fromList(
        objs,
        operation.details,
        operation.itemIds.difference(loadedIds),
        bindings.getId,
      );
    } on Exception catch (e) {
      _log.severe(e);
      return ReadListFailure<T>(
        FailureReason.serverError,
        'Failed to load $T by Ids',
      );
    }
  }

  @override
  Future<ReadListResult<T>> getItems(ReadListOperation<T> operation) async {
    if (getItemsHandler == null) {
      throw UnimplementedError();
    }
    try {
      final objs = await getItemsHandler!.call(operation);
      return ReadListResult.fromList(
        objs,
        operation.details,
        {},
        bindings.getId,
      );
    } on Exception catch (e) {
      _log.severe(e);
      return ReadListFailure<T>(FailureReason.serverError, 'Failed to load $T');
    }
  }

  @override
  Future<WriteResult<T>> setItem(WriteOperation<T> operation) async {
    if (setItemHandler == null) {
      throw UnimplementedError();
    }

    late final T? obj;
    try {
      obj = await setItemHandler!.call(operation);
    } on Exception catch (e) {
      _log.severe(e);
      return WriteFailure<T>(
        FailureReason.serverError,
        'Failed to save ${operation.item}',
      );
    }
    if (obj == null && bindings.getId(operation.item) == null) {
      _log.warning(
        'Saved new $T but no object was returned; therefore we do not know '
        'its Id',
      );
    }
    return WriteSuccess<T>(obj ?? operation.item, details: operation.details);
  }

  @override
  Future<WriteListResult<T>> setItems(WriteListOperation<T> operation) async {
    if (setItemsHandler == null) {
      throw UnimplementedError();
    }
    late final List<T>? objs;
    try {
      objs = await setItemsHandler!.call(operation);
    } on Exception catch (e) {
      _log.severe(e);
      return WriteListFailure<T>(
        FailureReason.serverError,
        'Failed to save ${operation.items}',
      );
    }
    final anyNewItems = operation.items.any(
      (item) => bindings.getId(item) == null,
    );
    if (anyNewItems && objs == null) {
      _log.warning(
        'Saved new $T objects but no finalized objects were returned; '
        'therefore we do not know their Ids',
      );
    }
    return WriteListSuccess(
      objs ?? operation.items,
      details: operation.details,
    );
  }

  @override
  final SourceType sourceType;
}
