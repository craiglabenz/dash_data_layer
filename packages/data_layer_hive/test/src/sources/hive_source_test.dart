import 'package:data_layer/data_layer.dart';
import 'package:data_layer_hive/data_layer_hive.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../models/test_model.dart';

class MockHive extends Mock implements HiveInterface {}

class MockRequestBox extends Mock implements Box<Set<String>> {}

class MockItemsBox extends Mock implements Box<TestModel> {}

class MockDateTimeBox extends Mock implements Box<DateTime> {}

// Cannot pre-type Maps with Hive
// ignore: strict_raw_type
class MockPaginationCacheBox extends Mock implements Box<Map> {}

void main() {
  final details = RequestDetails();
  const ttl = Duration(microseconds: 1);
  final ttlDetails = RequestDetails(ttl: ttl);

  group('HiveSource', () {
    late HiveSource<TestModel> source;
    late HiveInterface mockHive;
    late Box<TestModel> mockItemsBox;
    late Box<Set<String>> mockRequestBox;
    late Box<DateTime> mockRequestCacheKeyExpiryBox;
    late Box<DateTime> mockItemsExpiryBox;

    // Cannot pre-type Maps with Hive
    // ignore: strict_raw_type
    late Box<Map> mockPaginationCacheBox;

    setUp(() async {
      mockHive = MockHive();
      mockItemsBox = MockItemsBox();
      mockRequestBox = MockRequestBox();
      mockPaginationCacheBox = MockPaginationCacheBox();
      mockRequestCacheKeyExpiryBox = MockDateTimeBox();
      mockItemsExpiryBox = MockDateTimeBox();
      source = HiveSource(
        bindings: TestModel.bindings,
        hiveInit: Future.value(),
        hive: mockHive,
      );
      when(
        () => mockHive.openBox<TestModel>(any()),
      ).thenAnswer((_) => Future.value(mockItemsBox));
      when(
        () => mockHive.openBox<Set<String>>(any(that: isA<String>())),
      ).thenAnswer((_) => Future.value(mockRequestBox));
      when(
        () => mockHive.openBox<DateTime>('test/_requests_expiry'),
      ).thenAnswer((_) => Future.value(mockRequestCacheKeyExpiryBox));
      when(
        () => mockHive.openBox<DateTime>('test/_items_expiry'),
      ).thenAnswer((_) => Future.value(mockItemsExpiryBox));
      when(
        // ignore: strict_raw_type
        () => mockHive.openBox<Map>(any(that: isA<String>())),
      ).thenAnswer((_) => Future.value(mockPaginationCacheBox));
    });

    test(
      'setItem and getById',
      () async {
        final item = TestModel.randomId();

        when(() => mockItemsBox.get(item.id)).thenReturn(null);
        when(
          () => mockItemsBox.put(item.id, item),
        ).thenAnswer((_) => Future.value());

        final writeResult = await source.setItem(item, details);
        expect(writeResult, isSuccess);
        verifyNever(() => mockItemsExpiryBox.put(item.id, any()));

        when(() => mockItemsBox.get(item.id)).thenReturn(item);
        final readResult = await source.getById(item.id!, details);
        expect(readResult, isSuccess);
        expect((readResult as ReadSuccess<TestModel>).item, item);
      },
      timeout: const Timeout(Duration(milliseconds: 10)),
    );

    test('setItem then read with expired ttl', () async {
      final item = TestModel.randomId();

      when(
        () => mockItemsBox.put(item.id, item),
      ).thenAnswer((_) => Future.value());

      when(
        () => mockItemsExpiryBox.put(item.id, any()),
      ).thenAnswer((_) => Future.value());

      final writeResult = await source.setItem(item, ttlDetails);
      verify(
        () => mockItemsExpiryBox.put(item.id, any()),
      ).called(1);
      expect(writeResult, isSuccess);

      when(() => mockItemsBox.get(item.id)).thenReturn(item);
      when(
        () => mockItemsExpiryBox.get(item.id),
      ).thenReturn(DateTime.now().add(const Duration(days: 1)));

      final readResult = await source.getById(item.id!, details);
      expect(readResult, isSuccess);
      expect(readResult.itemOrRaise(), item);
    });

    test('setItem then read with fresh ttl', () async {
      final item = TestModel.randomId();

      when(
        () => mockItemsBox.put(item.id, item),
      ).thenAnswer((_) => Future.value());

      when(
        () => mockItemsExpiryBox.put(item.id, any()),
      ).thenAnswer((_) => Future.value());

      final writeResult = await source.setItem(item, ttlDetails);
      verify(
        () => mockItemsExpiryBox.put(item.id, any()),
      ).called(1);
      expect(writeResult, isSuccess);

      when(() => mockItemsBox.get(item.id)).thenReturn(item);
      when(
        () => mockItemsExpiryBox.get(item.id),
      ).thenReturn(DateTime.now().subtract(ttl));

      final readResult = await source.getById(item.id!, details);
      expect(readResult, isSuccess);
      expect(readResult.itemOrRaise(), isNull);
    });

    test(
      'setItem will set Id with CreationBindings',
      () async {
        const item = TestModel();
        final itemWithId = item.copyWith(id: 'abc');
        when(
          () => mockItemsBox.put('abc', itemWithId),
        ).thenAnswer((_) => Future.value());

        final writeResult = await source.setItem(item, details);
        expect(writeResult, isSuccess);
        expect((writeResult as WriteSuccess<TestModel>).item, itemWithId);
      },
      timeout: const Timeout(Duration(milliseconds: 10)),
    );

    test(
      'setItems and getByIds',
      () async {
        final item1 = TestModel.randomId();
        final item2 = TestModel.randomId();
        final items = [item1, item2];

        when(() => mockItemsBox.get(item1.id)).thenReturn(null);
        when(
          () => mockItemsBox.put(item1.id, item1),
        ).thenAnswer((_) => Future.value());

        when(() => mockItemsBox.get(item2.id)).thenReturn(null);
        when(
          () => mockItemsBox.put(item2.id, item2),
        ).thenAnswer((_) => Future.value());

        when(
          () => mockRequestBox.put(details.cacheKey, {item1.id!, item2.id!}),
        ).thenAnswer((_) => Future.value());

        when(
          () => mockItemsBox.putAll({item1.id: item1, item2.id: item2}),
        ).thenAnswer((_) => Future.value());

        final writeResult = await source.setItems(items, details);
        expect(writeResult, isSuccess);

        verify(
          () => mockRequestBox.put(details.cacheKey, {item1.id!, item2.id!}),
        ).called(1);
        verify(
          () => mockItemsBox.putAll({item1.id: item1, item2.id: item2}),
        ).called(1);
      },
      timeout: const Timeout(Duration(milliseconds: 10)),
    );

    test(
      'deleteIds',
      () async {
        final item = TestModel.randomId();
        final ids = {item.id!};

        when(() => mockItemsBox.get(item.id)).thenReturn(null);
        when(
          () => mockItemsBox.put(item.id, item),
        ).thenAnswer((_) => Future.value());

        await source.setItem(item, details);

        when(
          () => mockItemsBox.deleteAll(ids),
        ).thenAnswer((_) => Future.value());
        when(
          () => mockItemsExpiryBox.deleteAll(ids),
        ).thenAnswer((_) => Future.value());
        when(
          () => mockRequestCacheKeyExpiryBox.deleteAll(ids),
        ).thenAnswer((_) => Future.value());

        // Mock cache interactions for deleteIds
        when(() => mockRequestBox.keys).thenReturn([]);
        when(mockRequestBox.toMap).thenReturn({});
        when(mockItemsExpiryBox.toMap).thenReturn({});
        when(mockRequestCacheKeyExpiryBox.toMap).thenReturn({});
        when(() => mockPaginationCacheBox.keys).thenReturn([]);
        when(() => mockRequestBox.clear()).thenAnswer((_) => Future.value(0));
        when(
          () => mockPaginationCacheBox.clear(),
        ).thenAnswer((_) => Future.value(0));

        await source.deleteIds(ids);

        verify(() => mockItemsBox.deleteAll(ids)).called(1);
      },
      timeout: const Timeout(Duration(milliseconds: 10)),
    );

    test(
      'clear',
      () async {
        when(mockItemsBox.clear).thenAnswer((_) => Future.value(0));
        when(mockRequestBox.clear).thenAnswer((_) => Future.value(0));
        when(mockItemsExpiryBox.clear).thenAnswer((_) => Future.value(0));
        when(
          mockRequestCacheKeyExpiryBox.clear,
        ).thenAnswer((_) => Future.value(0));
        when(
          () => mockPaginationCacheBox.clear(),
        ).thenAnswer((_) => Future.value(0));

        await source.clear();

        verify(() => mockItemsBox.clear()).called(1);
        verify(() => mockRequestBox.clear()).called(1);
        verify(() => mockItemsExpiryBox.clear()).called(1);
        verify(() => mockRequestCacheKeyExpiryBox.clear()).called(1);
      },
      timeout: const Timeout(Duration(milliseconds: 10)),
    );

    test('readAll with all fresh data', () async {
      final item1 = TestModel.randomId();
      final item2 = TestModel.randomId();

      when(mockItemsBox.toMap).thenReturn({item1.id: item1, item2.id: item2});
      when(
        mockItemsExpiryBox.toMap,
      ).thenReturn({
        item1.id: DateTime.now().add(const Duration(days: 1)),
        item2.id: DateTime.now().add(const Duration(days: 1)),
      });
      final readResult = await source.getItems(
        RequestDetails(requestType: .allLocal),
      );
      expect(readResult, isSuccess);
      expect(readResult.itemsOrRaise(), [item1, item2]);
    });

    test('readAll with all mixed expired and evergreen data', () async {
      final item1 = TestModel.randomId();
      final item2 = TestModel.randomId();

      when(mockItemsBox.toMap).thenReturn({item1.id: item1, item2.id: item2});
      when(
        mockItemsExpiryBox.toMap,
      ).thenReturn({
        item1.id: DateTime.now().subtract(const Duration(days: 1)),
      });
      final readResult = await source.getItems(
        RequestDetails(requestType: .allLocal),
      );
      expect(readResult, isSuccess);
      expect(readResult.itemsOrRaise(), [item2]);
    });

    test('readAll with mixed expiries', () async {
      final item1 = TestModel.randomId();
      final item2 = TestModel.randomId();

      when(mockItemsBox.toMap).thenReturn({item1.id: item1, item2.id: item2});
      when(
        mockItemsExpiryBox.toMap,
      ).thenReturn({
        item1.id: DateTime.now().add(const Duration(days: 1)),
        item2.id: DateTime.now().subtract(const Duration(days: 1)),
      });
      final readResult = await source.getItems(
        RequestDetails(requestType: .allLocal),
      );
      expect(readResult, isSuccess);
      expect(readResult.itemsOrRaise(), [item1]);
    });
  });
}
