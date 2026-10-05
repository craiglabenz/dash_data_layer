import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

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

  /// Convenience constructor which assembles the inner caches for you.
  static LocalSource<T> builders<T>({
    required SourceCache<T> Function(String name) itemCache,
    required SourceCache<Set<String>> Function(String name) stringSetCache,
    required SourceCache<DateTime> Function(String name) dateTimeCache,
    Bindings<T>? bindings,
    Duration? ttl,
  }) => LocalSource(
    itemsCache: ExpiringCache<T>(
      cache: itemCache('items'),
      cacheExpiryTimes: dateTimeCache('items_expiry'),
    ),
    requestCache: ExpiringCache<Set<String>>(
      cache: stringSetCache('requests'),
      cacheExpiryTimes: dateTimeCache('requests_expiry'),
    ),
    paginatedRequestCache: stringSetCache('paginated_requests'),
    bindings: bindings,
    ttl: ttl,
  );

  final _log = Logger('$LocalSource<$T>');

  /// Warehouse for all known instances of [T].
  final ExpiringCache<T> _itemsCache;

  /// Warehouse for caching request metadata, both paginated and unpaginated.
  final ExpiringCache<Set<String>> _requestCache;

  /// Warehouse for caching request metadata, both paginated and unpaginated.
  /// Not an [ExpiringCache] because pages expire individually, which is all
  /// stored in the `requestCache`.
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

  /// Returns the subset of [keys] that are not referenced by any requests in
  /// the cache. This is used to detect whether keys orphaned by a specific
  /// write are in fact globally orphaned and should be deleted, or should
  /// merely be deleted from that specific request.
  @visibleForTesting
  Future<Set<String>> notReferencedByAnyRequests(Set<String> keys) async {
    final allCachedRequests = await _requestCache.readAll();
    final referencedKeys = <String>{};
    allCachedRequests.values.forEach(referencedKeys.addAll);
    return keys.difference(referencedKeys);
  }

  /// Removes these Ids from storage anywhere they may exist, which is why no
  /// [RequestDetails] are needed.
  Future<void> deleteIds(Set<String> ids) async {
    _log.finest('Deleting $ids');
    await _itemsCache.multiDelete(ids);

    final allCachedRequests = await _requestCache.readAll();
    final deletedRequests = <CacheKey>{};
    for (final requestCacheKey in allCachedRequests.keys) {
      final requestCacheIds = allCachedRequests[requestCacheKey];
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
  Future<ReadResult<T>> getById(ReadOperation<T> operation) async {
    operation.details.assertEmpty('LocalSource<$T>.getById');
    return ReadSuccess<T>(
      await _itemsCache.read(operation.itemId),
      details: operation.details,
    );
  }

  @override
  Future<ReadListResult<T>> getByIds(ReadByIdsOperation<T> operation) async {
    operation.details.assertEmpty('LocalSource<$T>.getByIds');
    final items = await _itemsCache.multiRead(operation.itemIds);
    final foundItemIds = items.keys.toSet();
    final missingItemIds = operation.itemIds.difference(foundItemIds);
    return ReadListResult<T>.fromMap(
      items,
      operation.details,
      missingItemIds,
    );
  }

  @override
  Future<ReadListResult<T>> getItems(ReadListOperation<T> operation) async {
    Set<String>? ids;
    if (operation.details.requestType == .allLocal) {
      final allItems = await _itemsCache.readAll();
      return ReadListResult.fromMap(
        allItems,
        operation.details,
        <String>{},
      );
    }

    ids = await _requestCache.read(operation.details.cacheKey);
    _log.finest(
      'Getting items for ${operation.details.cacheKey}. Found Ids $ids',
    );

    assert(
      ids == null || ids.isNotEmpty,
      'Unexpectedly found empty set of Ids $ids from cache for '
      '${operation.details.cacheKey}. \n'
      'Empty sets should never be cached.',
    );

    final items = ids != null
        ? await _itemsCache.multiRead(ids)
        : <String, T>{};

    return ReadListResult.fromMap(items, operation.details, <String>{});
  }

  T _generateItemId(T item) => (bindings as CreationBindings<T>).save(item);

  @override
  Future<WriteResult<T>> setItem(WriteOperation<T> operation) async {
    T itemCopy = operation.item;
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
        itemCopy = _generateItemId(itemCopy);
      }
    }

    await _itemsCache.write(
      bindings.getId(itemCopy)!,
      itemCopy,
      ttl: operation.details.ttl ?? ttl,
    );
    return WriteSuccess<T>(itemCopy, details: operation.details);
  }

  @override
  Future<WriteListResult<T>> setItems(WriteListOperation<T> operation) async {
    if (operation.items.isEmpty) {
      await clearForRequest(operation.details);
      return WriteListSuccess<T>(operation.items, details: operation.details);
    }

    final previousIds = await _requestCache.read(operation.details.cacheKey);

    final itemIds = operation.items
        .map<String>((item) => bindings.getId(item)!)
        .toSet();
    _log.finest('Caching $itemIds to ${operation.details.cacheKey}');
    await _requestCache.write(
      operation.details.cacheKey,
      itemIds,
      ttl: operation.details.ttl ?? ttl,
    );

    if (operation.details.pagination != null) {
      final pageClusterCacheKeys =
          await _paginatedRequestCache.read(
            operation.details.noPaginationCacheKey,
          ) ??
          <CacheKey>{};

      if (!pageClusterCacheKeys.contains(operation.details.cacheKey)) {
        pageClusterCacheKeys.add(operation.details.cacheKey);
        await _paginatedRequestCache.write(
          operation.details.noPaginationCacheKey,
          pageClusterCacheKeys,
          // Do not pass ttl here -- that is handled by [_requestCache]
          // because paginated requests timeout individually, not as a cluster
        );
      }
    }

    // Now save the actual item payloads
    await _itemsCache.multiWrite(
      Map.fromEntries(
        operation.items.map<MapEntry<String, T>>(
          (item) => MapEntry(bindings.getId(item)!, item),
        ),
      ),
      ttl: operation.details.ttl ?? ttl,
    );

    if (previousIds != null) {
      final orphanedIds = previousIds.difference(itemIds);
      if (orphanedIds.isNotEmpty) {
        final globallyOrphanedIds = await notReferencedByAnyRequests(
          orphanedIds,
        );
        if (globallyOrphanedIds.isNotEmpty) {
          await _itemsCache.multiDelete(globallyOrphanedIds);
        }
      }
    }

    return WriteListSuccess<T>(operation.items, details: operation.details);
  }

  @override
  Future<DeleteResult<T>> deleteItem(DeleteOperation<T> operation) async {
    assert(
      operation.details.requestType.includes(sourceType),
      'Should not route ${operation.details.requestType} request to $this',
    );
    await deleteIds({operation.itemId});
    return DeleteSuccess<T>(operation.details);
  }

  @override
  Future<DeleteResult<T>> deleteItems(DeleteListOperation<T> operation) async {
    assert(
      operation.details.requestType.includes(sourceType),
      'Should not route ${operation.details.requestType} request to $this',
    );
    final cachedIds = await _requestCache.read(operation.details.cacheKey);
    if (cachedIds != null && cachedIds.isNotEmpty) {
      await deleteIds(cachedIds);
    }
    await clearForRequest(operation.details);
    return DeleteSuccess<T>(operation.details);
  }
}
