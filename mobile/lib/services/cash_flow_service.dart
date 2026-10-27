import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// One month of income/spending from `GET /api/v1/cash_flow`.
class MonthCashFlow {
  const MonthCashFlow({
    required this.currency,
    required this.income,
    required this.spending,
    this.spendingDelta,
  });

  final String currency;
  final double income;
  final double spending;

  /// Spending minus the previous month's spending up to the same day.
  final double? spendingDelta;

  factory MonthCashFlow.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
    final comparison = json['spending_comparison'];
    return MonthCashFlow(
      currency: json['currency']?.toString() ?? 'PKR',
      income: parse(json['income']),
      spending: parse(json['spending']),
      spendingDelta: comparison is Map
          ? double.tryParse(comparison['delta']?.toString() ?? '')
          : null,
    );
  }
}

class CashFlowService {
  CashFlowService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// [month] is any day in the (non-future) month.
  Future<Map<String, dynamic>> getMonth({
    required String accessToken,
    required DateTime month,
  }) async {
    final first =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-01';
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/cash_flow')
        .replace(queryParameters: {'month': first});

    try {
      final response = await _client
          .get(url, headers: ApiConfig.getAuthHeaders(accessToken))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'cash_flow': MonthCashFlow.fromJson(Map<String, dynamic>.from(data)),
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'unauthorized'};
      }
      return {'success': false, 'error': 'Failed to fetch cash flow'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
