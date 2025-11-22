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
class HiveSource<T> extends LocalSource<T> with ReadinessMixin<void> {
  /// {@macro HiveSource}
  factory HiveSource({
    required Bindings<T> bindings,
    required Future<void> hiveInit,
    HiveInterface? hive,
  }) {
    final hiveItemsPersistence = HiveItemsPersistence<T>(
      bindings.getListUrl().path,
      bindings.getId,
      hiveInit,
      hive: hive,
      setId: (bindings is CreationBindings<T>) ? bindings.save : null,
    );
    final hiveCachePersistence = HiveCachePersistence(
      bindings.getListUrl().path,
      hiveInit,
      hive: hive,
    );
    return HiveSource._(
        hiveItemsPersistence,
        hiveCachePersistence,
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
    this.setId,
    HiveInterface? hive,
  }) : _hive = hive ?? Hive;

  /// Unique name of this box - must not be shared with any other boxes.
  final String name;

  /// Method which can read an the unique identifier off of an instance of [T].
  IdReader<T> getId;

  /// Future which should resolve when Hive is initialized.
  final Future<void> hiveInit;

  final HiveInterface _hive;

  /// Optional function to set an Id on an item. Should come from a
  /// [CreationBindings] value.
  final T Function(T)? setId;

  @override
  Future<void> performInitialization() async {
    await hiveInit;
    _itemsBox = await _hive.openBox<T>('${name}_items');
  }

  /// Opened Hive box.
  ///
  /// This box maps Ids to actual payloads for the given records.
  Future<Box<T>> get itemsBox async {
    await ready;
    return _itemsBox;
  }

  late final Box<T> _itemsBox;

  @override
  Future<void> clear() => _itemsBox.clear();

  @override
  Future<void> deleteIds(Set<String> ids) async =>
      (await itemsBox).deleteAll(ids);

  @override
  Future<T?> getById(String id) async => (await itemsBox).get(id);

  @override
  Future<Iterable<T>> getByIds(Set<String> ids) async {
    final box = await itemsBox;
    final results = <T>[];
    for (final id in ids) {
      final item = box.get(id);
      if (item != null) results.add(item);
    }
    return results;
  }

  @override
  Future<Iterable<T>> getAll() async => (await itemsBox).values;

  @override
  Future<void> setItem(T item, {required bool shouldOverwrite}) async {
    T itemCopy = item;
    if (getId(item) == null) {
      if (setId != null) {
        itemCopy = setId!.call(itemCopy);
      } else {
        throw Exception('Checking for null Id in Hive box - unsafe!');
      }
    }
    final box = await itemsBox;
    if (shouldOverwrite || box.get(getId(itemCopy)) == null) {
      await box.put(getId(itemCopy), itemCopy);
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

  /// Opened RequestCacheBox.
  ///
  /// This box maps [RequestDetails.cacheKey] values to the sets of
  /// Ids that were returned by the server.
  Future<Box<Set<String>>> get requestCacheBox async {
    await ready;
    return _requestCacheBox;
  }

  late final Box<Set<String>> _requestCacheBox;

  /// Opened PaginationRequestCacheBox.
  ///
  /// This box maps [RequestDetails.noPaginationCacheKey] values all of the
  /// paged data returned by the server. The inner map stores
  /// [RequestDetails.cacheKey] values as keys (each of which indicates a page),
  /// and sets of Ids returned in each page as values.
  // ignore: strict_raw_type
  Future<Box<Map>> get paginationCacheBox async {
    await ready;
    return _paginationCacheBox;
  }

  // Cannot pre-type Maps with Hive
  // ignore: strict_raw_type
  late final Box<Map> _paginationCacheBox;

  @override
  Future<void> clear() async {
    await ready;
    await Future.wait<void>([
      _requestCacheBox.clear(),
      _paginationCacheBox.clear(),
    ]);
  }

  @override
  Future<void> clearCacheKey(CacheKey key) async =>
      (await requestCacheBox).delete(key);

  @override
  Future<void> clearPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
  }) async => (await paginationCacheBox).delete(noPaginationCacheKey);

  @override
  Future<Set<String>?> getCacheKey(CacheKey key) async {
    final result = (await requestCacheBox).get(key);
    _log.finest('Loading $key - found $result');
    return result;
  }

  @override
  Future<Set<String>?> getPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
    required CacheKey cacheKey,
  }) async {
    final pagesMetadata = (await paginationCacheBox)
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
    await (await requestCacheBox).put(key, ids);
  }

  @override
  Future<void> setPaginatedCacheKey({
    required CacheKey noPaginationCacheKey,
    required CacheKey cacheKey,
    required Set<String> ids,
  }) async {
    _log.finest('Writing $ids to $noPaginationCacheKey::$cacheKey');
    final pagesMetadata =
        (await paginationCacheBox).get(noPaginationCacheKey) ??
        <CacheKey, Set<String>>{};

    pagesMetadata[cacheKey] = ids;
    await (await paginationCacheBox).put(noPaginationCacheKey, pagesMetadata);
  }

  @override
  Future<Iterable<CacheKey>> getRequestCacheKeys() async =>
      (await requestCacheBox).keys.cast<CacheKey>();

  @override
  Future<Iterable<CacheKey>> noPaginationCacheKeys() async =>
      (await paginationCacheBox).keys.cast<CacheKey>();

  @override
  Future<Iterable<CacheKey>> noPaginationInnerKeys(
    CacheKey noPaginationCacheKey,
  ) async {
    final innerMap =
        (await paginationCacheBox).get(noPaginationCacheKey) ??
        <CacheKey, Set<String>>{};
    return innerMap.keys.cast<CacheKey>();
  }
}
