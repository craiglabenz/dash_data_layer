import 'dart:async';

import 'package:data_layer/data_layer.dart';

/// {@template WatchableSource}
/// Optional mixin for [Source] classes indicating they are capable of opening
/// live data subscriptions (e.g. websockets, polling intervals, Firebase
/// snapshots) to stream ongoing results matching a given reading [Operation].
/// {@endtemplate}
mixin WatchableSource<T> on Source<T> {
  /// Opens a live stream which will yield the current matching model
  /// periodically via a [ReadResult].
  Stream<ReadResult<T>> watch(WatchOperation<T> operation);

  /// Opens a live stream which will yield the current matching models
  /// periodically via a [ReadListResult].
  Stream<ReadListResult<T>> watchList(WatchListOperation<T> operation);

  /// Opens a live stream which will yield the current matching models
  /// periodically via a [ReadListResult].
  Stream<ReadListResult<T>> watchByIds(WatchByIdsOperation<T> operation);

  @override
  Set<SourceOperationType> get supportedOperations => {
    ...super.supportedOperations,
    SourceOperationType.watch,
    SourceOperationType.watchList,
    SourceOperationType.watchByIds,
  };
}
