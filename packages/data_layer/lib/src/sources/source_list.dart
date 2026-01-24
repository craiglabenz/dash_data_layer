import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:logging/logging.dart';

/// {@template SourceList}
/// Data component which iteratively asks individual sources for an object.
///
/// Sources that originally fail to yield an object have it cached if a fallback
/// source is able to yield it. [SourceList] should rarely be subclassed, as all
/// of its operations are intended to be completely uniform across data types.
/// If you are tempted to subclass [SourceList], consider putting that special
/// logic in the data type or feature's [Repository] instead.
///
/// The [RequestType] parameter on [RequestDetails] can be used to
/// control which sources are asked, which is helpful when you want to force a
/// cache read or cache miss.
///
/// To retry failed operations, supply a [RetryPolicy], or use the default value
/// which aims to provide reasonable defaults.
///
/// See also:
///   * [RetryPolicy] which controls how failed operations are retried.
/// {@endtemplate}
class SourceList<T> extends DataContract<T> with ReadinessMixin<void> {
  /// {@macro SourceList}
  SourceList({
    required this.sources,
    required this.bindings,
    this.connectivityService,
    this.retryPolicy,
    DateTime Function()? getTime,
  }) : _getTime = getTime {
    for (final source in sources) {
      if (!source.hasBindings) {
        source.bindings = bindings;
      }
    }
    if (retryPolicy != null) {
      _retrySub = retryPolicy!.onRetryOperation().listen(_retryOperation);
    }
    if (connectivityService != null && retryPolicy != null) {
      _connectivitySub = connectivityService!.listen((bool status) {
        if (status) {
          unawaited(retryPolicy!.onReconnected().then(_onReconnected));
        }
      });
    }
  }

  /// Testing-friendly constructor for wiring things up that don't actually
  /// require a functioning [SourceList].
  factory SourceList.empty(Bindings<T> bindings) =>
      SourceList(sources: [], bindings: bindings);

  StreamSubscription<Operation<T>>? _retrySub;
  StreamSubscription<bool>? _connectivitySub;

  /// {@macro Bindings}
  final Bindings<T> bindings;

  /// Iterable of data [Source] objects which this [SourceList] will use to load
  /// requested data.
  final List<Source<T>> sources;

  /// Connectivity service for this [SourceList]. If this is supplied, then
  /// operations which fail due to a device being offline are immediately
  /// routed to the [RetryPolicy] class for triage.
  ///
  /// Because pkg:data_layer is a pure Dart package, capable of being used on
  /// the server for loading data from other servers, this is a concept which
  /// only truly applies to clients. As such, an implementation for
  /// [ConnectivityService], which uses pkg:connectivity_plus, is provided
  /// in pkg:data_layer_connectivity.
  final ConnectivityService? connectivityService;

  /// Retry policy for this [SourceList]. If this is supplied, then operations
  /// which fail due to connectivity or server issues can be retried.
  final RetryPolicy<T>? retryPolicy;

  final Logger _log = Logger('SourceList<$T>');

  DateTime Function()? _getTime;

  /// {@macro Repository.getTime}
  DateTime Function() get getTime {
    if (_getTime == null) {
      throw StateError(
        'getTime not initialized in $this. Repositories set this on their '
        'SourceList directly, but if you are creating this SourceList on your '
        'own then you must pass or set the variable yourself.',
      );
    }
    return _getTime!;
  }

  set getTime(DateTime Function() value) => _getTime = value;

  /// Returns all sources that match a given [RequestType]. Unmatches sources
  /// are also returned with that indicator, so they can still be stored in a
  /// list of empty sources for the purposes of caching.
  Iterable<MatchedSource<T>> getSources({
    RequestType requestType = RequestType.global,
    bool reversed = false,
  }) sync* {
    final orderedSources = reversed ? sources.reversed : sources;
    for (final source in orderedSources) {
      if (requestType.includes(source.sourceType)) {
        yield MatchedSource.matched(source);
      }
      yield MatchedSource.unmatched(source);
    }
  }

  Future<void> _cacheItem(
    List<Source<T>> emptySources,
    WriteOperation<T> operation,
  ) async {
    for (final source in emptySources) {
      await source.setItem(operation);
    }
  }

  Future<void> _cacheItems(
    List<Source<T>> emptySources,
    WriteListOperation<T> operation,
  ) async {
    for (final source in emptySources) {
      await source.setItems(operation);
    }
  }

