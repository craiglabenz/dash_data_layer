import 'dart:convert';
import 'dart:io';
import 'package:data_layer/data_layer.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../models/test_model.dart';

const _id = 'uuid';
const _id2 = 'uuid2';
const detailResponseBody = '{"id": "$_id", "msg": "Fred"}';
const detailResponseBody2 = '{"id": "$_id2", "msg": "Flintstone"}';
const listResponseBody = '{"results": [$detailResponseBody]}';
const twoElementResponseBody =
    '{"results": [$detailResponseBody, $detailResponseBody2]}';
const emptyResponseBody = '{"results": []}';
final returnHeaders = <String, String>{
  HttpHeaders.contentTypeHeader: 'application/json',
};
final requestHeaders = <String, String>{
  HttpHeaders.contentTypeHeader: 'application/json',
  HttpHeaders.acceptHeader: 'application/json',
};
const errorBody = '{"error": "not found"}';

final obj = TestModel.fromJson(jsonDecode(detailResponseBody) as Json);
final obj2 = TestModel.fromJson(jsonDecode(detailResponseBody2) as Json);

final details = RequestDetails();
final localDetails = RequestDetails(requestType: RequestType.local);
final refreshDetails = RequestDetails(
  requestType: RequestType.refresh,
);
final abcDetails = RequestDetails(
  filter: const MsgStartsWithFilter('abc'),
);
final localAbcDetails = RequestDetails(
  filter: const MsgStartsWithFilter('abc'),
  requestType: RequestType.local,
);

RequestDelegate getRequestDelegate(
  List<String> bodies, {
  int statusCode = 200,
  bool canCreate = false,
  bool canUpdate = false,
}) {
  int count = 0;
  final WriteRequestHandler? postHandler =
      canCreate //
      ? (url, {headers, body, encoding}) {
          count++;
          return Future.value(
            http.Response(
              bodies[count - 1],
              statusCode,
              headers: returnHeaders,
            ),
          );
        }
      : null;
  final WriteRequestHandler? updateHandler =
      canUpdate //
      ? (url, {headers, body, encoding}) {
          count++;
          return Future.value(
            http.Response(
              bodies[count - 1],
              statusCode,
              headers: returnHeaders,
            ),
          );
        }
      : null;

  return RequestDelegate.fake(
    readHandler: (uri, {headers}) {
      count++;
      // Because of pooling, all requests to ApiSource are turned into
      // list responses.
      return Future.value(
        http.Response(bodies[count - 1], statusCode, headers: returnHeaders),
      );
    },
    postHandler: postHandler,
    putHandler: updateHandler,
  );
}

final RequestDelegate delegate200 = getRequestDelegate([listResponseBody]);
final RequestDelegate twoItemdelegate200 = getRequestDelegate([
  twoElementResponseBody,
]);
final RequestDelegate twoItemdelegate200x2 = getRequestDelegate([
  twoElementResponseBody,
  twoElementResponseBody,
]);
final RequestDelegate delegate404 = getRequestDelegate(
  [errorBody],
  statusCode: HttpStatus.notFound,
);
final RequestDelegate delegate404x2 = getRequestDelegate(
  [errorBody, errorBody],
  statusCode: HttpStatus.notFound,
);
RequestDelegate getEmptyDelegate() => getRequestDelegate([emptyResponseBody]);

final RequestDelegate creatableDelegate = getRequestDelegate([
  listResponseBody,
], canCreate: true);
final RequestDelegate updateableDelegate = getRequestDelegate([
  listResponseBody,
], canUpdate: true);

SourceList<TestModel> getSourceList(RequestDelegate delegate) =>
    SourceList<TestModel>(
      sources: <Source<TestModel>>[
        LocalMemorySource<TestModel>(getId: TestModel.bindings.getId),
        LocalMemorySource<TestModel>(getId: TestModel.bindings.getId),
        ApiSource<TestModel>(
          bindings: TestModel.bindings,
          restApi: RestApi(
            apiBaseUrl: 'https://fake.com',
            headersBuilder: () => requestHeaders,
            delegate: delegate,
          ),
          timer: TestFriendlyTimer(),
        ),
      ],
      bindings: TestModel.bindings,
    );

