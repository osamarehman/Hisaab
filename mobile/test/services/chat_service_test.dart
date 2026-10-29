import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/models/message.dart';
import 'package:sure_mobile/models/pending_action.dart';
import 'package:sure_mobile/services/chat_service.dart';

Map<String, dynamic> _userMessage(String content) => {
      'id': 'msg-9',
      'chat_id': 'chat-1',
      'type': 'user_message',
      'role': 'user',
      'content': content,
      'created_at': '2026-10-29T10:00:00Z',
      'updated_at': '2026-10-29T10:00:00Z',
      'ai_response_status': 'pending',
    };

void main() {
  test('uploadVoiceNote sends a WAV multipart with duration_ms', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(
        jsonEncode({
          'transcript': 'Add 500 for milk',
          'message': _userMessage('Add 500 for milk'),
        }),
        201,
      );
    });

    final result = await ChatService(client: client).uploadVoiceNote(
      accessToken: 'token',
      chatId: 'chat-1',
      audioBytes: Uint8List.fromList(utf8.encode('RIFFfake')),
      durationMs: 4200,
    );

    expect(result['success'], isTrue);
    expect(result['transcript'], 'Add 500 for milk');
    expect((result['message'] as Message).content, 'Add 500 for milk');

    expect(sent.method, 'POST');
    expect(sent.url.path, '/api/v1/chats/chat-1/voice_notes');
    final contentType = sent.headers['Content-Type']!;
    expect(contentType, startsWith('multipart/form-data; boundary='));
    final boundary = contentType.split('boundary=').last;
    final body = latin1.decode(sent.bodyBytes);
    expect(body, contains('name="duration_ms"\r\n\r\n4200\r\n'));
    expect(body, contains('name="audio"; filename="voice.wav"'));
    expect(body, contains('Content-Type: audio/wav\r\n\r\nRIFFfake'));
    expect(body, endsWith('--$boundary--\r\n'));
  });

  test('uploadVoiceNote surfaces the server code and message on 422',
      () async {
    final client = MockClient((_) async => http.Response(
          jsonEncode({
            'error': 'audio_too_long',
            'message': 'Voice notes can be up to 2 minutes.',
          }),
          422,
        ));

    final result = await ChatService(client: client).uploadVoiceNote(
      accessToken: 'token',
      chatId: 'chat-1',
      audioBytes: Uint8List(4),
      durationMs: 1000,
    );

    expect(result['success'], isFalse);
    expect(result['error'], 'audio_too_long');
    expect(result['message'], 'Voice notes can be up to 2 minutes.');
  });

  test('attachStatement posts the import id and parses the message', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(
        jsonEncode({'message': _userMessage('Statement: oct.pdf')}),
        202,
      );
    });

    final result = await ChatService(client: client).attachStatement(
      accessToken: 'token',
      chatId: 'chat-1',
      importId: 'imp-1',
    );

    expect(result['success'], isTrue);
    expect((result['message'] as Message).isUser, isTrue);
    expect(sent.url.path, '/api/v1/chats/chat-1/statements');
    expect(jsonDecode(sent.body), {'import_id': 'imp-1'});
  });

  test('confirmActions posts the ids and returns the updated actions',
      () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(
        jsonEncode({
          'pending_actions': [
            {'id': 'pa-1', 'kind': 'create_entry', 'status': 'applied'},
            {
              'id': 'pa-2',
              'kind': 'create_entry',
              'status': 'failed',
              'error': 'Could not save: no account',
            },
          ],
        }),
        200,
      );
    });

    final result = await ChatService(client: client).confirmActions(
      accessToken: 'token',
      chatId: 'chat-1',
      ids: ['pa-1', 'pa-2'],
    );

    expect(sent.url.path, '/api/v1/chats/chat-1/pending_actions/confirm');
    expect(jsonDecode(sent.body), {
      'ids': ['pa-1', 'pa-2'],
    });
    final actions = result['pendingActions'] as List<PendingAction>;
    expect(actions.map((a) => a.status), ['applied', 'failed']);
    expect(actions.last.error, 'Could not save: no account');
  });

  test('cancelActions hits the cancel endpoint', () async {
    late Uri url;
    final client = MockClient((request) async {
      url = request.url;
      return http.Response('{"pending_actions": []}', 200);
    });

    final result = await ChatService(client: client).cancelActions(
      accessToken: 'token',
      chatId: 'chat-1',
      ids: ['pa-1'],
    );

    expect(result['success'], isTrue);
    expect(url.path, '/api/v1/chats/chat-1/pending_actions/cancel');
  });
}
