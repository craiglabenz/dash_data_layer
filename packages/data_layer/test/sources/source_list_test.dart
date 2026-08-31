import 'dart:convert';
import 'package:data_layer/data_layer.dart';
import 'package:data_layer/src/http.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../models/test_model.dart';
import 'operation_builders.dart';

DateTime Function() _now = () => DateTime.now().toUtc();

const _id = 'uuid';
const _id2 = 'uuid2';
const detailResponseBody = '{"id": "$_id", "msg": "Fred"}';
const detailResponseBody2 = '{"id": "$_id2", "msg": "Flintstone"}';
const listNoResultsKeyResponseBody = '[$detailResponseBody]';
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

final fred = TestModel.fromJson(jsonDecode(detailResponseBody) as Json);
final flintstone = TestModel.fromJson(jsonDecode(detailResponseBody2) as Json);

final details = RequestDetails();
final localDetails = RequestDetails(requestType: .local);
final refreshDetails = RequestDetails(
  requestType: .refresh,
);
final abcDetails = RequestDetails(
  filter: const MsgStartsWithFilter('abc'),
);
final localAbcDetails = RequestDetails(
  filter: const MsgStartsWithFilter('abc'),
  requestType: .local,
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

final RequestDelegate twoItemdelegate200 = getRequestDelegate([
  twoElementResponseBody,
]);
final RequestDelegate twoItemdelegate200x2 = getRequestDelegate([
  twoElementResponseBody,
  twoElementResponseBody,
]);
RequestDelegate getEmptyDelegate() => getRequestDelegate([emptyResponseBody]);

final RequestDelegate creatableDelegate = getRequestDelegate([
  listNoResultsKeyResponseBody,
], canCreate: true);
final RequestDelegate detailStyleCreatableDelegate = getRequestDelegate([
  detailResponseBody,
], canCreate: true);
final RequestDelegate updateableDelegate = getRequestDelegate([
  listNoResultsKeyResponseBody,
], canUpdate: true);
SourceList<TestModel> getSourceList(RequestDelegate delegate) =>
    SourceList<TestModel>(
      sources: <Source<TestModel>>[
        LocalMemorySource<TestModel>(bindings: TestModel.bindings),
        LocalMemorySource<TestModel>(bindings: TestModel.bindings),
        RestSource<TestModel>(
          bindings: TestModel.bindings,
          getDetailUrl: (id) => ApiUrl(path: 'test/$id'),
          getListUrl: () => const ApiUrl(path: 'test/'),
          restApi: RestApi(
            apiBaseUrl: 'https://fake.com',
            headersBuilder: () => requestHeaders,
            delegate: delegate,
          ),
          timer: TestFriendlyTimer(),
        ),
      ],
      bindings: TestModel.bindings,
      getTime: _now,
    );

void main() {
  group('SourceList.getById should', () {
    test('get and cache items', () async {
      final sl = getSourceList(getRequestDelegate([listResponseBody]));
      final readResult = await sl.getById(gro(_id, details));
      final loadedObj = readResult.getOrRaise().item;
      expect(loadedObj, equals(fred));
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
        final sl = getSourceList(
          getRequestDelegate(
            [errorBody],
            statusCode: HttpStatus.notFound,
          ),
        );
        final readResult = await sl.getById(gro(_id, details));
        expect(readResult.getOrRaise().item, isNull);
        await hasNotCached(
          sl,
          [fred, flintstone],
          [details, localDetails],
          shouldExistAtAll: false,
        );
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test('honor request types', () async {
      final sl = getSourceList(
        getRequestDelegate(
          [errorBody, errorBody],
          statusCode: HttpStatus.notFound,
        ),
      );
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItem(
        gwo(fred, localDetails),
      );
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItem(
        gwo(fred, localDetails),
      );

      final readResult = await sl.getById(gro(fred.id!, details));
      expect(readResult.getOrRaise().item, fred);

      final localReadResult = await sl.getById(gro(fred.id!, localDetails));
      expect(localReadResult.getOrRaise().item, fred);
      final localReadResult2 = await sl.getById(
        gro(flintstone.id!, localDetails),
      );
      expect(localReadResult2.getOrRaise().item, isNull);

      final remoteReadResult = await sl.getById(gro(fred.id!, refreshDetails));
      expect(remoteReadResult.getOrRaise().item, isNull);
    });
  });

  group('SourceList.getByIds should', () {
    test('get and cache items', () async {
      final sl = getSourceList(getRequestDelegate([twoElementResponseBody]));
      final readResult = await sl.getByIds(grido({_id, _id2}, details));
      expect(readResult.getOrRaise().items, containsAll([fred, flintstone]));
      await hasNotCached(sl, [fred, flintstone], [details, localDetails]);
    });

    test(
      'get and cache items on partial returns',
      () async {
        final sl = getSourceList(getRequestDelegate([listResponseBody]));
        final readResult = await sl.getByIds(grido({_id, _id2}, details));
        final loadedItems = readResult.getOrRaise().items;
        expect(loadedItems, contains(fred));
        expect(loadedItems, isNot(contains(flintstone)));
        await hasNotCached(sl, [fred], [details, localDetails]);
        await hasNotCached(
          sl,
          [flintstone],
          [details, localDetails],
          shouldExistAtAll: false,
        );
      },
      timeout: const Timeout(Duration(seconds: 1)),
    );

    test('complete partially filled local hits', () async {
      final sl = getSourceList(twoItemdelegate200);
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItem(
        gwo(fred, localDetails),
      );
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItem(
        gwo(fred, localDetails),
      );

      final localReadResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, localDetails),
      );
      final loadedItems = localReadResult.getOrRaise().items;
      expect(loadedItems, equals({fred}));
      expect(localReadResult.getOrRaise().missingItemIds, {flintstone.id!});
      // Not cached because only [setItems] can populate the cache
      await hasNotCached(sl, [fred], [details, localDetails]);
      await hasNotCached(
        sl,
        [flintstone],
        [details, localDetails],
        shouldExistAtAll: false,
      );

      final remoteReadResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, refreshDetails),
      );
      expect(remoteReadResult.getOrRaise().items.length, 2);
      await hasNotCached(sl, [fred, flintstone], [details, localDetails]);
    });

    test('honor request types', () async {
      final sl = getSourceList(getEmptyDelegate());
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], localDetails),
      );
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], localDetails),
      );

      final readResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, details),
      );
      expect(readResult.getOrRaise().items.length, 2);
      await hasCached(sl, [fred, flintstone], [details, localDetails]);

      final localReadResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, localDetails),
      );
      expect(localReadResult.getOrRaise().items.length, 2);

      final remoteReadResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, refreshDetails),
      );
      expect(remoteReadResult.getOrRaise().items.length, 0);
    });

    test('honor request types with filters when both are removed', () async {
      final sl = getSourceList(getRequestDelegate([listResponseBody]));

      // Write obj1 and obj2 to both [details] and [abcDetails]
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], localAbcDetails),
      );
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], details),
      );
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], localAbcDetails),
      );
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], details),
      );

      final readResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, details),
      );
      expect(readResult.getOrRaise().items.length, 2);
      await hasCached(
        sl,
        [fred, flintstone],
        [details, localDetails, localAbcDetails],
      );

      final localReadResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, localDetails),
      );
      expect(localReadResult.getOrRaise().items.length, 2);
      await hasCached(sl, [fred, flintstone], [details, localDetails]);

      final remoteReadResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, refreshDetails),
      );
      expect(remoteReadResult.getOrRaise().items.length, 1);
      await hasCached(
        sl,
        [fred],
        [details, localDetails],
      );
      await hasNotCached(
        sl,
        [flintstone],
        [details, localDetails],
        shouldExistAtAll: false,
      );
    });

    test('honor request types with filters when both are removed', () async {
      final sl = getSourceList(getEmptyDelegate());

      // Write obj1 and obj2 to both [details] and [abcDetails]
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], localAbcDetails),
      );
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], details),
      );
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], localAbcDetails),
      );
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], details),
      );

      final readResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, details),
      );
      expect(readResult.getOrRaise().items.length, 2);
      await hasCached(
        sl,
        [fred, flintstone],
        [details, localDetails, localAbcDetails],
      );

      final localReadResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, localDetails),
      );
      expect(localReadResult.getOrRaise().items.length, 2);
      await hasCached(sl, [fred, flintstone], [details, localDetails]);

      final remoteReadResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, refreshDetails),
      );
      expect(remoteReadResult.getOrRaise().items.length, 0);
      await hasNotCached(
        sl,
        [fred, flintstone],
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
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred], page1Details),
      );
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems(
        gwlo([flintstone], page2Details),
      );
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred], page1Details),
      );
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems(
        gwlo([flintstone], page2Details),
      );

      final readResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, localDetails),
      );
      expect(readResult.getOrRaise().items.length, 2);
      await hasCached(sl, [fred], [page1Details]);
      await hasCached(sl, [flintstone], [page2Details]);
      await hasNotCached(
        sl,
        [fred, flintstone],
        [details, localDetails, localAbcDetails],
      );

      final localReadResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, localDetails),
      );
      expect(localReadResult.getOrRaise().items.length, 2);

      final localRead2Result = await sl.getItems(grlo(localDetails));
      expect(localRead2Result.getOrRaise().items.length, 0);

      // Only loads object 1, which removes object 2 from all local caches
      final remoteReadResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, refreshDetails),
      );
      expect(remoteReadResult.getOrRaise().items.length, 1);
      expect(remoteReadResult.getOrRaise().missingItemIds, {flintstone.id!});
      await hasCached(
        sl,
        [fred],
        [page1Details],
      );
      await hasNotCached(sl, [fred], [details, page2Details]);
      await hasNotCached(
        sl,
        [flintstone],
        [details, page1Details, page2Details],
        shouldExistAtAll: false,
      );
    });

    test('surface 404s', () async {
      final sl = getSourceList(
        getRequestDelegate(
          [errorBody, errorBody],
          statusCode: HttpStatus.notFound,
        ),
      );
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], localDetails),
      );
      await (sl.sources[1] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], localDetails),
      );

      final readResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, details),
      );
      expect(readResult.getOrRaise().items.length, 2);

      final localReadResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, localDetails),
      );
      expect(localReadResult.getOrRaise().items.length, 2);

      final remoteReadResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, refreshDetails),
      );
      expect(remoteReadResult, isFailure);
    });
  });

  group('SourceList.getItems should', () {
    test('return empty sets', () async {
      final sl = getSourceList(getEmptyDelegate());
      final result = await sl.getItems(grlo(details));

      // Getting no results from the server saves the value as missing and logs
      // the request as being known-empty.
      expect(result.getOrRaise().items.length, 0);
      await hasNotCached(
        sl,
        [fred, flintstone],
        [details],
        shouldExistAtAll: false,
      );
    });

    test('load items not yet locally cached', () async {
      final sl = getSourceList(twoItemdelegate200x2);

      final localReadResult = await sl.getItems(grlo(localDetails));
      expect(localReadResult.getOrRaise().items.length, 0);
      // `details` is fine to pass here in place of `localDetails` because
      // `RequestType` is not factored into a RequestDetails' object's cache key
      await hasNotCached(
        sl,
        [fred, flintstone],
        [details],
        shouldExistAtAll: false,
      );

      final remoteReadResult = await sl.getItems(grlo(refreshDetails));
      expect(remoteReadResult.getOrRaise().items.length, 2);
      // `details` is fine to pass here in place of `localDetails` because
      // `RequestType` is not factored into a RequestDetails' object's cache key
      await hasCached(sl, [fred, flintstone], [details]);
    });

    test('load items already available in source', () async {
      final sl = getSourceList(twoItemdelegate200x2);
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], localDetails),
      );

      final localReadResult = await sl.getItems(grlo(localDetails));
      expect(localReadResult.getOrRaise().items.length, 2);

      final remoteReadResult = await sl.getItems(grlo(refreshDetails));
      expect(remoteReadResult.getOrRaise().items.length, 2);
    });

    test('honor request types and cache items', () async {
      final sl = getSourceList(getRequestDelegate([twoElementResponseBody]));

      final initialReadResult = await sl.getItems(grlo(localDetails));
      expect(initialReadResult.getOrRaise().items.length, 0);
      await hasNotCached(
        sl,
        [fred, flintstone],
        [details],
        shouldExistAtAll: false,
      );

      final remoteReadResult = await sl.getItems(grlo(refreshDetails));
      expect(remoteReadResult.getOrRaise().items.length, 2);
      await hasCached(sl, [fred, flintstone], [details]);
    });

    test('handle 404s', () async {
      final sl = getSourceList(
        getRequestDelegate([errorBody], statusCode: HttpStatus.notFound),
      );
      await (sl.sources[0] as LocalMemorySource<TestModel>).setItems(
        gwlo([fred, flintstone], localDetails),
      );

      final remoteReadResult = await sl.getItems(grlo(refreshDetails));
      expect(remoteReadResult, isFailure);

      final localReadResult = await sl.getItems(grlo(localDetails));
      expect(localReadResult.getOrRaise().items.length, 2);
    });

    test('honor filters not originally applied', () async {
      final sl = getSourceList(getRequestDelegate([twoElementResponseBody]));

      final remoteReadResult = await sl.getItems(grlo(details));
      expect(remoteReadResult.getOrRaise().items.length, 2);
      await hasCached(sl, [fred, flintstone], [details]);

      final filteredDetails = RequestDetails(
        filter: const MsgStartsWithFilter('abc'),
        requestType: RequestType.local,
      );
      await hasNotCached(sl, [fred, flintstone], [filteredDetails]);
    });

    test('honor filters originally applied', () async {
      final sl = getSourceList(getRequestDelegate([twoElementResponseBody]));

      final filteredDetails = RequestDetails(
        filter: const MsgStartsWithFilter('abc'),
      );
      final remoteReadResult = await sl.getItems(grlo(filteredDetails));
      expect(remoteReadResult.getOrRaise().items.length, 2);
      await hasCached(sl, [fred, flintstone], [filteredDetails]);
      await hasNotCached(sl, [fred, flintstone], [details]);
    });

    test('honor filters', () async {
      final sl = getSourceList(
        getRequestDelegate([
          twoElementResponseBody,
          twoElementResponseBody,
        ]),
      );
      await sl.getItems(grlo(details));

      final localReadResult = await sl.getItems(grlo(localDetails));
      expect(localReadResult.getOrRaise().items.length, 2);
      await hasCached(sl, [fred, flintstone], [details]);

      final localMsgFredDetails = RequestDetails(
        filter: FieldEquals<TestModel, String>('msg', 'Fred', (obj) => obj.msg),
        requestType: RequestType.local,
      );
      await hasNotCached(sl, [fred, flintstone], [localMsgFredDetails]);

      // Filters' contents are irrelevant because our fake API does not evaulate
      // its rules.
      final globalMsgFredDetails = RequestDetails(
        filter: FieldEquals<TestModel, String>('msg', 'Fred', (obj) => obj.msg),
      );

      final globalResults = await sl.getItems(grlo(globalMsgFredDetails));
      expect(globalResults.getOrRaise().items.length, 2);
      await hasCached(
        sl,
        [fred, flintstone],
        [details, localMsgFredDetails, globalMsgFredDetails],
      );
    }, timeout: const Timeout(Duration(milliseconds: 10)));
  });

  group('SourceList.setItem should', () {
    test('persist an item to all layers', () async {
      const newObj = TestModel(id: null, msg: 'new');
      final sl = getSourceList(creatableDelegate);
      final writeResult = await sl.setItem(gwo(newObj, details));
      expect(writeResult.getOrRaise().item, fred);
      // Not cached because [setItem] cannot populate the cache
      await hasNotCached(sl, [writeResult.getOrRaise().item], [details]);
    });

    test('persist an item to all layers from detail-style responses', () async {
      const newObj = TestModel(id: null, msg: 'new');
      final sl = getSourceList(detailStyleCreatableDelegate);
      final writeResult = await sl.setItem(gwo(newObj, details));
      expect(writeResult.getOrRaise().item, fred);
      // Not cached because [setItem] cannot populate the cache
      await hasNotCached(sl, [writeResult.getOrRaise().item], [details]);
    });

    test('not call update on new items', () async {
      const newObj = TestModel(id: null, msg: 'new');
      final sl = getSourceList(updateableDelegate);

      /// Here we pass in a source list which ONLY supports updates, but that
      /// method won't be called because this POSTs and does not PUT
      expect(
        sl.setItem(gwo(newObj, details)),
        throwsA(isA<UnexpectedRequest>()),
      );
    });

    test('not call create on existing items', () async {
      const existingObj = TestModel(id: 'some-value', msg: 'new');
      final sl = getSourceList(creatableDelegate);

      /// Here we pass in a source list which ONLY supports POSTs, but that
      /// method won't be called because this PUTs and does not POST
      expect(
        sl.setItem(gwo(existingObj, details)),
        throwsA(isA<UnexpectedRequest>()),
      );
    });

    test(
      'assert filter is null',
      () async {
        const newObj = TestModel(id: null, msg: 'new');
        final sl = getSourceList(
          getRequestDelegate([detailResponseBody], canCreate: true),
        );
        expect(
          () => sl.setItem(gwo(newObj, abcDetails)),
          throwsA(isA<AssertionError>()),
        );
      },
      timeout: const Timeout(Duration(milliseconds: 10)),
    );
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
        gwlo([newObj, newObj2], localDetails),
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
        () => sl.setItems(gwlo([newObj], refreshDetails)),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('SourceList.deleteItem should', () {
    test('assert filter is null', () async {
      final sl = getSourceList(getRequestDelegate([]));
      expect(
        () => sl.deleteItem(gdo('123', abcDetails)),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('SourceList.sendMessage should', () {
    test('assert filter is null', () async {
      final sl = getSourceList(getRequestDelegate([]));
      expect(
        () => sl.sendMessage(
          SendMessageOperation<TestModel>(
            operationId: 'op_msg',
            message: 'hello',
            details: abcDetails,
            createdAt: DateTime.now(),
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('SourceList should', () {
    test('be able to read all data', () async {
      final sl = getSourceList(getRequestDelegate([listResponseBody]));
      await sl.setItem(gwo(fred, localDetails));
      await sl.setItems(gwlo([flintstone], localDetails));
      final readResult = await sl.getItems(
        grlo(RequestDetails(requestType: .allLocal)),
      );
      final items = readResult.getOrRaise().items;
      expect(items.length, equals(2));
      expect(items, contains(fred));
      expect(items, contains(flintstone));
    });
  });

  group('SourceList with ttl should', () {
    test('fallback for partially missing data in getByIds', () async {
      // Returns Fred
      final sl = getSourceList(getRequestDelegate([listResponseBody]));

      // Set stale Fred
      await sl.setItem(
        gwo(fred, RequestDetails(requestType: .local, ttl: .zero)),
      );
      // Set fresh Flintstone
      await sl.setItem(
        gwo(
          flintstone,
          RequestDetails(requestType: .local, ttl: const Duration(days: 1)),
        ),
      );

      final readResult = await sl.getByIds(
        grido({fred.id!, flintstone.id!}, RequestDetails()),
      );
      final items = readResult.getOrRaise().items;
      expect(items.length, equals(2));
      expect(items, contains(fred));
      expect(items, contains(flintstone));
    });

    test('fallback for global requests in getItems', () async {
      // Returns Fred
      final sl = getSourceList(getRequestDelegate([listResponseBody]));

      // Set stale Flintstone
      await sl.setItems(
        gwlo([flintstone], RequestDetails(requestType: .local, ttl: .zero)),
      );

      final readResult = await sl.getItems(grlo(RequestDetails()));
      final items = readResult.getOrRaise().items;
      expect(items.length, equals(1));
      expect(items, contains(fred));
    });

    test('return only fresh data in getItems', () async {
      // Returns Fred, but won't get requested
      final sl = getSourceList(getRequestDelegate([listResponseBody]));

      // Set stale Fred
      await sl.setItems(
        gwlo([fred], RequestDetails(requestType: .local, ttl: .zero)),
      );

      // Set fresh Flintstone
      await sl.setItems(
        gwlo(
          [flintstone],
          RequestDetails(requestType: .local, ttl: const Duration(days: 1)),
        ),
      );

      final readResult = await sl.getItems(grlo(RequestDetails()));
      final items = readResult.getOrRaise().items;
      expect(items.length, equals(1));
      expect(items, contains(flintstone));
    });

    test('fallback for stale data in getById', () async {
      // Returns Fred from the mock remote ApiSource
      final sl = getSourceList(getRequestDelegate([listResponseBody]));

      // Set stale Fred locally (ttl is incredibly short)
      await sl.setItem(
        gwo(fred, RequestDetails(requestType: .local, ttl: .zero)),
      );

      // When requesting without specifically saying `.local`, the sourceList
      // will evaluate the cache, see it is cleanly expired/stale, and fall back
      // nicely to the server to fetch a fresh `fred`.
      final readResult = await sl.getById(gro(fred.id!, RequestDetails()));
      final item = readResult.getOrRaise().item;

      expect(item, isNotNull);
      expect(item, equals(fred));
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

    final byIdResult = await sl.getById(gro(item.id!, localDetails));
    expect(byIdResult.getOrRaise().item, equals(item));
    for (final (requestIndex, request) in requests.indexed) {
      final c = request.localCopy();
      final forRequestResult = await sl.getItems(grlo(c));
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

      final result = await source.getById(gro(item.id!, details));
      expect(
        result.getOrRaise().item,
        equals(item),
        reason:
            'Expected source $sourceIndex $source to load item $itemIndex '
            '$item by Id',
      );

      for (final (requestIndex, request) in requests.indexed) {
        final result2 = await source.getItems(grlo(request.localCopy()));
        expect(
          result2.getOrRaise().items,
          contains(item),
          reason:
              'Expected source $sourceIndex $source to find item '
              '$itemIndex $item in RequestDetails index:$requestIndex $request',
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

    final byIdResult = await sl.getById(gro(item.id!, localDetails));
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
      final forRequestRersult = await sl.getItems(grlo(request.localCopy()));
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

      final result = await source.getById(gro(item.id!, details));
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
