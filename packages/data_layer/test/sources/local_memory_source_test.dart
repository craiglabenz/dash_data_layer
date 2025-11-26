import 'package:data_layer/data_layer.dart';
import 'package:test/test.dart';

import '../models/test_model.dart';

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
  late LocalMemorySource<TestModel> source;

  setUp(() {
    source = LocalMemorySource<TestModel>(
      bindings: TestModel.bindings,
    );
  });

  group('LocalMemorySource.setItem should', () {
    test('save items', () async {
      await source.setItem(item, details);
      await fullyContains(source, [item], requests: []);

      await source.setItem(item2, abcDetails);
      await fullyContains(source, [item2], requests: []);
    });
  });

  test('accept items twice', () async {
    await source.setItem(item, details);
    await fullyContains(source, [item], requests: []);

    await source.setItem(item, details);
    await fullyContains(source, [item], requests: []);
  });

  test('overwrite', () async {
    await source.setItem(item, details);
    await fullyContains(source, [item], requests: []);

    const itemTake2 = TestModel(id: 'item 1', msg: 'different');
    await source.setItem(itemTake2, details);
    await fullyContains(source, [itemTake2], requests: []);
    await notInCache(source, [item], requests: []);
  });

  test('set Ids', () async {
    const item = TestModel(id: null, msg: 'hello');
    final idSettingMem = LocalMemorySource<TestModel>(
      bindings: TestModel.bindings,
    );
    final result = await idSettingMem.setItem(item, details);
    expect(result.getOrRaise().item.id, 'new');
  });

  group('LocalMemorySource.setItem should', () {
    test('set items', () async {
      const item2 = TestModel(id: 'item 2');
      await source.setItems([item, item2], details);
      await fullyContains(source, [item, item2], requests: [details]);

      await source.setItems([item2, item3], details);
      await fullyContains(source, [item], requests: []);
      await fullyContains(source, [item2, item3], requests: [details]);
    });

    test('set items with in waves with all pagination', () async {
      await source.setItems([item, item2], paginationDetails);
      await fullyContains(source, [item, item2], requests: [paginationDetails]);

      await source.setItems([item2, item3], paginationDetails);
      await notInCache(source, [item], requests: [details, paginationDetails]);
      await fullyContains(source, [item2], requests: [paginationDetails]);
      await fullyContains(source, [item3], requests: [paginationDetails]);
    });

    test('set items with pagination then without', () async {
      await source.setItems([item, item2], paginationDetails);
      await fullyContains(source, [item, item2], requests: [paginationDetails]);

      await source.setItems([item2, item3], details);
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
        await source.setItems([item, item2], paginationDetails);
        await fullyContains(
          source,
          [item, item2],
          requests: [paginationDetails],
        );

        const item3 = TestModel(id: 'item 3');
        await source.setItems([item3], page2Details);
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
      await source.setItems([item, item2], details);
      await fullyContains(source, [item, item2], requests: [details]);

      await source.setItems([item2, item3], abcDetails);
      await fullyContains(source, [item], requests: [details]);
      await fullyContains(source, [item2], requests: [details, abcDetails]);
      await fullyContains(source, [item3], requests: [abcDetails]);
    });
  });

  group('LocalMemorySource.getById should', () {
    test('throw for filters or pagination', () async {
      expect(
        () => source.getById(item.id!, abcDetails),
        _throwsAssertionError,
      );
    });

    test('return known items', () async {
      await source.setItem(item, details);
      final readResult = await source.getById(item.id!, details);
      expect(item, equals(readResult.itemOrRaise()));
      // no request cache hits bc only [setItems] can do that
      await fullyContains(source, [item], requests: []);
    });

    test('return empty ReadSuccess for unknown items', () async {
      await source.setItem(item, details);
      await notInCache(source, [item2], containsAtAll: false);
    });

    test('NOT honor request details', () async {
      await source.setItem(item, details);
      await fullyContains(source, [item], requests: []);

      await source.setItem(item, abcDetails);
      await fullyContains(source, [item], requests: []);

      await source.setItem(item, paginationDetails);
      await fullyContains(source, [item], requests: []);
    });
  });

  group('LocalMemorySource.getByIds should', () {
    test('throw for filters or pagination', () async {
      expect(
        () => source.getByIds({item.id!}, abcDetails),
        _throwsAssertionError,
      );
    });

    test('return items', () async {
      await source.setItems([item, item2], details);
      final maybeResult = await source.getByIds(
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
      await source.setItems([item, item2], details);
      final maybeResult = await source.getByIds(
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
    test('return items', () async {
      await source.setItems([item, item2], details);
      final maybeResult = await source.getItems(details);
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
      await source.setItems([item, item2], abcDetails);

      final xyzDetails = RequestDetails(
        filter: const MsgStartsWithFilter('xyz'),
      );
      await notInCache(source, [item, item2], requests: [details, xyzDetails]);
    });

    test('return no items from filter if empty', () async {
      await source.setItems([item, item2], details);
      await notInCache(source, [item, item2], requests: [abcDetails]);
    });
  });

  group('LocalMemorySource.requestCache should', () {
    test('clearForRequest removes from request cache', () async {
      await source.setItems([item, item2], details);

      final detailsWithFilter = RequestDetails(
        filter: const MsgStartsWithFilter('asdf'),
      );
      await source.setItems([item], detailsWithFilter);

      final detailsWithFilter2 = RequestDetails(
        filter: const MsgStartsWithFilter('xyz'),
      );
      await source.setItems([item2], detailsWithFilter2);

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
      await source.setItems([item, item2], details);
      await source.setItems([item], paginationDetails);
      await source.setItems([item2], page2Details);

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

  group('LocalMemorySource.delete should', () {
    test('remove an item', () async {
      await source.setItems([item, item2], details);
      await fullyContains(source, [item, item2], requests: [details]);
      await source.delete(item.id!, details);
      await fullyContains(source, [item2], requests: [details]);
      await notInCache(source, [item], requests: [], containsAtAll: false);
    });

    test('remove items', () async {
      await source.setItems([item, item2, item3], details);
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
      await source.setItems([item, item2, item3], paginationDetails);
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
      (await mem.getById(item.id!, details)).getOrRaise().item,
      equals(item),
    );

    if (requests.isEmpty) {
      // No passed cacheKeys means this item is not expected to be in any search
      // results, so let's confirm that.
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
