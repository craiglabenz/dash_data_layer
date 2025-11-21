import 'package:data_layer/data_layer.dart';

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
/// {@endtemplate}
class SourceList<T> extends DataContract<T> {
  /// {@macro SourceList}
  SourceList({required this.sources, required this.bindings}) {
    for (final source in sources) {
      if (!source.hasBindings) {
        source.bindings = bindings;
      }
    }
  }

  /// Testing-friendly constructor for wiring things up that don't actually
  /// require a functioning [SourceList].
  factory SourceList.empty(Bindings<T> bindings) =>
      SourceList(sources: [], bindings: bindings);

  /// {@macro Bindings}
  final Bindings<T> bindings;

  /// Iterable of data [Source] objects which this [SourceList] will use to load
  /// requested data.
  final List<Source<T>> sources;

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
    T item,
    List<Source<T>> emptySources,
    RequestDetails details,
  ) async {
    for (final source in emptySources) {
      await source.setItem(item, details);
    }
  }

  Future<void> _cacheItems(
    Iterable<T> items,
    List<Source<T>> emptySources,
    RequestDetails details,
  ) async {
    for (final source in emptySources) {
      await source.setItems(items, details);
    }
  }

  @override
  Future<ReadResult<T>> getById(String id, RequestDetails details) async {
    details.assertEmpty('SourceList<$T>.getById');
    final emptySources = <Source<T>>[];
    for (final matchedSource in getSources(requestType: details.requestType)) {
      if (matchedSource.unmatched) {
        emptySources.add(matchedSource.source);
        continue;
      }
      final source = matchedSource.source;
      final sourceResult = await source.getById(id, details);

      switch (sourceResult) {
        case ReadSuccess(:final item):
          if (item != null) {
            await _cacheItem(item, emptySources, details);
            return sourceResult;
          }
          emptySources.add(source);
        case ReadFailure<T>():
          return sourceResult;
      }
    }
    return ReadSuccess<T>(null, details: details);
  }

  @override
  Future<ReadListResult<T>> getByIds(
    Set<String> ids,
    RequestDetails details,
  ) async {
    details.assertEmpty('SourceList<$T>.getByIds');
    final items = <String, T>{};
    final pastSources = <Source<T>>[];
    final backfillMap = <Source<T>, Set<T>>{};

    // Copy the list of ids.
    // Called `missingIds` not because we've deemed these are all missing, but
    // because we're going to iteratively remove items that are locally known -
    // meaning at the end of the loop, remaining ids will be confirmed missing.
    var missingIds = Set<String>.from(ids);

    for (final matchedSource in getSources(requestType: details.requestType)) {
      if (missingIds.isEmpty) {
        break;
      }

      if (matchedSource.unmatched) {
        pastSources.add(matchedSource.source);
        continue;
      }
      final sourceResult = await matchedSource.source.getByIds(
        missingIds,
        details,
      );

      switch (sourceResult) {
        case ReadListFailure():
          return sourceResult;
        case ReadListSuccess():
          items.addAll(sourceResult.itemsMap);
          // Mark which Source needs which items
          for (final pastSource in pastSources) {
            backfillMap.putIfAbsent(pastSource, () => <T>{});
            backfillMap[pastSource]!.addAll(sourceResult.items);
          }

          // Remove any now-known Ids from `missingIds`
          missingIds = missingIds.where((id) => !items.containsKey(id)).toSet();

          // Note that we've already processed this Source, so if future
          // Sources produce any new items, we can backfill them to here.
          pastSources.add(matchedSource.source);
      }
    }

    // Persist any items we found to local stores
    for (final pastSource in backfillMap.keys) {
      if (pastSource is! LocalSource) continue;

      if (backfillMap[pastSource]!.isNotEmpty) {
        for (final item in backfillMap[pastSource]!) {
          await pastSource.setItem(item, details);
        }
      }

      if (!details.isLocal && missingIds.isNotEmpty) {
        // Missing Ids at this point would mean that we tried to load data from
        // the server and still failed to pull in certain Ids. That means they
        // don't exist anymore, and thus we can delete them.
        await (pastSource as LocalSource<T>).deleteIds(missingIds);
      }
    }

    return ReadListResult<T>.fromMap(items, details, missingIds);
  }

  @override
  Future<ReadListResult<T>> getItems(RequestDetails details) async {
    final emptySources = <Source<T>>[];
    for (final matchedSource in getSources(requestType: details.requestType)) {
      if (matchedSource.unmatched) {
        emptySources.add(matchedSource.source);
        continue;
      }

      final sourceResult = await matchedSource.source.getItems(details);

      switch (sourceResult) {
        case ReadListSuccess<T>():
          final items = sourceResult.items;
          if (items.isNotEmpty) {
            await _cacheItems(items, emptySources, details);
            return ReadListResult<T>.fromList(
              items,
              details,
              {},
              bindings.getId,
            );
          } else {
            emptySources.add(matchedSource.source);
          }
        case ReadListFailure<T>():
          return sourceResult;
      }
    }

    // Lastly, help any local sources track their known empty sets.
    if (details.requestType == RequestType.global ||
        details.requestType == RequestType.refresh) {
      for (final source in emptySources) {
        if (source is LocalSource<T>) {
          await source.setItems(<T>[], details);
        }
      }
    }
    return ReadListResult<T>.fromList([], details, {}, bindings.getId);
  }

  @override
  Future<WriteResult<T>> setItem(T item, RequestDetails details) async {
    T itemDup = item;
    for (final ms in getSources(
      requestType: details.requestType,
      // Hit API first if item is new, so as to get an Id
      reversed: bindings.getId(item) == null,
    )) {
      if (ms.unmatched) continue;

      final result = await ms.source.setItem(itemDup, details);

      switch (result) {
        case WriteSuccess<T>():
          if (bindings.getId(item) == null) {
            if (bindings.getId(result.item) == null) {
              return WriteFailure<T>(
                FailureReason.serverError,
                'Failed to generate Id for new $T',
              );
            }
            itemDup = result.item;
          }
        case WriteFailure<T>():
          return result;
      }
    }
    return WriteSuccess<T>(itemDup, details: details);
  }

  @override
  Future<WriteListResult<T>> setItems(
    Iterable<T> items,
    RequestDetails details,
  ) async {
    assert(
      details.requestType == RequestType.local,
      'setItems is a local-only method',
    );
    for (final ms in getSources(requestType: details.requestType)) {
      if (ms.unmatched) continue;
      final result = await ms.source.setItems(items, details);
      if (result is WriteListFailure) {
        return result;
      }
    }
    return WriteListSuccess<T>(items, details: details);
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

  @override
  Future<DeleteResult<T>> delete(String id, RequestDetails details) async {
    for (final ms in getSources(requestType: details.requestType)) {
      if (ms.unmatched) continue;
      final result = await ms.source.delete(id, details);
      if (result is DeleteFailure<T>) {
        return result;
      }
    }
    return DeleteSuccess<T>(details);
  }
}

/// Indicates whether a given [Source] was queried within a request, which is
/// used when during the write-through cache phase.
class MatchedSource<T> {
  MatchedSource._({required this.source, required this.matched});

  /// Flavor of [Source] that matched the given [RequestType]. This [Source]
  /// will be asked for the desired data.
  factory MatchedSource.matched(Source<T> source) => MatchedSource._(
    source: source,
    matched: true,
  );

  /// Flavor of [Source] that did not match the given [RequestType]. This
  /// [Source] will not be asked for the desired data and will only be able to
  /// cache the results of another [Source], if appropriate.
  factory MatchedSource.unmatched(Source<T> source) => MatchedSource._(
    source: source,
    matched: false,
  );

  /// {@macro Source}
  final Source<T> source;

  /// Whether or not this [Source] matched the given [RequestType].
  final bool matched;

  /// Opposite of [matched].
  bool get unmatched => !matched;

  @override
  String toString() => 'MatchedSource(matched=$matched, source=$source)';
}
