import 'package:data_layer/data_layer.dart';
import 'package:test/test.dart';

import '../models/test_model.dart';
import 'operation_builders.dart';

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

void main() {
  late LocalSource<TestModel> source;

  setUp(() {
    source = LocalSource.builders<TestModel>(
      bindings: TestModel.bindings,
      itemCache: (name) => InMemoryPersistence<TestModel>(),
      stringSetCache: (name) => InMemoryPersistence<Set<String>>(),
      dateTimeCache: (name) => InMemoryPersistence<DateTime>(),
    );
  });

  group('LocalSource.builders.setItem should', () {
    test('save items', () async {
      await source.setItem(gwo(item, details));
      await fullyContains(source, [item], requests: []);

      await source.setItem(gwo(item2, abcDetails));
      await fullyContains(source, [item2], requests: []);
    });
  });

  test('accept items twice', () async {
    await source.setItem(gwo(item, details));
    await fullyContains(source, [item], requests: []);

    await source.setItem(gwo(item, details));
    await fullyContains(source, [item], requests: []);
  });

  test('overwrite', () async {
    await source.setItem(gwo(item, details));
    await fullyContains(source, [item], requests: []);

    const itemTake2 = TestModel(id: 'item 1', msg: 'different');
    await source.setItem(gwo(itemTake2, details));
    await fullyContains(source, [itemTake2], requests: []);
    await notInCache(source, [item], requests: []);
  });

  test('set Ids', () async {
    const item = TestModel(id: null, msg: 'hello');
    final idSettingMem = LocalSource.builders<TestModel>(
      bindings: TestModel.bindings,
      itemCache: (name) => InMemoryPersistence<TestModel>(),
      stringSetCache: (name) => InMemoryPersistence<Set<String>>(),
      dateTimeCache: (name) => InMemoryPersistence<DateTime>(),
    );
    final result = await idSettingMem.setItem(gwo(item, details));
    expect(result.getOrRaise().item.id, 'new');
  });

  group('LocalSource.builders.setItems should', () {
    test('set items', () async {
      const item2 = TestModel(id: 'item 2');
      await source.setItems(gwlo([item, item2], details));
      await fullyContains(source, [item, item2], requests: [details]);

      await source.setItems(gwlo([item2, item3], details));
      await notInCache(source, [item], containsAtAll: false);
      await fullyContains(source, [item2, item3], requests: [details]);
    });

    test('set items with in waves with all pagination', () async {
      await source.setItems(gwlo([item, item2], paginationDetails));
      await fullyContains(source, [item, item2], requests: [paginationDetails]);

      await source.setItems(gwlo([item2, item3], paginationDetails));
      await notInCache(
        source,
        [item],
        requests: [details, paginationDetails],
        containsAtAll: false,
      );
      await fullyContains(source, [item2], requests: [paginationDetails]);
      await fullyContains(source, [item3], requests: [paginationDetails]);
    });

    test('not delete items belonging to a different request', () async {
      await source.setItems(gwlo([item, item2], details));
      await source.setItems(gwlo([item, item2], abcDetails));
      await fullyContains(
        source,
        [item, item2],
        requests: [details, abcDetails],
      );
      await source.setItems(gwlo([item2, item3], abcDetails));

      // [item] is still in [details]
      await fullyContains(source, [item, item2], requests: [details]);
      // [item] is no longer in [abcDetails]
      await notInCache(source, [item], requests: [abcDetails]);
      await fullyContains(source, [item2, item3], requests: [abcDetails]);
    });

    test(
      'not delete items belonging to a different paginated request',
      () async {
        await source.setItems(gwlo([item, item2], paginationDetails));
        await source.setItems(gwlo([item, item2], abcDetails));
        await fullyContains(
          source,
          [item, item2],
          requests: [paginationDetails, abcDetails],
        );
        await source.setItems(gwlo([item2, item3], abcDetails));

        // [item] is still in [details]
        await fullyContains(
          source,
          [item, item2],
          requests: [paginationDetails],
        );
        // [item] is no longer in [abcDetails]
        await notInCache(source, [item], requests: [abcDetails]);
        await fullyContains(source, [item2, item3], requests: [abcDetails]);
      },
    );

    test('set items with pagination then without', () async {
      await source.setItems(gwlo([item, item2], paginationDetails));
      await fullyContains(source, [item, item2], requests: [paginationDetails]);

      await source.setItems(gwlo([item2, item3], details));
      await notInCache(source, [item], requests: [details]);
      await fullyContains(source, [item], requests: [paginationDetails]);
      await fullyContains(
        source,
        [item2],
        requests: [details, paginationDetails],
      );
      await fullyContains(source, [item3], requests: [details]);
    });

    test(
      'set items with all pagination requests different page',
      () async {
        await source.setItems(gwlo([item, item2], paginationDetails));
        await fullyContains(
          source,
          [item, item2],
          requests: [paginationDetails],
        );

        const item3 = TestModel(id: 'item 3');
        await source.setItems(gwlo([item3], page2Details));
        await fullyContains(
          source,
          [item, item2],
          requests: [paginationDetails],
        );
        await notInCache(source, [item, item2], requests: [page2Details]);
        await fullyContains(source, [item3], requests: [page2Details]);
        await notInCache(source, [item3], requests: [paginationDetails]);
      },
    );

    test('set items with set name', () async {
      await source.setItems(gwlo([item, item2], details));
      await fullyContains(source, [item, item2], requests: [details]);

      await source.setItems(gwlo([item2, item3], abcDetails));
      await fullyContains(source, [item], requests: [details]);
      await fullyContains(source, [item2], requests: [details, abcDetails]);
      await fullyContains(source, [item3], requests: [abcDetails]);
    });

    test('remove locally existing items missing from new batch', () async {
      await source.setItems(gwlo([item, item2], details));
      await source.setItems(gwlo([item, item2], abcDetails));
      // details: [item, item2]
      // abcDetails: [item, item2]
      await fullyContains(
        source,
        [item, item2],
        requests: [details, abcDetails],
      );

      // Removes [item] from [details], but not from [abcDetails]
      await source.setItems(gwlo([item2, item3], details));

      // details: [item2, item3]
      // abcDetails: [item, item2]
      await notInCache(source, [item], requests: [details]);
      await fullyContains(
        source,
        [item2],
        requests: [details, abcDetails],
      );
      await fullyContains(source, [item3], requests: [details]);
    });

    test(
      'completely remove items from global cache if no longer in any requests',
      () async {
        await source.setItems(gwlo([item, item2], details));
        await source.setItems(gwlo([item, item2], abcDetails));

        await source.setItems(gwlo([item2], details));

        // Now [details] has lost reference to [item], but [item] is still
        // cached because of its membership in [abcDetails]

        await notInCache(source, [item], requests: [details]);
        await fullyContains(source, [item], requests: [abcDetails]);

        // Now [item]'s last set membership, [abcDetails], has also dropped it
        await source.setItems(gwlo([item2], abcDetails));

        await notInCache(
          source,
          [item],
          requests: [details, abcDetails],
          containsAtAll: false,
        );
      },
    );
  });

  group('LocalSource.builders.getById should', () {
    test('throw for filters or pagination', () async {
      expect(
        () => source.getById(gro(item.id!, abcDetails)),
        _throwsAssertionError,
      );
    });

    test('return known items', () async {
      await source.setItem(gwo(item, details));
      final readResult = await source.getById(gro(item.id!, details));
      expect(item, equals(readResult.itemOrRaise()));
      // no request cache hits bc only [setItems] can do that
      await fullyContains(source, [item], requests: []);
    });

    test('return empty ReadSuccess for unknown items', () async {
      await source.setItem(gwo(item, details));
      await notInCache(source, [item2], containsAtAll: false);
    });

    test('NOT honor request details', () async {
      await source.setItem(gwo(item, details));
      await fullyContains(source, [item], requests: []);

      await source.setItem(gwo(item, abcDetails));
      await fullyContains(source, [item], requests: []);

      await source.setItem(gwo(item, paginationDetails));
      await fullyContains(source, [item], requests: []);
    });
  });

  group('LocalSource.builders.getByIds should', () {
    test('throw for filters or pagination', () async {
      expect(
        () => source.getByIds(grido({item.id!}, abcDetails)),
        _throwsAssertionError,
      );
    });

    test('return items', () async {
      await source.setItems(gwlo([item, item2], details));
      final maybeResult = await source.getByIds(
        grido({item.id!, item2.id!}, details),
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
      await source.setItems(gwlo([item, item2], details));
      final maybeResult = await source.getByIds(
        grido({item.id!, item2.id!, item3.id!}, details),
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

  group('LocalSource.builders.getItems should', () {
    test('return items', () async {
      await source.setItems(gwlo([item, item2], details));
      final maybeResult = await source.getItems(grlo(details));
      await fullyContains(source, [item, item2], requests: [details]);
      await notInCache(source, [item, item2], requests: [abcDetails]);
      await notInCache(
        source,
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
      await source.setItems(gwlo([item, item2], abcDetails));

      final xyzDetails = RequestDetails(
        filter: const MsgStartsWithFilter('xyz'),
      );
      await notInCache(source, [item, item2], requests: [details, xyzDetails]);
    });

    test('return no items from filter if empty', () async {
      await source.setItems(gwlo([item, item2], details));
      await notInCache(source, [item, item2], requests: [abcDetails]);
    });
  });

  group('LocalSource.builders.requestCache should', () {
    test('clearForRequest removes from request cache', () async {
      await source.setItems(gwlo([item, item2], details));

      final detailsWithFilter = RequestDetails(
        filter: const MsgStartsWithFilter('asdf'),
      );
      await source.setItems(gwlo([item], detailsWithFilter));

      final detailsWithFilter2 = RequestDetails(
        filter: const MsgStartsWithFilter('xyz'),
      );
      await source.setItems(gwlo([item2], detailsWithFilter2));

      await fullyContains(
        source,
        [item],
        requests: [details, detailsWithFilter],
      );
      await notInCache(source, [item], requests: [detailsWithFilter2]);
      await fullyContains(
        source,
        [item2],
        requests: [details, detailsWithFilter2],
      );
      await notInCache(source, [item2], requests: [detailsWithFilter]);

      await source.clearForRequest(detailsWithFilter);

      await fullyContains(source, [item], requests: [details]);
      await notInCache(
        source,
        [item],
        requests: [detailsWithFilter, detailsWithFilter2],
      );
      await fullyContains(
        source,
        [item2],
        requests: [details, detailsWithFilter2],
      );
      await notInCache(source, [item2], requests: [detailsWithFilter]);
    });

    test('clearForRequest removes all pages', () async {
      await source.setItems(gwlo([item, item2], details));
      await source.setItems(gwlo([item], paginationDetails));
      await source.setItems(gwlo([item2], page2Details));

      await fullyContains(
        source,
        [item],
        requests: [details, paginationDetails],
      );
      await notInCache(source, [item], requests: [page2Details]);
      await fullyContains(source, [item2], requests: [details, page2Details]);
      await notInCache(source, [item2], requests: [paginationDetails]);

      await source.clearForRequest(paginationDetails);

      await fullyContains(source, [item, item2], requests: [details]);
      await notInCache(
        source,
        [item, item2],
        requests: [paginationDetails, page2Details],
      );
    });
  });

  group('LocalSource.builders.delete should', () {
    test('remove an item', () async {
      await source.setItems(gwlo([item, item2], details));
      await fullyContains(source, [item, item2], requests: [details]);
      await source.delete(gdo(item.id!, details));
      await fullyContains(source, [item2], requests: [details]);
      await notInCache(source, [item], requests: [], containsAtAll: false);
    });

    test('remove items', () async {
      await source.setItems(gwlo([item, item2, item3], details));
      await fullyContains(source, [item, item2, item3], requests: [details]);
      await source.deleteIds({item.id!, item2.id!});
      await fullyContains(source, [item3], requests: [details]);
      await notInCache(
        source,
        [item, item2],
        requests: [],
        containsAtAll: false,
      );
    });

    test('remove from pagination', () async {
      await source.setItems(gwlo([item, item2, item3], paginationDetails));
      await fullyContains(
        source,
        [item, item2, item3],
        requests: [paginationDetails],
      );
      await source.deleteIds({item.id!});
      await fullyContains(
        source,
        [item2, item3],
        requests: [paginationDetails],
      );
      await notInCache(
        source,
        [item],
        requests: [],
        containsAtAll: false,
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
      (await mem.getById(gro(item.id!, details))).getOrRaise().item,
      equals(item),
      reason: 'Item $item should be in cache when accessed by Id',
    );

    if (requests.isEmpty) {
      // No passed cacheKeys means this item is not expected to be in any search
      // results, so let's confirm that.
      expect(
        (await mem.getItems(grlo(details))).getOrRaise().items,
        isNot(contains(item)),
      );
    } else {
      for (final request in requests) {
        expect(
          (await mem.getItems(grlo(request))).getOrRaise().items,
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
    final maybeItem = (await mem.getById(
      gro(item.id!, details),
    )).getOrRaise().item;
    if (containsAtAll) {
      expect(
        maybeItem,
        isNotNull,
        reason: 'Item $item expected to be in cache',
      );
    } else {
      expect(
        maybeItem,
        isNull,
        reason: 'Item $item expected to be completely deleted',
      );
    }

    final requestsToEvaluate = requests.isNotEmpty ? requests : [details];

    for (final request in requestsToEvaluate) {
      expect(
        (await mem.getItems(grlo(request))).getOrRaise().items,
        isNot(contains(item)),
        reason: 'Request $request not expected to contain $item',
      );
    }
  }
}

final Matcher _throwsAssertionError = throwsA(isA<AssertionError>());
