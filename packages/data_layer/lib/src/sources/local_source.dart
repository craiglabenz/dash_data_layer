import 'package:data_layer/data_layer.dart';
import 'package:logging/logging.dart';

/// Function which can assign a new Id to an unsaved item.
typedef IdBuilder<T> = String Function(T);

/// Interface for how a [LocalSource] persists its request cache data.
abstract class CachePersistence {
  /// Logs a [RequestDetails.cacheKey] as being associated with these ids.
  void setCacheKey(CacheKey key, Set<String> ids);

  /// Returns all Ids associated with the given cache, if any.
  Set<String>? getCacheKey(CacheKey key);

  /// Yields all keys in the normal request cache.
  Iterable<CacheKey> getRequestCacheKeys();

  /// Yields all top level keys in the paginated cache.
  Iterable<CacheKey> noPaginationCacheKeys();

  /// Yields all second level keys under the top level key.
  Iterable<CacheKey> noPaginationInnerKeys(CacheKey noPaginationCacheKey);

  /// Removes any trace of the [RequestDetails.cacheKey].
  void clearCacheKey(CacheKey key);

  /// Logs a paginated [RequestDetails.noPaginationCacheKey] and
  /// [RequestDetails.cacheKey] as being associated with these ids.
  void setPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
    required CacheKey cacheKey,
    required Set<String> ids,
  });

  /// Returns all Ids associated with the given cache, if any.
  Set<String>? getPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
    required CacheKey cacheKey,
  });

  /// Removes any trace of the paginated [RequestDetails] from the cache,
  /// including other pages from the same request.
  void clearPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
  });

  /// Clears all caching information.
  void clear();
}

/// Engine of [LocalSource] which gives it its juice. Typical options are
/// in-memory and `pkg:hive_ce`.
abstract class LocalSourcePersistence<T> {
  /// Deletes all objects.
  void clear();

  /// Loads the instance of [T] whose primary key is [id].
  T? getById(String id);

  /// Loads all known instances of [T] whose primary key is contained in [ids].
  /// [ids] is allowed to be empty, in which case this should of course return
  /// an empty iterable.
  Iterable<T> getByIds(Set<String> ids);

  /// Persists an instance of [T].
  void setItem(T item, {required bool shouldOverwrite});

  /// Persists multiple instances of [T].
  void setItems(Iterable<T> items, {required bool shouldOverwrite});

  /// Removes records matching these Ids.
  void deleteIds(Set<String> ids);
}

/// {@template LocalSource}
/// Flavor of [Source] which is entirely on-device. Exists to coordinate its
/// [LocalSourcePersistence] and optional [CachePersistence].
/// {@endtemplate}
class LocalSource<T> extends Source<T> {
  /// {@macro LocalSource}
  LocalSource(
    this._itemsPersistence,
    this._cachePersistence, {
    this.idBuilder,
    super.bindings,
  });

  final _log = Logger('$LocalSource<$T>');

  /// Function to assign fresh Ids to new records. Only use very intentionally,
  /// as this task is typically best completed by a server.
  final IdBuilder<T>? idBuilder;

  /// Warehouse for all known instances of [T].
  final LocalSourcePersistence<T> _itemsPersistence;

  /// Warehouse for caching metadata, both paginated and unpaginated.
  final CachePersistence _cachePersistence;

  /// Removes all data from the local persistence.
  Future<void> clear() async {
    _itemsPersistence.clear();
    _cachePersistence.clear();
  }

  /// Removes these Ids from storage anywhere they may exist, which is why no
  /// [RequestDetails] are needed.
  void deleteIds(Set<String> ids) {
    _log.finest('Deleting $ids');
    _itemsPersistence.deleteIds(ids);

    final requestCacheCopy = <CacheKey, Set<String>>{};
    for (final cacheKey in _cachePersistence.getRequestCacheKeys()) {
      requestCacheCopy[cacheKey] = _cachePersistence.getCacheKey(cacheKey)!;
    }
    for (final cacheKey in _cachePersistence.getRequestCacheKeys()) {
      requestCacheCopy[cacheKey]!.removeAll(ids);
      if (requestCacheCopy[cacheKey]!.isEmpty) {
        requestCacheCopy.remove(cacheKey);
      }
    }

    final paginatedCacheCopy = <CacheKey, Map<CacheKey, Set<String>>>{};
    var noPageIter = _cachePersistence.noPaginationCacheKeys();
    for (final noPaginationCacheKey in noPageIter) {
      // Add a default empty Map if the key is brand new
      if (!paginatedCacheCopy.containsKey(noPaginationCacheKey)) {
        paginatedCacheCopy[noPaginationCacheKey] = <CacheKey, Set<String>>{};
      }

      final innerPageIter = _cachePersistence.noPaginationInnerKeys(
        noPaginationCacheKey,
      );
      for (final cacheKey in innerPageIter) {
        final innerIds = _cachePersistence.getPaginatedCacheKey(
          noPaginationCacheKey: noPaginationCacheKey,
          cacheKey: cacheKey,
        );
        paginatedCacheCopy[noPaginationCacheKey]![cacheKey] = innerIds!;
      }
    }

    noPageIter = _cachePersistence.noPaginationCacheKeys();
    for (final noPaginationCacheKey in noPageIter) {
      final innerPageIter = _cachePersistence.noPaginationInnerKeys(
        noPaginationCacheKey,
      );
      for (final cacheKey in innerPageIter) {
        paginatedCacheCopy[noPaginationCacheKey]![cacheKey]!.removeAll(ids);

        if (paginatedCacheCopy[noPaginationCacheKey]![cacheKey]!.isEmpty) {
          paginatedCacheCopy[noPaginationCacheKey]!.remove(cacheKey);
        }
        if (paginatedCacheCopy[noPaginationCacheKey]!.isEmpty) {
          paginatedCacheCopy.remove(noPaginationCacheKey);
        }
      }
    }

    _cachePersistence.clear();
    for (final cacheKey in requestCacheCopy.keys) {
      _cachePersistence.setCacheKey(cacheKey, requestCacheCopy[cacheKey]!);
    }
    for (final noPaginationCacheKey in paginatedCacheCopy.keys) {
      for (final cacheKey in paginatedCacheCopy[noPaginationCacheKey]!.keys) {
        _cachePersistence.setPaginatedCacheKey(
          noPaginationCacheKey: noPaginationCacheKey,
          cacheKey: cacheKey,
          ids: paginatedCacheCopy[noPaginationCacheKey]![cacheKey]!,
        );
      }
    }
  }

