import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/screens/ai_key_screen.dart';
import 'package:sure_mobile/services/ai_settings_service.dart';
import 'package:sure_mobile/theme/sure_theme.dart';

void main() {
  late List<http.Request> requests;
  late Map<String, dynamic> settings;
  late http.Response Function(http.Request) testResponse;

  const presets = [
    {
      'id': 'gemini',
      'base_url': 'https://generativelanguage.googleapis.com/v1beta/openai/',
      'model': 'gemini-2.5-flash',
    },
    {
      'id': 'groq',
      'base_url': 'https://api.groq.com/openai/v1',
      'model': 'llama-3.3-70b-versatile',
    },
  ];

  Future<void> pumpScreen(WidgetTester tester, {bool canEdit = true}) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    settings['can_edit'] = canEdit;
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/test')) return testResponse(request);
      if (request.method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        settings = {
          ...settings,
          'key_present': true,
          'key_last4': (body['api_key'] as String).substring(
              (body['api_key'] as String).length - 4),
          'base_url': body['base_url'],
          'model': body['model'],
          'preset': body['preset'] ?? 'custom',
        };
      }
      if (request.method == 'DELETE') {
        settings = {...settings, 'key_present': false, 'key_last4': null};
      }
      return http.Response(jsonEncode(settings), 200);
    });

    await tester.pumpWidget(MaterialApp(
      theme: SureTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AiKeyScreen(
        service: AiSettingsService(client: client),
        tokenLoader: () async => 'tok',
      ),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() {
    requests = [];
    settings = {
      'key_present': false,
      'can_edit': true,
      'ai_available': false,
      'presets': presets,
    };
    testResponse = (_) =>
        http.Response(jsonEncode({'success': true, 'reply': 'OK'}), 200);
  });

  testWidgets('prefills a preset, tests and saves the key', (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(const Key('aiKeyStatus')), findsOneWidget);
    await tester.tap(find.byKey(const Key('aiPreset-groq')));
    await tester.pumpAndSettle();
    expect(find.text('llama-3.3-70b-versatile'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('aiKeyField')), 'gsk_abcd1234');
    await tester.tap(find.byKey(const Key('aiKeyTest')));
    await tester.pumpAndSettle();
    expect(find.text('The key works.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('aiKeySave')));
    await tester.pumpAndSettle();

    final put = requests.firstWhere((r) => r.method == 'PUT');
    expect(jsonDecode(put.body)['preset'], 'groq');
    expect(jsonDecode(put.body)['api_key'], 'gsk_abcd1234');
    expect(find.text('Using your Groq key ending in 1234'), findsOneWidget);
  });

  testWidgets('shows the provider error from a failed test', (tester) async {
    testResponse = (_) => http.Response(
        jsonEncode({
          'success': false,
          'error': 'connection_failed',
          'message': 'API key not valid.',
        }),
        422);
    await pumpScreen(tester);

    await tester.enterText(find.byKey(const Key('aiKeyField')), 'bad-key');
    await tester.tap(find.byKey(const Key('aiKeyTest')));
    await tester.pumpAndSettle();

    expect(find.text('The key did not work: API key not valid.'),
        findsOneWidget);
  });

  testWidgets('asks for a key before saving', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('aiKeySave')));
    await tester.pumpAndSettle();

    expect(find.text('Paste a key first.'), findsOneWidget);
    expect(requests.where((r) => r.method == 'PUT'), isEmpty);
  });

  testWidgets('removes a saved key', (tester) async {
    settings.addAll({
      'key_present': true,
      'key_last4': '9876',
      'base_url': presets.first['base_url'],
      'model': presets.first['model'],
      'preset': 'gemini',
    });
    await pumpScreen(tester);
    expect(find.text('Using your Google Gemini key ending in 9876'),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('aiKeyRemove')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove key').last);
    await tester.pumpAndSettle();

    expect(requests.any((r) => r.method == 'DELETE'), isTrue);
    expect(find.byKey(const Key('aiKeyRemove')), findsNothing);
  });

  testWidgets('members see the status but no form', (tester) async {
    await pumpScreen(tester, canEdit: false);

    expect(find.text('Only a household admin can change the AI key.'),
        findsOneWidget);
    expect(find.byKey(const Key('aiKeyField')), findsNothing);
  });
}
