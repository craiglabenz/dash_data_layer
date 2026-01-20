import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../models/test_model.dart';

class MockSource extends Mock implements Source<TestModel> {}

class MockRetryPolicy extends Mock implements RetryPolicy<TestModel> {}

void main() {
  late SourceList<TestModel> sourceList;
  late StreamController<Operation<TestModel>> retryController;

  final readOperation = ReadOperation<TestModel>(
    operationId: '1',
    itemId: 'item-id',
    createdAt: DateTime.now(),
    details: RequestDetails(),
  );

  group('SourceList', () {
    final source = MockSource();
    final retryPolicy = MockRetryPolicy();

    setUp(() {
      when(() => source.hasBindings).thenReturn(true);
      when(() => source.sourceType).thenReturn(.remote);

      retryController = StreamController<Operation<TestModel>>();
      when(
        retryPolicy.onRetryOperation,
      ).thenAnswer((_) => retryController.stream);

      sourceList = SourceList<TestModel>(
        bindings: TestModel.bindings,
        sources: [source],
        retryPolicy: retryPolicy,
      );
    });

    test('should reinvoke emitted failed operations', () async {
      final retryOperation = readOperation.retry<ReadOperation<TestModel>>();
      retryController.add(retryOperation);
      when(
        () => source.getById(retryOperation),
      ).thenAnswer(
        (_) async => ReadSuccess<TestModel>(
          const TestModel(id: 'abc'),
          details: RequestDetails(),
        ),
      );

      // Let the stream flush.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verify(() => source.getById(retryOperation)).called(1);
    });
  });

  group('SourceList', () {
    final source = MockSource();
    final retryPolicy = MockRetryPolicy();

    setUpAll(() {
      registerFallbackValue(readOperation);
      registerFallbackValue(FailureReason.connectivity);
      registerFallbackValue(FailureReason.serverError);
      registerFallbackValue(FailureReason.badRequest);
    });

    setUp(() {
      when(() => source.hasBindings).thenReturn(true);
      when(() => source.sourceType).thenReturn(.remote);

      retryController = StreamController<Operation<TestModel>>();
      when(
        retryPolicy.onRetryOperation,
      ).thenAnswer((_) => retryController.stream);

      sourceList = SourceList<TestModel>(
        bindings: TestModel.bindings,
        sources: [source],
        retryPolicy: retryPolicy,
      );
    });

    test(
      'should retry on connectivity failure '
      '(not handled by connectivity service)',
      () async {
        // The read fails
        when(() => source.getById(readOperation)).thenAnswer(
          (_) async =>
              const ReadFailure<TestModel>(.connectivity, 'does not matter'),
        );
        when(
          () => retryPolicy.shouldRetry(readOperation, .connectivity),
        ).thenReturn(true);

        when(
          () =>
              retryPolicy.storeOperationForRetry(readOperation, .connectivity),
        ).thenAnswer((_) async {});

        final result = await sourceList.getById(readOperation);
        expect(
          result,
          const ReadFailure<TestModel>(.connectivity, 'does not matter'),
        );

        verify(
          () =>
              retryPolicy.storeOperationForRetry(readOperation, .connectivity),
        ).called(1);
      },
    );

    test(
      'should retry on serverError failure',
      () async {
        // The read fails
        when(() => source.getById(readOperation)).thenAnswer(
          (_) async =>
              const ReadFailure<TestModel>(.serverError, 'does not matter'),
        );
        when(
          () => retryPolicy.shouldRetry(readOperation, .serverError),
        ).thenReturn(true);

        when(
          () => retryPolicy.storeOperationForRetry(readOperation, .serverError),
        ).thenAnswer((_) async {});

        final result = await sourceList.getById(readOperation);
        expect(
          result,
          const ReadFailure<TestModel>(.serverError, 'does not matter'),
        );

        verify(
          () => retryPolicy.storeOperationForRetry(readOperation, .serverError),
        ).called(1);
      },
    );

    test(
      'should not retry on badRequest failure',
      () async {
        // The read fails
        when(() => source.getById(readOperation)).thenAnswer(
          (_) async =>
              const ReadFailure<TestModel>(.badRequest, 'does not matter'),
        );
        when(
          () => retryPolicy.shouldRetry(readOperation, .badRequest),
        ).thenReturn(false);

        when(
          () => retryPolicy.storeOperationForRetry(readOperation, .badRequest),
        ).thenAnswer((_) async {});

        final result = await sourceList.getById(readOperation);
        expect(
          result,
          const ReadFailure<TestModel>(.badRequest, 'does not matter'),
        );

        verifyNever(
          () => retryPolicy.storeOperationForRetry(any(), any()),
        );
      },
    );
  });
}
