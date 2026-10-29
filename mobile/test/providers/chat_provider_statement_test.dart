import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/providers/chat_provider.dart';
import 'package:sure_mobile/services/chat_service.dart';
import 'package:sure_mobile/services/imports_service.dart';

Map<String, dynamic> _message(String id, String role, String content) => {
      'id': id,
      'type': role == 'user' ? 'user_message' : 'assistant_message',
      'role': role,
      'content': content,
      'created_at': '2026-10-29T10:00:00Z',
      'updated_at': '2026-10-29T10:00:00Z',
    };

Map<String, dynamic> _chat(List<Map<String, dynamic>> messages,
        {required int total, int pages = 1}) =>
    {
      'id': 'chat-1',
      'title': 'oct.pdf',
      'created_at': '2026-10-29T10:00:00Z',
      'updated_at': '2026-10-29T10:00:00Z',
      'messages': messages,
      'pending_actions': [],
      'pagination': {
        'page': 1,
        'per_page': 50,
        'total_count': total,
        'total_pages': pages,
      },
    };

void main() {
  testWidgets(
      'statement wait polls page 1 only until a new message, then loads all',
      (tester) async {
    final requestedPages = <String>[];
    var polls = 0;
    final user = _message('m-1', 'user', 'Statement: oct.pdf');

    final client = MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'POST' && path == '/api/v1/chats') {
        return http.Response(jsonEncode(_chat([], total: 0)), 201);
      }
      if (path == '/api/v1/imports') {
        return http.Response(
          jsonEncode({
            'data': {'id': 'imp-1', 'type': 'PdfImport', 'status': 'pending'},
          }),
          202,
        );
      }
      if (path == '/api/v1/chats/chat-1/statements') {
        return http.Response(jsonEncode({'message': user}), 202);
      }
      final page = request.url.queryParameters['page'] ?? '1';
      requestedPages.add(page);
      if (page == '1') polls++;
      if (polls < 2) return http.Response(jsonEncode(_chat([user], total: 1)), 200);
      if (page == '1') {
        return http.Response(
            jsonEncode(_chat([user], total: 2, pages: 2)), 200);
      }
      return http.Response(
        jsonEncode(_chat(
          [_message('m-2', 'assistant', 'I found 12 entries.')],
          total: 2,
          pages: 2,
        )),
        200,
      );
    });

    final provider = ChatProvider(
      chatService: ChatService(client: client),
      importsService: ImportsService(client: client),
    );
    await provider.createChat(accessToken: 'token', title: 'oct.pdf');

    ChatRequestResult? result;
    provider
        .attachStatement(
          accessToken: 'token',
          chatId: 'chat-1',
          accountId: 'acc-1',
          fileName: 'oct.pdf',
          bytes: Uint8List.fromList(utf8.encode('%PDF')),
        )
        .then((r) => result = r);

    await tester.pump();
    expect(provider.isReadingStatement, isTrue);

    await tester.pump(const Duration(seconds: 3));
    expect(requestedPages, ['1']);
    expect(result, isNull);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(requestedPages, ['1', '1', '2']);
    expect(result?.ok, isTrue);
    expect(provider.isReadingStatement, isFalse);
    expect(provider.currentChat!.messages.map((m) => m.id), ['m-1', 'm-2']);

    provider.dispose();
  });
}
