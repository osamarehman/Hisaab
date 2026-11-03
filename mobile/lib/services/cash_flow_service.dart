import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/period.dart';
import 'api_config.dart';

/// One label's spending in the period, from `spending_by_category`.
class CategorySpend {
  const CategorySpend({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.amount,
  });

  /// null = spending without a label.
  final String? categoryId;
  final String? name;
  final String? color;
  final double amount;
}

/// Income, spending and the opening/closing cash position for a period,
/// from `GET /api/v1/cash_flow`.
///
/// Servers older than the statement fields omit [openingBalance],
/// [closingBalance], [otherChanges] and [byCategory]; callers hide those
/// parts when they are null.
class PeriodCashFlow {
  const PeriodCashFlow({
    required this.currency,
    required this.income,
    required this.spending,
    this.spendingDelta,
    this.openingBalance,
    this.closingBalance,
    this.otherChanges,
    this.byCategory,
  });

  /// The household currency; null when the server didn't say.
  final String? currency;
  final double income;
  final double spending;

  /// Spending minus the previous period's spending (to the same day for a
  /// month). null when there is nothing to compare with.
  final double? spendingDelta;

  final double? openingBalance;
  final double? closingBalance;

  /// Balance changes that are neither income nor spending.
  final double? otherChanges;

  final List<CategorySpend>? byCategory;

  bool get hasStatement => openingBalance != null && closingBalance != null;

  factory PeriodCashFlow.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
    double? maybe(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    final comparison = json['spending_comparison'];
    final categories = json['spending_by_category'];
    return PeriodCashFlow(
      currency: json['currency']?.toString(),
      income: parse(json['income']),
      spending: parse(json['spending']),
      spendingDelta: comparison is Map ? maybe(comparison['delta']) : null,
      openingBalance: maybe(json['opening_balance']),
      closingBalance: maybe(json['closing_balance']),
      otherChanges: maybe(json['other_changes']),
      byCategory: categories is List
          ? [
              for (final c in categories.whereType<Map>())
                CategorySpend(
                  categoryId: c['category_id']?.toString(),
                  name: c['name']?.toString(),
                  color: c['color']?.toString(),
                  amount: parse(c['amount']),
                ),
            ]
          : null,
    );
  }
}

class CashFlowService {
  CashFlowService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Fails (success: false) for ranges on servers that only support months;
  /// callers fall back to totals computed from transactions.
  Future<Map<String, dynamic>> getPeriod({
    required String accessToken,
    required Period period,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/cash_flow')
        .replace(queryParameters: period.cashFlowQuery());

    try {
      final response = await _client
          .get(url, headers: ApiConfig.getAuthHeaders(accessToken))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'cash_flow': PeriodCashFlow.fromJson(Map<String, dynamic>.from(data)),
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
