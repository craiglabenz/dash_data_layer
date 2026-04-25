import 'package:data_layer/data_layer.dart';
import 'package:data_layer_hive/data_layer_hive.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../operation_builders.dart';
import '../models/test_model.dart';

class MockHive extends Mock implements HiveInterface {}

class MockRequestBox extends Mock implements Box<Set<String>> {}

class MockItemsBox extends Mock implements Box<TestModel> {}

class MockDateTimeBox extends Mock implements Box<DateTime> {}

void main() {
  final details = RequestDetails();

  group('HiveSource via LocalSource.builders', () {
    late LocalSource<TestModel> source;
    late HiveInterface mockHive;
    late Box<TestModel> mockItemsBox;
    late Box<Set<String>> mockRequestBox;
    late Box<DateTime> mockRequestCacheKeyExpiryBox;
    late Box<DateTime> mockItemsExpiryBox;

    setUp(() async {
      mockHive = MockHive();
      mockItemsBox = MockItemsBox();
      mockRequestBox = MockRequestBox();
      mockRequestCacheKeyExpiryBox = MockDateTimeBox();
      mockItemsExpiryBox = MockDateTimeBox();

      final hiveInit = Future<void>.value();

      source = LocalSource.builders<TestModel>(
        bindings: TestModel.bindings,
        itemCache: (name) =>
            HiveCache<TestModel>(name, hiveInit, hive: mockHive),
        stringSetCache: (name) =>
            HiveCache<Set<String>>(name, hiveInit, hive: mockHive),
        dateTimeCache: (name) =>
            HiveCache<DateTime>(name, hiveInit, hive: mockHive),
      );

      when(
        () => mockHive.openBox<TestModel>(any()),
      ).thenAnswer((_) => Future.value(mockItemsBox));

      when(
        () => mockHive.openBox<Set<String>>(any()),
      ).thenAnswer((_) => Future.value(mockRequestBox));

      when(
        () => mockHive.openBox<DateTime>(any()),
      ).thenAnswer((_) => Future.value(mockRequestCacheKeyExpiryBox));

      when(() => mockItemsBox.toMap()).thenReturn({});
      when(() => mockItemsExpiryBox.toMap()).thenReturn({});
      when(() => mockRequestBox.toMap()).thenReturn({});
      when(() => mockRequestCacheKeyExpiryBox.toMap()).thenReturn({});
    });

    test(
      'setItem and getById',
      () async {
        final item = TestModel.randomId();

        when(() => mockItemsBox.get(item.id)).thenReturn(null);
        when(
          () => mockItemsBox.put(item.id, item),
        ).thenAnswer((_) => Future.value());

        final writeResult = await source.setItem(gwo(item, details));
        expect(writeResult, isSuccess);

        when(() => mockItemsBox.get(item.id)).thenReturn(item);
        final readResult = await source.getById(gro(item.id!, details));
        expect(readResult, isSuccess);
        expect((readResult as ReadSuccess<TestModel>).item, item);
      },
    );

    test('delete removes item from cache', () async {
      final item = TestModel.randomId();

      when(
        () => mockItemsBox.deleteAll(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockItemsExpiryBox.deleteAll(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockRequestBox.deleteAll(any()),
      ).thenAnswer((_) => Future.value());
      when(
        () => mockRequestCacheKeyExpiryBox.deleteAll(any()),
      ).thenAnswer((_) => Future.value());

      when(() => mockRequestBox.keys).thenReturn([]);

      final deleteResult = await source.delete(gdo(item.id!, details));
      expect(deleteResult, isSuccess);
      verify(() => mockItemsBox.deleteAll(any())).called(1);
    });
  });
}
