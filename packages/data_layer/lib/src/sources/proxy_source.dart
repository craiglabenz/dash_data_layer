import 'package:data_layer/data_layer.dart';
import 'package:logging/logging.dart';

/// Logic to activate `getById`.
typedef GetById<T> = Future<T> Function(String, RequestDetails);

/// Logic to activate `getByIds`.
typedef GetByIds<T> = Future<List<T>> Function(Set<String>, RequestDetails);

/// Logic to activate `getItems`.
typedef GetItems<T> = Future<List<T>> Function(RequestDetails);

/// Logic to activate `setItem`.
typedef SetItem<T> = Future<T?> Function(T, RequestDetails);

/// Logic to activate `setItems`.
typedef SetItems<T> = Future<List<T>?> Function(Iterable<T>, RequestDetails);

/// Logic to activate `deleteItem`.
typedef DeleteItem<T> =
    Future<DeleteResult<T>> Function(
      String,
      RequestDetails,
    );

/// {@template ProxySource}
/// {@endtemplate}
class ProxySource<T> extends Source<T> {
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

  @override
  Future<DeleteResult<T>> delete(String id, RequestDetails details) async {
    if (deleteHandler == null) {
      throw UnimplementedError();
    }
    try {
      return deleteHandler!.call(id, details);
    } on Exception catch (e) {
      _log.severe(e);
      return DeleteFailure<T>(
        FailureReason.serverError,
        'Failed to delete $T with Id $id',
      );
    }
  }

  @override
  Future<ReadResult<T>> getById(String id, RequestDetails details) async {
    if (getByIdHandler == null) {
      throw UnimplementedError();
    }

    try {
      final obj = await getByIdHandler!.call(id, details);
      return ReadSuccess<T>(obj, details: details);
    } on Exception catch (e) {
      _log.severe(e);
      return ReadFailure<T>(
        FailureReason.serverError,
        'Failed to load $T with Id $id',
      );
    }
  }

  @override
  Future<ReadListResult<T>> getByIds(
    Set<String> ids,
    RequestDetails details,
  ) async {
    if (getByIdsHandler == null) {
      throw UnimplementedError();
    }

    try {
      final objs = await getByIdsHandler!.call(ids, details);
      final loadedIds = objs.map<String>((obj) => bindings.getId(obj)!).toSet();
      return ReadListResult.fromList(
        objs,
        details,
        ids.difference(loadedIds),
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
  Future<ReadListResult<T>> getItems(RequestDetails details) async {
    if (getItemsHandler == null) {
      throw UnimplementedError();
    }
    try {
      final objs = await getItemsHandler!.call(details);
      return ReadListResult.fromList(objs, details, {}, bindings.getId);
    } on Exception catch (e) {
      _log.severe(e);
      return ReadListFailure<T>(FailureReason.serverError, 'Failed to load $T');
    }
  }

  @override
  Future<WriteResult<T>> setItem(T item, RequestDetails details) async {
    if (setItemHandler == null) {
      throw UnimplementedError();
    }

    late final T? obj;
    try {
      obj = await setItemHandler!.call(item, details);
    } on Exception catch (e) {
      _log.severe(e);
      return WriteFailure<T>(FailureReason.serverError, 'Failed to save $item');
    }
    if (obj == null && bindings.getId(item) == null) {
      _log.warning(
        'Saved new $T but no object was returned; therefore we do not know '
        'its Id',
      );
    }
    return WriteSuccess<T>(obj ?? item, details: details);
  }

  @override
  Future<WriteListResult<T>> setItems(
    Iterable<T> items,
    RequestDetails details,
  ) async {
    if (setItemsHandler == null) {
      throw UnimplementedError();
    }
    late final List<T>? objs;
    try {
      objs = await setItemsHandler!.call(items, details);
    } on Exception catch (e) {
      _log.severe(e);
      return WriteListFailure<T>(
        FailureReason.serverError,
        'Failed to save $items',
      );
    }
    final anyNewItems = items.any((item) => bindings.getId(item) == null);
    if (anyNewItems && objs == null) {
      _log.warning(
        'Saved new $T objects but no finalized objects were returned; '
        'therefore we do not know their Ids',
      );
    }
    return WriteListSuccess(objs ?? items, details: details);
  }

  @override
  final SourceType sourceType;
}