void main() {
  group('SourceList.getById should', () {
    test('get and cache items', () async {
      final sl = getSourceList(delegate200);
      final readResult = await sl.getById(_id, details);
      final loadedObj = readResult.getOrRaise().item;
      expect(loadedObj, equals(obj));
      // Object will be asserted to exist, but it should not be cached.
      // Only [setItems] can power [getItems].
      await hasNotCached(
        sl,
        [loadedObj!],
        [details, localDetails],
      );
    });

    test(
      'return empty result when item is not found',
      () async {
        final sl = getSourceList(delegate404);
        final readResult = await sl.getById(_id, details);
        expect(readResult.getOrRaise().item, isNull);
        await hasNotCached(
          sl,
          [obj, obj2],
          [details, localDetails],
          shouldExistAtAll: false,
        );
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test('honor request types', () async {
      final sl = getSourceList(delegate404x2);
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItem(
        obj,
        localDetails,
      );
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItem(
        obj,
        localDetails,
      );

      final readResult = await sl.getById(obj.id!, details);
      expect(readResult.getOrRaise().item, obj);

      final localReadResult = await sl.getById(obj.id!, localDetails);
      expect(localReadResult.getOrRaise().item, obj);
      final localReadResult2 = await sl.getById(obj2.id!, localDetails);
      expect(localReadResult2.getOrRaise().item, isNull);

      final remoteReadResult = await sl.getById(obj.id!, refreshDetails);
      expect(remoteReadResult.getOrRaise().item, isNull);
    });
  });

  group('SourceList.getByIds should', () {
    test('get and cache items', () async {
      final sl = getSourceList(getRequestDelegate([twoElementResponseBody]));
      final readResult = await sl.getByIds({_id, _id2}, details);
      expect(readResult.getOrRaise().items, containsAll([obj, obj2]));
      await hasNotCached(sl, [obj, obj2], [details, localDetails]);
    });

    test(
      'get and cache items on partial returns',
      () async {
        final sl = getSourceList(getRequestDelegate([listResponseBody]));
        final readResult = await sl.getByIds({_id, _id2}, details);
        final loadedItems = readResult.getOrRaise().items;
        expect(loadedItems, contains(obj));
        expect(loadedItems, isNot(contains(obj2)));
        await hasNotCached(sl, [obj], [details, localDetails]);
        await hasNotCached(
          sl,
          [obj2],
          [details, localDetails],
          shouldExistAtAll: false,
        );
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test('complete partially filled local hits', () async {
      final sl = getSourceList(twoItemdelegate200);
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItem(
        obj,
        localDetails,
      );
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItem(
        obj,
        localDetails,
      );

      final localReadResult = await sl.getByIds({
        obj.id!,
        obj2.id!,
      }, localDetails);
      final loadedItems = localReadResult.getOrRaise().items;
      expect(loadedItems, equals({obj}));
      expect(localReadResult.getOrRaise().missingItemIds, {obj2.id!});
      // Not cached because only [setItems] can populate the cache
      await hasNotCached(sl, [obj], [details, localDetails]);
      await hasNotCached(
        sl,
        [obj2],
        [details, localDetails],
        shouldExistAtAll: false,
      );

      final remoteReadResult = await sl.getByIds({
        obj.id!,
        obj2.id!,
      }, refreshDetails);
      expect(remoteReadResult.getOrRaise().items.length, 2);
      await hasNotCached(sl, [obj, obj2], [details, localDetails]);
    });

    test('honor request types', () async {
      final sl = getSourceList(getEmptyDelegate());
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], localDetails);
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], localDetails);

      final readResult = await sl.getByIds({obj.id!, obj2.id!}, details);
      expect(readResult.getOrRaise().items.length, 2);
      await hasCached(sl, [obj, obj2], [details, localDetails]);

      final localReadResult = await sl.getByIds({
        obj.id!,
        obj2.id!,
      }, localDetails);
      expect(localReadResult.getOrRaise().items.length, 2);

      final remoteReadResult = await sl.getByIds({
        obj.id!,
        obj2.id!,
      }, refreshDetails);
      expect(remoteReadResult.getOrRaise().items.length, 0);
    });

    test('honor request types with filters when both are removed', () async {
      final sl = getSourceList(getRequestDelegate([listResponseBody]));

      // Write obj1 and obj2 to both [details] and [abcDetails]
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], localAbcDetails);
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], details);
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], localAbcDetails);
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], details);

      final readResult = await sl.getByIds({obj.id!, obj2.id!}, details);
      expect(readResult.getOrRaise().items.length, 2);
      await hasCached(
        sl,
        [obj, obj2],
        [details, localDetails, localAbcDetails],
      );

      final localReadResult = await sl.getByIds({
        obj.id!,
        obj2.id!,
      }, localDetails);
      expect(localReadResult.getOrRaise().items.length, 2);
      await hasCached(sl, [obj, obj2], [details, localDetails]);

      final remoteReadResult = await sl.getByIds({
        obj.id!,
        obj2.id!,
      }, refreshDetails);
      expect(remoteReadResult.getOrRaise().items.length, 1);
      await hasCached(
        sl,
        [obj],
        [details, localDetails],
      );
      await hasNotCached(
        sl,
        [obj2],
        [details, localDetails],
        shouldExistAtAll: false,
      );
    });

    test('honor request types with filters when both are removed', () async {
      final sl = getSourceList(getEmptyDelegate());

      // Write obj1 and obj2 to both [details] and [abcDetails]
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], localAbcDetails);
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], details);
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], localAbcDetails);
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], details);

      final readResult = await sl.getByIds({obj.id!, obj2.id!}, details);
      expect(readResult.getOrRaise().items.length, 2);
      await hasCached(
        sl,
        [obj, obj2],
        [details, localDetails, localAbcDetails],
      );

      final localReadResult = await sl.getByIds({
        obj.id!,
        obj2.id!,
      }, localDetails);
      expect(localReadResult.getOrRaise().items.length, 2);
      await hasCached(sl, [obj, obj2], [details, localDetails]);

      final remoteReadResult = await sl.getByIds({
        obj.id!,
        obj2.id!,
      }, refreshDetails);
      expect(remoteReadResult.getOrRaise().items.length, 0);
      await hasNotCached(
        sl,
        [obj, obj2],
        [details, localDetails],
        shouldExistAtAll: false,
      );
    });

    test('honor request types with filters when one is removed', () async {
      final sl = getSourceList(getRequestDelegate([listResponseBody]));

      final page1Details = RequestDetails(
        pagination: Pagination.page(1),
      );
      final page2Details = RequestDetails(
        pagination: Pagination.page(2),
      );

      // Write obj1 and obj2 to [page1Details] and [page2Details], respectively
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems([
        obj,
      ], page1Details);
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems([
        obj2,
      ], page2Details);
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems([
        obj,
      ], page1Details);
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems([
        obj2,
      ], page2Details);

      final readResult = await sl.getByIds({obj.id!, obj2.id!}, localDetails);
      expect(readResult.getOrRaise().items.length, 2);
      await hasCached(sl, [obj], [page1Details]);
      await hasCached(sl, [obj2], [page2Details]);
      await hasNotCached(
        sl,
        [obj, obj2],
        [details, localDetails, localAbcDetails],
      );

      final localReadResult = await sl.getByIds({
        obj.id!,
        obj2.id!,
      }, localDetails);
      expect(localReadResult.getOrRaise().items.length, 2);

      final localRead2Result = await sl.getItems(localDetails);
      expect(localRead2Result.getOrRaise().items.length, 0);

      // Only loads object 1, which removes object 2 from all local caches
      final remoteReadResult = await sl.getByIds({
        obj.id!,
        obj2.id!,
      }, refreshDetails);
      expect(remoteReadResult.getOrRaise().items.length, 1);
      expect(remoteReadResult.getOrRaise().missingItemIds, {obj2.id!});
      await hasCached(
        sl,
        [obj],
        [page1Details],
      );
      await hasNotCached(sl, [obj], [details, page2Details]);
      await hasNotCached(
        sl,
        [obj2],
        [details, page1Details, page2Details],
        shouldExistAtAll: false,
      );
    });

    test('surface 404s', () async {
      final sl = getSourceList(delegate404x2);
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], localDetails);
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], localDetails);

      final readResult = await sl.getByIds({obj.id!, obj2.id!}, details);
      expect(readResult.getOrRaise().items.length, 2);

      final localReadResult = await sl.getByIds({
        obj.id!,
        obj2.id!,
      }, localDetails);
      expect(localReadResult.getOrRaise().items.length, 2);

      final remoteReadResult = await sl.getByIds({
        obj.id!,
        obj2.id!,
      }, refreshDetails);
      expect(remoteReadResult, isFailure);
    });
  });

  group('SourceList.getItems should', () {
    test('return empty sets', () async {
      final sl = getSourceList(getEmptyDelegate());
      final result = await sl.getItems(details);

      // Getting no results from the server saves the value as missing and logs
      // the request as being known-empty.
      expect(result.getOrRaise().items.length, 0);
      await hasNotCached(sl, [obj, obj2], [details], shouldExistAtAll: false);
    });

    test('load items not yet locally cached', () async {
      final sl = getSourceList(twoItemdelegate200x2);

      final localReadResult = await sl.getItems(localDetails);
      expect(localReadResult.getOrRaise().items.length, 0);
      // `details` is fine to pass here in place of `localDetails` because
      // `RequestType` is not factored into a RequestDetails' object's cache key
      await hasNotCached(sl, [obj, obj2], [details], shouldExistAtAll: false);

      final remoteReadResult = await sl.getItems(refreshDetails);
      expect(remoteReadResult.getOrRaise().items.length, 2);
      // `details` is fine to pass here in place of `localDetails` because
      // `RequestType` is not factored into a RequestDetails' object's cache key
      await hasCached(sl, [obj, obj2], [details]);
    });

    test('load items already available in source', () async {
      final sl = getSourceList(twoItemdelegate200x2);
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], localDetails);

      final localReadResult = await sl.getItems(localDetails);
      expect(localReadResult.getOrRaise().items.length, 2);

      final remoteReadResult = await sl.getItems(refreshDetails);
      expect(remoteReadResult.getOrRaise().items.length, 2);
    });

    test('honor request types and cache items', () async {
      final sl = getSourceList(getRequestDelegate([twoElementResponseBody]));

      final initialReadResult = await sl.getItems(localDetails);
      expect(initialReadResult.getOrRaise().items.length, 0);
      await hasNotCached(sl, [obj, obj2], [details], shouldExistAtAll: false);

      final remoteReadResult = await sl.getItems(refreshDetails);
      expect(remoteReadResult.getOrRaise().items.length, 2);
      await hasCached(sl, [obj, obj2], [details]);
    });

    test('handle 404s', () async {
      final sl = getSourceList(
        getRequestDelegate([errorBody], statusCode: HttpStatus.notFound),
      );
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems([
        obj,
        obj2,
      ], localDetails);

      final remoteReadResult = await sl.getItems(refreshDetails);
      expect(remoteReadResult, isFailure);

      final localReadResult = await sl.getItems(localDetails);
      expect(localReadResult.getOrRaise().items.length, 2);
    });

    test('honor filters not originally applied', () async {
      final sl = getSourceList(getRequestDelegate([twoElementResponseBody]));

      final remoteReadResult = await sl.getItems(details);
      expect(remoteReadResult.getOrRaise().items.length, 2);
      await hasCached(sl, [obj, obj2], [details]);

      final filteredDetails = RequestDetails(
        filter: const MsgStartsWithFilter('abc'),
        requestType: RequestType.local,
      );
      await hasNotCached(sl, [obj, obj2], [filteredDetails]);
    });

    test('honor filters originally applied', () async {
      final sl = getSourceList(getRequestDelegate([twoElementResponseBody]));

      final filteredDetails = RequestDetails(
        filter: const MsgStartsWithFilter('abc'),
      );
      final remoteReadResult = await sl.getItems(filteredDetails);
      expect(remoteReadResult.getOrRaise().items.length, 2);
      await hasCached(sl, [obj, obj2], [filteredDetails]);
      await hasNotCached(sl, [obj, obj2], [details]);
    });

    test('honor filters', () async {
      final sl = getSourceList(
        getRequestDelegate([
          twoElementResponseBody,
          twoElementResponseBody,
        ]),
      );
      await sl.getItems(details);

      final localReadResult = await sl.getItems(localDetails);
      expect(localReadResult.getOrRaise().items.length, 2);
      await hasCached(sl, [obj, obj2], [details]);

      final localMsgFredDetails = RequestDetails(
        filter: FieldEquals<TestModel, String>('msg', 'Fred', (obj) => obj.msg),
        requestType: RequestType.local,
      );
      await hasNotCached(sl, [obj, obj2], [localMsgFredDetails]);

      // Filters' contents are irrelevant because our fake API does not evaulate
      // its rules.
      final globalMsgFredDetails = RequestDetails(
        filter: FieldEquals<TestModel, String>('msg', 'Fred', (obj) => obj.msg),
      );

      final globalResults = await sl.getItems(globalMsgFredDetails);
      expect(globalResults.getOrRaise().items.length, 2);
      await hasCached(
        sl,
        [obj, obj2],
        [details, localMsgFredDetails, globalMsgFredDetails],
      );
    });
  });

  group('SourceList.setItem should', () {
    test('persist an item to all layers', () async {
      const newObj = TestModel(id: null, msg: 'new');
      final sl = getSourceList(creatableDelegate);
      final writeResult = await sl.setItem(newObj, details);
      expect(writeResult.getOrRaise().item, obj);
      // Not cached because [setItem] cannot populate the cache
      await hasNotCached(sl, [writeResult.getOrRaise().item], [details]);
    });

    test('not call update on new items', () async {
      const newObj = TestModel(id: null, msg: 'new');
      final sl = getSourceList(updateableDelegate);

      /// Here we pass in a source list which ONLY supports updates, but that
      /// method won't be called because this POSTs and does not PUT
      expect(sl.setItem(newObj, details), throwsA(isA<UnexpectedRequest>()));
    });

    test('not call create on existing items', () async {
      const existingObj = TestModel(id: 'some-value', msg: 'new');
      final sl = getSourceList(creatableDelegate);

      /// Here we pass in a source list which ONLY supports POSTs, but that
      /// method won't be called because this PUTs and does not POST
      expect(
        sl.setItem(existingObj, details),
        throwsA(isA<UnexpectedRequest>()),
      );
    });

    test('honor filters', () async {
      const newObj = TestModel(id: null, msg: 'new');
      final sl = getSourceList(
        getRequestDelegate([listResponseBody], canCreate: true),
      );
      final writeResult = await sl.setItem(newObj, abcDetails);
      final savedObj = writeResult.getOrRaise().item;
      expect(savedObj, obj);

      await hasNotCached(
        sl,
        [savedObj],
        [details, abcDetails, localAbcDetails],
      );
    });
  });

  group('SourceList.setItems should', () {
    test('persist items to all local layers', () async {
      const newObj = TestModel(id: 'item 1', msg: 'new');
      const newObj2 = TestModel(id: 'item 2', msg: 'new 2');
      final sl = getSourceList(
        getRequestDelegate(
          [detailResponseBody, detailResponseBody2],
          canCreate: true,
        ),
      );
      final writeResult = await sl.setItems(
        [newObj, newObj2],
        localDetails,
      );
      expect(writeResult.getOrRaise().items.length, 2);
      await hasCached(sl, [newObj, newObj2], [details]);
      await hasNotCached(sl, [newObj, newObj2], [abcDetails]);
    });

    test('throw for remote setItems', () async {
      const newObj = TestModel(id: 'item 1', msg: 'new');
      // Config of SourceList does not matter for this test
      final sl = getSourceList(
        getRequestDelegate(
          [detailResponseBody, detailResponseBody2],
          canCreate: true,
        ),
      );
      expect(
        () => sl.setItems([newObj], refreshDetails),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

Future<void> hasCached(
  SourceList<TestModel> sl,
  List<TestModel> items,
  List<RequestDetails> requests,
) async {
  for (final (itemIndex, item) in items.indexed) {
    assert(item.id != null, '$item should all have Ids');

    final byIdResult = await sl.getById(item.id!, localDetails);
    expect(byIdResult.getOrRaise().item, equals(item));
    for (final (requestIndex, request) in requests.indexed) {
      final c = request.localCopy();
      final forRequestResult = await sl.getItems(c);
      final loadedItems = forRequestResult.getOrRaise().items;
      expect(
        loadedItems,
        contains(item),
        reason:
            'Expected request $requestIndex $request [getItems] to contain '
            'item $itemIndex: $item. Received: $loadedItems',
      );
    }

    for (final (sourceIndex, source) in sl.sources.indexed) {
      if (source is! LocalSource<TestModel>) continue;

      final result = await source.getById(item.id!, details);
      expect(
        result.getOrRaise().item,
        equals(item),
        reason:
            'Expected source $sourceIndex $source to load item $itemIndex '
            '$item by Id',
      );

      for (final (requestIndex, request) in requests.indexed) {
        final result2 = await source.getItems(request.localCopy());
        expect(
          result2.getOrRaise().items,
          contains(item),
          reason:
              'Expected source $sourceIndex $source to find item '
              '$itemIndex $item in RequestDetails $requestIndex $request',
        );
      }
    }
  }
}

Future<void> hasNotCached(
  SourceList<TestModel> sl,
  List<TestModel> items,
  List<RequestDetails> requests, {
  bool shouldExistAtAll = true,
}) async {
  for (final (itemIndex, item) in items.indexed) {
    assert(item.id != null, 'Cached items should all have Ids');

    final byIdResult = await sl.getById(item.id!, localDetails);
    final loadedItem = byIdResult.getOrRaise().item;
    if (shouldExistAtAll) {
      expect(
        loadedItem,
        equals(item),
        reason: 'Expected item $itemIndex $item to be loadable by its Id',
      );
    } else {
      expect(
        loadedItem,
        isNull,
        reason: 'Expected item $itemIndex $item to not exist',
      );
    }
    for (final (requestIndex, request) in requests.indexed) {
      final forRequestRersult = await sl.getItems(request.localCopy());
      expect(
        forRequestRersult.getOrRaise().items,
        isNot(contains(item)),
        reason:
            'Expected request $requestIndex $request to not contain '
            'item $itemIndex $item',
      );
    }

    for (final (sourceIndex, source) in sl.sources.indexed) {
      if (source is! LocalSource<TestModel>) continue;

      final result = await source.getById(item.id!, details);
      final loadedItem = result.getOrRaise().item;
      if (shouldExistAtAll) {
        expect(
          loadedItem,
          equals(item),
          reason:
              'Expected source $sourceIndex $source to load item '
              '$itemIndex $item by its Id',
        );
      } else {
        expect(
          loadedItem,
          isNull,
          reason:
              'Expected source $sourceIndex $source to NOT load item '
              '$itemIndex $item by its Id',
        );
      }
    }
  }
}
