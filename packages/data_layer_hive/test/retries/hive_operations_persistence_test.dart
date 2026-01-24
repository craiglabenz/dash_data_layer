import 'dart:async';
import 'package:data_layer/data_layer.dart';
import 'package:data_layer_hive/src/retries/hive_operations_persistence.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../src/models/test_model.dart';

class MockHive extends Mock implements HiveInterface {}

// ignore: strict_raw_type
class MockBox extends Mock implements Box<Map> {}

void main() {
  group('HiveOperationsPersistence', () {
    late HiveOperationsPersistence<TestModel> persistence;
    late HiveInterface mockHive;
    // ignore: strict_raw_type
    late Box<Map> mockSavedBox;
    // ignore: strict_raw_type
    late Box<Map> mockScheduledBox;

    setUp(() {
      mockHive = MockHive();
      mockSavedBox = MockBox();
      mockScheduledBox = MockBox();

      when(
        () => mockHive.openBox<Map<dynamic, dynamic>>('test_saved'),
      ).thenAnswer((_) async => mockSavedBox);
      when(
        () => mockHive.openBox<Map<dynamic, dynamic>>('test_scheduled'),
      ).thenAnswer((_) async => mockScheduledBox);

      // Default for scheduler in performInitialization
      when(() => mockScheduledBox.keys).thenReturn([]);

      persistence = HiveOperationsPersistence<TestModel>(
        name: 'test',
        hiveInit: Future.value(),
        bindings: TestModel.bindings,
        hive: mockHive,
        scheduler: TestFriendlyScheduler(),
      );
    });

    test('save puts operation in saved box', () async {
      final operation = Operation<TestModel>.getItem(
        operationId: '1',
        itemId: 'id-1',
        details: RequestDetails(),
        createdAt: DateTime.now(),
      );
      final serializedRetryOperation = operation
          .retry<ReadOperation<TestModel>>()
          .toJson(
            TestModel.bindings.toJson,
          );

      when(
        () => mockSavedBox.put('1', serializedRetryOperation),
      ).thenAnswer((_) async {});

      await persistence.save(operation);

      verify(
        () => mockSavedBox.put('1', serializedRetryOperation),
      ).called(1);
    });

    test(
      'schedule puts operation in scheduled box and triggers scheduler',
      () async {
        final operation = Operation<TestModel>.getItem(
          operationId: '1',
          itemId: 'id-1',
          details: RequestDetails(),
          createdAt: DateTime.now(),
          attemptNumber: 1,
        );

        // .retry() is called after the scheduling delay, not when the
        // Operation is in fact scheduled
        final serializedOperation = operation.toJson(
          TestModel.bindings.toJson,
        );

        when(
          () => mockScheduledBox.put('1', serializedOperation),
        ).thenAnswer((_) async {});
        when(() => mockScheduledBox.delete('1')).thenAnswer((_) async {});

        final completer = Completer<void>();
        final results = <Operation<TestModel>>[];
        final subscription = persistence.onRetryOperation().listen(
          (operation) {
            results.add(operation);
            completer.complete();
          },
        );

        await persistence.schedule(operation);
        await completer.future;

        verify(() => mockScheduledBox.put('1', any())).called(1);
        expect(results, hasLength(1));
        expect(results.first.operationId, '1');
        expect(results.first.attemptNumber, 2);

        verify(() => mockScheduledBox.delete('1')).called(1);
        await subscription.cancel();
      },
      timeout: const Timeout(Duration(milliseconds: 100)),
    );

    test('getSavedOperations retrieves from saved box and deletes', () async {
      final operation = Operation<TestModel>.getItem(
        operationId: 'abc',
        itemId: 'id-1',
        details: RequestDetails(),
        createdAt: DateTime.now(),
      );
      final json = operation.toJson(TestModel.bindings.toJson);

      when(() => mockSavedBox.keys).thenReturn(['abc']);
      when(() => mockSavedBox.get('abc')).thenReturn(json);
      when(() => mockSavedBox.deleteAll(any())).thenAnswer((_) async {});

      final saved = await persistence.getSavedOperations();

      expect(saved, hasLength(1));
      expect(saved.first.operationId, 'abc');
      verify(() => mockSavedBox.deleteAll(['abc'])).called(1);
    });

    test('initialization re-schedules operations from scheduled box', () async {
      final operation = Operation<TestModel>.getItem(
        operationId: '1',
        itemId: 'id-1',
        details: RequestDetails(),
        createdAt: DateTime.now(),
        attemptNumber: 1,
      );
      final json = operation.toJson(TestModel.bindings.toJson);

      final mockHive2 = MockHive();
      final mockScheduledBox2 = MockBox();
      final mockSavedBox2 = MockBox();

      when(
        () => mockHive2.openBox<Map<dynamic, dynamic>>('test2_saved'),
      ).thenAnswer((_) async => mockSavedBox2);
      when(
        () => mockHive2.openBox<Map<dynamic, dynamic>>('test2_scheduled'),
      ).thenAnswer((_) async => mockScheduledBox2);

      when(() => mockScheduledBox2.keys).thenReturn(['1']);
      when(() => mockScheduledBox2.get('1')).thenReturn(json);
      when(() => mockScheduledBox2.delete('1')).thenAnswer((_) async {});

      final persistence2 = HiveOperationsPersistence<TestModel>(
        name: 'test2',
        hiveInit: Future.value(),
        bindings: TestModel.bindings,
        hive: mockHive2,
        scheduler: TestFriendlyScheduler(),
      );

      final results = <Operation<TestModel>>[];
      final subscription = persistence2.onRetryOperation().listen(results.add);

      await persistence2.ready;

      expect(results, hasLength(1));
      expect(results.first.operationId, '1');

      await subscription.cancel();
    });

    test('close closes both boxes', () async {
      when(() => mockSavedBox.close()).thenAnswer((_) async {});
      when(() => mockScheduledBox.close()).thenAnswer((_) async {});

      await persistence.ready;
      await persistence.close();

      verify(() => mockSavedBox.close()).called(1);
      verify(() => mockScheduledBox.close()).called(1);
    });
  });
}
