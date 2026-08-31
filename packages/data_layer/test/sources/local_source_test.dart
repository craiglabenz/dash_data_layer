import 'package:data_layer/data_layer.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import '../models/test_model.dart';
import 'operation_builders.dart';

class MockItemsCache extends Mock implements ExpiringCache<TestModel> {}

class MockRequestCache extends Mock implements ExpiringCache<Set<String>> {}

final details = RequestDetails();
final abcDetails = RequestDetails(
  filter: const MsgStartsWithFilter('abc'),
);
final paginationDetails = RequestDetails(
  pagination: Pagination.page(1),
);
final page2Details = RequestDetails(
  pagination: Pagination.page(2),
);
const item = TestModel(id: 'item 1');
const item2 = TestModel(id: 'item 2');
const item3 = TestModel(id: 'item 3');

const allItemsByIds = <String, TestModel>{
  'item 1': item,
  'item 2': item2,
  'item 3': item3,
};
const items1and2ByIds = <String, TestModel>{
  'item 1': item,
  'item 2': item2,
};
const items2and3ByIds = <String, TestModel>{
  'item 2': item2,
  'item 3': item3,
};
const items1And3ByIds = <String, TestModel>{
  'item 1': item,
  'item 3': item3,
};

void main() {
  late LocalSource<TestModel> source;

  late MockItemsCache mockItemsCache;
  late MockRequestCache mockRequestCache;
  late MockRequestCache mockPaginatedRequestCache;
  setUp(() {
    mockItemsCache = MockItemsCache();
    mockRequestCache = MockRequestCache();
    mockPaginatedRequestCache = MockRequestCache();
    source = LocalSource<TestModel>(
      bindings: TestModel.bindings,
      itemsCache: mockItemsCache,
      requestCache: mockRequestCache,
      paginatedRequestCache: mockPaginatedRequestCache,
    );
  });

  group('LocalMemorySource.setItem should', () {
    test('save items', () async {
      when(() => mockItemsCache.write(item.id!, item)).thenAnswer((_) async {});
      await source.setItem(gwo(item, details));
      verify(() => mockItemsCache.write(item.id!, item)).called(1);

      when(
        () => mockItemsCache.write(item2.id!, item2),
      ).thenAnswer((_) async {});
      await source.setItem(gwo(item2, abcDetails));
      verify(() => mockItemsCache.write(item2.id!, item2)).called(1);

      // setItem never writes cache info - only setItems can do that
      verifyNever(() => mockRequestCache.write(details.cacheKey, any()));
      verifyNever(() => mockRequestCache.write(abcDetails.cacheKey, any()));
    });

    test('accept items twice', () async {
      when(() => mockItemsCache.write(item.id!, item)).thenAnswer((_) async {});
      await source.setItem(gwo(item, details));
      verify(() => mockItemsCache.write(item.id!, item)).called(1);

      when(() => mockItemsCache.write(item.id!, item)).thenAnswer((_) async {});
      await source.setItem(gwo(item, details));
      verify(() => mockItemsCache.write(item.id!, item)).called(1);

      verifyNever(() => mockRequestCache.write(details.cacheKey, any()));
    });

    test('overwrite', () async {
      when(() => mockItemsCache.write(item.id!, item)).thenAnswer((_) async {});
      await source.setItem(gwo(item, details));
      verify(() => mockItemsCache.write(item.id!, item)).called(1);

      final itemTake2 = TestModel(id: item.id, msg: 'different');
      when(
        () => mockItemsCache.write(itemTake2.id!, itemTake2),
      ).thenAnswer((_) async {});
      await source.setItem(gwo(itemTake2, details));
      verify(() => mockItemsCache.write(itemTake2.id!, itemTake2)).called(1);
    });

    test('not cache pagination info', () async {
      final deets = RequestDetails(pagination: Pagination.page(2));
      final item = TestModel.randomId();

      when(() => mockItemsCache.write(item.id!, item)).thenAnswer((_) async {});
      // setItem never writes cache info - only setItems can do that
      await source.setItem(gwo(item, deets));
      verify(() => mockItemsCache.write(item.id!, item)).called(1);

      verifyNever(
        () => mockRequestCache.write(deets.cacheKey, any()),
      ).called(0);
    });
  });

  group('LocalMemorySource.setItems should', () {
    test('set items', () async {
      when(
        () => mockItemsCache.multiWrite(items1and2ByIds),
      ).thenAnswer((_) async {});
      when(
        () => mockRequestCache.write(details.cacheKey, <String>{
          item.id!,
          item2.id!,
        }),
      ).thenAnswer((_) async {});
      when(
        () => mockRequestCache.read(details.cacheKey),
      ).thenAnswer((_) async => <String>{});
      when(
        () => mockRequestCache.readAll(),
      ).thenAnswer(
        (_) async => {
          details.cacheKey: {item.id!, item2.id!},
        },
      );

      await source.setItems(gwlo([item, item2], details));
      verify(() => mockItemsCache.multiWrite(items1and2ByIds)).called(1);

      when(
        () => mockItemsCache.multiWrite(items2and3ByIds),
      ).thenAnswer((_) async {});
      when(
        () => mockRequestCache.write(details.cacheKey, <String>{
          item2.id!,
          item3.id!,
        }),
      ).thenAnswer((_) async {});
      await source.setItems(gwlo([item2, item3], details));
      verify(() => mockItemsCache.multiWrite(items2and3ByIds)).called(1);
    });

    test('set items with pagination', () async {
      when(
        () => mockItemsCache.multiWrite(items1and2ByIds),
      ).thenAnswer((_) async {});
      when(
        () => mockPaginatedRequestCache.read(
          paginationDetails.noPaginationCacheKey,
        ),
      ).thenAnswer((_) async => {});
      when(
        () => mockPaginatedRequestCache.write(
          paginationDetails.noPaginationCacheKey,
          <String>{paginationDetails.cacheKey},
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockRequestCache.write(paginationDetails.cacheKey, <String>{
          item.id!,
          item2.id!,
        }),
      ).thenAnswer((_) async {});
      when(
        () => mockRequestCache.read(paginationDetails.cacheKey),
      ).thenAnswer((_) async => <String>{});
      when(
        () => mockRequestCache.readAll(),
      ).thenAnswer(
        (_) async => {
          details.cacheKey: {item.id!, item2.id!},
        },
      );

      await source.setItems(gwlo([item, item2], paginationDetails));
    });

    test('set items with filters', () async {
      when(
        () => mockItemsCache.multiWrite(items2and3ByIds),
      ).thenAnswer((_) async {});
      when(
        () => mockRequestCache.write(abcDetails.cacheKey, <String>{
          item2.id!,
          item3.id!,
        }),
      ).thenAnswer((_) async {});
      when(
        () => mockRequestCache.read(abcDetails.cacheKey),
      ).thenAnswer((_) async => <String>{});
      when(
        () => mockRequestCache.readAll(),
      ).thenAnswer(
        (_) async => {
          abcDetails.cacheKey: {item2.id!, item3.id!},
        },
      );

      await source.setItems(gwlo([item2, item3], abcDetails));
    });

    // test('remove existing items not in new batch', () async {
    //   when(
    //     () => mockItemsCache.multiWrite(allItemsByIds),
    //   ).thenAnswer((_) async {});
    //   when(
    //     () => mockRequestCache.write(abcDetails.cacheKey, <String>{
    //       item.id!,
    //       item2.id!,
    //       item3.id!,
    //     }),
    //   ).thenAnswer((_) async {});
    //   await source.setItems(gwlo([item2, item3], abcDetails));
    // });
  });

  group('LocalMemorySource.getById should', () {
    test('throw for filters or pagination', () async {
      expect(
        () => source.getById(gro(item.id!, abcDetails)),
        _throwsAssertionError,
      );
    });

    test('return known items', () async {
      when(() => mockItemsCache.read(item.id!)).thenAnswer((_) async => item);
      await source.getById(gro(item.id!, details));
      verify(() => mockItemsCache.read(item.id!)).called(1);
    });

    test('return empty ReadSuccess for unknown items', () async {
      when(() => mockItemsCache.read(item.id!)).thenAnswer((_) async => null);
      final result = await source.getById(gro(item.id!, details));
      expect(result, isA<ReadSuccess<TestModel>>());
      expect(result.itemOrRaise(), isNull);
      verify(() => mockItemsCache.read(item.id!)).called(1);
    });

    test('NOT honor request details', () async {
      when(() => mockItemsCache.write(item.id!, item)).thenAnswer((_) async {});
      await source.setItem(gwo(item, details));
      verifyNever(() => mockRequestCache.write(details.cacheKey, any()));
    });

    test('NOT honor pagination', () async {
      when(() => mockItemsCache.write(item.id!, item)).thenAnswer((_) async {});
      await source.setItem(gwo(item, paginationDetails));
      verifyNever(
        () => mockRequestCache.write(paginationDetails.cacheKey, any()),
      );
    });
  });

  group('LocalMemorySource.getByIds should', () {
    test('throw for filters or pagination', () async {
      expect(
        () => source.getByIds(grido({item.id!}, abcDetails)),
        _throwsAssertionError,
      );
    });

    test('return items', () async {
      when(
        () => mockItemsCache.multiRead({item.id!, item2.id!}),
      ).thenAnswer((_) async => items1and2ByIds);
      final maybeResult = await source.getByIds(
        grido({item.id!, item2.id!}, details),
      );
      expect(maybeResult, isA<ReadListSuccess<TestModel>>());
      verify(() => mockItemsCache.multiRead({item.id!, item2.id!})).called(1);
    });

    test('return items for partial hits', () async {
      when(
        () => mockItemsCache.multiRead({item.id!, item2.id!, item3.id!}),
      ).thenAnswer((_) async => allItemsByIds);
      final maybeResult = await source.getByIds(
        grido({item.id!, item2.id!, item3.id!}, details),
      );
      expect(maybeResult, isA<ReadListSuccess<TestModel>>());
      verify(
        () => mockItemsCache.multiRead({item.id!, item2.id!, item3.id!}),
      ).called(1);
    });
  });

  group('LocalMemorySource.getItems should', () {
    test('return items', () async {
      when(
        () => mockRequestCache.read(details.cacheKey),
      ).thenAnswer((_) async => items1And3ByIds.keys.toSet());
      when(
        () => mockItemsCache.multiRead(items1And3ByIds.keys.toSet()),
      ).thenAnswer((_) async => items1And3ByIds);
      final maybeResult = await source.getItems(grlo(details));
      expect(
        maybeResult,
        ReadListResult<TestModel>.fromList(
          items1And3ByIds.values.toList(),
          details,
          {},
          TestModel.bindings.getId,
        ),
      );
    });

    test('return no items from custom filter if empty', () async {
      final xyzDetails = RequestDetails(
        filter: const MsgStartsWithFilter('xyz'),
      );
      when(
        () => mockRequestCache.read(xyzDetails.cacheKey),
      ).thenAnswer((_) async => null);

      final maybeResult = await source.getItems(grlo(xyzDetails));
      expect(maybeResult, isA<ReadListSuccess<TestModel>>());
      expect(
        (maybeResult as ReadListSuccess<TestModel>).itemsOrRaise(),
        isEmpty,
      );
    });

    test(
      'return no items from filter when other requests have items',
      () async {
        when(
          () => mockRequestCache.read(details.cacheKey),
        ).thenAnswer((_) async => items1And3ByIds.keys.toSet());
        when(
          () => mockItemsCache.multiRead(items1And3ByIds.keys.toSet()),
        ).thenAnswer((_) async => items1And3ByIds);
        when(
          () => mockRequestCache.read(abcDetails.cacheKey),
        ).thenAnswer((_) async => null);
        final maybeResult = await source.getItems(grlo(abcDetails));
        expect(maybeResult, isA<ReadListSuccess<TestModel>>());
        expect(
          (maybeResult as ReadListSuccess<TestModel>).itemsOrRaise(),
          isEmpty,
        );
      },
    );
  });

  group('LocalMemorySource.delete should', () {
    test('delete items', () async {
      when(
        () => mockItemsCache.multiDelete(<String>{item.id!}),
      ).thenAnswer((_) async {});
      when(
        () => mockRequestCache.readAll(),
      ).thenAnswer((_) async => <CacheKey, Set<String>>{});
      when(
        mockPaginatedRequestCache.readAll,
      ).thenAnswer((_) async => <CacheKey, Set<String>>{});
      await source.deleteItem(gdo(item.id!, details));
      verify(
        () => mockItemsCache.multiDelete(<String>{item.id!}),
      ).called(1);
    });

    test('delete items and delete empty pages', () async {
      when(
        () => mockItemsCache.multiDelete(<String>{item.id!}),
      ).thenAnswer((_) async {});

      // details points to just this item
      when(
        () => mockRequestCache.readAll(),
      ).thenAnswer(
        (_) async => <CacheKey, Set<String>>{
          details.cacheKey: {item.id!},
        },
      );

      when(
        mockPaginatedRequestCache.readAll,
      ).thenAnswer((_) async => <CacheKey, Set<String>>{});

      // Prepare deletion
      when(
        () => mockRequestCache.delete(details.cacheKey),
      ).thenAnswer((_) async {});

      await source.deleteItem(gdo(item.id!, details));

      // The item was deleted
      verify(
        () => mockItemsCache.multiDelete(<String>{item.id!}),
      ).called(1);

      // Confirm empty page was in fact dropped
      verify(
        () => mockRequestCache.delete(details.cacheKey),
      ).called(1);
    });

    test('delete items and persist non-empty pages', () async {
      when(
        () => mockItemsCache.multiDelete(<String>{item.id!}),
      ).thenAnswer((_) async {});

      // details points to just this item
      when(
        () => mockRequestCache.readAll(),
      ).thenAnswer(
        (_) async => <CacheKey, Set<String>>{
          details.cacheKey: {item.id!, item2.id!},
        },
      );

      when(
        mockPaginatedRequestCache.readAll,
      ).thenAnswer((_) async => <CacheKey, Set<String>>{});

      // Prepare deletion
      when(
        () => mockRequestCache.delete(details.cacheKey),
      ).thenAnswer((_) async {});

      // Prepare update
      when(
        () => mockRequestCache.write(details.cacheKey, {item2.id!}),
      ).thenAnswer((_) async {});

      await source.deleteItem(gdo(item.id!, details));

      // The item was deleted
      verify(
        () => mockItemsCache.multiDelete(<String>{item.id!}),
      ).called(1);

      // But deletion is never called
      verifyNever(() => mockRequestCache.delete(details.cacheKey));

      // Instead, update is called
      verify(
        () => mockRequestCache.write(details.cacheKey, {item2.id!}),
      ).called(1);
    });

    test('delete items clear pagination clusters', () async {
      when(
        () => mockItemsCache.multiDelete(<String>{item.id!, item2.id!}),
      ).thenAnswer((_) async {});

      when(
        () => mockRequestCache.readAll(),
      ).thenAnswer(
        (_) async => <CacheKey, Set<String>>{
          paginationDetails.cacheKey: {item.id!, item2.id!},
        },
      );

      // Set up a pagination cluster that will be empty after `item` is removed
      when(mockPaginatedRequestCache.readAll).thenAnswer(
        (_) async => {
          paginationDetails.noPaginationCacheKey: {paginationDetails.cacheKey},
        },
      );
      // Prepare deletion of the pagination cluster
      when(
        () => mockPaginatedRequestCache.delete(
          paginationDetails.noPaginationCacheKey,
        ),
      ).thenAnswer((_) async {});

      // Prepare deletion
      when(
        () => mockRequestCache.delete(paginationDetails.cacheKey),
      ).thenAnswer((_) async {});

      await source.deleteIds(<String>{item.id!, item2.id!});

      // The items were deleted
      verify(
        () => mockItemsCache.multiDelete(<String>{item.id!, item2.id!}),
      ).called(1);

      // The pagination cluster was deleted
      verify(
        () => mockPaginatedRequestCache.delete(
          paginationDetails.noPaginationCacheKey,
        ),
      ).called(1);
    });

    test('delete items leave non-empty pagination clusters', () async {
      when(
        () => mockItemsCache.multiDelete(<String>{item.id!, item2.id!}),
      ).thenAnswer((_) async {});

      when(
        () => mockRequestCache.readAll(),
      ).thenAnswer(
        (_) async => <CacheKey, Set<String>>{
          paginationDetails.cacheKey: {item.id!, item2.id!},
          page2Details.cacheKey: {item3.id!},
        },
      );

      // Set up a pagination cluster that will be non-empty after  items are
      // removed
      when(mockPaginatedRequestCache.readAll).thenAnswer(
        (_) async => {
          paginationDetails.noPaginationCacheKey: {
            paginationDetails.cacheKey,
            page2Details.cacheKey,
          },
        },
      );
      // Prepare deletion
      when(
        () => mockRequestCache.delete(paginationDetails.cacheKey),
      ).thenAnswer((_) async {});

      await source.deleteIds(<String>{item.id!, item2.id!});

      // The items were deleted
      verify(
        () => mockItemsCache.multiDelete(<String>{item.id!, item2.id!}),
      ).called(1);

      // The pagination cluster was left alone
      verifyNever(
        () => mockPaginatedRequestCache.delete(
          paginationDetails.noPaginationCacheKey,
        ),
      );
    });
  });

  group('LocalSource.notReferencedByAnyRequests should', () {
    test(
      'return an empty set when all keys are referenced by a request',
      () async {
        when(
          () => mockRequestCache.readAll(),
        ).thenAnswer(
          (_) async => <CacheKey, Set<String>>{
            details.cacheKey: {item.id!, item2.id!},
            abcDetails.cacheKey: {item2.id!, item3.id!},
          },
        );
        final result = await source.notReferencedByAnyRequests(
          <String>{item.id!, item2.id!, item3.id!},
        );
        expect(result, <String>{});
      },
    );

    test('return keys not referenced by any requests', () async {
      when(
        () => mockRequestCache.readAll(),
      ).thenAnswer(
        (_) async => <CacheKey, Set<String>>{
          details.cacheKey: {item.id!, item2.id!},
          abcDetails.cacheKey: {item2.id!},
        },
      );
      final result = await source.notReferencedByAnyRequests(
        <String>{item.id!, item2.id!, item3.id!},
      );
      expect(result, <String>{item3.id!});
    });
  });
}

final Matcher _throwsAssertionError = throwsA(isA<AssertionError>());
