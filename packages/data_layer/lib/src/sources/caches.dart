import 'package:data_layer/data_layer.dart';

/// {@template SourceCache}
/// {@endtemplate}
abstract class SourceCache<T> {
  /// {@macro SourceCache}
  SourceCache();

  /// Reads a value from the cache. Returns null if no valid data is available.
  Future<T?> read(String key);

  /// Reads all values from the cache. Returns an empty list if no valid data is
  /// available.
  Future<Map<String, T>> readAll();

  /// Reads a set of values from the cache. Returns an empty set if no valid
  /// data is available.
  Future<Map<String, T>> multiRead(Set<String> keys);

  /// Removes the value from the cache.
  Future<void> delete(String key);

  /// Removes [keys] from the cache.
  Future<void> multiDelete(Set<String> keys);

  /// Empties the cache.
  Future<void> clear();

  /// Writes a value to the cache.
  Future<void> write(String key, T value);

  /// Writes a set of values to the cache.
  Future<void> multiWrite(Map<String, T> data);
}

/// {@template ExpiringCache}
/// {@endtemplate}
class ExpiringCache<T> extends SourceCache<T> {
  /// {@macro ExpiringCache}
  ExpiringCache({
    required SourceCache<T> cache,
    required SourceCache<DateTime> cacheExpiryTimes,
    DateTime Function()? now,
  }) : _cache = cache,
       _cacheExpiryTimes = cacheExpiryTimes,
       _now = now ?? utc;

  /// Raw data cache unaware of any expiry info.
  final SourceCache<T> _cache;

  /// Stores expiry times for items in [_cache]. Missing values are considered
  /// to never expire.
  final SourceCache<DateTime> _cacheExpiryTimes;

  /// Testing-friendly hook to control the current time.
  final DateTime Function() _now;

  bool _expiryIsFresh(DateTime? expiresAt) =>
      expiresAt == null || !expiresAt.difference(_now()).isNegative;

  @override
  Future<T?> read(String key) async {
    final expiresAt = await _cacheExpiryTimes.read(key);
    if (_expiryIsFresh(expiresAt)) {
      return _cache.read(key);
    }
    return Future.value();
  }

  @override
  Future<Map<String, T>> readAll() async {
    final expirationDates = await _cacheExpiryTimes.readAll();
    final allItems = await _cache.readAll();
    final stillValidItems = <String, T>{};
    for (final item in allItems.entries) {
      if (_expiryIsFresh(expirationDates[item.key])) {
        stillValidItems[item.key] = item.value;
      }
    }
    return stillValidItems;
  }

  @override
  Future<Map<String, T>> multiRead(Set<String> keys) async {
    final expirationDates = await _cacheExpiryTimes.multiRead(keys);

    final stillValidKeys = <String>{};
    for (final key in keys) {
      if (_expiryIsFresh(expirationDates[key])) {
        stillValidKeys.add(key);
      }
    }
    if (stillValidKeys.isNotEmpty) {
      return _cache.multiRead(stillValidKeys);
    }
    return <String, T>{};
  }

  @override
  Future<void> write(String key, T value, {Duration? ttl}) async {
    await _cache.write(key, value);
    if (ttl != null) {
      await _cacheExpiryTimes.write(key, _now().add(ttl));
    }
  }

  @override
  Future<void> delete(String key) async => Future.wait([
    _cache.delete(key),
    _cacheExpiryTimes.delete(key),
  ]);

  @override
  Future<void> clear() => Future.wait([
    _cache.clear(),
    _cacheExpiryTimes.clear(),
  ]);

  @override
  Future<void> multiDelete(Set<String> keys) => Future.wait([
    _cache.multiDelete(keys),
    _cacheExpiryTimes.multiDelete(keys),
  ]);

  @override
  Future<void> multiWrite(Map<String, T> data, {Duration? ttl}) {
    final expiresAt = ttl != null ? _now().add(ttl) : null;
    return Future.wait([
      _cache.multiWrite(data),
      if (ttl != null)
        _cacheExpiryTimes.multiWrite(
          data.map((key, value) => MapEntry(key, expiresAt!)),
        ),
    ]);
  }
}
