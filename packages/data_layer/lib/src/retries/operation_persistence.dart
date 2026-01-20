import 'dart:async';
import 'dart:math';

import 'package:data_layer/data_layer.dart';
import 'package:meta/meta.dart';

/// {@template OperationPersistence}
/// Persistence engine for failed operations, powering retry at a later time.
/// This may involve durable persistence to retry even after the app is killed
/// and relaunched (for certain writes), or may only be in-memory for
/// short-lived retries (like reads).
/// {@endtemplate}
abstract class OperationPersistence<T> {
  /// {@macro OperationPersistence}
  const OperationPersistence();

  /// Saves a [Operation] to retry later. This operation will not be
  /// automatically retried; it is up to the caller to schedule retries.
  Future<void> save(Operation<T> operation);

  /// Schedules a [Operation] to be retried later. Exponential backoff
  /// is used if the operation has failed multiple times.
  Future<void> schedule(Operation<T> operation);

  /// Stream of [Operation]s whose time to retry has come. It is the
  /// job of the [RetryPolicy] to subscribe to this stream and ferry each
  /// emitted [Operation] back to the [SourceList].
  Stream<Operation<T>> onRetryOperation();

  /// Retrieves all [Operation] passed to [save] still in persistence.
  /// These should be fully removed from persistence because connectivity has
  /// now been restored; and if they fail again for some reason, they should
  /// be passed back to [save].
  Future<List<Operation<T>>> getSavedOperations();

  /// Releases all resources.
  Future<void> close();
}

/// Lightweight in-memory persistence engine for failed operations. This is
/// suitable for short-lived retries (like reads) but not durable persistence
/// for retries after app restarts (for certain writes).
///
/// To reiterate: when the user kills the app, all data persisted here will be
/// lost. If you are using this class, this should be desired.
class InMemoryOperationPersistence<T> implements OperationPersistence<T> {
  /// {@macro InMemoryOperationPersistence}
  InMemoryOperationPersistence([this._scheduler = const RealScheduler()]);

  /// Test-friendly constructor.
  @visibleForTesting
  factory InMemoryOperationPersistence.test() =>
      InMemoryOperationPersistence(TestFriendlyScheduler());

  final _retryTimers = <ITimer>[];
  final _savedOperations = <Operation<T>>[];
  final _scheduledOperations = <String, Operation<T>>{};
  final _streamController = StreamController<Operation<T>>.broadcast();

  final Scheduler _scheduler;

  @override
  Future<void> save(Operation<T> operation) async {
    _savedOperations.add(operation.retry());
  }

  @override
  Future<void> schedule(Operation<T> operation) async {
    _scheduledOperations[operation.operationId] = operation;
    _retryTimers.add(
      _scheduler.schedule(
        Duration(seconds: pow(2, operation.attemptNumber).toInt()),
        () {
          _streamController.add(operation.retry());
          _scheduledOperations.remove(operation.operationId);
        },
      ),
    );
  }

  @override
  Stream<Operation<T>> onRetryOperation() => _streamController.stream;

  @override
  Future<List<Operation<T>>> getSavedOperations() {
    if (_savedOperations.isEmpty) return Future.value([]);
    final savedOperationsCopy = _savedOperations
        .map<Operation<T>>(
          (operation) => operation.copyWith(),
        )
        .toList();
    _savedOperations.clear();
    return Future.value(savedOperationsCopy);
  }

  @override
  Future<void> close() async {
    for (final timer in _retryTimers) {
      if (!timer.isCompleted) {
        timer.cancel();
      }
    }
    _retryTimers.clear();
    await _streamController.close();
  }
}
