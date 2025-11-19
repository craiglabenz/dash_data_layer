import 'package:data_layer/data_layer.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import '../models/test_model.dart';

class MockCachePersistence extends Mock implements CachePersistence {}

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

void main() {
  late LocalSource<TestModel> mem;
  late LocalSource<TestModel> mockMem;
  late MockCachePersistence cache;
  const item = TestModel(id: 'item 1');
  const item2 = TestModel(id: 'item 2');
  const item3 = TestModel(id: 'item 3');

  group('LocalMemorySource.setItem should', () {
    late LocalMemorySource<TestModel> idSettingMem;
    setUp(() {
      cache = MockCachePersistence();
      mem = LocalSource<TestModel>(
        InMemorySourcePersistence<TestModel>(
          TestModel.bindings.getId,
        ),
        InMemoryCachePersistence(),
        bindings: TestModel.bindings,
      );
      mockMem = LocalSource<TestModel>(
        InMemorySourcePersistence<TestModel>(TestModel.bindings.getId),
        cache,
        bindings: TestModel.bindings,
      );
      idSettingMem = LocalMemorySource<TestModel>(
        bindings: TestModel.bindings,
        idBuilder: (item) => 'new',
      );
    });

    test('save items', () async {
      await mem.setItem(item, details);
      await fullyContains(mem, [item], requests: []);

      await mem.setItem(item2, abcDetails);
      await fullyContains(mem, [item2], requests: []);

      await mockMem.setItem(item, details);
      await mockMem.setItem(item2, abcDetails);
      verifyNever(() => cache.setCacheKey(details.cacheKey, any()));
    });

    test('accept items twice', () async {
      await mem.setItem(item, details);
      await fullyContains(mem, [item], requests: []);

      await mem.setItem(item, details);
      await fullyContains(mem, [item], requests: []);

      await mockMem.setItem(item, details);
      await mockMem.setItem(item, details);
      verifyNever(() => cache.setCacheKey(details.cacheKey, any()));
    });

    test('overwrite', () async {
      await mem.setItem(item, details);
      await fullyContains(mem, [item], requests: []);

      const itemTake2 = TestModel(id: 'item 1', msg: 'different');
      await mem.setItem(itemTake2, details);
      await fullyContains(mem, [itemTake2], requests: []);
    });

    test('honor overwrite=False', () async {
      await mem.setItem(item, details);
      await fullyContains(mem, [item], requests: []);

      const itemTake2 = TestModel(id: 'item 1', msg: 'different');
      await mem.setItem(itemTake2, RequestDetails(shouldOverwrite: false));
      await fullyContains(mem, [item], requests: []);
    });

    test('not cache pagination info', () async {
      final deets = RequestDetails(
        pagination: Pagination.page(2),
      );
      final item = TestModel.randomId();
      await mem.setItem(item, deets);

      // setItem never writes cache info - only setItems can do that
      await mockMem.setItem(item, deets);
      verifyNever(() => cache.setCacheKey(deets.cacheKey, any())).called(0);
      verifyNever(
        () => cache.setPaginatedCacheKey(
          noPaginationCacheKey: any(named: 'noPaginationCacheKey'),
          cacheKey: any(named: 'cacheKey'),
          ids: any(named: 'ids'),
        ),
      );
    });

    test('set Ids', () async {
      const item = TestModel(id: null, msg: 'hello');
      final result = await idSettingMem.setItem(item, details);
      expect(result.getOrRaise().item.id, 'new');
    });
  });

  group('LocalMemorySource.setItems should', () {
    setUp(() {
      cache = MockCachePersistence();
      mem = LocalSource<TestModel>(
        InMemorySourcePersistence<TestModel>(TestModel.bindings.getId),
        InMemoryCachePersistence(),
        bindings: TestModel.bindings,
      );
      mockMem = LocalSource<TestModel>(
        InMemorySourcePersistence<TestModel>(TestModel.bindings.getId),
        cache,
        bindings: TestModel.bindings,
      );
    });

    test('set items', () async {
      const item2 = TestModel(id: 'item 2');
      await mem.setItems([item, item2], details);
      await fullyContains(mem, [item, item2], requests: [details]);

      await mem.setItems([item2, item3], details);
      await fullyContains(mem, [item], requests: []);
      await fullyContains(mem, [item2, item3], requests: [details]);
    });

    test('set items mocked', () async {
      const item2 = TestModel(id: 'item 2');
      await mockMem.setItems([item, item2], details);
      // Called a first time
      verify(() => cache.setCacheKey(details.cacheKey, any())).called(1);

      await mockMem.setItems([item2, item3], details);
      // Called again
      verify(() => cache.setCacheKey(details.cacheKey, any())).called(1);
    });

    test('set items with in waves with all pagination', () async {
      await mem.setItems([item, item2], paginationDetails);
      await fullyContains(mem, [item, item2], requests: [paginationDetails]);

      await mem.setItems([item2, item3], paginationDetails);
      await notInCache(mem, [item], requests: [details, paginationDetails]);
      await fullyContains(mem, [item2], requests: [paginationDetails]);
      await fullyContains(mem, [item3], requests: [paginationDetails]);
    });

    test('set items with in waves with all pagination [mock mem]', () async {
      await mockMem.setItems([item, item2], paginationDetails);
      verifyNever(() => cache.setCacheKey(paginationDetails.cacheKey, any()));
      verify(
        () => cache.setPaginatedCacheKey(
          noPaginationCacheKey: any(
            named: 'noPaginationCacheKey',
            that: equals(paginationDetails.noPaginationCacheKey),
          ),
          cacheKey: any(
            named: 'cacheKey',
            that: equals(paginationDetails.cacheKey),
          ),
          ids: any(
            named: 'ids',
            that: equals({item.id!, item2.id!}),
          ),
        ),
      ).called(1);

      await mockMem.setItems([item2, item3], paginationDetails);

      verifyNever(() => cache.setCacheKey(paginationDetails.cacheKey, any()));
      verify(
        () => cache.setPaginatedCacheKey(
          noPaginationCacheKey: any(
            named: 'noPaginationCacheKey',
            that: equals(paginationDetails.noPaginationCacheKey),
          ),
          cacheKey: any(
            named: 'cacheKey',
            that: equals(paginationDetails.cacheKey),
          ),
          ids: any(
            named: 'ids',
            that: equals({item2.id!, item3.id!}),
          ),
        ),
      ).called(1);
    });

    test('set items with pagination then without [real mem]', () async {
      await mem.setItems([item, item2], paginationDetails);
      await fullyContains(mem, [item, item2], requests: [paginationDetails]);

      await mem.setItems([item2, item3], details);
      await notInCache(mem, [item], requests: [details]);
      await fullyContains(mem, [item], requests: [paginationDetails]);
      await fullyContains(mem, [item2], requests: [details, paginationDetails]);
      await fullyContains(mem, [item3], requests: [details]);
    });

    test('set items with pagination then without [mock mem]', () async {
      await mockMem.setItems([item, item2], paginationDetails);
      verifyNever(() => cache.setCacheKey(paginationDetails.cacheKey, any()));
      verify(
        () => cache.setPaginatedCacheKey(
          noPaginationCacheKey: any(
            named: 'noPaginationCacheKey',
            that: equals(paginationDetails.noPaginationCacheKey),
          ),
          cacheKey: any(
            named: 'cacheKey',
            that: equals(paginationDetails.cacheKey),
          ),
          ids: any(
            named: 'ids',
            that: equals({item.id!, item2.id!}),
          ),
        ),
      ).called(1);

      await mockMem.setItems([item2, item3], details);
      verify(
        () => cache.setCacheKey(details.cacheKey, {item2.id!, item3.id!}),
      ).called(1);
      verifyNever(
        () => cache.setPaginatedCacheKey(
          noPaginationCacheKey: any(named: 'noPaginationCacheKey'),
          cacheKey: any(named: 'cacheKey'),
          ids: any(named: 'ids'),
        ),
      );
    });

    test(
      'set items with all pagination requests different page [real mem]',
      () async {
        await mem.setItems([item, item2], paginationDetails);
        await fullyContains(mem, [item, item2], requests: [paginationDetails]);

        const item3 = TestModel(id: 'item 3');
        await mem.setItems([item3], page2Details);
        await fullyContains(mem, [item, item2], requests: [paginationDetails]);
        await notInCache(mem, [item, item2], requests: [page2Details]);
        await fullyContains(mem, [item3], requests: [page2Details]);
        await notInCache(mem, [item3], requests: [paginationDetails]);
      },
    );

    test(
      'set items with all pagination requests different page [mock mem]',
      () async {
        await mockMem.setItems([item, item2], paginationDetails);
        verifyNever(() => cache.setCacheKey(paginationDetails.cacheKey, any()));
        verify(
          () => cache.setPaginatedCacheKey(
            noPaginationCacheKey: any(
              named: 'noPaginationCacheKey',
              that: equals(paginationDetails.noPaginationCacheKey),
            ),
            cacheKey: any(
              named: 'cacheKey',
              that: equals(paginationDetails.cacheKey),
            ),
            ids: any(
              named: 'ids',
              that: equals({item.id!, item2.id!}),
            ),
          ),
        ).called(1);

        await mockMem.setItems([item3], page2Details);
        verifyNever(() => cache.setCacheKey(page2Details.cacheKey, any()));
        verify(
          () => cache.setPaginatedCacheKey(
            noPaginationCacheKey: any(
              named: 'noPaginationCacheKey',
              that: equals(page2Details.noPaginationCacheKey),
            ),
            cacheKey: any(
              named: 'cacheKey',
              that: equals(page2Details.cacheKey),
            ),
            ids: any(
              named: 'ids',
              that: equals({item3.id!}),
            ),
          ),
        ).called(1);
      },
    );

    test('set items with set name [real mem]', () async {
      await mem.setItems([item, item2], details);
      await fullyContains(mem, [item, item2], requests: [details]);

      await mem.setItems([item2, item3], abcDetails);
      await fullyContains(mem, [item], requests: [details]);
      await fullyContains(mem, [item2], requests: [details, abcDetails]);
      await fullyContains(mem, [item3], requests: [abcDetails]);
    });

    test('set items with set name [mock mem]', () async {
      await mockMem.setItems([item, item2], details);
      verify(
        () => cache.setCacheKey(details.cacheKey, {item.id!, item2.id!}),
      ).called(1);
      verifyNever(
        () => cache.setPaginatedCacheKey(
          noPaginationCacheKey: any(named: 'noPaginationCacheKey'),
          cacheKey: any(named: 'cacheKey'),
          ids: any(named: 'ids'),
        ),
      );

      await mockMem.setItems([item2, item3], abcDetails);
      verify(
        () => cache.setCacheKey(abcDetails.cacheKey, {item2.id!, item3.id!}),
      ).called(1);
      verifyNever(
        () => cache.setPaginatedCacheKey(
          noPaginationCacheKey: any(named: 'noPaginationCacheKey'),
          cacheKey: any(named: 'cacheKey'),
          ids: any(named: 'ids'),
        ),
      );
    });
  });

  group('LocalMemorySource.getById should', () {
    const item2 = TestModel(id: 'item 2');

    setUp(() {
      mem = LocalMemorySource<TestModel>(bindings: TestModel.bindings);
    });

    test('throw for filters or pagination', () async {
      expect(
        () => mem.getById(item.id!, abcDetails),
        _throwsAssertionError,
      );
    });

    test('return known items', () async {
      await mem.setItem(item, details);
      await mem.getById(item.id!, details);
      // no request cache hits bc only [setItems] can do that
      await fullyContains(mem, [item], requests: []);
    });

    test('return empty ReadSuccess for unknown items', () async {
      await mem.setItem(item, details);
      await notInCache(mem, [item2], containsAtAll: false);
    });

    test('NOT honor request details', () async {
      await mem.setItem(item, details);
      await fullyContains(mem, [item], requests: []);

      await mem.setItem(item, abcDetails);
      await fullyContains(mem, [item], requests: []);
    });

    test('NOT honor pagination', () async {
      final page1Deets = RequestDetails(
        pagination: Pagination.page(1),
      );
      final randomIdItem = TestModel.randomId();
      await mem.setItem(randomIdItem, page1Deets);

      // Item exists and is loadable by Id, but is not visible in the
      // getItems payload for `details` (as indicated by the empty list)
      await fullyContains(mem, [randomIdItem], requests: []);
    });
  });

  group('LocalMemorySource.getByIds should', () {
    setUp(() {
      mem = LocalMemorySource<TestModel>(bindings: TestModel.bindings);
    });

    test('throw for filters or pagination', () async {
      expect(
        () => mem.getByIds({item.id!}, abcDetails),
        _throwsAssertionError,
      );
    });

    test('return items', () async {
      await mem.setItems([item, item2], details);
      final maybeResult = await mem.getByIds(
        {item.id!, item2.id!},
        details,
      );
      expect(maybeResult, isA<ReadListSuccess<TestModel>>());
      final result = maybeResult as ReadListSuccess<TestModel>;
      expect(
        result,
        ReadListResult<TestModel>.fromList(
          [item, item2],
          details,
          {},
          TestModel.bindings.getId,
        ),
      );
    });

    test('return items for partial hits', () async {
      await mem.setItems([item, item2], details);
      final maybeResult = await mem.getByIds(
        {item.id!, item2.id!, item3.id!},
        details,
      );
      expect(maybeResult, isA<ReadListSuccess<TestModel>>());
      final result = maybeResult as ReadListSuccess<TestModel>;
      expect(
        result,
        ReadListResult<TestModel>.fromList(
          [item, item2],
          details,
          {item3.id!},
          TestModel.bindings.getId,
        ),
      );
    });
  });

  group('LocalMemorySource.getItems should', () {
    setUp(() {
      mem = LocalMemorySource<TestModel>(bindings: TestModel.bindings);
    });
    test('return items', () async {
      await mem.setItems([item, item2], details);
      final maybeResult = await mem.getItems(details);
      await fullyContains(mem, [item, item2], requests: [details]);
      await notInCache(mem, [item, item2], requests: [abcDetails]);
      await notInCache(
        mem,
        [item3],
        requests: [details, abcDetails],
        containsAtAll: false,
      );
      expect(
        maybeResult,
        ReadListResult<TestModel>.fromList(
          [item, item2],
          details,
          {},
          TestModel.bindings.getId,
        ),
      );
    });

    test('return no items from custom filter if empty', () async {
      await mem.setItems([item, item2], abcDetails);

      final xyzDetails = RequestDetails(
        filter: const MsgStartsWithFilter('xyz'),
      );
      await notInCache(mem, [item, item2], requests: [details, xyzDetails]);
    });

    test('return no items from filter if empty', () async {
      await mem.setItems([item, item2], details);
      await notInCache(mem, [item, item2], requests: [abcDetails]);
    });

    test('return items', () async {
      await mem.setItems([item, item2], details);
      final maybeResult = await mem.getItems(details);
      final result = maybeResult as ReadListSuccess;
      expect(
        result,
        ReadListResult<TestModel>.fromList(
          [item, item2],
          details,
          {},
          TestModel.bindings.getId,
        ),
      );
    });

    test('honor pagination', () async {
      final item = TestModel.randomId();
      final item2 = TestModel.randomId();
      await mem.setItems([item, item2], page2Details);

      await fullyContains(mem, [item, item2], requests: [page2Details]);
      await notInCache(
        mem,
        [item, item2],
        requests: [details, paginationDetails],
      );
    });
  });

  group('LocalMemorySource.requestCache should', () {
    setUp(() {
      mem = LocalSource<TestModel>(
        InMemorySourcePersistence<TestModel>(TestModel.bindings.getId),
        InMemoryCachePersistence(),
        bindings: TestModel.bindings,
      );
    });

    test('clearForRequest removes from request cache', () async {
      await mem.setItems([item, item2], details);

      final detailsWithFilter = RequestDetails(
        filter: const MsgStartsWithFilter('asdf'),
      );
      await mem.setItems([item], detailsWithFilter);

      final detailsWithFilter2 = RequestDetails(
        filter: const MsgStartsWithFilter('xyz'),
      );
      await mem.setItems([item2], detailsWithFilter2);

      await fullyContains(mem, [item], requests: [details, detailsWithFilter]);
      await notInCache(mem, [item], requests: [detailsWithFilter2]);
      await fullyContains(
        mem,
        [item2],
        requests: [details, detailsWithFilter2],
      );
      await notInCache(mem, [item2], requests: [detailsWithFilter]);

      await mem.clearForRequest(detailsWithFilter);

      await fullyContains(mem, [item], requests: [details]);
      await notInCache(
        mem,
        [item],
        requests: [detailsWithFilter, detailsWithFilter2],
      );
      await fullyContains(
        mem,
        [item2],
        requests: [details, detailsWithFilter2],
      );
      await notInCache(mem, [item2], requests: [detailsWithFilter]);
    });

    test('clearForRequest removes all pages', () async {
      await mem.setItems([item, item2], details);
      await mem.setItems([item], paginationDetails);
      await mem.setItems([item2], page2Details);

      await fullyContains(mem, [item], requests: [details, paginationDetails]);
      await notInCache(mem, [item], requests: [page2Details]);
      await fullyContains(mem, [item2], requests: [details, page2Details]);
      await notInCache(mem, [item2], requests: [paginationDetails]);

      await mem.clearForRequest(paginationDetails);

      await fullyContains(mem, [item, item2], requests: [details]);
      await notInCache(
        mem,
        [item, item2],
        requests: [paginationDetails, page2Details],
      );
    });
  });
}

