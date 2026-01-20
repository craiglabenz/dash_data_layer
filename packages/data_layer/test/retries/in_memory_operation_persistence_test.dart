import 'dart:async';

import 'package:data_layer/data_layer.dart';
import 'package:test/test.dart';
import '../models/test_model.dart';

void main() {
  late InMemoryOperationPersistence<TestModel> persistence;

  setUp(() {
    persistence = InMemoryOperationPersistence<TestModel>();
  });

  tearDown(() async {
    await persistence.close();
  });

  group('InMemoryOperationPersistence', () {
    test('save adds operation to saved operations', () async {
      final operation = Operation<TestModel>.getItem(
        operationId: '1',
        itemId: 'id-1',
        details: RequestDetails(),
        createdAt: DateTime.now(),
      );

      await persistence.save(operation);

      final saved = await persistence.getSavedOperations();
      expect(saved, hasLength(1));
      expect(saved.first.operationId, '1');
    });

    test('getSavedOperations clears operations after retrieval', () async {
      final operation = Operation<TestModel>.getItem(
        operationId: '1',
        itemId: 'id-1',
        details: RequestDetails(),
        createdAt: DateTime.now(),
      );

      await persistence.save(operation);

      final savedFirst = await persistence.getSavedOperations();
      expect(savedFirst, hasLength(1));

      final savedSecond = await persistence.getSavedOperations();
      expect(savedSecond, isEmpty);
    });

    test('getSavedOperations returns deep copies of operations', () async {
      final operation = Operation<TestModel>.getItem(
        operationId: '1',
        itemId: 'id-1',
        details: RequestDetails(),
        createdAt: DateTime.now(),
        attemptNumber: 1,
      );

      await persistence.save(operation);

      final saved = await persistence.getSavedOperations();
      expect(saved, hasLength(1));
      expect(saved.first, equals(operation.retry()));
      // identical() check to ensure it's a copy
      expect(identical(saved.first, operation), isFalse);
    });

    test('schedule emits operation on onRetryOperation after delay', () async {
      final operation = Operation<TestModel>.getItem(
        operationId: '1',
        itemId: 'id-1',
        details: RequestDetails(),
        createdAt: DateTime.now(),
        attemptNumber: 1,
      );

      final persistence = InMemoryOperationPersistence<TestModel>.test();
      final results = <Operation<TestModel>>[];

      final completer = Completer<void>();
      final subscription = persistence.onRetryOperation().listen((op) {
        results.add(op);
        completer.complete();
      });

      await persistence.schedule(operation);

      await completer.future;

      expect(results, hasLength(1));
      expect(results.first.operationId, '1');

      await subscription.cancel();
      await persistence.close();
    });

    test(
      'multiple scheduled operations can coexist',
      () async {
        final op1 = Operation<TestModel>.getItem(
          operationId: '1',
          itemId: 'id-1',
          details: RequestDetails(),
          createdAt: DateTime.now(),
          attemptNumber: 1,
        );
        final op2 = Operation<TestModel>.setItem(
          operationId: '2',
          item: const TestModel(id: '2', msg: 'test'),
          details: RequestDetails(),
          createdAt: DateTime.now(),
          attemptNumber: 1,
        );

        final persistence = InMemoryOperationPersistence<TestModel>.test();
        final results = <Operation<TestModel>>[];

        final completer = Completer<void>();
        final subscription = persistence.onRetryOperation().listen((op) {
          results.add(op);
          if (results.length == 2) {
            completer.complete();
          }
        });

        await persistence.schedule(op1);
        await persistence.schedule(op2);

        await completer.future;

        expect(results, hasLength(2));

        await subscription.cancel();
        await persistence.close();
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test('getSavedOperations does not return scheduled operations', () async {
      final operation = Operation<TestModel>.getItem(
        operationId: '1',
        itemId: 'id-1',
        details: RequestDetails(),
        createdAt: DateTime.now(),
      );

      await persistence.schedule(operation);

      final saved = await persistence.getSavedOperations();
      expect(saved, isEmpty);
    });

    test('onRetryOperation stream closes when persistence is closed', () async {
      final persistence = InMemoryOperationPersistence<TestModel>();
      final stream = persistence.onRetryOperation();

      await persistence.close();

      await expectLater(stream, emitsDone);
    });
  });
}
