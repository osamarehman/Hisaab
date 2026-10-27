import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/account.dart';
import 'api_config.dart';
import 'response_list_parser.dart';

class AccountsService {
  AccountsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> getAccounts({
    required String accessToken,
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/accounts?page=$page&per_page=$perPage',
      );

      final response = await _client
          .get(
            url,
            headers: ApiConfig.getAuthHeaders(accessToken),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final accountsList = (responseData['accounts'] as List)
            .map((json) => Account.fromJson(json))
            .toList();

        return {
          'success': true,
          'accounts': accountsList,
          'pagination': responseData['pagination'],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
          'message': 'Session expired. Please login again.',
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch accounts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// `POST /api/v1/accounts`: a manual account with its opening balance.
  /// [accountableType] is one of Depository, CreditCard, Loan, OtherAsset,
  /// OtherLiability; [balance] is a plain decimal string ("25000.50"), the
  /// amount owed for liabilities.
  Future<Map<String, dynamic>> createAccount({
    required String accessToken,
    required String name,
    required String accountableType,
    String? subtype,
    required String balance,
    String? currency,
  }) {
    return _write(
      accessToken: accessToken,
      method: 'POST',
      path: '/api/v1/accounts',
      body: {
        'name': name,
        'accountable_type': accountableType,
        if (subtype != null) 'subtype': subtype,
        'balance': balance,
        if (currency != null) 'currency': currency,
      },
      fallback: 'Could not add the account',
    );
  }

  /// `PATCH /api/v1/accounts/:id`: rename and/or set today's balance.
  Future<Map<String, dynamic>> updateAccount({
    required String accessToken,
    required String accountId,
    String? name,
    String? balance,
  }) {
    return _write(
      accessToken: accessToken,
      method: 'PATCH',
      path: '/api/v1/accounts/$accountId',
      body: {
        if (name != null) 'name': name,
        if (balance != null) 'balance': balance,
      },
      fallback: 'Could not save the account',
    );
  }

  /// `DELETE /api/v1/accounts/:id`; the server removes it in the background.
  Future<Map<String, dynamic>> deleteAccount({
    required String accessToken,
    required String accountId,
  }) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/accounts/$accountId'),
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
            fallback: 'Could not delete the account'),
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> _write({
    required String accessToken,
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required String fallback,
  }) async {
    try {
      final request =
          http.Request(method, Uri.parse('${ApiConfig.baseUrl}$path'))
            ..headers.addAll(ApiConfig.getJsonAuthHeaders(accessToken))
            ..body = jsonEncode({'account': body});
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 30)),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'account': Account.fromJson(Map<String, dynamic>.from(json as Map)),
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
