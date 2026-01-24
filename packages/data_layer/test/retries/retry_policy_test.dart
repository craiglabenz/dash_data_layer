import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../models/test_model.dart';

class MockOperationPersistence<T> extends Mock
    implements OperationPersistence<T> {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      ReadOperation<TestModel>(
        operationId: 'fake',
        itemId: 'fake',
        details: RequestDetails(),
        createdAt: DateTime.now(),
      ),
    );
  });

  group('DefaultRetryPolicy', () {
    late DefaultRetryPolicy<TestModel> retryPolicy;
    late MockOperationPersistence<TestModel> readsPersistence;
    late MockOperationPersistence<TestModel> writesPersistence;

    void setupRetryPolicy({int maxRetries = 3}) {
      retryPolicy = DefaultRetryPolicy<TestModel>(
        maxRetries: maxRetries,
        readsPersistence: readsPersistence,
        writesPersistence: writesPersistence,
      );
    }

    setUp(() {
      readsPersistence = MockOperationPersistence<TestModel>();
      writesPersistence = MockOperationPersistence<TestModel>();

      when(
        () => readsPersistence.onRetryOperation(),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => writesPersistence.onRetryOperation(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => readsPersistence.close()).thenAnswer((_) async {});
      when(() => writesPersistence.close()).thenAnswer((_) async {});
      when(
        () => readsPersistence.getSavedOperations(),
      ).thenAnswer((_) async => []);
      when(
        () => writesPersistence.getSavedOperations(),
      ).thenAnswer((_) async => []);

      setupRetryPolicy();
    });

    tearDown(() async {
      await retryPolicy.close();
    });

    group('shouldRetry', () {
      test('returns true when attemptNumber < maxRetries + 1', () {
        final operation = ReadOperation<TestModel>(
          operationId: '1',
          itemId: '1',
          details: RequestDetails(),
          createdAt: DateTime.now(),
          attemptNumber: 3, // maxRetries is 3
        );

        expect(retryPolicy.shouldRetry(operation, .connectivity), isTrue);
      });

      test('returns false when attemptNumber >= maxRetries + 1', () {
        final operation = ReadOperation<TestModel>(
          operationId: '1',
          itemId: '1',
          details: RequestDetails(),
          createdAt: DateTime.now(),
          attemptNumber: 4, // 3 + 1
        );

        expect(retryPolicy.shouldRetry(operation, .connectivity), isFalse);
      });

      test('returns false for FailureReason.badRequest', () {
        final operation = ReadOperation<TestModel>(
          operationId: '1',
          itemId: '1',
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );

        expect(retryPolicy.shouldRetry(operation, .badRequest), isFalse);
      });

      test('returns true for FailureReason.connectivity and serverError', () {
        final operation = ReadOperation<TestModel>(
          operationId: '1',
          itemId: '1',
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );

        expect(retryPolicy.shouldRetry(operation, .connectivity), isTrue);
        expect(retryPolicy.shouldRetry(operation, .serverError), isTrue);
      });

      test('returns false for shouldRetry=false', () {
        final operation = ReadOperation<TestModel>(
          operationId: '1',
          itemId: '1',
          details: RequestDetails(shouldRetry: false),
          createdAt: DateTime.now(),
        );

        expect(
          retryPolicy.shouldRetry(operation, .connectivity),
          isFalse,
        );
      });
    });

    group('storeOperationForRetry', () {
      final readOp = ReadOperation<TestModel>(
        operationId: '1',
        itemId: '1',
        details: RequestDetails(),
        createdAt: DateTime.now(),
      );

      final writeOp = WriteOperation<TestModel>(
        operationId: '2',
        item: const TestModel(id: '2'),
        details: RequestDetails(),
        createdAt: DateTime.now(),
      );

      test(
        'connectivity failures call save on appropriate persistence',
        () async {
          when(() => readsPersistence.save(any())).thenAnswer((_) async {});
          when(() => writesPersistence.save(any())).thenAnswer((_) async {});

          await retryPolicy.storeOperationForRetry(readOp, .connectivity);
          verify(() => readsPersistence.save(readOp)).called(1);
          verifyNever(() => writesPersistence.save(any()));

          await retryPolicy.storeOperationForRetry(writeOp, .connectivity);
          verify(() => writesPersistence.save(writeOp)).called(1);
        },
      );

      test(
        'serverError failures call schedule on appropriate persistence',
        () async {
          when(() => readsPersistence.schedule(any())).thenAnswer((_) async {});
          when(
            () => writesPersistence.schedule(any()),
          ).thenAnswer((_) async {});

          await retryPolicy.storeOperationForRetry(readOp, .serverError);
          verify(() => readsPersistence.schedule(readOp)).called(1);
          verifyNever(() => writesPersistence.schedule(any()));

          await retryPolicy.storeOperationForRetry(writeOp, .serverError);
          verify(() => writesPersistence.schedule(writeOp)).called(1);
        },
      );

      test('badRequest failures do nothing', () async {
        await retryPolicy.storeOperationForRetry(readOp, .badRequest);
        verifyNever(() => readsPersistence.save(any()));
        verifyNever(() => readsPersistence.schedule(any()));
        verifyNever(() => writesPersistence.save(any()));
        verifyNever(() => writesPersistence.schedule(any()));
      });
    });

    group('onRetryOperation', () {
      test('forwards operations from both persistences', () async {
        final readController = StreamController<Operation<TestModel>>();
        final writeController = StreamController<Operation<TestModel>>();

        // We need to recreate the mock or reset it because DefaultRetryPolicy
        // calls onRetryOperation in its constructor.
        final readsMock = MockOperationPersistence<TestModel>();
        final writesMock = MockOperationPersistence<TestModel>();

        when(
          readsMock.onRetryOperation,
        ).thenAnswer((_) => readController.stream);
        when(
          writesMock.onRetryOperation,
        ).thenAnswer((_) => writeController.stream);
        when(readsMock.close).thenAnswer((_) async {});
        when(writesMock.close).thenAnswer((_) async {});

        final localRetryPolicy = DefaultRetryPolicy<TestModel>(
          maxRetries: 3,
          readsPersistence: readsMock,
          writesPersistence: writesMock,
        );

        final results = <Operation<TestModel>>[];
        final sub = localRetryPolicy.onRetryOperation().listen(results.add);

        final op1 = ReadOperation<TestModel>(
          operationId: '1',
          itemId: '1',
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );
        final op2 = WriteOperation<TestModel>(
          operationId: '2',
          item: const TestModel(id: '2'),
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );

        readController.add(op1);
        writeController.add(op2);

        // Yield to stream
        await Future<void>.delayed(Duration.zero);

        expect(results, containsAll([op1, op2]));

        await sub.cancel();
        await localRetryPolicy.close();
        await readController.close();
        await writeController.close();
      });
    });

    group('onReconnected', () {
      test('returns saved operations from both persistences', () async {
        final op1 = ReadOperation<TestModel>(
          operationId: '1',
          itemId: '1',
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );
        final op2 = WriteOperation<TestModel>(
          operationId: '2',
          item: const TestModel(id: '2'),
          details: RequestDetails(),
          createdAt: DateTime.now(),
        );

        when(
          () => readsPersistence.getSavedOperations(),
        ).thenAnswer((_) async => [op1]);
        when(
          () => writesPersistence.getSavedOperations(),
        ).thenAnswer((_) async => [op2]);

        final result = await retryPolicy.onReconnected();

        expect(result, containsAll([op1, op2]));
        verify(() => readsPersistence.getSavedOperations()).called(1);
        verify(() => writesPersistence.getSavedOperations()).called(1);
      });
    });

    test('close cancels subscriptions and closes persistences', () async {
      final readController = StreamController<Operation<TestModel>>();
      final writeController = StreamController<Operation<TestModel>>();

      final readsMock = MockOperationPersistence<TestModel>();
      final writesMock = MockOperationPersistence<TestModel>();

      when(
        readsMock.onRetryOperation,
      ).thenAnswer((_) => readController.stream);
      when(
        writesMock.onRetryOperation,
      ).thenAnswer((_) => writeController.stream);
      when(readsMock.close).thenAnswer((_) async {});
      when(writesMock.close).thenAnswer((_) async {});

      final localRetryPolicy = DefaultRetryPolicy<TestModel>(
        maxRetries: 3,
        readsPersistence: readsMock,
        writesPersistence: writesMock,
      );

      await localRetryPolicy.close();

      verify(readsMock.close).called(1);
      verify(writesMock.close).called(1);

      expect(readController.hasListener, isFalse);
      expect(writeController.hasListener, isFalse);

      await readController.close();
      await writeController.close();
    });
  });
}
