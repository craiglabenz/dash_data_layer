import 'package:data_layer/data_layer.dart';
import 'package:data_layer_hive/data_layer_hive.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../models/test_model.dart';

class MockHive extends Mock implements HiveInterface {}

class MockIdsBox extends Mock implements Box<Set<String>> {}

class MockItemsBox extends Mock implements Box<TestModel> {}

// Cannot pre-type Maps with Hive
// ignore: strict_raw_type
class MockPaginationCacheBox extends Mock implements Box<Map> {}

void main() {
  final details = RequestDetails();

  group('HiveSource', () {
    late HiveSource<TestModel> source;
    late HiveInterface mockHive;
    late Box<TestModel> mockItemsBox;
    late Box<Set<String>> mockIdsBox;

    // Cannot pre-type Maps with Hive
    // ignore: strict_raw_type
    late Box<Map> mockPaginationCacheBox;

    setUp(() async {
      mockHive = MockHive();
      mockItemsBox = MockItemsBox();
      mockIdsBox = MockIdsBox();
      mockPaginationCacheBox = MockPaginationCacheBox();
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
      ).thenAnswer((_) => Future.value(mockIdsBox));
      when(
        // ignore: strict_raw_type
        () => mockHive.openBox<Map>(any(that: isA<String>())),
      ).thenAnswer((_) => Future.value(mockPaginationCacheBox));
      await source.ready;
    });

    test('initializes correctly', () async {
      expect(source.isReady, isTrue);
    });

    test('setItem and getById', () async {
      final item = TestModel.randomId();

      when(() => mockItemsBox.get(item.id)).thenReturn(null);
      when(
        () => mockItemsBox.put(item.id, item),
      ).thenAnswer((_) => Future.value());

      final writeResult = await source.setItem(item, details);
      expect(writeResult, isSuccess);
    });

    test('setItems and getByIds', () async {
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
        () => mockIdsBox.put(details.cacheKey, {item1.id!, item2.id!}),
      ).thenAnswer((_) => Future.value());

      final writeResult = await source.setItems(items, details);
      expect(writeResult, isSuccess);
    });

    test('deleteIds', () async {
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

      // Mock cache interactions for deleteIds
      when(() => mockIdsBox.keys).thenReturn([]);
      when(() => mockPaginationCacheBox.keys).thenReturn([]);
      when(() => mockIdsBox.clear()).thenAnswer((_) => Future.value(0));
      when(
        () => mockPaginationCacheBox.clear(),
      ).thenAnswer((_) => Future.value(0));

      await source.deleteIds(ids);

      verify(() => mockItemsBox.deleteAll(ids)).called(1);
    });

    test('clear', () async {
      when(() => mockItemsBox.clear()).thenAnswer((_) => Future.value(0));
      when(() => mockIdsBox.clear()).thenAnswer((_) => Future.value(0));
      when(
        () => mockPaginationCacheBox.clear(),
      ).thenAnswer((_) => Future.value(0));

      await source.clear();

      verify(() => mockItemsBox.clear()).called(1);
      verify(() => mockIdsBox.clear()).called(1);
      verify(() => mockPaginationCacheBox.clear()).called(1);
    });
  });

  group('HiveItemsPersistence', () {
    late HiveItemsPersistence<TestModel> persistence;
    late HiveInterface mockHive;
    late Box<TestModel> mockItemsBox;

    setUp(() async {
      mockHive = MockHive();
      mockItemsBox = MockItemsBox();

      when(
        () => mockHive.openBox<TestModel>(any()),
      ).thenAnswer((_) => Future.value(mockItemsBox));

      persistence = HiveItemsPersistence(
        'test_box',
        TestModel.bindings.getId,
        Future.value(),
        hive: mockHive,
      );
      await persistence.ready;
    });

    test('initializes correctly', () async {
      expect(persistence.isReady, isTrue);
    });

    test('setItem and getById', () async {
      final item = TestModel.randomId();

      when(() => mockItemsBox.get(item.id)).thenReturn(null);
      when(
        () => mockItemsBox.put(item.id, item),
      ).thenAnswer((_) => Future.value());

      await persistence.setItem(item, shouldOverwrite: true);
      verify(() => mockItemsBox.put(item.id, item)).called(1);

      when(() => mockItemsBox.get(item.id)).thenReturn(item);
      final result = await persistence.getById(item.id!);
      expect(result, equals(item));
    });

    test('setItems and getByIds', () async {
      final item1 = TestModel.randomId();
      final item2 = TestModel.randomId();
      final items = [item1, item2];

      when(() => mockItemsBox.get(item1)).thenReturn(null);
      when(
        () => mockItemsBox.put(item1.id, item1),
      ).thenAnswer((_) => Future.value());
      when(() => mockItemsBox.get(item2)).thenReturn(null);
      when(
        () => mockItemsBox.put(item2.id, item2),
      ).thenAnswer((_) => Future.value());

      await persistence.setItems(items, shouldOverwrite: true);
      verify(() => mockItemsBox.put(item1.id, item1)).called(1);
      verify(() => mockItemsBox.put(item2.id, item2)).called(1);

      when(() => mockItemsBox.get(item1.id)).thenReturn(item1);
      when(() => mockItemsBox.get(item2.id)).thenReturn(item2);

      final result = await persistence.getByIds({item1.id!, item2.id!});
      expect(result, containsAll(items));
    });

    test('deleteIds', () async {
      final ids = {'id1', 'id2'};
      when(
        () => mockItemsBox.deleteAll(ids),
      ).thenAnswer((_) => Future.value());

      await persistence.deleteIds(ids);
      verify(() => mockItemsBox.deleteAll(ids)).called(1);
    });
  });

  group('HiveCachePersistence', () {
    late HiveCachePersistence persistence;
    late HiveInterface mockHive;
    late Box<Set<String>> mockIdsBox;
    // Cannot pre-type Maps with Hive
    // ignore: strict_raw_type
    late Box<Map> mockPaginationCacheBox;

    setUp(() async {
      mockHive = MockHive();
      mockIdsBox = MockIdsBox();
      mockPaginationCacheBox = MockPaginationCacheBox();

      when(
        () => mockHive.openBox<Set<String>>(any(that: isA<String>())),
      ).thenAnswer((_) => Future.value(mockIdsBox));
      when(
        // ignore: strict_raw_type
        () => mockHive.openBox<Map>(any(that: isA<String>())),
      ).thenAnswer((_) => Future.value(mockPaginationCacheBox));

      persistence = HiveCachePersistence(
        'test_cache_box',
        Future.value(),
        hive: mockHive,
      );
      await persistence.ready;
    });

    test('initializes correctly', () async {
      expect(persistence.isReady, isTrue);
    });

    test('setCacheKey and getCacheKey', () async {
      const key = 'test_key';
      const ids = {'id1', 'id2'};

      when(
        () => mockIdsBox.put(key, ids),
      ).thenAnswer((_) => Future.value());

      await persistence.setCacheKey(key, ids);
      verify(() => mockIdsBox.put(key, ids)).called(1);

      when(() => mockIdsBox.get(key)).thenReturn(ids);
      final result = await persistence.getCacheKey(key);
      expect(result, equals(ids));
    });

    test('setPaginatedCacheKey and getPaginatedCacheKey', () async {
      const noPaginationKey = 'no_page_key';
      const cacheKey = 'page_1_key';
      const ids = {'id1', 'id2'};
      const pagesMetadata = <String, Set<String>>{cacheKey: ids};

      when(() => mockPaginationCacheBox.get(noPaginationKey)).thenReturn(null);
      when(
        () => mockPaginationCacheBox.put(noPaginationKey, any()),
      ).thenAnswer((_) => Future.value());

      await persistence.setPaginatedCacheKey(
        noPaginationCacheKey: noPaginationKey,
        cacheKey: cacheKey,
        ids: ids,
      );
      verify(
        () => mockPaginationCacheBox.put(noPaginationKey, pagesMetadata),
      ).called(1);

      when(
        () => mockPaginationCacheBox.get(noPaginationKey),
      ).thenReturn(pagesMetadata);

      final result = await persistence.getPaginatedCacheKey(
        noPaginationCacheKey: noPaginationKey,
        cacheKey: cacheKey,
      );
      expect(result, equals(ids));
    });

    test('clearCacheKey', () async {
      const key = 'test_key';
      when(
        () => mockIdsBox.delete(key),
      ).thenAnswer((_) => Future.value());

      await persistence.clearCacheKey(key);
      verify(() => mockIdsBox.delete(key)).called(1);
    });

    test('clearPaginatedCacheKey', () async {
      const noPaginationKey = 'no_page_key';
      when(
        () => mockPaginationCacheBox.delete(noPaginationKey),
      ).thenAnswer((_) => Future.value());

      await persistence.clearPaginatedCacheKey(
        noPaginationCacheKey: noPaginationKey,
      );
      verify(() => mockPaginationCacheBox.delete(noPaginationKey)).called(1);
    });
  });
}