  /// Clears this request from the request cache.
  Future<void> clearForRequest(RequestDetails details) async {
    if (details.pagination == null) {
      _log.finest(
        'Clearing unpaginated request $details with CacheKey '
        '${details.cacheKey}',
      );
      _cachePersistence.clearCacheKey(details.cacheKey);
    } else {
      _log.finest(
        'Clearing paginated request $details with CacheKey '
        '${details.noPaginationCacheKey}::${details.cacheKey}',
      );
      // The "noPaginationCacheKey" is the family cache key of a paginated
      // request, so this removes all pages of a given request.
      _cachePersistence.clearPaginatedCacheKey(
        noPaginationCacheKey: details.noPaginationCacheKey,
      );
    }
  }

  @override
  SourceType sourceType = SourceType.local;

  @override
  Future<ReadResult<T>> getById(String id, RequestDetails details) async {
    details.assertEmpty('LocalSource<$T>.getById');
    return ReadSuccess<T>(_itemsPersistence.getById(id), details: details);
  }

  @override
  Future<ReadListResult<T>> getByIds(
    Set<String> ids,
    RequestDetails details,
  ) async {
    details.assertEmpty('LocalSource<$T>.getByIds');
    final items = _itemsPersistence.getByIds(ids);
    final foundItemIds = items
        .map<String>((item) => bindings.getId(item)!)
        .toSet();
    final missingItemIds = ids.difference(foundItemIds);
    return ReadListResult<T>.fromList(
      items,
      details,
      missingItemIds,
      bindings.getId,
    );
  }

  @override
  Future<ReadListResult<T>> getItems(RequestDetails details) async {
    Set<String>? ids;
    if (details.pagination == null) {
      ids = _cachePersistence.getCacheKey(details.cacheKey);
      _log.finest('Getting items for ${details.cacheKey}. Found Ids $ids');
    } else {
      ids = _cachePersistence.getPaginatedCacheKey(
        noPaginationCacheKey: details.noPaginationCacheKey,
        cacheKey: details.cacheKey,
      );
      _log.finest(
        'Getting items for ${details.noPaginationCacheKey}::'
        '${details.cacheKey}. Found Ids $ids',
      );
    }

    assert(
      ids == null || ids.isNotEmpty,
      'Unexpectedly found empty set of Ids $ids from cache for $details. \n'
      '[${details.noPaginationCacheKey}::${details.cacheKey}]\n'
      'Empty sets should not be cached.',
    );

    final items = ids != null ? _itemsPersistence.getByIds(ids) : <T>[];

    return ReadListResult.fromList(items, details, <String>{}, bindings.getId);
  }

  T _generateId(T item) => bindings.fromJson(
    bindings.toJson(item)..update('id', (value) => idBuilder!.call(item)),
  );

  @override
  Future<WriteResult<T>> setItem(T item, RequestDetails details) async {
    var itemCopy = item;
    if (bindings.getId(itemCopy) == null) {
      if (idBuilder == null) {
        _log.shout(
          'Failed to set Id to unsaved $itemCopy because idBuilder was null',
        );
        return WriteFailure<T>(FailureReason.badRequest, 'Could not save item');
      } else {
        itemCopy = _generateId(itemCopy);
      }
    }
    _itemsPersistence.setItem(
      itemCopy,
      shouldOverwrite: details.shouldOverwrite,
    );
    return WriteSuccess<T>(itemCopy, details: details);
  }

  @override
  Future<WriteListResult<T>> setItems(
    Iterable<T> items,
    RequestDetails details,
  ) async {
    if (items.isEmpty) {
      await clearForRequest(details);
      return WriteListSuccess<T>(items, details: details);
    }

    final itemIds = items.map<String>((item) => bindings.getId(item)!).toSet();
    if (details.pagination == null) {
      _log.finest('Caching $itemIds to ${details.cacheKey}');
      _cachePersistence.setCacheKey(details.cacheKey, itemIds);
    } else {
      _log.finest(
        'Caching $itemIds to ${details.noPaginationCacheKey}::'
        '${details.cacheKey}',
      );
      _cachePersistence.setPaginatedCacheKey(
        noPaginationCacheKey: details.noPaginationCacheKey,
        cacheKey: details.cacheKey,
        ids: itemIds,
      );
    }
    _itemsPersistence.setItems(items, shouldOverwrite: details.shouldOverwrite);

    return WriteListSuccess<T>(items, details: details);
  }

  @override
  Future<DeleteResult<T>> delete(String id, RequestDetails details) {
    assert(
      details.requestType.includes(sourceType),
      'Should not route ${details.requestType} request to $this',
    );
    deleteIds({id});
    return Future.value(DeleteSuccess<T>(details));
  }
}
