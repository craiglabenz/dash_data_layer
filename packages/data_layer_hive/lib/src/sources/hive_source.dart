import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:hive_ce/hive.dart';
import 'package:logging/logging.dart';

/// {@template HiveInitializer}
/// Helper to initialize Hive bindings.
/// {@endtemplate}
abstract class HiveInitializer with ReadinessMixin<void> {
  /// {@macro HiveInitializer}
  HiveInitializer();
}

/// {@template HiveSource}
/// Implements [LocalSource] using Hive.
/// {@endtemplate}
class HiveSource<T> extends LocalSource<T> {
  /// {@macro HiveSource}
  factory HiveSource({
    required Bindings<T> bindings,
    required String boxName,
    required Future<void> hiveInit,
    HiveInterface? hive,
  }) {
    return HiveSource._(
      itemsCache: ExpiringCache<T>(
        cache: HiveCache<T>(
          boxName,
          hiveInit,
          hive: hive,
        ),
        cacheExpiryTimes: HiveCache<DateTime>(
          '${boxName}_items_expiry',
          hiveInit,
          hive: hive,
        ),
      ),
      requestCache: ExpiringCache<Set<String>>(
        cache: HiveCache<Set<String>>(
          '${boxName}_requests',
          hiveInit,
          hive: hive,
        ),
        cacheExpiryTimes: HiveCache<DateTime>(
          '${boxName}_requests_expiry',
          hiveInit,
          hive: hive,
        ),
      ),
      paginatedRequestCache: HiveCache<Set<String>>(
        '${boxName}_paginated_requests',
        hiveInit,
        hive: hive,
      ),
      bindings: bindings,
    );
  }

  HiveSource._({
    required super.itemsCache,
    required super.requestCache,
    required super.paginatedRequestCache,
    required super.bindings,
  });
}

/// {@template HiveCache}
/// Persists various records to Hive boxes.
/// {@endtemplate}
class HiveCache<T> extends SourceCache<T> with ReadinessMixin<void> {
  /// {@macro HiveCache}
  HiveCache(
    this.name,
    this.hiveInit, {
    HiveInterface? hive,
  }) : _hive = hive ?? Hive,
       _log = Logger('$HiveCache<$T>($name)');

  /// Unique name of this box - must not be shared with any other boxes.
  final String name;

  /// Future which should resolve when Hive is initialized.
  final Future<void> hiveInit;

  final HiveInterface _hive;

  late final Logger _log;

  @override
  Future<void> performInitialization() async {
    await hiveInit;
    _box = await _hive.openBox<T>(name);
    markReady(null);
  }

  /// Opened Hive box.
  ///
  /// This box maps Ids to actual payloads for the given records.
  Future<Box<T>> get box async {
    await ready;
    return _box;
  }

  late final Box<T> _box;

  @override
  Future<void> clear() async {
    _log.finest('Clearing box $name');
    await (await box).clear();
  }

  @override
  Future<void> delete(String key) async {
    _log.finest('Deleting $key');
    return (await box).delete(key);
  }

  @override
  Future<void> multiDelete(Set<String> ids) async {
    _log.finest('Deleting ids $ids');
    return (await box).deleteAll(ids);
  }

  @override
  Future<Map<String, T>> multiRead(Set<String> keys) async {
    _log.finest('Reading $keys');
    final box = await this.box;
    final results = <String, T>{};
    for (final key in keys) {
      try {
        final item = box.get(key);
        if (item != null) {
          results[key] = item;
        }
      } on Object catch (e, stackTrace) {
        _log.warning(
          'Failed to read key "$key" from box "$name", deleting key',
          e,
          stackTrace,
        );
        await delete(key);
      }
    }
    return results;
  }

  @override
  Future<void> multiWrite(Map<String, T> data) async {
    _log.finest('Writing $data');
    return (await box).putAll(data);
  }

  @override
  Future<T?> read(String key) async {
    _log.finest('Reading $key');
    final box = await this.box;
    try {
      return box.get(key);
    } on Object catch (e, stackTrace) {
      _log.warning(
        'Failed to read key "$key" from box "$name", deleting key',
        e,
        stackTrace,
      );
      await delete(key);
      return null;
    }
  }

  @override
  Future<Map<String, T>> readAll() async {
    _log.finest('Reading all');
    final box = await this.box;
    try {
      return box.toMap().cast<String, T>();
    } on Object catch (e, stackTrace) {
      _log.warning(
        'Failed to read all from box "$name" via toMap(), '
        'falling back to key-by-key read',
        e,
        stackTrace,
      );
      final results = <String, T>{};
      for (final key in box.keys.cast<String>()) {
        try {
          final item = box.get(key);
          if (item != null) {
            results[key] = item;
          }
        } on Object catch (e, stackTrace) {
          _log.warning(
            'Failed to read key "$key" from box "$name", deleting key',
            e,
            stackTrace,
          );
          await delete(key);
        }
      }
      return results;
    }
  }

  @override
  Future<void> write(String key, T value) {
    _log.finest('Writing $key: $value');
    return box.then((b) => b.put(key, value));
  }
}
