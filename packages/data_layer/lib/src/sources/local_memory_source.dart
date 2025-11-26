import 'package:data_layer/data_layer.dart';
import 'package:logging/logging.dart';

/// {@template LocalMemorySource}
/// On-device, in-memory store which caches previously loaded data for
/// instantaneous retrieval. Does not persist any data across sessions.
/// {@endtemplate}
class LocalMemorySource<T> extends LocalSource<T> {
  /// {@macro LocalMemorySource}
  LocalMemorySource({
    required super.bindings,
    DateTime Function()? now,
    super.ttl,
  }) : super(
         itemsCache: ExpiringCache<T>(
           cache: InMemoryPersistence<T>(),
           cacheExpiryTimes: InMemoryPersistence<DateTime>(),
           now: now,
         ),
         requestCache: ExpiringCache<Set<String>>(
           cache: InMemoryPersistence<Set<String>>(),
           cacheExpiryTimes: InMemoryPersistence<DateTime>(),
           now: now,
         ),
         paginatedRequestCache: ExpiringCache<Set<String>>(
           cache: InMemoryPersistence<Set<String>>(),
           cacheExpiryTimes: InMemoryPersistence<DateTime>(),
           now: now,
         ),
       );
}

/// {@template InMemoryPersistence}
/// In-memory storage for a [LocalSource]. This is a glorified [Map].
/// {@endtemplate}
class InMemoryPersistence<T> extends SourceCache<T> {
  final _items = <String, T>{};

  final _log = Logger('$InMemoryPersistence<$T>');

  @override
  Future<void> clear() async => _items.clear();

  @override
  Future<T?> read(String id) async => _items[id];

  @override
  Future<Map<String, T>> multiRead(Set<String> ids) async {
    _log.finest('Getting $ids');
    return Map.fromEntries(
      _items.keys
          .where((String key) => ids.contains(key))
          .map((key) => MapEntry(key, _items[key] as T)),
    );
  }

  @override
  Future<Map<String, T>> readAll() => Future.value(_items);

  @override
  Future<void> write(String key, T item) async {
    _log.finest('Setting $item');
    _items[key] = item;
  }

  @override
  Future<void> multiWrite(Map<String, T> items) async {
    _log.finest('Setting $items');
    _items.addAll(items);
  }

  @override
  Future<void> multiDelete(Set<String> ids) async {
    _log.finest('Deleting $ids');
    ids.forEach(_items.remove);
  }

  @override
  Future<void> delete(String key) async {
    _log.finest('Deleting $key');
    _items.remove(key);
  }
}
