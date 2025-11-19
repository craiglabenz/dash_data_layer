import 'dart:async';
import 'package:logging/logging.dart';

final _log = Logger('Readiness');

/// Possible statuses for the readiness check flow.
enum Readiness {
  /// Fully ready. All dependencies cleared.
  ready,

  /// Striving for readiness. Some or all dependencies not yet cleared.
  loading,
}

/// Adds functionality to check and verify readiness. This usually constitutes
/// completing some setup operation, but could also involve depending on
/// another object's readiness and then taking an action.
///
/// Setup can be synchronous or asynchronous, which should be transparent to
/// any code using this class.
///
/// To use [ReadinessMixin], implement [performInitialization] and then in
/// other code which depends on this object's readiness, await the [ready]
/// property.
///
/// [T] is the central object this resource produces once ready. If no such
/// resource exists, choose `void`.
///
/// Synchronous usage:
/// ```dart
/// class SyncResource with ReadinessMixin<SomeObject> {
///   @override
///   void performInitialization() {
///     // Do setup...
///     return SomeObject();
///   }
/// }
///
/// // Elsewhere
/// final mySyncResource = SyncResource();
/// mySyncResource.initialize();
///
/// // Yet elsewhere
/// final SomeObject val = await mySyncResource.ready;
/// ```
///
/// Asynchronous usage:
/// ```dart
/// class AsyncResource with ReadinessMixin<SomeObject> {
///   @override
///   Future<SomeObject> performInitialization() async {
///     // Do setup...
///     return SomeObject();
///   }
/// }
///
/// // Elsewhere
/// final myAsyncResource = AsyncResource();
/// myAsyncResource.initialize();
///
/// // Yet elsewhere
/// final SomeObject val = await myAsyncResource.ready;
/// ```
mixin ReadinessMixin<T> {
  /// Cache of whether this object is ready. Set by the completer.
  Readiness status = Readiness.loading;

  /// Returns `true` if this object has successfully achieved readiness.
  bool get isReady => status == Readiness.ready;

  /// Returns `true` if this object has not yet successfully achieved readiness.
  bool get isNotReady => !isReady;

  // That which flips the readiness bit.
  var _readinessCompleter = Completer<T>();

  /// Resolves when readiness is achieved, or immediately if it has already been
  /// achieved.
  Future<T> get ready {
    if (!_hasCalledInitialize) {
      initialize();
    }
    return _readinessCompleter.future;
  }

  var _hasCalledInitialize = false;

  /// Calls [performInitialization] with extra bookkeeping. Descendant classes
  /// should implement [performInitialization] but then invoke [initialize].
  void initialize() {
    if (_hasCalledInitialize) {
      _log.warning(
        'Re-initializing readiness for $this. This is a no-op, but did you '
        'potentially await `ready` first, which calls `initialize` if you '
        'did not?',
      );
      return;
    }

    _log.finest('Initializing readiness for $this');
    _hasCalledInitialize = true;
    final initializationResult = performInitialization();
    if (initializationResult is Future<T>) {
      unawaited(initializationResult.then(_markReady));
    } else {
      _markReady(initializationResult);
    }
  }

  /// Classes using [ReadinessMixin] should implement this method to perform
  /// any necessary initialization. Additionally, if there is a critical value
  /// that is required for the object to be ready, it should be returned from
  /// this method.
  FutureOr<T> performInitialization();

  /// Resets any established readiness, if for example a dependency of this
  /// object has also lost readiness.
  ///
  /// A common use case to call this method is for anything that marks itself
  /// ready once a user session is established; after that user logs out.
  void resetReadiness() {
    _log.fine('Resetting readiness for $this');
    _readinessCompleter = Completer<T>();
    _hasCalledInitialize = false;
    status = Readiness.loading;
  }

  /// Marks this object as ready.
  void _markReady(T obj) {
    if (_readinessCompleter.isCompleted) {
      throw Exception(
        'Redundantly marking $this ready when already ready. '
        'Call resetReadiness() if you intended to do this.',
      );
    }
    _log.fine('Marking $this as ready with $obj');
    status = Readiness.ready;
    _readinessCompleter.complete(obj);
  }
}
