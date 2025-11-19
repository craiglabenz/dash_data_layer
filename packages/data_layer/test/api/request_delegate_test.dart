import 'package:data_layer/data_layer.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

final Uri stubUri = const StubUrl().uri;
final getRequest = http.Request('GET', stubUri);

http.Response getResp({
  String body = '',
  int statusCode = 200,
  http.Request? request,
  Map<String, String> headers = const {'Content-Type': 'application/json'},
}) => http.Response(
  body,
  statusCode,
  request: request ?? getRequest,
  headers: headers,
);

void main() {
  group('RequestDelegate.processResponse should', () {
    test('process an empty 200 OK', () {
      final ApiSuccess result =
          RequestDelegate.processResponse(
                DateTime.now(),
                getResp(),
              )
              as ApiSuccess;
      expect(result.body, const ApiResultBody.json({}));
      expect(result.statusCode, 200);
      expect(result.url, stubUri.toString());
      expect(result.responseTime, greaterThan(Duration.zero));
    });

    test('process a 200 OK with a body', () {
      final ApiSuccess result =
          RequestDelegate.processResponse(
                DateTime.now(),
                getResp(body: '{"id": 5}'),
              )
              as ApiSuccess;
      expect(result.body, const ApiResultBody.json({'id': 5}));
      expect(result.statusCode, 200);
      expect(result.url, stubUri.toString());
      expect(result.responseTime, greaterThan(Duration.zero));
    });

    test('process a 200 OK with a text body', () {
      final ApiSuccess result =
          RequestDelegate.processResponse(
                DateTime.now(),
                getResp(
                  body: 'Accepted',
                  headers: {'Content-Type': 'text/plain'},
                ),
              )
              as ApiSuccess;
      expect(result.body, const ApiResultBody.plainText('Accepted'));
      expect(result.statusCode, 200);
      expect(result.url, stubUri.toString());
      expect(result.responseTime, greaterThan(Duration.zero));
    });

    test('process an empty 500 Server Error', () {
      final ApiError result =
          RequestDelegate.processResponse(
                DateTime.now(),
                getResp(statusCode: 500),
              )
              as ApiError;
      expect(
        result.error,
        const ErrorMessage.fromMap({'error': 'Unknown 500 Error'}),
      );
      expect(result.statusCode, 500);
      expect(result.url, stubUri.toString());
      expect(result.responseTime, greaterThan(Duration.zero));
    });
  });
}
