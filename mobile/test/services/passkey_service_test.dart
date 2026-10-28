import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/services/api_config.dart';
import 'package:sure_mobile/services/passkey_service.dart';

import '../support/fake_passkey_authenticator.dart';

const _device = {
  'device_id': 'd',
  'device_name': 'Pixel',
  'device_type': 'android',
  'os_version': '15',
  'app_version': '1.0.0',
};

void main() {
  setUp(() => ApiConfig.setBaseUrl('https://hisaab.test'));
  tearDown(() => ApiConfig.setBaseUrl(ApiConfig.defaultBaseUrl));

  group('signIn', () {
    test('sends the assertion with the challenge it was issued', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/v1/auth/passkey/options') {
          return http.Response(
              jsonEncode({
                'challenge': 'abc',
                'rpId': 'hisaab.test',
                'userVerification': 'required',
              }),
              200);
        }
        return http.Response(
            jsonEncode({'access_token': 't', 'refresh_token': 'r'}), 200);
      });
      final authenticator = FakeAuthenticator();

      final result = await PasskeyService(
              client: client, authenticator: authenticator)
          .signIn(deviceInfo: _device);

      expect(result['success'], true);
      expect((result['body'] as Map)['access_token'], 't');
      expect(authenticator.lastOptions!['rpId'], 'hisaab.test');
      final login = jsonDecode(requests.last.body) as Map;
      expect(requests.last.url.path, '/api/v1/auth/passkey/login');
      expect(login['challenge'], 'abc');
      expect((login['credential'] as Map)['id'], 'cred');
      expect((login['device'] as Map)['device_type'], 'android');
    });

    test('reports a dismissed passkey sheet as cancelled', () async {
      final client = MockClient((request) async =>
          http.Response(jsonEncode({'challenge': 'abc'}), 200));

      final result = await PasskeyService(
        client: client,
        authenticator: FakeAuthenticator(error: PasskeyCancelledException()),
      ).signIn(deviceInfo: _device);

      expect(result['success'], false);
      expect(result['cancelled'], true);
    });

    test('passes the server error through', () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/options')) {
          return http.Response(jsonEncode({'challenge': 'abc'}), 200);
        }
        return http.Response(jsonEncode({'error': 'Nope'}), 401);
      });

      final result = await PasskeyService(
              client: client, authenticator: FakeAuthenticator())
          .signIn(deviceInfo: _device);

      expect(result['success'], false);
      expect(result['error'], 'Nope');
    });
  });

  group('management', () {
    test('lists passkeys and the step-up they need', () async {
      final client = MockClient((request) async => http.Response(
          jsonEncode({
            'passkeys': [
              {
                'id': '1',
                'nickname': 'Pixel',
                'created_at': '2026-10-01T10:00:00Z',
                'last_used_at': null,
              }
            ],
            'step_up': 'password',
          }),
          200));

      final result = await PasskeyService(
              client: client, authenticator: FakeAuthenticator())
          .list(accessToken: 'tok');

      expect(result['success'], true);
      expect(result['step_up'], PasskeyStepUp.password);
      final passkeys = result['passkeys'] as List<Passkey>;
      expect(passkeys.single.nickname, 'Pixel');
      expect(passkeys.single.createdAt, DateTime.utc(2026, 10, 1, 10));
      expect(passkeys.single.lastUsedAt, isNull);
    });

    test('add sends the step-up with both calls', () async {
      final bodies = <String, Map>{};
      final client = MockClient((request) async {
        bodies[request.url.path] = jsonDecode(request.body) as Map;
        expect(request.headers['Authorization'], 'Bearer tok');
        if (request.url.path == '/api/v1/passkeys/options') {
          return http.Response(jsonEncode({'challenge': 'reg'}), 200);
        }
        return http.Response(
            jsonEncode({'id': '9', 'nickname': 'Phone', 'created_at': null}),
            201);
      });

      final result = await PasskeyService(
              client: client, authenticator: FakeAuthenticator())
          .add(accessToken: 'tok', nickname: 'Phone', password: 'secret');

      expect(result['success'], true);
      expect((result['passkey'] as Passkey).id, '9');
      expect(bodies['/api/v1/passkeys/options'], {'password': 'secret'});
      final create = bodies['/api/v1/passkeys']!;
      expect(create['password'], 'secret');
      expect(create['challenge'], 'reg');
      expect(create['nickname'], 'Phone');
      expect((create['credential'] as Map)['id'], 'new-cred');
    });

    test('add stops before the passkey prompt when the step-up fails',
        () async {
      final authenticator = FakeAuthenticator();
      final client = MockClient((request) async => http.Response(
          jsonEncode({'error': 'That password is not correct.'}), 422));

      final result = await PasskeyService(
              client: client, authenticator: authenticator)
          .add(accessToken: 'tok', nickname: '', password: 'wrong');

      expect(result['success'], false);
      expect(result['status'], 422);
      expect(result['error'], 'That password is not correct.');
      expect(authenticator.lastOptions, isNull);
    });

    test('remove deletes by id', () async {
      late http.Request seen;
      final client = MockClient((request) async {
        seen = request;
        return http.Response('', 204);
      });

      final result = await PasskeyService(
              client: client, authenticator: FakeAuthenticator())
          .remove(accessToken: 'tok', id: 'abc');

      expect(result['success'], true);
      expect(seen.method, 'DELETE');
      expect(seen.url.path, '/api/v1/passkeys/abc');
    });
  });
}
