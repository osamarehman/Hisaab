import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/services/passkey_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.shipdeck.hisaab/passkeys');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('passes the WebAuthn options through and returns the credential',
      () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return {
        'id': 'cred',
        'type': 'public-key',
        'response': {'clientDataJSON': 'cd', 'signature': 'sig'},
      };
    });

    final credential = await IosPasskeyAuthenticator()
        .get({'challenge': 'abc', 'rpId': 'hisaab.test'});

    expect(received?.method, 'get');
    expect(received?.arguments, {'challenge': 'abc', 'rpId': 'hisaab.test'});
    expect(credential['id'], 'cred');
    expect((credential['response'] as Map)['signature'], 'sig');
  });

  test('maps a dismissed sheet to PasskeyCancelledException', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'cancelled');
    });

    expect(IosPasskeyAuthenticator().create({'challenge': 'abc'}),
        throwsA(isA<PasskeyCancelledException>()));
  });

  test('maps a missing passkey to PasskeyNotFoundException', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'not_found');
    });

    expect(IosPasskeyAuthenticator().get({'challenge': 'abc'}),
        throwsA(isA<PasskeyNotFoundException>()));
  });

  test('is the platform authenticator on iOS only', () {
    expect(platformPasskeyAuthenticator(), isA<IosPasskeyAuthenticator>());
    expect(IosPasskeyAuthenticator().isSupported, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(platformPasskeyAuthenticator(),
        isA<CredentialManagerPasskeyAuthenticator>());
    expect(IosPasskeyAuthenticator().isSupported, isFalse);
  });
}
