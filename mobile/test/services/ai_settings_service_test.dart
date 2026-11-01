import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/services/ai_settings_service.dart';

void main() {
  final saved = {
    'key_present': true,
    'key_last4': '9876',
    'base_url': 'https://api.groq.com/openai/v1',
    'model': 'llama-3.3-70b-versatile',
    'preset': 'groq',
    'can_edit': true,
    'ai_available': true,
    'presets': [
      {
        'id': 'groq',
        'base_url': 'https://api.groq.com/openai/v1',
        'model': 'llama-3.3-70b-versatile',
      },
    ],
  };

  test('fetch parses the settings without the key itself', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(jsonEncode(saved), 200);
    });

    final result = await AiSettingsService(client: client)
        .fetch(accessToken: 'token');

    expect(sent.method, 'GET');
    expect(sent.url.path, '/api/v1/ai_settings');
    expect(result.ok, isTrue);
    expect(result.settings!.keyPresent, isTrue);
    expect(result.settings!.keyLast4, '9876');
    expect(result.settings!.preset, 'groq');
    expect(result.settings!.presets.single.model, 'llama-3.3-70b-versatile');
  });

  test('save sends the preset and trimmed fields', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(jsonEncode(saved), 200);
    });

    final result = await AiSettingsService(client: client).save(
      accessToken: 'token',
      preset: 'groq',
      apiKey: ' gsk_abc ',
      baseUrl: 'https://api.groq.com/openai/v1',
      model: 'llama-3.3-70b-versatile ',
    );

    expect(sent.method, 'PUT');
    expect(jsonDecode(sent.body), {
      'preset': 'groq',
      'api_key': 'gsk_abc',
      'base_url': 'https://api.groq.com/openai/v1',
      'model': 'llama-3.3-70b-versatile',
    });
    expect(result.ok, isTrue);
  });

  test('save reports the validation message', () async {
    final client = MockClient((_) async => http.Response(
        jsonEncode({
          'error': 'validation_failed',
          'message': 'Base URL must be an https:// address',
        }),
        422));

    final result = await AiSettingsService(client: client).save(
      accessToken: 'token',
      preset: 'custom',
      apiKey: 'k',
      baseUrl: 'http://example.com',
      model: 'm',
    );

    expect(result.ok, isFalse);
    expect(result.error, 'Base URL must be an https:// address');
  });

  test('a custom preset is not sent', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(jsonEncode({'success': true, 'reply': 'OK'}), 200);
    });

    await AiSettingsService(client: client).test(
      accessToken: 'token',
      preset: 'custom',
      apiKey: 'k',
      baseUrl: 'https://api.example.com/v1',
      model: 'm',
    );

    expect(sent.url.path, '/api/v1/ai_settings/test');
    expect(jsonDecode(sent.body).containsKey('preset'), isFalse);
  });

  test('test returns the provider error message', () async {
    final client = MockClient((_) async => http.Response(
        jsonEncode({
          'success': false,
          'error': 'connection_failed',
          'message': 'Invalid API Key',
        }),
        422));

    final result = await AiSettingsService(client: client).test(
      accessToken: 'token',
      preset: 'groq',
      apiKey: 'bad',
      baseUrl: '',
      model: '',
    );

    expect(result.ok, isFalse);
    expect(result.error, 'Invalid API Key');
  });

  test('remove deletes and returns the empty settings', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(
          jsonEncode({'key_present': false, 'can_edit': true}), 200);
    });

    final result = await AiSettingsService(client: client)
        .remove(accessToken: 'token');

    expect(sent.method, 'DELETE');
    expect(result.settings!.keyPresent, isFalse);
  });

  test('a network failure is reported as offline', () async {
    final client = MockClient((_) async => throw Exception('no network'));

    final result = await AiSettingsService(client: client)
        .fetch(accessToken: 'token');

    expect(result.error, AiSettingsResult.offline);
  });
}
