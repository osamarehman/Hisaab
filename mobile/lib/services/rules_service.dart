import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/rule.dart';
import 'api_config.dart';
import 'response_list_parser.dart';

/// Auto-label keywords (Sure rules). See docs/redesign/household-api.md.
class RulesService {
  RulesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> _headers(String token) => {
        ...ApiConfig.getAuthHeaders(token),
        'Content-Type': 'application/json',
      };

  /// All transaction rules, every page.
  Future<Map<String, dynamic>> getRules({required String accessToken}) async {
    final rules = <LabelRule>[];
    try {
      for (var page = 1; page <= 20; page++) {
        final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/rules').replace(
          queryParameters: {
            'resource_type': 'transaction',
            'page': '$page',
            'per_page': '100',
          },
        );
        final response = await _client
            .get(url, headers: _headers(accessToken))
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 401) {
          return {'success': false, 'error': 'unauthorized'};
        }
        if (response.statusCode != 200) {
          return {
            'success': false,
            'error': extractErrorMessage(response.body,
                fallback: 'Failed to fetch auto-label keywords'),
          };
        }
        final body = jsonDecode(response.body);
        for (final json in extractJsonObjectList(body, key: 'data')) {
          rules.add(LabelRule.fromJson(json));
        }
        final next = body is Map && body['meta'] is Map
            ? (body['meta'] as Map)['next_page']
            : null;
        if (next == null) break;
      }
      return {'success': true, 'rules': rules};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// `POST /api/v1/rules`: lines whose name contains [keyword] get
  /// [categoryId]; [applyToExisting] also relabels lines already imported.
  Future<Map<String, dynamic>> createRule({
    required String accessToken,
    required String keyword,
    required String categoryId,
    bool applyToExisting = true,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/rules'),
            headers: _headers(accessToken),
            body: jsonEncode({
              'rule': {
                'keyword': keyword,
                'category_id': categoryId,
                'apply_to_existing': applyToExisting,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return {
          'success': true,
          'rule': body is Map
              ? LabelRule.fromJson(Map<String, dynamic>.from(body))
              : null,
        };
      }
      if (response.statusCode == 401) {
        return {'success': false, 'error': 'unauthorized'};
      }
      return {
        'success': false,
        'error': extractErrorMessage(response.body,
            fallback: 'Could not save the keyword'),
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteRule({
    required String accessToken,
    required String ruleId,
  }) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/rules/$ruleId'),
            headers: _headers(accessToken),
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
            fallback: 'Could not remove the keyword'),
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
