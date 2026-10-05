import 'dart:convert';
import 'package:data_layer/data_layer.dart';
import 'package:data_layer/src/http.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import '../models/test_model.dart';
import 'operation_builders.dart';

const respHeaders = <String, String>{
  HttpHeaders.contentTypeHeader: 'application/json',
};

RestSource<TestModel> getSrc({
  ReadHandler? readHandler,
  WriteRequestHandler? postHandler,
  WriteRequestHandler? deleteHandler,
  ITimer? timer,
  String? resultsKey = 'results',
}) => RestSource<TestModel>(
  resultsKey: resultsKey,
  bindings: TestModel.bindings,
  getDetailUrl: (id) => ApiUrl(path: 'test/$id'),
  getListUrl: () => const ApiUrl(path: 'test/'),
  restApi: RestApi(
    apiBaseUrl: 'https://fake.com',
    delegate: RequestDelegate.fake(
      readHandler: readHandler,
      postHandler: postHandler,
      deleteHandler: deleteHandler,
    ),
    headersBuilder: () => <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    },
  ),
  timer: timer ?? TestFriendlyTimer(),
);

void main() {
  group('RestSource.getById should', () {
    test(
      'make a GET request and process its response',
      () async {
        final RestSource<TestModel> src = getSrc(
          readHandler: (url, {headers}) async {
            return http.Response(
              jsonEncode({
                'results': {'id': 'abc', 'msg': 'amazing'},
              }),
              HttpStatus.ok,
              headers: respHeaders,
            );
          },
        );
        final result = await src.getById(gro('abc', RequestDetails()));
        expect(result, isA<ReadSuccess<TestModel>>());
        expect(
          (result as ReadSuccess).item,
          const TestModel(id: 'abc', msg: 'amazing'),
        );
      },
      timeout: const Timeout(Duration(milliseconds: 10)),
    );

    test(
      'make a GET request and process its response without results key',
      () async {
        final RestSource<TestModel> src = getSrc(
          resultsKey: null,
          readHandler: (url, {headers}) async {
            return http.Response(
              jsonEncode([
                {'id': 'abc', 'msg': 'amazing'},
              ]),
              HttpStatus.ok,
              headers: respHeaders,
            );
          },
        );
        final result = await src.getById(gro('abc', RequestDetails()));
        expect(result, isA<ReadSuccess<TestModel>>());
        expect(
          (result as ReadSuccess).item,
          const TestModel(id: 'abc', msg: 'amazing'),
        );
      },
      timeout: const Timeout(Duration(milliseconds: 10)),
    );

    test(
      'work with a real timer',
      () async {
        final RestSource<TestModel> src = getSrc(
          resultsKey: null,
          readHandler: (url, {headers}) async {
            return http.Response(
              jsonEncode([
                {'id': 'abc', 'msg': 'amazing'},
              ]),
              HttpStatus.ok,
              headers: respHeaders,
            );
          },
          timer: RealTimer(),
        );
        final result = await src.getById(gro('abc', RequestDetails()));
        expect(result, isA<ReadSuccess<TestModel>>());
        expect(
          (result as ReadSuccess).item,
          const TestModel(id: 'abc', msg: 'amazing'),
        );
      },
      timeout: const Timeout(Duration(milliseconds: 10)),
    );

    test(
      'return null from a 404',
      () async {
        final RestSource<TestModel> src = getSrc(
          readHandler: (url, {headers}) async {
            return http.Response(
              'Not found',
              HttpStatus.notFound,
              headers: {HttpHeaders.contentTypeHeader: 'text/plain'},
            );
          },
        );
        final result = await src.getById(gro('abc', RequestDetails()));
        expect(result, isA<ReadSuccess<TestModel>>());
        expect((result as ReadSuccess).item, null);
      },
      timeout: const Timeout(Duration(milliseconds: 10)),
    );
  });

  group('RestSource.getByIds should', () {
    test('make a GET request and process its response', () async {
      final RestSource<TestModel> src = getSrc(
        readHandler: (url, {headers}) async {
          return http.Response(
            jsonEncode(
              {
                'results': [
                  {'id': 'abc', 'msg': 'amazing'},
                  {'id': 'xyz', 'msg': 'pretty good'},
                ],
              },
            ),
            HttpStatus.ok,
            headers: respHeaders,
          );
        },
      );
      final result = await src.getByIds(
        grido({'abc', 'xyz'}, RequestDetails()),
      );
      expect(result, isA<ReadListSuccess<TestModel>>());
      final items = (result as ReadListSuccess).items;
      expect(items.first, const TestModel(id: 'abc', msg: 'amazing'));
      expect(items.last, const TestModel(id: 'xyz', msg: 'pretty good'));
    });

    test(
      'make a GET request and process its response without results key',
      () async {
        final RestSource<TestModel> src = getSrc(
          resultsKey: null,
          readHandler: (url, {headers}) async {
            return http.Response(
              jsonEncode(
                [
                  {'id': 'abc', 'msg': 'amazing'},
                  {'id': 'xyz', 'msg': 'pretty good'},
                ],
              ),
              HttpStatus.ok,
              headers: respHeaders,
            );
          },
        );
        final result = await src.getByIds(
          grido({'abc', 'xyz'}, RequestDetails()),
        );
        expect(result, isA<ReadListSuccess<TestModel>>());
        final items = (result as ReadListSuccess).items;
        expect(items.first, const TestModel(id: 'abc', msg: 'amazing'));
        expect(items.last, const TestModel(id: 'xyz', msg: 'pretty good'));
      },
    );

    test('handle partial responses', () async {
      final RestSource<TestModel> src = getSrc(
        readHandler: (url, {headers}) async {
          return http.Response(
            jsonEncode(
              {
                'results': [
                  {'id': 'abc', 'msg': 'amazing'},
                ],
              },
            ),
            HttpStatus.ok,
            headers: respHeaders,
          );
        },
      );
      final result = await src.getByIds(
        grido({'abc', 'xyz'}, RequestDetails()),
      );
      expect(result, isA<ReadListSuccess<TestModel>>());
      final success = result as ReadListSuccess;
      final items = success.items;
      expect(items.first, const TestModel(id: 'abc', msg: 'amazing'));
      expect(success.missingItemIds.contains('xyz'), isTrue);
    });

    test('handle zero hits', () async {
      final RestSource<TestModel> src = getSrc(
        readHandler: (url, {headers}) async {
          return http.Response(
            jsonEncode({'results': <Object>[]}),
            HttpStatus.ok,
            headers: respHeaders,
          );
        },
      );
      final result = await src.getByIds(
        grido({'abc', 'xyz'}, RequestDetails()),
      );
      expect(result, isA<ReadListSuccess<TestModel>>());
      final success = result as ReadListSuccess;
      final items = success.items;
      expect(items, isEmpty);
      expect(success.missingItemIds.contains('abc'), isTrue);
      expect(success.missingItemIds.contains('xyz'), isTrue);
    });

    test('handle a 404', () async {
      final RestSource<TestModel> src = getSrc(
        readHandler: (url, {headers}) async {
          return http.Response(
            'Not found',
            HttpStatus.notFound,
            headers: {HttpHeaders.contentTypeHeader: 'text/plain'},
          );
        },
      );
      final result = await src.getByIds(
        grido({'abc', 'xyz'}, RequestDetails()),
      );
      expect(result, isA<ReadListFailure<TestModel>>());
    });
  });

  group('RestSource.deleteItem', () {
    test('sends DELETE request to detail URL', () async {
      Uri? deletedUri;
      final RestSource<TestModel> src = getSrc(
        deleteHandler: (url, {body, encoding, headers}) async {
          deletedUri = url;
          return http.Response(
            '',
            HttpStatus.noContent,
            headers: respHeaders,
          );
        },
      );
      final result = await src.deleteItem(gdo('123', RequestDetails()));
      expect(result, isSuccess);
      expect(deletedUri?.path, '/test/123');
    });
  });

  group('RestSource.deleteItems', () {
    test('sends DELETE request to list URL with params', () async {
      Uri? deletedUri;
      final RestSource<TestModel> src = getSrc(
        deleteHandler: (url, {body, encoding, headers}) async {
          deletedUri = url;
          return http.Response(
            '',
            HttpStatus.noContent,
            headers: respHeaders,
          );
        },
      );
      final result = await src.deleteItems(gdlo(RequestDetails()));
      expect(result, isSuccess);
      expect(deletedUri?.path, '/test/');
    });
  });
}