Future<void> fullyContains(
  LocalSource<TestModel> mem,
  List<TestModel> items, {
  required List<RequestDetails> requests,
}) async {
  for (final item in items) {
    expect(item.id, isNotNull);
    expect(
      (await mem.getById(item.id!, details)).getOrRaise().item,
      equals(item),
    );

    if (requests.isEmpty) {
      // No passed cacheKeys means this item is not expected to be in any search
      // results, so let's confirm tha.
      expect(
        (await mem.getItems(details)).getOrRaise().items,
        isNot(contains(item)),
      );
    } else {
      for (final request in requests) {
        expect(
          (await mem.getItems(request)).getOrRaise().items,
          contains(item),
        );
      }
    }
  }
}

Future<void> notInCache(
  LocalSource<TestModel> mem,
  List<TestModel> items, {
  List<RequestDetails> requests = const [],
  bool containsAtAll = true,
}) async {
  for (final item in items) {
    expect(item.id, isNotNull);
    final maybeItem = (await mem.getById(item.id!, details)).getOrRaise().item;
    if (containsAtAll) {
      expect(maybeItem, isNotNull);
    } else {
      expect(maybeItem, isNull);
    }

    final requestsToEvaluate = requests.isNotEmpty ? requests : [details];

    for (final request in requestsToEvaluate) {
      expect(
        (await mem.getItems(request)).getOrRaise().items,
        isNot(contains(item)),
      );
    }
  }
}

final Matcher _throwsAssertionError = throwsA(isA<AssertionError>());
