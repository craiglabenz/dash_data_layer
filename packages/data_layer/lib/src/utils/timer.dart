import 'dart:async';

/// Interface for clock-aware object which can schedule callbacks. [ITimer]
/// subtypes exist to remove delays from tests and are little more than wrappers
/// around [Timer].
abstract class ITimer {
  /// Registers a function to execute after the given [delay].
  void start(Duration delay, void Function() callback);

  /// Cancels the scheduled function. Does nothing if the function has already
  /// been run.
  void cancel();
}

/// Real implementation of [ITimer] which uses a [Timer] to schedule a callback.
class BatchTimer extends ITimer {
  Timer? _sub;

  @override
  void start(Duration delay, void Function() callback) =>
      _sub = Timer(delay, callback);
  @override
  void cancel() => _sub?.cancel();
}

/// Variant of [ITimer] which runs all functions immediately. Suitable for
/// tests.
class TestFriendlyTimer extends ITimer {
  @override
  void cancel() {}
  @override
  void start(Duration delay, void Function() callback) => callback();
}