  /// Checks connectivity if a [ConnectivityService] is provided. If the device
  /// is offline...
  ///
  /// A no-op if no [ConnectivityService] is provided.
  Future<void> checkConnectivity(RequestDetails details) async {
    if (details.isLocal) {
      // Local requests don't need connectivity.
      return;
    }
    if (connectivityService != null) {
      if (!await connectivityService!.isConnected) {
        throw NoConnectivityException();
      }
    }
  }

  /// Invokes a callback function with retry logic.
  Future<R> _guarded<R>(
    Operation<T> operation,
    Future<R> Function() fn,
    R Function() connectivityFailureBuilder,
  ) async {
    if (retryPolicy == null) {
      return fn();
    }
    try {
      await checkConnectivity(operation.details);
    } on NoConnectivityException {
      _log.fine('Device is offline, storing $operation for retry');
      await retryPolicy!.storeOperationForRetry(operation, .connectivity);
      return connectivityFailureBuilder();
    }
    final result = await fn();
    bool shouldRetry = false;
    FailureReason? failureReason;

    switch (result) {
      case ReadFailure<T>(:final reason) ||
          ReadListFailure<T>(:final reason) ||
          WriteFailure<T>(:final reason) ||
          WriteListFailure<T>(:final reason) ||
          DeleteFailure<T>(:final reason):
        shouldRetry = retryPolicy!.shouldRetry(operation, reason);
        failureReason = reason;
      //
      case ReadSuccess<T>() ||
          ReadListSuccess<T>() ||
          WriteSuccess<T>() ||
          WriteListSuccess<T>() ||
          DeleteSuccess<T>():
      // Capture these just to route unhandled results to the catch-all.

      case _:
        _log.warning('Unhandled result: $result');
    }

    if (shouldRetry) {
      _log.fine(
        'Operation error: $failureReason, storing $operation for retry',
      );
      await retryPolicy!.storeOperationForRetry(operation, failureReason!);
    }
    return result;
  }

  @override
  Future<ReadResult<T>> getById(ReadOperation<T> operation) async {
    return _guarded<ReadResult<T>>(
      operation,
      () => _getById(operation),
      () => ReadFailure<T>(.connectivity, 'The device is offline.'),
    );
  }

  Future<ReadResult<T>> _getById(ReadOperation<T> operation) async {
    operation.details.assertEmpty('SourceList<$T>.getById');

    final emptySources = <Source<T>>[];
    final sourcesIter = getSources(
      requestType: operation.details.requestType,
    );
    for (final ms in sourcesIter) {
      if (ms.unmatched) {
        emptySources.add(ms.source);
        continue;
      }
      final source = ms.source;
      final sourceResult = await source.getById(operation);

      switch (sourceResult) {
        case ReadSuccess(:final item):
          if (item != null) {
            await _cacheItem(
              emptySources,
              WriteOperation<T>(
                operationId: operation.operationId,
                details: operation.details,
                item: item,
                createdAt: operation.createdAt,
                attemptNumber: operation.attemptNumber,
              ),
            );
            return sourceResult;
          }
          emptySources.add(source);
        case ReadFailure<T>():
          return sourceResult;
      }
    }
    return ReadSuccess<T>(null, details: operation.details);
  }

  @override
  Future<ReadListResult<T>> getByIds(ReadByIdsOperation<T> operation) async {
    return _guarded<ReadListResult<T>>(
      operation,
      () => _getByIds(operation),
      () => ReadListFailure<T>(.connectivity, 'The device is offline.'),
    );
  }

