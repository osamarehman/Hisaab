import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import '../models/chat.dart';
import '../models/message.dart';
import '../models/pending_action.dart';
import 'api_config.dart';
import 'imports_service.dart';

class ChatService {
  ChatService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;

  /// Whether this service created [_client] itself. Injected clients stay the
  /// caller's responsibility and must not be closed here.
  final bool _ownsClient;

  /// Closes the underlying HTTP client, but only when this service created it.
  void close() {
    if (_ownsClient) _client.close();
  }

  /// Get list of chats with pagination
  Future<Map<String, dynamic>> getChats({
    required String accessToken,
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/chats?page=$page&per_page=$perPage',
      );

      final response = await _client.get(
        url,
        headers: ApiConfig.getAuthHeaders(accessToken),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final chatsList = (responseData['chats'] as List)
            .map((json) => Chat.fromJson(json))
            .toList();

        return {
          'success': true,
          'chats': chatsList,
          'pagination': responseData['pagination'],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 403) {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': 'feature_disabled',
          'message': responseData['message'] ?? 'AI features not enabled',
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch chats',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get a specific chat with messages
  Future<Map<String, dynamic>> getChat({
    required String accessToken,
    required String chatId,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/chats/$chatId?page=$page&per_page=$perPage',
      );

      final response = await _client.get(
        url,
        headers: ApiConfig.getAuthHeaders(accessToken),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final chat = Chat.fromJson(responseData);

        return {
          'success': true,
          'chat': chat,
          // Expose pagination so callers can fetch the remaining pages.
          // The API orders messages oldest-first and paginates them, so a
          // single request only returns one page of a long conversation.
          'pagination': responseData['pagination'],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'not_found',
          'message': 'Chat not found',
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch chat',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Create a new chat with optional initial message
  Future<Map<String, dynamic>> createChat({
    required String accessToken,
    String? title,
    String? initialMessage,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chats');

      final body = <String, dynamic>{};

      if (title != null) {
        body['title'] = title;
      }

      if (initialMessage != null) {
        body['message'] = initialMessage;
      }

      final response = await _client.post(
        url,
        headers: {
          ...ApiConfig.getAuthHeaders(accessToken),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final chat = Chat.fromJson(responseData);

        return {
          'success': true,
          'chat': chat,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 403) {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': 'feature_disabled',
          'message': responseData['message'] ?? 'AI features not enabled',
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to create chat',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Send a message to a chat
  Future<Map<String, dynamic>> sendMessage({
    required String accessToken,
    required String chatId,
    required String content,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chats/$chatId/messages');

      final response = await _client.post(
        url,
        headers: {
          ...ApiConfig.getAuthHeaders(accessToken),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final message = Message.fromJson(responseData);

        return {
          'success': true,
          'message': message,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'not_found',
          'message': 'Chat not found',
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to send message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Update chat title
  Future<Map<String, dynamic>> updateChat({
    required String accessToken,
    required String chatId,
    required String title,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chats/$chatId');

      final response = await _client.patch(
        url,
        headers: {
          ...ApiConfig.getAuthHeaders(accessToken),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final chat = Chat.fromJson(responseData);

        return {
          'success': true,
          'chat': chat,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'not_found',
          'message': 'Chat not found',
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to update chat',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Delete a chat
  Future<Map<String, dynamic>> deleteChat({
    required String accessToken,
    required String chatId,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chats/$chatId');

      final response = await _client.delete(
        url,
        headers: ApiConfig.getAuthHeaders(accessToken),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 204) {
        return {
          'success': true,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'not_found',
          'message': 'Chat not found',
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to delete chat',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Delete multiple chats in parallel
  Future<Map<String, dynamic>> deleteMultipleChats({
    required String accessToken,
    required List<String> chatIds,
  }) async {
    final results = await Future.wait(
      chatIds.map((id) async {
        try {
          return await deleteChat(accessToken: accessToken, chatId: id);
        } catch (_) {
          return {'success': false};
        }
      }),
      eagerError: false,
    );
    final failedIds = chatIds
        .asMap()
        .entries
        .where((e) => results[e.key]['success'] != true)
        .map((e) => e.value)
        .toList();
    return {
      'success': failedIds.isEmpty,
      'deletedCount': chatIds.length - failedIds.length,
      'failedIds': failedIds,
    };
  }

  /// Retry the last assistant response in a chat
  Future<Map<String, dynamic>> retryMessage({
    required String accessToken,
    required String chatId,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chats/$chatId/messages/retry');

      final response = await _client.post(
        url,
        headers: ApiConfig.getAuthHeaders(accessToken),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 202) {
        return {
          'success': true,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'not_found',
          'message': 'Chat not found',
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to retry message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Hands an uploaded statement import to the assistant, which reads it and
  /// proposes the entries. Answers 202 with the user message it added.
  Future<Map<String, dynamic>> attachStatement({
    required String accessToken,
    required String chatId,
    required String importId,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(
                '${ApiConfig.baseUrl}/api/v1/chats/$chatId/statements'),
            headers: {
              ...ApiConfig.getAuthHeaders(accessToken),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'import_id': importId}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 202 || response.statusCode == 201) {
        return {
          'success': true,
          'message': _messageFrom(response.body),
        };
      }
      return _failure(response, 'Could not send the statement');
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Uploads a WAV voice note; the server transcribes it and posts the
  /// transcript as the user's message, then starts the assistant reply.
  Future<Map<String, dynamic>> uploadVoiceNote({
    required String accessToken,
    required String chatId,
    required Uint8List audioBytes,
    required int durationMs,
  }) async {
    final boundary = 'sure-${Random().nextInt(1 << 32)}'
        '${DateTime.now().microsecondsSinceEpoch}';
    final request = http.Request(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/v1/chats/$chatId/voice_notes'),
    )
      ..headers.addAll(ApiConfig.getAuthHeaders(accessToken))
      ..headers['Content-Type'] = 'multipart/form-data; boundary=$boundary'
      ..bodyBytes = ImportsService.buildMultipartBody(
        boundary: boundary,
        fields: {'duration_ms': '$durationMs'},
        fileField: 'audio',
        fileName: 'voice.wav',
        fileContentType: 'audio/wav',
        fileBytes: audioBytes,
      );

    try {
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'transcript': data['transcript']?.toString() ?? '',
          'message': _messageFrom(response.body),
        };
      }
      return _failure(response, 'Could not send the voice note');
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Saves the given pending actions. Already-applied ones come back
  /// unchanged; ones that could not be saved come back `failed` with `error`.
  Future<Map<String, dynamic>> confirmActions({
    required String accessToken,
    required String chatId,
    required List<String> ids,
  }) =>
      _pendingActionsRequest(accessToken, chatId, 'confirm', ids);

  /// Discards the given pending actions.
  Future<Map<String, dynamic>> cancelActions({
    required String accessToken,
    required String chatId,
    required List<String> ids,
  }) =>
      _pendingActionsRequest(accessToken, chatId, 'cancel', ids);

  Future<Map<String, dynamic>> _pendingActionsRequest(
    String accessToken,
    String chatId,
    String verb,
    List<String> ids,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/chats/$chatId'
                '/pending_actions/$verb'),
            headers: {
              ...ApiConfig.getAuthHeaders(accessToken),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'ids': ids}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'pendingActions': PendingAction.listFromJson(
            data is Map ? data['pending_actions'] : null,
          ),
        };
      }
      return _failure(response, 'Could not update the changes');
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Message _messageFrom(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    return Message.fromJson(data['message'] as Map<String, dynamic>);
  }

  /// `error` is the server's code (e.g. `audio_too_long`); `message` is only
  /// set when the server sent user-facing text, so callers can fall back to a
  /// localized line.
  Map<String, dynamic> _failure(http.Response response, String fallback) {
    if (response.statusCode == 401) {
      return {
        'success': false,
        'error': 'unauthorized',
        'message': 'Session expired. Please login again.',
      };
    }
    Object? data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {}
    final map = data is Map ? data : const {};
    final error = map['error']?.toString();
    final message = map['message']?.toString();
    return {
      'success': false,
      'error': error ??
          (response.statusCode == 404 ? 'not_found' : fallback),
      if (message != null && message.trim().isNotEmpty) 'message': message,
    };
  }
}
