import 'package:data_layer/data_layer.dart';
import 'package:logging/logging.dart';

/// {@template LocalMemorySource}
/// On-device, in-memory store which caches previously loaded data for
/// instantaneous retrieval. Does not persist any data across sessions.
/// {@endtemplate}
class LocalMemorySource<T> extends LocalSource<T> {
  /// {@macro LocalMemorySource}
  LocalMemorySource({super.bindings, IdReader<T>? getId})
    : assert(
        bindings != null || getId != null,
        'You must provide either a Bindings object or an IdReader to the getId '
        'parameter for this constructor.',
      ),
      super(
        InMemoryItemsPersistence(bindings?.getId ?? getId!),
        InMemoryCachePersistence(),
      );
}

/// {@template InMemoryItemsPersistence}
/// In-memory storage for a [LocalSource]. This is a glorified [Map].
/// {@endtemplate}
class InMemoryItemsPersistence<T> extends LocalSourceItemsPersistence<T> {
  /// {@macro InMemoryItemsPersistence}
  InMemoryItemsPersistence(this.getId);

  /// Extracts the primary key from this object if it has been saved to the.
  /// database. Returns null if the object is unsaved.
  final IdReader<T> getId;

  final _items = <String, T>{};

  final _log = Logger('$InMemoryItemsPersistence<$T>');

  @override
  Future<void> clear() async => _items.clear();

  @override
  Future<T?> getById(String id) async => _items[id];

  @override
  Future<Iterable<T>> getByIds(Set<String> ids) async {
    _log.finest('Getting $ids');
    return ids
        .map<T?>((id) => _items[id])
        .where((T? obj) => obj != null)
        .cast<T>();
  }

  @override
  Future<Iterable<T>> getAll() => Future.value(_items.values);

  @override
  Future<void> setItem(T item, {required bool shouldOverwrite}) async {
    if (shouldOverwrite || !_items.containsKey(getId(item))) {
      _log.finest('Setting $item');
      _items[getId(item)!] = item;
    }
  }

  @override
  Future<void> setItems(
    Iterable<T> items, {
    required bool shouldOverwrite,
  }) async {
    _log.finest('Setting $items');
    // ignore: avoid_function_literals_in_foreach_calls
    items.forEach(
      (item) => setItem(item, shouldOverwrite: shouldOverwrite),
    );
  }

  @override
  Future<void> deleteIds(Set<String> ids) async {
    _log.finest('Deleting $ids');
    ids.forEach(_items.remove);
  }
}

/// In memory storage for caching metadata of a [LocalSource] object. Naturally,
/// this caching strategy does not persist any information across unique
/// launches of the application.
class InMemoryCachePersistence extends RequestCachePersistence {
  /// Map of request hashes to the Ids they returned. This cache is only used
  /// for requests *without* any pagination.
  final Map<CacheKey, Set<String>> _requestCache = {};

  /// Map of request hashes to the Ids they returned. This cache is used for
  /// requests *with* pagination.
  ///
  /// The outermost [CacheKey] is the parent cache key - essentially the
  /// paginated request's cache key after its pagination is removed. The
  /// secondary [CacheKey] is full cache key with pagination. This allows for
  /// refreshes of data loaded with pagination to clear all pages of its data.
  final Map<CacheKey, Map<CacheKey, Set<String>>> _paginatedCache = {};

  @override
  Future<void> clear() async {
    _requestCache.clear();
    _paginatedCache.clear();
  }

  @override
  Future<void> clearCacheKey(CacheKey key) async => _requestCache.remove(key);

  @override
  Future<void> clearPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
  }) async => _paginatedCache.remove(noPaginationCacheKey);

  @override
  Future<Set<String>?> getCacheKey(CacheKey key) async => _requestCache[key];

  @override
  Future<Set<String>?> getPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
    required CacheKey cacheKey,
  }) async {
    return (_paginatedCache[noPaginationCacheKey] ??
        <CacheKey, Set<String>>{})[cacheKey];
  }

  @override
  Future<void> setCacheKey(CacheKey key, Set<String> ids) async =>
      _requestCache[key] = ids;

  @override
  Future<void> setPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
    required CacheKey cacheKey,
    required Set<String> ids,
  }) async {
    if (!_paginatedCache.containsKey(noPaginationCacheKey)) {
      _paginatedCache[noPaginationCacheKey] = <CacheKey, Set<String>>{};
    }
    _paginatedCache[noPaginationCacheKey]![cacheKey] = ids;
  }

  @override
  Future<Iterable<CacheKey>> getRequestCacheKeys() async => _requestCache.keys;

  @override
  Future<Iterable<CacheKey>> noPaginationCacheKeys() async =>
      _paginatedCache.keys;

  @override
  Future<Iterable<CacheKey>> noPaginationInnerKeys(
    CacheKey noPaginationCacheKey,
  ) async => _paginatedCache[noPaginationCacheKey]!.keys;
}
