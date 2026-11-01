import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/services/api_config.dart';
import 'package:sure_mobile/services/apple_sign_in_service.dart';

const _device = {
  'device_id': 'd',
  'device_name': 'iPhone',
  'device_type': 'ios',
  'os_version': '26',
  'app_version': '1.0.3',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.shipdeck.hisaab/apple_sign_in');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    ApiConfig.setBaseUrl('https://hisaab.test');
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    ApiConfig.setBaseUrl(ApiConfig.defaultBaseUrl);
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('sends the token with the nonce Apple was given and the first-time name',
      () async {
    String? nonceSentToApple;
    messenger.setMockMethodCallHandler(channel, (call) async {
      nonceSentToApple = (call.arguments as Map)['nonce'] as String;
      return {
        'identityToken': 'apple.jwt',
        'givenName': 'Ayesha',
        'familyName': 'Khan',
      };
    });
    late Map<String, dynamic> sent;
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/auth/apple');
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
          jsonEncode({'access_token': 't', 'refresh_token': 'r'}), 200);
    });

    final result = await AppleSignInService(client: client)
        .signIn(deviceInfo: _device);

    expect(result['success'], isTrue);
    expect((result['body'] as Map)['access_token'], 't');
    expect(sent['identity_token'], 'apple.jwt');
    expect(sent['nonce'], nonceSentToApple);
    expect(sent['nonce'], isNotEmpty);
    expect(sent['first_name'], 'Ayesha');
    expect(sent['last_name'], 'Khan');
    expect(sent['device'], _device);
  });

  test('passes an unlinked Apple ID on to SSO onboarding', () async {
    messenger.setMockMethodCallHandler(
        channel, (call) async => {'identityToken': 'apple.jwt'});
    final client = MockClient((request) async => http.Response(
        jsonEncode({
          'status': 'account_not_linked',
          'linking_code': 'link-1',
          'email': 'x@privaterelay.appleid.com',
          'allow_account_creation': true,
        }),
        200));

    final result = await AppleSignInService(client: client)
        .signIn(deviceInfo: _device);

    expect(result['account_not_linked'], isTrue);
    expect(result['linking_code'], 'link-1');
    expect(result['allow_account_creation'], isTrue);
  });

  test('reports a dismissed Apple sheet as cancelled without calling the server',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'cancelled');
    });
    final client = MockClient((request) async => fail('should not be called'));

    final result = await AppleSignInService(client: client)
        .signIn(deviceInfo: _device);

    expect(result['cancelled'], isTrue);
  });

  test('surfaces the server error message', () async {
    messenger.setMockMethodCallHandler(
        channel, (call) async => {'identityToken': 'apple.jwt'});
    final client = MockClient((request) async => http.Response(
        jsonEncode({'error': 'Apple sign-in could not be verified.'}), 401));

    final result = await AppleSignInService(client: client)
        .signIn(deviceInfo: _device);

    expect(result['success'], isFalse);
    expect(result['error'], 'Apple sign-in could not be verified.');
  });

  test('is only offered on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final service = AppleSignInService();

    expect(service.isSupported, isFalse);
    expect((await service.signIn(deviceInfo: _device))['unsupported'], isTrue);
  });
}
