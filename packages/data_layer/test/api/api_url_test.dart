import 'package:data_layer/data_layer.dart';
import 'package:test/test.dart';

class LoginUrl extends ApiV1Url {
  const LoginUrl() : super(path: 'users/login/');
}

class DynamicUrl extends ApiV1Url {
  DynamicUrl(String token)
    : super(
        path: 'users/{{token}}/',
        context: <String, Object?>{'token': token},
      );
}

void main() {
  group('Value rendered correctly for', () {
    test('LoginUrl', () {
      expect(
        const LoginUrl().value,
        'api/v1/users/login/',
      );
    });
    test('DynamicUrl', () {
      expect(
        DynamicUrl('asdf').value,
        'api/v1/users/asdf/',
      );
    });
  });
}
