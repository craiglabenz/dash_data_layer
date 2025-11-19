import 'dart:async';

import 'package:data_layer/src/utils/readiness.dart';
import 'package:test/test.dart';

class AsyncResource with ReadinessMixin<String> {
  AsyncResource({this.value = 'ready', this.shouldFail = false});

  final bool shouldFail;
  final String value;

  @override
  Future<String> performInitialization() async {
    await Future<void>.delayed(Duration.zero);
    if (!shouldFail) {
      return value;
    } else {
      throw Exception('Failed to initialize');
    }
  }
}

class SyncResource with ReadinessMixin<String> {
  SyncResource({this.shouldFail = false});

  final bool shouldFail;

  @override
  String performInitialization() {
    if (!shouldFail) {
      return 'ready';
    } else {
      throw Exception('Failed to initialize');
    }
  }
}

class VoidResource with ReadinessMixin<void> {
  VoidResource({this.shouldFail = false});

  final bool shouldFail;

  @override
  void performInitialization() {
    if (shouldFail) {
      throw Exception('Failed to initialize');
    }
  }
}

void main() {
  group('ReadinessMixin', () {
    test(
      'starts in loading state',
      () {
        final resource = AsyncResource();
        expect(resource.status, Readiness.loading);
        expect(resource.isReady, isFalse);
        expect(resource.isNotReady, isTrue);

        final resource2 = SyncResource();
        expect(resource2.status, Readiness.loading);
        expect(resource2.isReady, isFalse);
        expect(resource2.isNotReady, isTrue);

        final resource3 = VoidResource();
        expect(resource3.status, Readiness.loading);
        expect(resource3.isReady, isFalse);
        expect(resource3.isNotReady, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test(
      'asynchronously initializes successfully when initialize is called '
      'explicitly',
      () async {
        final resource = AsyncResource()..initialize();
        // Must await `ready` up front for async resources whether or not you
        // intend to use the value. But if you do intend to use it, it is also
        // returned.
        final val = await resource.ready;
        expect(val, 'ready');

        expect(resource.status, Readiness.ready);
        expect(resource.isReady, isTrue);
        expect(resource.isNotReady, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test(
      'asynchronously initializes successfully when initialize is not called '
      'implicitly',
      () async {
        final resource = AsyncResource();
        // Must await `ready` up front for async resources whether or not you
        // intend to use the value. But if you do intend to use it, it is also
        // returned.
        final val = await resource.ready;
        expect(val, 'ready');

        expect(resource.status, Readiness.ready);
        expect(resource.isReady, isTrue);
        expect(resource.isNotReady, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test(
      'synchronously initializes successfully when initialize is called '
      'explicitly',
      () async {
        final resource = SyncResource()..initialize();
        // For synchronous implementations of `performInitialization`, only have
        // to await `ready` if we expect to use the value.

        expect(resource.status, Readiness.ready);
        expect(resource.isReady, isTrue);
        expect(resource.isNotReady, isFalse);

        // Awaiting `ready` is also not an error.
        expect(await resource.ready, 'ready');
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test(
      'synchronously initializes successfully when initialize is not called '
      'implicitly',
      () async {
        final resource = SyncResource();

        // If not calling `initialize` explicitly, must await `ready` up front.
        await resource.ready;

        expect(resource.status, Readiness.ready);
        expect(resource.isReady, isTrue);
        expect(resource.isNotReady, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test(
      'resetReadiness resets state',
      () async {
        final resource = SyncResource()..initialize();
        expect(resource.isReady, isTrue);

        resource.resetReadiness();
        expect(resource.status, Readiness.loading);
        expect(resource.isReady, isFalse);

        resource.initialize();
        expect(resource.isReady, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );
  });
}
