import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Outcome of a family settings call: the household [currency] on success,
/// otherwise [error] (one of the constants below, or the server's message).
class FamilySettingsResult {
  const FamilySettingsResult.success(String this.currency) : error = null;
  const FamilySettingsResult.failure(String this.error) : currency = null;

  final String? currency;
  final String? error;

  static const offline = 'offline';
  static const unauthorized = 'unauthorized';

  /// A member who isn't a household admin, or a read-only token.
  static const forbidden = 'forbidden';

  bool get ok => error == null;
}

/// `/api/v1/family_settings`: household defaults such as the currency.
class FamilySettingsService {
  FamilySettingsService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Uri get _uri => Uri.parse('${ApiConfig.baseUrl}/api/v1/family_settings');

  Future<FamilySettingsResult> fetch({required String accessToken}) =>
      _call(http.Request('GET', _uri), accessToken);

  /// Changes the household currency. Existing accounts keep their own.
  Future<FamilySettingsResult> setCurrency({
    required String accessToken,
    required String currency,
  }) =>
      _call(
        http.Request('PATCH', _uri)..body = jsonEncode({'currency': currency}),
        accessToken,
      );

  Future<FamilySettingsResult> _call(
      http.Request request, String accessToken) async {
    try {
      request.headers.addAll(ApiConfig.getJsonAuthHeaders(accessToken));
      final response = await http.Response.fromStream(
          await _client.send(request).timeout(_timeout));
      final data = _decode(response.body);
      if (response.statusCode == 200) {
        final currency = data['currency']?.toString();
        if (currency != null && currency.isNotEmpty) {
          return FamilySettingsResult.success(currency.toUpperCase());
        }
        return const FamilySettingsResult.failure('');
      }
      if (response.statusCode == 401) {
        return const FamilySettingsResult.failure(
            FamilySettingsResult.unauthorized);
      }
      if (response.statusCode == 403) {
        return const FamilySettingsResult.failure(
            FamilySettingsResult.forbidden);
      }
      return FamilySettingsResult.failure(
          (data['message'] ?? data['error'] ?? '').toString());
    } catch (_) {
      return const FamilySettingsResult.failure(FamilySettingsResult.offline);
    }
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final data = jsonDecode(body);
      return data is Map ? Map<String, dynamic>.from(data) : const {};
    } catch (_) {
      return const {};
    }
  }
}