  Future<ReadListResult<T>> _getByIds(ReadByIdsOperation<T> operation) async {
    operation.details.assertEmpty('SourceList<$T>.getByIds');

    try {
      await checkConnectivity(operation.details);
    } on NoConnectivityException {
      return ReadListFailure<T>(.connectivity, 'The device is offline.');
    }

    final items = <String, T>{};
    final pastSources = <Source<T>>[];
    final backfillMap = <Source<T>, Set<T>>{};

    // Copy the list of ids.
    // Called `missingIds` not because we've deemed these are all missing, but
    // because we're going to iteratively remove items that are locally known -
    // meaning at the end of the loop, remaining ids will be confirmed missing.
    var missingIds = Set<String>.from(operation.itemIds);

    for (final ms in getSources(requestType: operation.details.requestType)) {
      if (missingIds.isEmpty) {
        break;
      }

      if (ms.unmatched) {
        pastSources.add(ms.source);
        continue;
      }
      final sourceResult = await ms.source.getByIds(
        operation.copyWith(itemIds: missingIds),
      );

      switch (sourceResult) {
        case ReadListFailure<T>():
          return sourceResult;
        case ReadListSuccess<T>():
          items.addAll(sourceResult.itemsMap);
          // Mark which sources needs which items
          for (final pastSource in pastSources) {
            backfillMap.putIfAbsent(pastSource, () => <T>{});
            backfillMap[pastSource]!.addAll(sourceResult.items);
          }

          // Remove any now-known Ids from `missingIds`
          missingIds = missingIds.where((id) => !items.containsKey(id)).toSet();

          // Note that we've already processed this Source, so if future
          // Sources produce any new items, we can backfill them to here.
          pastSources.add(ms.source);
      }
    }

    // Persist any items we found to local stores
    for (final pastSource in backfillMap.keys) {
      if (pastSource is! LocalSource<T>) continue;

      if (backfillMap[pastSource]!.isNotEmpty) {
        for (final item in backfillMap[pastSource]!) {
          // await pastSource.setItem(item, details);
          await pastSource.setItem(
            WriteOperation<T>(
              operationId: operation.operationId,
              item: item,
              details: operation.details,
              createdAt: getTime(),
            ),
          );
        }
      }

      if (!operation.details.isLocal && missingIds.isNotEmpty) {
        // Missing Ids at this point would mean that we tried to load data from
        // the server and still failed to pull in certain Ids. That means they
        // don't exist anymore, and thus we can delete them from any local
        // caches.
        await pastSource.deleteIds(missingIds);
      }
    }

    return ReadListResult<T>.fromMap(items, operation.details, missingIds);
  }

  @override
  Future<ReadListResult<T>> getItems(ReadListOperation<T> operation) async {
    return _guarded<ReadListResult<T>>(
      operation,
      () => _getItems(operation),
      () => ReadListFailure<T>(.connectivity, 'The device is offline.'),
    );
  }

  Future<ReadListResult<T>> _getItems(ReadListOperation<T> operation) async {
    final emptySources = <Source<T>>[];
    for (final ms in getSources(requestType: operation.details.requestType)) {
      if (ms.unmatched) {
        emptySources.add(ms.source);
        continue;
      }

      final sourceResult = await ms.source.getItems(operation);

      switch (sourceResult) {
        case ReadListSuccess<T>():
          final items = sourceResult.items;
          if (items.isNotEmpty) {
            await _cacheItems(
              emptySources,
              WriteListOperation<T>(
                operationId: operation.operationId,
                items: items,
                details: operation.details,
                createdAt: getTime(),
              ),
            );
            return ReadListResult<T>.fromList(
              items,
              operation.details,
              {},
              bindings.getId,
            );
          } else {
            emptySources.add(ms.source);
          }
        case ReadListFailure<T>():
          return sourceResult;
      }
    }

    // Lastly, help any local sources track their known empty sets.
    if (operation.details.requestType == RequestType.global ||
        operation.details.requestType == RequestType.refresh) {
      for (final source in emptySources) {
        if (source is LocalSource<T>) {
          await source.setItems(
            WriteListOperation<T>(
              operationId: operation.operationId,
              items: <T>[],
              details: operation.details,
              createdAt: getTime(),
            ),
          );
        }
      }
    }
    return ReadListResult<T>.fromList(
      [],
      operation.details,
      {},
      bindings.getId,
    );
  }

  @override
  Future<WriteResult<T>> setItem(WriteOperation<T> operation) async {
    return _guarded<WriteResult<T>>(
      operation,
      () => _setItem(operation),
      () => WriteFailure<T>(.connectivity, 'The device is offline.'),
    );
  }

  Future<WriteResult<T>> _setItem(WriteOperation<T> operation) async {
    try {
      await checkConnectivity(operation.details);
    } on NoConnectivityException {
      return WriteFailure<T>(.connectivity, 'The device is offline.');
    }

    T itemCopy = operation.item;
    for (final ms in getSources(
      requestType: operation.details.requestType,
      // Hit API first if item is new, so as to get an Id
      reversed: bindings.getId(operation.item) == null,
    )) {
      if (ms.unmatched) continue;

      final result = await ms.source.setItem(
        operation.copyWith(item: itemCopy),
      );

      switch (result) {
        case WriteSuccess<T>():
          if (bindings.getId(operation.item) == null) {
            if (bindings.getId(result.item) == null) {
              return WriteFailure<T>(
                FailureReason.serverError,
                'Failed to generate Id for new $T',
              );
            }
            itemCopy = result.item;
          }
        case WriteFailure<T>():
          return result;
      }
    }
    return WriteSuccess<T>(itemCopy, details: operation.details);
  }

