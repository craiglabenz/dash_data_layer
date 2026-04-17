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

/// A [LocalMemorySource] which masquerades as a [SourceType.remote] source.
///
/// This source type is not suitable for anything other than tests or API stubs.
/// To use this, insert it at the back of a [SourceList]'s list of sources and
/// script the API behavior you want by first writing data. The [SourceList]
/// will then be none the wiser when it asks this class for data and returns
/// what you just wrote.
class RemoteMemorySource<T> extends LocalMemorySource<T> {
  /// Instantiates a [RemoteMemorySource].
  RemoteMemorySource({
    required super.bindings,
    super.now,
    super.ttl,
  });

  /// This lie is the whole point of this class.
  @override
  SourceType get sourceType => .remote;
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
          .where((key) => ids.contains(key))
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
