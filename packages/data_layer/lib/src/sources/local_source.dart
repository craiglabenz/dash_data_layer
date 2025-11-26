import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:logging/logging.dart';

/// Function which can assign a new Id to an unsaved item.
typedef IdBuilder<T> = String Function(T);

/// {@template LocalSource}
/// Flavor of [Source] which is entirely on-device.
///
/// Internally, this class's entire job is to coordinate its various
/// [ExpiringCache] objects.
/// {@endtemplate}
class LocalSource<T> extends Source<T> {
  /// {@macro LocalSource}
  LocalSource({
    required ExpiringCache<T> itemsCache,
    required ExpiringCache<Set<String>> requestCache,
    required SourceCache<Set<String>> paginatedRequestCache,
    this.ttl,
    super.bindings,
  }) : _itemsCache = itemsCache,
       _requestCache = requestCache,
       _paginatedRequestCache = paginatedRequestCache;

  final _log = Logger('$LocalSource<$T>');

  /// Warehouse for all known instances of [T].
  final ExpiringCache<T> _itemsCache;

  /// Warehouse for caching request metadata, both paginated and unpaginated.
  final ExpiringCache<Set<String>> _requestCache;

  /// Warehouse for caching request metadata, both paginated and unpaginated.
  /// Not an [ExpiringCache] because pages expire individually.
  final SourceCache<Set<String>> _paginatedRequestCache;

  /// Duration after which the data should be considered stale. Stale data will
  /// not be returned, and will be deleted when requested. There is no other
  /// periodic process to remove stale data - if it is never requested again,
  /// it will remain in storage indefinitely.
  ///
  /// A null value indicates that the data should never expire.
  final Duration? ttl;

  /// Removes all data from the local persistence.
  Future<void> clear() => Future.wait<void>([
    _itemsCache.clear(),
    _requestCache.clear(),
  ]);

  /// Removes these Ids from storage anywhere they may exist, which is why no
  /// [RequestDetails] are needed.
  Future<void> deleteIds(Set<String> ids) async {
    _log.finest('Deleting $ids');
    await _itemsCache.multiDelete(ids);

    final allcachedRequests = await _requestCache.readAll();
    final deletedRequests = <CacheKey>{};
    for (final requestCacheKey in allcachedRequests.keys) {
      final requestCacheIds = allcachedRequests[requestCacheKey];
      if (requestCacheIds != null) {
        final originalLength = requestCacheIds.length;
        requestCacheIds.removeWhere((id) => ids.contains(id));
        if (requestCacheIds.isEmpty) {
          await _requestCache.delete(requestCacheKey);
          deletedRequests.add(requestCacheKey);
        } else if (requestCacheIds.length < originalLength) {
          await _requestCache.write(requestCacheKey, requestCacheIds);
        }
      }
    }

    final allPaginationClusters = await _paginatedRequestCache.readAll();
    for (final paginationCluster in allPaginationClusters.entries) {
      final noPaginationCacheKey = paginationCluster.key;
      final paginatedCacheKeys = paginationCluster.value;

      // If all of the paginated CacheKeys from this cluster were deleted, then
      // we can delete the parent CacheKey as well.
      if (deletedRequests.intersection(paginatedCacheKeys).length ==
          paginatedCacheKeys.length) {
        await _paginatedRequestCache.delete(noPaginationCacheKey);
      }
    }
  }

  /// Clears this request from the request cache.
  Future<void> clearForRequest(RequestDetails details) async {
    _log.finest(
      'Clearing paginated request $details with CacheKey '
      '${details.cacheKey}',
    );
    if (details.pagination == null) {
      return _requestCache.delete(details.cacheKey);
    } else {
      final paginationCluster = await _paginatedRequestCache.read(
        details.noPaginationCacheKey,
      );
      if (paginationCluster != null) {
        await _requestCache.multiDelete(paginationCluster);
        await _paginatedRequestCache.delete(details.noPaginationCacheKey);
      }
    }
  }

  @override
  SourceType sourceType = SourceType.local;

  @override
  Future<ReadResult<T>> getById(String id, RequestDetails details) async {
    details.assertEmpty('LocalSource<$T>.getById');
    return ReadSuccess<T>(
      await _itemsCache.read(id),
      details: details,
    );
  }

  @override
  Future<ReadListResult<T>> getByIds(
    Set<String> ids,
    RequestDetails details,
  ) async {
    details.assertEmpty('LocalSource<$T>.getByIds');
    final items = await _itemsCache.multiRead(ids);
    final foundItemIds = items.keys.toSet();
    final missingItemIds = ids.difference(foundItemIds);
    return ReadListResult<T>.fromMap(
      items,
      details,
      missingItemIds,
    );
  }

  @override
  Future<ReadListResult<T>> getItems(RequestDetails details) async {
    Set<String>? ids;
    if (details.requestType == .allLocal) {
      final allItems = await _itemsCache.readAll();
      return ReadListResult.fromMap(
        allItems,
        details,
        <String>{},
      );
    }

    ids = await _requestCache.read(details.cacheKey);
    _log.finest('Getting items for ${details.cacheKey}. Found Ids $ids');

    assert(
      ids == null || ids.isNotEmpty,
      'Unexpectedly found empty set of Ids $ids from cache for $details. \n'
      'Empty sets should never be cached.',
    );

    final items = ids != null
        ? await _itemsCache.multiRead(ids)
        : <String, T>{};

    return ReadListResult.fromMap(items, details, <String>{});
  }

  T _generateId(T item) => (bindings as CreationBindings<T>).save(item);

  @override
  Future<WriteResult<T>> setItem(T item, RequestDetails details) async {
    var itemCopy = item;
    if (bindings.getId(itemCopy) == null) {
      if (bindings is! CreationBindings<T>) {
        _log.shout(
          'Failed to set Id to unsaved $itemCopy because Bindings was not a '
          'CreationBindings',
        );
        return WriteFailure<T>(
          FailureReason.badRequest,
          'Could not save item with null Id',
        );
      } else {
        itemCopy = _generateId(itemCopy);
      }
    }

    await _itemsCache.write(
      bindings.getId(itemCopy)!,
      itemCopy,
      ttl: details.ttl ?? ttl,
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
    _log.finest('Caching $itemIds to ${details.cacheKey}');
    await _requestCache.write(
      details.cacheKey,
      itemIds,
      ttl: details.ttl ?? ttl,
    );

    if (details.pagination != null) {
      final pageClusterCacheKeys =
          await _paginatedRequestCache.read(
            details.noPaginationCacheKey,
          ) ??
          <CacheKey>{};

      if (!pageClusterCacheKeys.contains(details.cacheKey)) {
        pageClusterCacheKeys.add(details.cacheKey);
        await _paginatedRequestCache.write(
          details.noPaginationCacheKey,
          pageClusterCacheKeys,
          // Do not pass ttl here -- that is handled by [_requestCache]
          // because paginated requests timeout individually, not as a cluster
        );
      }
    }

    // Now save the actual item payloads
    await _itemsCache.multiWrite(
      Map.fromEntries(
        items.map<MapEntry<String, T>>(
          (item) => MapEntry(bindings.getId(item)!, item),
        ),
      ),
      ttl: details.ttl ?? ttl,
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
