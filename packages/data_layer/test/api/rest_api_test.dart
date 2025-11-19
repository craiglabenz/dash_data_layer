import 'package:data_layer/data_layer.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class TestUrl extends ApiUrl {
  const TestUrl({super.path = 'test'});
}

class TestReadRequest extends ReadApiRequest {
  const TestReadRequest({
    super.url = const TestUrl(),
    super.params,
    super.headers,
  });
}

class TestWriteRequest extends WriteApiRequest {
  const TestWriteRequest({
    super.url = const TestUrl(),
    super.body,
    super.headers,
  });
}

void main() {
  const baseUrl = 'https://example.com';

  group('RestApi', () {
    late RestApi api;
    late RequestDelegate delegate;

    // Variables to capture delegate calls
    Uri? capturedUri;
    Map<String, String>? capturedHeaders;
    Object? capturedBody;

    setUp(() {
      capturedUri = null;
      capturedHeaders = null;
      capturedBody = null;

      delegate = RequestDelegate.fake(
        readHandler: (url, {headers}) async {
          capturedUri = url;
          capturedHeaders = headers;
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        },
        postHandler: (url, {headers, body, encoding}) async {
          capturedUri = url;
          capturedHeaders = headers;
          capturedBody = body;
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        },
        putHandler: (url, {headers, body, encoding}) async {
          capturedUri = url;
          capturedHeaders = headers;
          capturedBody = body;
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        },
        patchHandler: (url, {headers, body, encoding}) async {
          capturedUri = url;
          capturedHeaders = headers;
          capturedBody = body;
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        },
        deleteHandler: (url, {headers, body, encoding}) async {
          capturedUri = url;
          capturedHeaders = headers;
          capturedBody = body;
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        },
      );

      api = RestApi(
        apiBaseUrl: baseUrl,
        headersBuilder: () => {'Auth': 'Token'},
        delegate: delegate,
      );
    });

    test('get constructs correct URL and headers', () async {
      final response = await api.get(const TestReadRequest());

      expect(response.statusCode, 200);
      expect(capturedUri.toString(), '$baseUrl/test');
      expect(capturedHeaders, containsPair('Auth', 'Token'));
    });

    test('get handles non-200s', () async {
      final api = RestApi(
        apiBaseUrl: baseUrl,
        headersBuilder: () => {},
        delegate: RequestDelegate.fake(
          readHandler: (url, {headers}) async {
            return http.Response(
              'error',
              500,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );
      final response = await api.get(const TestReadRequest());

      expect(response.statusCode, 500);
    });

    test('get adds query parameters', () async {
      await api.get(
        const TestReadRequest(
          params: {'q': 'search', 'page': '1'},
        ),
      );

      expect(capturedUri.toString(), '$baseUrl/test?q=search&page=1');
    });

    test('post sends body and headers', () async {
      final response = await api.post(
        const TestWriteRequest(
          body: {'key': 'value'},
        ),
      );

      expect(response.statusCode, 200);
      expect(capturedUri.toString(), '$baseUrl/test');
      expect(capturedBody, '{"key":"value"}');
      expect(capturedHeaders, containsPair('Auth', 'Token'));
    });

    test('delete sends request', () async {
      final response = await api.delete(const TestWriteRequest());

      expect(response.statusCode, 200);
      expect(capturedUri.toString(), '$baseUrl/test');
    });

    test('update (put) sends request', () async {
      final response = await api.update(
        const TestWriteRequest(body: {'id': 1}),
      );

      expect(response.statusCode, 200);
      expect(capturedUri.toString(), '$baseUrl/test');
      // update passes body as is
      expect(capturedBody, {'id': 1});
    });

    test('update (patch) sends request', () async {
      final response = await api.update(
        const TestWriteRequest(body: {'id': 1}),
        partial: true,
      );

      expect(response.statusCode, 200);
      expect(capturedUri.toString(), '$baseUrl/test');
      expect(capturedBody, {'id': 1});
    });

    test('forceEndingSlash adds slash', () async {
      api = RestApi(
        apiBaseUrl: baseUrl,
        headersBuilder: () => {},
        delegate: delegate,
        forceEndingSlash: true,
      );

      await api.get(const TestReadRequest());
      expect(capturedUri.toString(), '$baseUrl/test/');
    });

    test('forceEndingSlash with query params', () async {
      api = RestApi(
        apiBaseUrl: baseUrl,
        headersBuilder: () => {},
        delegate: delegate,
        forceEndingSlash: true,
      );

      await api.get(const TestReadRequest(params: {'a': 'b'}));
      expect(capturedUri.toString(), '$baseUrl/test/?a=b');
    });
  });
}
