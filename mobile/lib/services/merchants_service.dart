import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/merchant.dart';
import 'api_config.dart';
import 'response_list_parser.dart';

/// People (server-side merchants): who the family pays or gets paid by.
class MerchantsService {
  MerchantsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> getMerchants({
    required String accessToken,
  }) async {
    return fetchApiList<Merchant>(
      accessToken: accessToken,
      path: '/api/v1/merchants',
      key: 'merchants',
      resultKey: 'merchants',
      fromJson: Merchant.fromJson,
      isValid: (merchant) => merchant.id.isNotEmpty,
      failureMessage: 'Failed to fetch merchants',
    );
  }

  /// `POST /api/v1/merchants`. Only [name] is required.
  Future<Map<String, dynamic>> createMerchant({
    required String accessToken,
    required Map<String, String?> fields,
  }) {
    return _write(
      accessToken: accessToken,
      method: 'POST',
      path: '/api/v1/merchants',
      body: fields,
      fallback: 'Could not save this person',
    );
  }

  /// `PATCH /api/v1/merchants/:id`. An empty string clears a field.
  Future<Map<String, dynamic>> updateMerchant({
    required String accessToken,
    required String merchantId,
    required Map<String, String?> fields,
  }) {
    return _write(
      accessToken: accessToken,
      method: 'PATCH',
      path: '/api/v1/merchants/$merchantId',
      body: fields,
      fallback: 'Could not save this person',
    );
  }

  /// `DELETE /api/v1/merchants/:id`; their transactions keep everything else.
  Future<Map<String, dynamic>> deleteMerchant({
    required String accessToken,
    required String merchantId,
  }) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/merchants/$merchantId'),
            headers: ApiConfig.getAuthHeaders(accessToken),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      }
      if (response.statusCode == 401) {
        return {'success': false, 'error': 'unauthorized'};
      }
      return {
        'success': false,
        'error': extractErrorMessage(response.body,
            fallback: 'Could not delete this person'),
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> _write({
    required String accessToken,
    required String method,
    required String path,
    required Map<String, String?> body,
    required String fallback,
  }) async {
    try {
      final request =
          http.Request(method, Uri.parse('${ApiConfig.baseUrl}$path'))
            ..headers.addAll(ApiConfig.getJsonAuthHeaders(accessToken))
            ..body = jsonEncode({'merchant': body});
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 30)),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'merchant': Merchant.fromJson(Map<String, dynamic>.from(json as Map)),
        };
      }
      if (response.statusCode == 401) {
        return {'success': false, 'error': 'unauthorized'};
      }
      return {
        'success': false,
        'error': extractErrorMessage(response.body, fallback: fallback),
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
