import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../models/test_model.dart';
import 'operation_builders.dart';

class MockSource extends Mock implements Source<TestModel> {}

class MockRetryPolicy extends Mock implements RetryPolicy<TestModel> {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  setUpAll(() {
    registerFallbackValue(SourceOperationType.getById);
    registerFallbackValue(gro('1', RequestDetails()));
    registerFallbackValue(grlo(RequestDetails()));
    registerFallbackValue(grido({'1'}, RequestDetails()));
    registerFallbackValue(gwo(const TestModel(id: '1'), RequestDetails()));
    registerFallbackValue(gwlo([const TestModel(id: '1')], RequestDetails()));
    registerFallbackValue(gdo('1', RequestDetails()));
    registerFallbackValue(FailureReason.connectivity);
  });

  group('SourceList Retry Integration', () {
    late SourceList<TestModel> sl;
    late MockSource source;
    late MockRetryPolicy retryPolicy;
    late MockConnectivityService connectivityService;
    late StreamController<Operation<TestModel>> retryController;
    late StreamController<bool> connectivityController;

    setUp(() {
      source = MockSource();
      retryPolicy = MockRetryPolicy();
      connectivityService = MockConnectivityService();
      retryController = StreamController<Operation<TestModel>>.broadcast();
      connectivityController = StreamController<bool>.broadcast();

      when(() => source.hasBindings).thenReturn(true);
      when(() => source.sourceType).thenReturn(SourceType.remote);
      when(() => source.supports(any())).thenReturn(true);

      when(
        retryPolicy.onRetryOperation,
      ).thenAnswer((_) => retryController.stream);
      when(() => connectivityService.listen(any())).thenAnswer((invocation) {
        final callback =
            // ignore: avoid_positional_boolean_parameters
            invocation.positionalArguments[0] as void Function(bool);
        return connectivityController.stream.listen(callback);
      });
      when(() => connectivityService.isConnected).thenAnswer((_) async => true);

      sl = SourceList<TestModel>(
        bindings: TestModel.bindings,
        sources: [source],
        retryPolicy: retryPolicy,
        connectivityService: connectivityService,
        getTime: () => DateTime.now().toUtc(),
      );
    });

    tearDown(() async {
      await sl.close();
      await retryController.close();
      await connectivityController.close();
    });

    group('Initial Failure handling', () {
      test('getById stores for retry on connectivity failure', () async {
        final op = gro('1', RequestDetails());
        when(() => source.getById(op)).thenAnswer(
          (_) async => const ReadFailure<TestModel>(.connectivity, 'offline'),
        );
        when(() => retryPolicy.shouldRetry(any(), any())).thenReturn(true);
        when(
          () => retryPolicy.storeOperationForRetry(any(), any()),
        ).thenAnswer((_) async {});

        await sl.getById(op);

        verify(
          () => retryPolicy.storeOperationForRetry(op, .connectivity),
        ).called(1);
      });

      test('getById stores for retry on server error', () async {
        final op = gro('1', RequestDetails());
        when(() => source.getById(op)).thenAnswer(
          (_) async => const ReadFailure<TestModel>(.serverError, 'error'),
        );
        when(() => retryPolicy.shouldRetry(any(), any())).thenReturn(true);
        when(
          () => retryPolicy.storeOperationForRetry(any(), any()),
        ).thenAnswer((_) async {});

        await sl.getById(op);

        verify(
          () => retryPolicy.storeOperationForRetry(op, .serverError),
        ).called(1);
      });

      test(
        'setItem stores for retry on offline (NoConnectivityException)',
        () async {
          final op = gwo(const TestModel(id: '1'), RequestDetails());
          when(
            () => connectivityService.isConnected,
          ).thenAnswer((_) async => false);
          when(
            () => retryPolicy.storeOperationForRetry(any(), any()),
          ).thenAnswer((_) async {});

          await sl.setItem(op);

          verify(
            () => retryPolicy.storeOperationForRetry(op, .connectivity),
          ).called(1);
          verifyNever(() => source.setItem(any()));
        },
      );
    });

    group('Retry fulfillment', () {
      test('re-invokes getById when retryPolicy emits', () async {
        final op = gro('1', RequestDetails());
        final retryOp = op.retry<ReadOperation<TestModel>>();

        final completer = Completer<void>();
        when(() => source.getById(retryOp)).thenAnswer((_) async {
          completer.complete();
          return ReadSuccess<TestModel>(
            const TestModel(id: '1'),
            details: RequestDetails(),
          );
        });

        retryController.add(retryOp);

        await completer.future.timeout(const Duration(seconds: 1));
        verify(() => source.getById(retryOp)).called(1);
      });

      test('re-invokes getItems when retryPolicy emits', () async {
        final op = grlo(RequestDetails());
        final retryOp = op.retry<ReadListOperation<TestModel>>();

        final completer = Completer<void>();
        when(() => source.getItems(retryOp)).thenAnswer((_) async {
          completer.complete();
          return ReadListResult<TestModel>.fromList(
            [const TestModel(id: '1')],
            RequestDetails(),
            {},
            TestModel.bindings.getId,
          );
        });

        retryController.add(retryOp);

        await completer.future.timeout(const Duration(seconds: 1));
        verify(() => source.getItems(retryOp)).called(1);
      });

      test('re-invokes getByIds when retryPolicy emits', () async {
        final op = grido({'1'}, RequestDetails());
        final retryOp = op.retry<ReadByIdsOperation<TestModel>>();

        final completer = Completer<void>();
        when(() => source.getByIds(retryOp)).thenAnswer((_) async {
          completer.complete();
          return ReadListResult<TestModel>.fromList(
            [const TestModel(id: '1')],
            RequestDetails(),
            {},
            TestModel.bindings.getId,
          );
        });

        retryController.add(retryOp);

        await completer.future.timeout(const Duration(seconds: 1));
        verify(() => source.getByIds(retryOp)).called(1);
      });

      test('re-invokes setItem when retryPolicy emits', () async {
        final op = gwo(const TestModel(id: '1'), RequestDetails());
        final retryOp = op.retry<WriteOperation<TestModel>>();

        final completer = Completer<void>();
        when(() => source.setItem(retryOp)).thenAnswer((_) async {
          completer.complete();
          return WriteSuccess<TestModel>(
            const TestModel(id: '1'),
            details: RequestDetails(),
          );
        });

        retryController.add(retryOp);

        await completer.future.timeout(const Duration(seconds: 1));
        verify(() => source.setItem(retryOp)).called(1);
      });

      test('re-invokes setItems when retryPolicy emits', () async {
        final op = gwlo([const TestModel(id: '1')], RequestDetails());
        final retryOp = op.retry<WriteListOperation<TestModel>>();

        final completer = Completer<void>();
        when(() => source.setItems(retryOp)).thenAnswer((_) async {
          completer.complete();
          return WriteListSuccess<TestModel>([
            const TestModel(id: '1'),
          ], details: RequestDetails());
        });

        retryController.add(retryOp);

        await completer.future.timeout(const Duration(seconds: 1));
        verify(() => source.setItems(retryOp)).called(1);
      });

      test('re-invokes delete when retryPolicy emits', () async {
        final op = gdo('1', RequestDetails());
        final retryOp = op.retry<DeleteOperation<TestModel>>();

        final completer = Completer<void>();
        when(() => source.delete(retryOp)).thenAnswer((_) async {
          completer.complete();
          return DeleteSuccess<TestModel>(RequestDetails());
        });

        retryController.add(retryOp);

        await completer.future.timeout(const Duration(seconds: 1));
        verify(() => source.delete(retryOp)).called(1);
      });
    });

    group('Connectivity Restoration', () {
      test(
        'triggers retryPolicy.onReconnected when connectivity returns',
        () async {
          final op = gwo(const TestModel(id: '1'), RequestDetails());

          when(() => retryPolicy.onReconnected()).thenAnswer((_) async => [op]);
          when(() => source.setItem(op)).thenAnswer(
            (_) async => WriteSuccess<TestModel>(
              const TestModel(id: '1'),
              details: RequestDetails(),
            ),
          );

          connectivityController.add(true);

          // Wait a bit for the async chain to trigger
          await Future<void>.delayed(Duration.zero);

          verify(() => retryPolicy.onReconnected()).called(1);
          verify(() => source.setItem(op)).called(1);
        },
      );
    });
  });
}