  @override
  Future<WriteListResult<T>> setItems(WriteListOperation<T> operation) async {
    return _guarded<WriteListResult<T>>(
      operation,
      () => _setItems(operation),
      () => WriteListFailure<T>(.connectivity, 'The device is offline.'),
    );
  }

  Future<WriteListResult<T>> _setItems(WriteListOperation<T> operation) async {
    try {
      await checkConnectivity(operation.details);
    } on NoConnectivityException {
      return WriteListFailure<T>(.connectivity, 'The device is offline.');
    }
    for (final ms in getSources(requestType: operation.details.requestType)) {
      if (ms.unmatched) continue;
      final result = await ms.source.setItems(operation);
      if (result is WriteListFailure) {
        return result;
      }
    }
    return WriteListSuccess<T>(operation.items, details: operation.details);
  }

  @override
  Future<DeleteResult<T>> delete(DeleteOperation<T> operation) async {
    return _guarded<DeleteResult<T>>(
      operation,
      () => _delete(operation),
      () => DeleteFailure<T>(.connectivity, 'The device is offline.'),
    );
  }

  Future<DeleteResult<T>> _delete(DeleteOperation<T> operation) async {
    try {
      await checkConnectivity(operation.details);
    } on NoConnectivityException {
      return DeleteFailure<T>(.connectivity, 'The device is offline.');
    }
    for (final ms in getSources(requestType: operation.details.requestType)) {
      if (ms.unmatched) continue;
      final result = await ms.source.delete(operation);
      if (result is DeleteFailure<T>) {
        return result;
      }
    }
    return DeleteSuccess<T>(operation.details);
  }

  @override
  FutureOr<void> performInitialization() async {
    final futures = <Future<dynamic>>[];
    for (final source in sources) {
      if (source is ReadinessMixin) {
        futures.add((source as ReadinessMixin).ready);
      }
    }
    await Future.wait(futures);
    markReady(null);
  }

  /// Calls clear on all [LocalSource]s.
  Future<void> clear() async {
    for (final s in sources) {
      if (s is LocalSource) {
        await (s as LocalSource<T>).clear();
      }
    }
  }

  /// Clears all local data cached against this request.
  Future<void> clearForRequest(RequestDetails details) async {
    for (final source in sources) {
      if (source is! LocalSource) continue;
      await (source as LocalSource<T>).clearForRequest(details);
    }
  }

  Future<void> _onReconnected(List<Operation<T>> operations) async {
    _log.fine('Reconnected, retrying ${operations.length} operations');
    operations.forEach(_retryOperation);
  }

  Future<void> _retryOperation(Operation<T> operation) async {
    switch (operation) {
      case ReadOperation<T>():
        await getById(operation);
      case ReadListOperation<T>():
        await getItems(operation);
      case ReadByIdsOperation<T>():
        await getByIds(operation);
      case WriteOperation<T>():
        await setItem(operation);
      case WriteListOperation<T>():
        await setItems(operation);
      case DeleteOperation<T>():
        await delete(operation);
    }
  }

  /// Closes the [SourceList] and releases any resources it holds.
  Future<void> close() async {
    await Future.wait([
      _connectivitySub?.cancel() ?? Future<void>.value(),
      _retrySub?.cancel() ?? Future<void>.value(),
    ]);
  }

  @override
  String toString() => 'SourceList<$T>(sources: $sources)';
}

/// Indicates whether a given [Source] was queried within a request, which is
/// used when during the write-through cache phase.
class MatchedSource<T> {
  MatchedSource._({required this.source, required this.matched});

  /// Flavor of [Source] that matched the given [RequestType]. This [Source]
  /// will be asked for the desired data.
  factory MatchedSource.matched(Source<T> source) =>
      MatchedSource._(source: source, matched: true);

  /// Flavor of [Source] that did not match the given [RequestType]. This
  /// [Source] will not be asked for the desired data and will only be able to
  /// cache the results of another [Source], if appropriate.
  factory MatchedSource.unmatched(Source<T> source) =>
      MatchedSource._(source: source, matched: false);

  /// {@macro Source}
  final Source<T> source;

  /// Whether or not this [Source] matched the given [RequestType].
  final bool matched;

  /// Opposite of [matched].
  bool get unmatched => !matched;

  @override
  String toString() => 'MatchedSource(matched=$matched, source=$source)';
}
