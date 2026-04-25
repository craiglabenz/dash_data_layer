import 'dart:async';
import 'dart:math';

import 'package:data_layer/data_layer.dart';
import 'package:hive_ce/hive.dart';

/// {@template HiveOperationsPersistence}
/// Durable persistence engine for failed operations using Hive. This is most
/// suited for write operations which you want to try again later, such as to
/// provide offline support which queues up writes for when connectivity is
/// restored; even if that is after a fresh launch of the app.
/// {@endtemplate}
class HiveOperationsPersistence<T>
    with ReadinessMixin<void>
    implements OperationPersistence<T> {
  /// {@macro HiveOperationsPersistence}
  HiveOperationsPersistence({
    required this.name,
    required this.hiveInit,
    required this.bindings,
    HiveInterface? hive,
    this.scheduler = const RealScheduler(),
  }) : _hive = hive ?? Hive;

  /// Unique base name for the Hive boxes.
  ///
  /// This will be used to create two boxes:
  /// - `[name]_saved` for operations to be retried later (e.g. on
  ///    reconnection).
  /// - `[name]_scheduled` for operations with an active backoff timer.
  final String name;

  /// Future which should resolve when Hive is initialized.
  final Future<void> hiveInit;

  /// Serialization bindings for [T].
  final Bindings<T> bindings;

  final HiveInterface _hive;

  /// Scheduler for retry timers.
  final Scheduler scheduler;

  /// Persistence for failed operations which should not be rescheduled on
  /// account of the app having no reason to expect they will magically succeed
  /// at an arbitrary point in the future. Instead of being scheduled, these
  /// operations will be held until they are asked for.
  ///
  /// In practice, this means operations which failed due to connectivity
  /// reasons, further implying that when connectivity is restored, they will
  /// be requested via [getSavedOperations].
  late final Box<Map<dynamic, dynamic>> _savedBox;

  /// Persistence for failed operations which should be periodically rescheduled
  /// via standard exponential backoff mechanisms.
  late final Box<Map<dynamic, dynamic>> _scheduledBox;

  final _streamController = StreamController<Operation<T>>.broadcast();
  final _retryTimers = <ITimer>[];

  @override
  FutureOr<void> performInitialization() async {
    await hiveInit;
    _savedBox = await _hive.openBox<Map<dynamic, dynamic>>('${name}_saved');
    _scheduledBox = await _hive.openBox<Map<dynamic, dynamic>>(
      '${name}_scheduled',
    );

    // Re-schedule any operations found in the scheduled box
    for (final key in _scheduledBox.keys.cast<String>()) {
      final data = _scheduledBox.get(key);
      if (data != null) {
        final json = data.cast<String, dynamic>();
        final operation = Operation<T>.fromJson(
          json,
          (obj) => bindings.fromJson(obj! as Json),
        );
        _scheduleInternal(operation);
      }
    }
    markReady(null);
  }

  @override
  Future<void> save(Operation<T> operation) async {
    await ready;
    final op = operation.retry<Operation<T>>();
    await _savedBox.put(op.operationId, op.toJson(bindings.toJson));
  }

  @override
  Future<void> schedule(Operation<T> operation, {Duration? maxWait}) async {
    await ready;
    await _scheduledBox.put(
      operation.operationId,
      operation.toJson(bindings.toJson),
    );
    _scheduleInternal(operation, maxWait: maxWait);
  }

  void _scheduleInternal(Operation<T> operation, {Duration? maxWait}) {
    Duration wait = Duration(seconds: pow(2, operation.attemptNumber).toInt());
    if (maxWait != null && maxWait.inSeconds < wait.inSeconds) {
      wait = maxWait;
    }

    _retryTimers.add(
      scheduler.schedule(
        wait,
        () async {
          _streamController.add(operation.retry());
          await _scheduledBox.delete(operation.operationId);
        },
      ),
    );
  }

  @override
  Stream<Operation<T>> onRetryOperation() => _streamController.stream;

  @override
  Future<List<Operation<T>>> getSavedOperations() async {
    await ready;
    final operations = <Operation<T>>[];
    final keysToDelete = <String>[];

    for (final key in _savedBox.keys.cast<String>()) {
      final data = _savedBox.get(key);
      if (data != null) {
        final json = data.cast<String, Object?>();
        operations.add(
          Operation<T>.fromJson(
            json,
            (obj) => bindings.fromJson(obj! as Json),
          ),
        );
        keysToDelete.add(key);
      }
    }

    await _savedBox.deleteAll(keysToDelete);
    return operations;
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
    if (isReady) {
      await Future.wait([
        _savedBox.close(),
        _scheduledBox.close(),
      ]);
    }
  }
}
