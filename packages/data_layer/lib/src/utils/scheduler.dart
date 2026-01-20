// ignore_for_file: one_member_abstracts

import 'package:data_layer/src/utils/timer.dart';

/// Schedules functions to be called after a given delay.
///
/// This class is essentially a factory builder for [ITimer].
abstract class Scheduler {
  /// {@macro Scheduler}
  const Scheduler();

  /// Registers a function to execute after the given [delay].
  ITimer schedule(Duration delay, void Function() callback);
}

/// Real implementation of [Scheduler] which uses a [RealTimer] to schedule
/// callbacks.
class RealScheduler implements Scheduler {
  /// {@macro Scheduler}
  const RealScheduler();

  @override
  ITimer schedule(Duration delay, void Function() callback) =>
      RealTimer()..start(delay, callback);
}

/// Test-friendly implementation of [Scheduler] which uses a [TestFriendlyTimer]
/// to invoke callbacks immediately.
class TestFriendlyScheduler implements Scheduler {
  @override
  ITimer schedule(Duration delay, void Function() callback) =>
      TestFriendlyTimer()..start(delay, callback);
}
