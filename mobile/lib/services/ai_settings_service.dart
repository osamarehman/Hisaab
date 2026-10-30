import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// An OpenAI-compatible provider the settings screen can prefill.
class AiPreset {
  const AiPreset({
    required this.id,
    required this.baseUrl,
    required this.model,
  });

  factory AiPreset.fromJson(Map<String, dynamic> json) => AiPreset(
        id: json['id'] as String? ?? '',
        baseUrl: json['base_url'] as String? ?? '',
        model: json['model'] as String? ?? '',
      );

  final String id;
  final String baseUrl;
  final String model;
}

/// The household's own AI key, as the server reports it. The key itself never
/// comes back, only whether one is set and its last four characters.
class AiSettings {
  const AiSettings({
    required this.keyPresent,
    this.keyLast4,
    this.baseUrl,
    this.model,
    this.preset,
    this.canEdit = false,
    this.aiAvailable = false,
    this.presets = const [],
  });

  factory AiSettings.fromJson(Map<String, dynamic> json) => AiSettings(
        keyPresent: json['key_present'] == true,
        keyLast4: json['key_last4'] as String?,
        baseUrl: json['base_url'] as String?,
        model: json['model'] as String?,
        preset: json['preset'] as String?,
        canEdit: json['can_edit'] == true,
        aiAvailable: json['ai_available'] == true,
        presets: (json['presets'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AiPreset.fromJson)
            .toList(),
      );

  final bool keyPresent;
  final String? keyLast4;
  final String? baseUrl;
  final String? model;

  /// `gemini`, `openrouter`, `groq`, `custom`, or null without a key.
  final String? preset;
  final bool canEdit;
  final bool aiAvailable;
  final List<AiPreset> presets;
}

/// Outcome of a call: [settings] (or [reply] for a test) on success,
/// otherwise [error] with the server's or provider's message when it gave one.
class AiSettingsResult {
  const AiSettingsResult.success({this.settings, this.reply}) : error = null;
  const AiSettingsResult.failure([this.error])
      : settings = null,
        reply = null;

  final AiSettings? settings;
  final String? reply;
  final String? error;

  static const offline = 'offline';

  bool get ok => error == null;
}

/// `/api/v1/ai_settings`: the household's bring-your-own AI key.
class AiSettingsService {
  AiSettingsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Uri get _uri => Uri.parse('${ApiConfig.baseUrl}/api/v1/ai_settings');

  Map<String, String> _headers(String accessToken) => {
        ...ApiConfig.getAuthHeaders(accessToken),
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<AiSettingsResult> fetch({required String accessToken}) =>
      _settingsCall(() => _client.get(_uri, headers: _headers(accessToken)));

  /// A blank [apiKey] keeps the stored key.
  Future<AiSettingsResult> save({
    required String accessToken,
    required String preset,
    required String apiKey,
    required String baseUrl,
    required String model,
  }) =>
      _settingsCall(() => _client.put(
            _uri,
            headers: _headers(accessToken),
            body: _body(preset, apiKey, baseUrl, model),
          ));

  Future<AiSettingsResult> remove({required String accessToken}) =>
      _settingsCall(() => _client.delete(_uri, headers: _headers(accessToken)));

  /// One tiny completion with these settings (or the stored ones for blank
  /// fields); the provider's own error message comes back on failure.
  Future<AiSettingsResult> test({
    required String accessToken,
    required String preset,
    required String apiKey,
    required String baseUrl,
    required String model,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_uri/test'),
            headers: _headers(accessToken),
            body: _body(preset, apiKey, baseUrl, model),
          )
          .timeout(_timeout);
      final data = _decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return AiSettingsResult.success(reply: data['reply'] as String?);
      }
      return AiSettingsResult.failure(_message(data));
    } catch (_) {
      return const AiSettingsResult.failure(AiSettingsResult.offline);
    }
  }

  String _body(String preset, String apiKey, String baseUrl, String model) =>
      jsonEncode({
        if (preset != 'custom') 'preset': preset,
        'api_key': apiKey.trim(),
        'base_url': baseUrl.trim(),
        'model': model.trim(),
      });

  Future<AiSettingsResult> _settingsCall(
      Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      final data = _decode(response.body);
      if (response.statusCode == 200) {
        return AiSettingsResult.success(settings: AiSettings.fromJson(data));
      }
      return AiSettingsResult.failure(_message(data));
    } catch (_) {
      return const AiSettingsResult.failure(AiSettingsResult.offline);
    }
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  /// Empty when the server gave no message, so the screen shows its own.
  String _message(Map<String, dynamic> data) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    return '';
  }
}
