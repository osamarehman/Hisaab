import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/screens/passkeys_screen.dart';
import 'package:sure_mobile/services/passkey_service.dart';
import 'package:sure_mobile/theme/sure_theme.dart';

import '../support/fake_passkey_authenticator.dart';

void main() {
  late List<http.Request> requests;
  late List<Map<String, dynamic>> passkeys;
  late String stepUp;

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'GET') {
        return http.Response(
            jsonEncode({'passkeys': passkeys, 'step_up': stepUp}), 200);
      }
      if (request.method == 'DELETE') {
        passkeys.clear();
        return http.Response('', 204);
      }
      if (request.url.path.endsWith('/options')) {
        return http.Response(jsonEncode({'challenge': 'reg'}), 200);
      }
      passkeys.add({'id': '2', 'nickname': 'New phone'});
      return http.Response(jsonEncode(passkeys.last), 201);
    });

    await tester.pumpWidget(MaterialApp(
      theme: SureTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PasskeysScreen(
        service:
            PasskeyService(client: client, authenticator: FakeAuthenticator()),
        tokenLoader: () async => 'tok',
      ),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() {
    requests = [];
    passkeys = [
      {'id': '1', 'nickname': 'Pixel', 'created_at': '2026-10-01T10:00:00Z'},
    ];
    stepUp = 'password';
  });

  testWidgets('lists passkeys and asks for the password to add one',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Pixel'), findsOneWidget);
    expect(find.text('Current password'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('passkeyName')), 'New phone');
    await tester.enterText(find.byKey(const Key('passkeyConfirm')), 'secret');
    await tester.tap(find.text('Add passkey'));
    await tester.pumpAndSettle();

    final create = requests.firstWhere(
        (r) => r.method == 'POST' && r.url.path == '/api/v1/passkeys');
    expect(jsonDecode(create.body)['password'], 'secret');
    expect(find.text('New phone'), findsOneWidget);
  });

  testWidgets('asks for the authenticator code when two-factor is on',
      (tester) async {
    stepUp = 'code';
    await pumpScreen(tester);

    expect(find.text('Authenticator or backup code'), findsOneWidget);
  });

  testWidgets('requires the confirmation before adding', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Add passkey'));
    await tester.pumpAndSettle();

    expect(find.text("Enter it to confirm it's you."), findsOneWidget);
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('removes a passkey after confirming', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Remove this passkey?'), findsOneWidget);
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();

    expect(requests.any((r) => r.method == 'DELETE'), isTrue);
    expect(find.text('Pixel'), findsNothing);
  });

  testWidgets('explains when the account cannot confirm a new passkey',
      (tester) async {
    stepUp = 'none';
    await pumpScreen(tester);

    expect(find.textContaining('Set a password'), findsOneWidget);
    expect(find.text('Add passkey'), findsNothing);
  });
}
