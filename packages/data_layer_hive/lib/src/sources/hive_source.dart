import 'dart:async';

import 'package:data_layer/data_layer.dart';
// TODO: Export this from data_layer
import 'package:data_layer/src/utils/readiness.dart';
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
class HiveSource<T> extends LocalSource<T> with ReadinessMixin<void> {
  /// {@macro HiveSource}
  factory HiveSource({
    required Bindings<T> bindings,
    required Future<void> hiveInit,
    IdBuilder<T>? idBuilder,
    HiveInterface? hive,
  }) {
    final hiveItemsPersistence = HiveItemsPersistence<T>(
      bindings.getListUrl().path,
      bindings.getId,
      hiveInit,
      hive: hive,
    );
    final hiveCachePersistence = HiveCachePersistence(
      bindings.getListUrl().path,
      hiveInit,
      hive: hive,
    );
    return HiveSource._(
        hiveItemsPersistence,
        hiveCachePersistence,
        idBuilder: idBuilder,
        bindings: bindings,
      )
      .._hiveItemsPersistence = hiveItemsPersistence
      .._hiveCachePersistence = hiveCachePersistence;
  }

  // ignore: use_super_parameters
  HiveSource._(
    HiveItemsPersistence<T> itemsPersistence,
    HiveCachePersistence cachePersistence, {
    required super.bindings,
    super.idBuilder,
  }) : super(itemsPersistence, cachePersistence);

  late HiveItemsPersistence<T> _hiveItemsPersistence;
  late HiveCachePersistence _hiveCachePersistence;

  @override
  Future<void> performInitialization() async {
    await Future.wait<void>([
      _hiveItemsPersistence.ready,
      _hiveCachePersistence.ready,
    ]);
  }
}

/// {@template HiveItemsPersistence}
/// Implements [LocalSourceItemsPersistence] using Hive.
/// {@endtemplate}
class HiveItemsPersistence<T> extends LocalSourceItemsPersistence<T>
    with ReadinessMixin<void> {
  /// {@macro HiveItemsPersistence}
  ///
  /// [hiveInit] is a Future that resolves when Hive is initialized.
  HiveItemsPersistence(
    this.name,
    this.getId,
    this.hiveInit, {
    HiveInterface? hive,
  }) : _hive = hive ?? Hive;

  /// Unique name of this box - must not be shared with any other boxes.
  final String name;

  /// Method which can read an the unique identifier off of an instance of [T].
  IdReader<T> getId;

  /// Future which should resolve when Hive is initialized.
  final Future<void> hiveInit;

  final HiveInterface _hive;
  late final Box<T> _itemsBox;

  @override
  Future<void> performInitialization() async {
    await hiveInit;
    _itemsBox = await _hive.openBox<T>('${name}_items');
  }

  @override
  Future<void> clear() => _itemsBox.clear();

  @override
  Future<void> deleteIds(Set<String> ids) => _itemsBox.deleteAll(ids);

  @override
  Future<T?> getById(String id) async => _itemsBox.get(id);

  @override
  Future<Iterable<T>> getByIds(Set<String> ids) async {
    final results = <T>[];
    for (final id in ids) {
      final item = _itemsBox.get(id);
      if (item != null) results.add(item);
    }
    return results;
  }

  @override
  Future<void> setItem(T item, {required bool shouldOverwrite}) async {
    assert(
      getId(item) != null,
      'Checking for null Id in Hive box - unsafe!',
    );
    if (shouldOverwrite || _itemsBox.get(getId(item)) == null) {
      await _itemsBox.put(getId(item), item);
    }
  }

  @override
  Future<void> setItems(
    Iterable<T> items, {
    required bool shouldOverwrite,
  }) async {
    for (final item in items) {
      await setItem(item, shouldOverwrite: shouldOverwrite);
    }
  }
}

/// {@template HiveCachePersistence}
/// Implements [RequestCachePersistence] using Hive.
/// {@endtemplate}
class HiveCachePersistence extends RequestCachePersistence
    with ReadinessMixin<void> {
  /// {@macro HiveCachePersistence}
  HiveCachePersistence(this.name, this.hiveInit, {HiveInterface? hive})
    : _hive = hive ?? Hive {
    _log = Logger('HiveCachePersistence($name)');
  }

  /// Namespace for Hive box name prefixes.
  final String name;

  /// Future which should resolve when Hive is initialized.
  final Future<void> hiveInit;

  final HiveInterface _hive;
  late final Box<Set<String>> _requestCacheBox;

  // Cannot pre-type Maps with Hive
  // ignore: strict_raw_type
  late final Box<Map> _paginationCacheBox;

  late final Logger _log;

  @override
  Future<void> performInitialization() async {
    await hiveInit;
    _requestCacheBox = await _hive.openBox<Set<String>>('${name}_requestCache');
    // Cannot pre-type Maps with Hive
    // ignore: strict_raw_type
    _paginationCacheBox = await _hive.openBox<Map>(
      '${name}_paginationRequestCache',
    );
  }

  @override
  Future<void> clear() async {
    assert(
      isReady,
      'Must complete initialization before calling HiveCachePersistence.clear',
    );
    await _requestCacheBox.clear();
    await _paginationCacheBox.clear();
  }

  @override
  Future<void> clearCacheKey(CacheKey key) => _requestCacheBox.delete(key);

  @override
  Future<void> clearPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
  }) => _paginationCacheBox.delete(noPaginationCacheKey);

  @override
  Future<Set<String>?> getCacheKey(CacheKey key) async {
    final result = _requestCacheBox.get(key);
    _log.finest('Loading $key - found $result');
    return result;
  }

  @override
  Future<Set<String>?> getPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
    required CacheKey cacheKey,
  }) async {
    final pagesMetadata = _paginationCacheBox
        .get(noPaginationCacheKey)
        ?.cast<CacheKey, Set<String>>();
    _log.finest(
      'Loading $noPaginationCacheKey::$cacheKey - found $pagesMetadata',
    );
    return pagesMetadata != null ? pagesMetadata[cacheKey] : null;
  }

  @override
  Future<void> setCacheKey(CacheKey key, Set<String> ids) async {
    _log.finest('Writing $ids to $key');
    await _requestCacheBox.put(key, ids);
  }

  @override
  Future<void> setPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
    required CacheKey cacheKey,
    required Set<String> ids,
  }) async {
    _log.finest('Writing $ids to $noPaginationCacheKey::$cacheKey');
    final pagesMetadata =
        _paginationCacheBox.get(noPaginationCacheKey) ??
        <CacheKey, Set<String>>{};

    pagesMetadata[cacheKey] = ids;
    await _paginationCacheBox.put(noPaginationCacheKey, pagesMetadata);
  }

  @override
  Future<Iterable<CacheKey>> getRequestCacheKeys() async =>
      _requestCacheBox.keys.cast<CacheKey>();

  @override
  Future<Iterable<CacheKey>> noPaginationCacheKeys() async =>
      _paginationCacheBox.keys.cast<CacheKey>();

  @override
  Future<Iterable<CacheKey>> noPaginationInnerKeys(
    CacheKey noPaginationCacheKey,
  ) async {
    final innerMap =
        _paginationCacheBox.get(noPaginationCacheKey) ??
        <CacheKey, Set<String>>{};
    return innerMap.keys.cast<CacheKey>();
  }
}
