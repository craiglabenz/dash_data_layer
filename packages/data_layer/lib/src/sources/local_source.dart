import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:logging/logging.dart';

/// Function which can assign a new Id to an unsaved item.
typedef IdBuilder<T> = String Function(T);

/// Interface for how a [LocalSource] persists which requests returned which
/// records. Internally, this should store a map of request [CacheKey] values
/// to the set of Ids on each record returned by the server.
abstract class RequestCachePersistence {
  /// Logs a [RequestDetails.cacheKey] as being associated with these ids.
  Future<void> setCacheKey(CacheKey key, Set<String> ids);

  /// Returns all Ids associated with the given cache, if any. Empty result
  /// sets are not written to the cache, so a null result could indicate that
  /// the request is completely fresh or that it was previously made but
  /// returned no results.
  Future<Set<String>?> getCacheKey(CacheKey key);

  /// Yields all keys in the normal request cache.
  Future<Iterable<CacheKey>> getRequestCacheKeys();

  /// Yields all top level keys in the paginated cache.
  Future<Iterable<CacheKey>> noPaginationCacheKeys();

  /// Yields all second level keys under the top level key.
  Future<Iterable<CacheKey>> noPaginationInnerKeys(
    CacheKey noPaginationCacheKey,
  );

  /// Removes any trace of the [RequestDetails.cacheKey].
  Future<void> clearCacheKey(CacheKey key);

  /// Logs a paginated [RequestDetails.noPaginationCacheKey] and
  /// [RequestDetails.cacheKey] as being associated with these ids.
  Future<void> setPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
    required CacheKey cacheKey,
    required Set<String> ids,
  });

  /// Returns all Ids associated with the given cache, if any.
  Future<Set<String>?> getPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
    required CacheKey cacheKey,
  });

  /// Removes any trace of the paginated [RequestDetails] from the cache,
  /// including other pages from the same request.
  Future<void> clearPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
  });

  /// Clears all caching information.
  Future<void> clear();
}

/// Engine of [LocalSource] which stores serialized versions of actual data
/// records, accessible by their unique identifiers.
abstract class LocalSourceItemsPersistence<T> {
  /// Deletes all objects.
  Future<void> clear();

  /// Loads the instance of [T] whose primary key is [id].
  Future<T?> getById(String id);

  /// Loads all known instances of [T] whose primary key is contained in [ids].
  /// [ids] is allowed to be empty, in which case this should of course return
  /// an empty iterable.
  Future<Iterable<T>> getByIds(Set<String> ids);

  /// Persists an instance of [T].
  Future<void> setItem(T item, {required bool shouldOverwrite});

  /// Persists multiple instances of [T].
  Future<void> setItems(Iterable<T> items, {required bool shouldOverwrite});

  /// Removes records matching these Ids.
  Future<void> deleteIds(Set<String> ids);
}

/// {@template LocalSource}
/// Flavor of [Source] which is entirely on-device. Exists to coordinate its
/// [LocalSourceItemsPersistence] and [RequestCachePersistence].
/// {@endtemplate}
class LocalSource<T> extends Source<T> {
  /// {@macro LocalSource}
  LocalSource(
    this._itemsPersistence,
    this._requestCachePersistence, {
    this.idBuilder,
    super.bindings,
  });

  final _log = Logger('$LocalSource<$T>');

  /// Function to assign fresh Ids to new records. Only use very intentionally,
  /// as this task is typically best completed by a server.
  final IdBuilder<T>? idBuilder;

  /// Warehouse for all known instances of [T].
  final LocalSourceItemsPersistence<T> _itemsPersistence;

  /// Warehouse for caching metadata, both paginated and unpaginated.
  final RequestCachePersistence _requestCachePersistence;

  /// Removes all data from the local persistence.
  Future<void> clear() => Future.wait<void>([
    _itemsPersistence.clear(),
    _requestCachePersistence.clear(),
  ]);

