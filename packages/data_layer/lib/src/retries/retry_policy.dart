import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:logging/logging.dart';

/// {@template RetryPolicy}
/// Policy for handling retries of failed requests.
/// {@endtemplate}
abstract class RetryPolicy<T> {
  /// {@macro RetryPolicy}
  const RetryPolicy({
    required this.maxRetries,
  });

  /// Global maximum number of retries to attempt for any operation before
  /// abandoning the effort.
  final int maxRetries;

  /// Called by the [SourceList] when connectivity is reestablished. Should
  /// return all operations which failed due to connectivity issues, but not any
  /// operations which failed due to server errors, as exponential backoff will
  /// decide when they are retried.
  Future<List<Operation<T>>> onReconnected();

  /// Stream of [Operation<T>]s whose time to retry has come.
  Stream<Operation<T>> onRetryOperation();

  /// Triages a failed operation for possible retry.
  Future<void> storeOperationForRetry(
    Operation<T> operation,
    FailureReason reason,
  );

  /// Determines whether an operation should be retried.
  bool shouldRetry(Operation<T> operation, FailureReason reason);

  /// Releases all resources.
  Future<void> close();
}

/// {@macro RetryPolicy}
///
/// Flavor of [RetryPolicy] which triages failed operations based on two
/// parameters:
///   1. Whether the operation was a read or write
///   2. The reason for the failure, as provided by the *Failure object which is
///      the final parameter to each function.
///
/// This policy is designed to be simple and effective for most use cases.
class DefaultRetryPolicy<T> extends RetryPolicy<T> {
  /// Creates an instance of [DefaultRetryPolicy].
  DefaultRetryPolicy({
    required super.maxRetries,
    OperationPersistence<T>? readsPersistence,
    OperationPersistence<T>? writesPersistence,
  }) : readsPersistence = readsPersistence ?? InMemoryOperationPersistence<T>(),
       writesPersistence =
           writesPersistence ?? InMemoryOperationPersistence<T>() {
    _readsSub = this.readsPersistence.onRetryOperation().listen(
      _retryOperation,
    );
    _writesSub = this.writesPersistence.onRetryOperation().listen(
      _retryOperation,
    );
  }

  StreamSubscription<Operation<T>>? _readsSub;
  StreamSubscription<Operation<T>>? _writesSub;

  final StreamController<Operation<T>> _retryController =
      StreamController<Operation<T>>.broadcast();

  @override
  Stream<Operation<T>> onRetryOperation() => _retryController.stream;

  /// Continues the bucket brigade of [Operation]s up to the [SourceList].
  void _retryOperation(Operation<T> operation) =>
      _retryController.add(operation);

  /// Flavor of persistence used to store failed read operations.
  ///
  /// {@macro OperationPersistence}
  final OperationPersistence<T> readsPersistence;

  /// Flavor of persistence used to store failed write operations.
  ///
  /// {@macro OperationPersistence}
  final OperationPersistence<T> writesPersistence;

  final _log = Logger('DefaultRetryPolicy<$T>');

  @override
  Future<List<Operation<T>>> onReconnected() async {
    return [
      ...await readsPersistence.getSavedOperations(),
      ...await writesPersistence.getSavedOperations(),
    ];
  }

  @override
  Future<void> storeOperationForRetry(
    Operation<T> operation,
    FailureReason reason,
  ) async {
    switch (reason) {
      case .connectivity:
        await (operation.isRead
            ? readsPersistence.save(operation)
            : writesPersistence.save(operation));
      case .serverError:
        await (operation.isRead
            ? readsPersistence.schedule(operation)
            : writesPersistence.schedule(operation));
      case .badRequest:
      // Do nothing
    }
  }

  @override
  bool shouldRetry(Operation<T> operation, FailureReason reason) {
    if (operation.attemptNumber >= maxRetries + 1) {
      _log.fine('Abandoning $operation after $maxRetries retries');
      return false;
    }
    return switch (reason) {
      FailureReason.badRequest => false,
      FailureReason.connectivity || FailureReason.serverError => true,
    };
  }

  @override
  Future<void> close() async {
    await Future.wait([
      readsPersistence.close(),
      writesPersistence.close(),
      _readsSub?.cancel() ?? Future<void>.value(),
      _writesSub?.cancel() ?? Future<void>.value(),
    ]);
  }
}
