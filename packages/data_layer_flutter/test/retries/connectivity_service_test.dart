import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:data_layer_flutter/data_layer_flutter.dart'
    show ConnectivityPlusStream;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('ConnectivityPlusStream', () {
    late Connectivity connectivity;
    late StreamController<List<ConnectivityResult>> connectivityController;

    setUp(() {
      connectivity = MockConnectivity();
      connectivityController =
          StreamController<List<ConnectivityResult>>.broadcast();

      when(
        () => connectivity.onConnectivityChanged,
      ).thenAnswer((_) => connectivityController.stream);
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    });

    tearDown(() async {
      await connectivityController.close();
    });

    test('initializes with current connectivity status', () async {
      final service = ConnectivityPlusStream(connectivity: connectivity);
      expect(await service.isConnected, isTrue);
    });

    test(
      'stream listeners immediately fire with existing value',
      () async {
        final service = ConnectivityPlusStream(connectivity: connectivity);

        bool? isConnected;
        final completer = Completer<void>();

        // Force a delay so that connectivity initialization is fully complete
        await Future.delayed(const Duration(milliseconds: 10), () {});

        service.listen((bool newConnectedValue) {
          isConnected = newConnectedValue;
          completer.complete();
        });
        await completer.future;
        expect(isConnected, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test('emits true when connected to wifi', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      final service = ConnectivityPlusStream(connectivity: connectivity);

      // Wait for initial check to complete (it returns false)
      expect(await service.isConnected, isFalse);

      // Now activate wifi
      connectivityController.add([ConnectivityResult.wifi]);

      // Wait for wifi connection to propagate through the stream so we only
      // see the latest value (true) in the listener
      await Future.delayed(const Duration(milliseconds: 10), () {});

      bool? nextEmission;
      final completer = Completer<void>();
      service.listen((bool newConnectedValue) {
        nextEmission = newConnectedValue;
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      await completer.future;

      expect(nextEmission, isTrue);
      expect(await service.isConnected, isTrue);
    });

    test('emits false when disconnected', () async {
      final service = ConnectivityPlusStream(connectivity: connectivity);
      expect(await service.isConnected, isTrue);

      connectivityController.add([ConnectivityResult.none]);
      // Wait for wifi connection to propagate through the stream so we only
      // see the latest value (true) in the listener
      await Future.delayed(const Duration(milliseconds: 10), () {});

      bool? nextEmission;
      final completer = Completer<void>();
      service.listen((bool newConnectedValue) {
        nextEmission = newConnectedValue;
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      await completer.future;

      expect(nextEmission, isFalse);
      expect(await service.isConnected, isFalse);
    });

    test('respects allowedConnectivityResults', () async {
      final service = ConnectivityPlusStream(
        connectivity: connectivity,
        allowedConnectivityResults: {ConnectivityResult.wifi},
      );

      // Mobile should be treated as disconnected because it's not in allowed
      // list
      connectivityController.add([ConnectivityResult.mobile]);

      // We need to wait a tick for the listener to fire
      await Future<void>.delayed(Duration.zero);
      expect(await service.isConnected, isFalse);

      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      expect(await service.isConnected, isTrue);
    });

    test(
      'isConnected waits for initial result if checkConnectivity is slow',
      () async {
        final completer = Completer<List<ConnectivityResult>>();
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) => completer.future);

        final service = ConnectivityPlusStream(connectivity: connectivity);

        var futureCompleted = false;
        unawaited(service.isConnected.then((_) => futureCompleted = true));

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(futureCompleted, isFalse);

        completer.complete([ConnectivityResult.wifi]);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(futureCompleted, isTrue);
        expect(await service.isConnected, isTrue);
      },
    );
  });
}