  /// Removes these Ids from storage anywhere they may exist, which is why no
  /// [RequestDetails] are needed.
  Future<void> deleteIds(Set<String> ids) async {
    _log.finest('Deleting $ids');
    await _itemsPersistence.deleteIds(ids);

    final requestCacheCopy = <CacheKey, Set<String>>{};
    for (final cacheKey
        in await _requestCachePersistence.getRequestCacheKeys()) {
      final cacheResults = await _requestCachePersistence.getCacheKey(cacheKey);
      if (cacheResults != null) {
        requestCacheCopy[cacheKey] = cacheResults;
      }
    }
    for (final cacheKey
        in await _requestCachePersistence.getRequestCacheKeys()) {
      requestCacheCopy[cacheKey]!.removeAll(ids);
      if (requestCacheCopy[cacheKey]!.isEmpty) {
        requestCacheCopy.remove(cacheKey);
      }
    }

    final paginatedCacheCopy = <CacheKey, Map<CacheKey, Set<String>>>{};
    var noPageIter = await _requestCachePersistence.noPaginationCacheKeys();
    for (final noPaginationCacheKey in noPageIter) {
      // Add a default empty Map if the key is brand new
      if (!paginatedCacheCopy.containsKey(noPaginationCacheKey)) {
        paginatedCacheCopy[noPaginationCacheKey] = <CacheKey, Set<String>>{};
      }

      final innerPageIter = await _requestCachePersistence
          .noPaginationInnerKeys(
            noPaginationCacheKey,
          );
      for (final cacheKey in innerPageIter) {
        final innerIds = await _requestCachePersistence.getPaginatedCacheKey(
          noPaginationCacheKey: noPaginationCacheKey,
          cacheKey: cacheKey,
        );
        if (innerIds != null) {
          paginatedCacheCopy[noPaginationCacheKey]![cacheKey] = innerIds;
        }
      }
    }

    noPageIter = await _requestCachePersistence.noPaginationCacheKeys();
    for (final noPaginationCacheKey in noPageIter) {
      final innerPageIter = await _requestCachePersistence
          .noPaginationInnerKeys(
            noPaginationCacheKey,
          );
      for (final cacheKey in innerPageIter) {
        if (paginatedCacheCopy[noPaginationCacheKey] != null &&
            paginatedCacheCopy[noPaginationCacheKey]![cacheKey] != null) {
          paginatedCacheCopy[noPaginationCacheKey]![cacheKey]!.removeAll(ids);
        }

        if (paginatedCacheCopy[noPaginationCacheKey]![cacheKey]!.isEmpty) {
          paginatedCacheCopy[noPaginationCacheKey]!.remove(cacheKey);
        }
        if (paginatedCacheCopy[noPaginationCacheKey]!.isEmpty) {
          paginatedCacheCopy.remove(noPaginationCacheKey);
        }
      }
    }

    // Remove the entire request cache persistence and rebuild it from the
    // copy which has had the necessary deleted items removed.
    await _requestCachePersistence.clear();
    for (final cacheKey in requestCacheCopy.keys) {
      await _requestCachePersistence.setCacheKey(
        cacheKey,
        requestCacheCopy[cacheKey]!,
      );
    }
    for (final noPaginationCacheKey in paginatedCacheCopy.keys) {
      for (final cacheKey in paginatedCacheCopy[noPaginationCacheKey]!.keys) {
        await _requestCachePersistence.setPaginatedCacheKey(
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
      await _requestCachePersistence.clearCacheKey(details.cacheKey);
    } else {
      _log.finest(
        'Clearing paginated request $details with CacheKey '
        '${details.noPaginationCacheKey}::${details.cacheKey}',
      );
      // The "noPaginationCacheKey" is the family cache key of a paginated
      // request, so this removes all pages of a given request.
      await _requestCachePersistence.clearPaginatedCacheKey(
        noPaginationCacheKey: details.noPaginationCacheKey,
      );
    }
  }

  @override
  SourceType sourceType = SourceType.local;

  @override
  Future<ReadResult<T>> getById(String id, RequestDetails details) async {
    details.assertEmpty('LocalSource<$T>.getById');
    return ReadSuccess<T>(
      await _itemsPersistence.getById(id),
      details: details,
    );
  }

  @override
  Future<ReadListResult<T>> getByIds(
    Set<String> ids,
    RequestDetails details,
  ) async {
    details.assertEmpty('LocalSource<$T>.getByIds');
    final items = await _itemsPersistence.getByIds(ids);
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
      ids = await _requestCachePersistence.getCacheKey(details.cacheKey);
      _log.finest('Getting items for ${details.cacheKey}. Found Ids $ids');
    } else {
      ids = await _requestCachePersistence.getPaginatedCacheKey(
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

    final items = ids != null ? await _itemsPersistence.getByIds(ids) : <T>[];

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
    await _itemsPersistence.setItem(
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
      await _requestCachePersistence.setCacheKey(details.cacheKey, itemIds);
    } else {
      _log.finest(
        'Caching $itemIds to ${details.noPaginationCacheKey}::'
        '${details.cacheKey}',
      );
      await _requestCachePersistence.setPaginatedCacheKey(
        noPaginationCacheKey: details.noPaginationCacheKey,
        cacheKey: details.cacheKey,
        ids: itemIds,
      );
    }
    await _itemsPersistence.setItems(
      items,
      shouldOverwrite: details.shouldOverwrite,
    );

    return WriteListSuccess<T>(items, details: details);
  }

  @override
  Future<DeleteResult<T>> delete(String id, RequestDetails details) async {
    assert(
      details.requestType.includes(sourceType),
      'Should not route ${details.requestType} request to $this',
    );
    await deleteIds({id});
    return DeleteSuccess<T>(details);
  }
}
