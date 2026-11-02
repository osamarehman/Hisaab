import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/models/period.dart';
import 'package:sure_mobile/services/cash_flow_service.dart';

void main() {
  group('PeriodCashFlow.fromJson', () {
    test('reads the statement fields and spending by label', () {
      final flow = PeriodCashFlow.fromJson({
        'currency': 'PKR',
        'income': '0.00',
        'spending': '228000.00',
        'opening_balance': '138550.00',
        'closing_balance': '-89450.00',
        'other_changes': '0.00',
        'spending_comparison': {'delta': '-1200.50'},
        'spending_by_category': [
          {
            'category_id': 'c1',
            'name': 'Rent',
            'color': '#112233',
            'amount': '200000.00'
          },
          {
            'category_id': null,
            'name': null,
            'color': null,
            'amount': '28000.00'
          },
        ],
      });

      expect(flow.hasStatement, isTrue);
      expect(flow.openingBalance, 138550);
      expect(flow.closingBalance, -89450);
      expect(flow.otherChanges, 0);
      expect(flow.spendingDelta, -1200.5);
      // Opening + in − out + other = closing.
      expect(
        flow.openingBalance! + flow.income - flow.spending + flow.otherChanges!,
        flow.closingBalance,
      );
      expect(flow.byCategory!.map((c) => c.categoryId), ['c1', null]);
      expect(flow.byCategory!.last.amount, 28000);
    });

    test('older servers: statement and categories are not available', () {
      final flow = PeriodCashFlow.fromJson({
        'currency': 'PKR',
        'income': '5000',
        'spending': '3000',
        'spending_comparison': null,
      });

      expect(flow.hasStatement, isFalse);
      expect(flow.openingBalance, isNull);
      expect(flow.otherChanges, isNull);
      expect(flow.byCategory, isNull);
      expect(flow.spendingDelta, isNull);
    });
  });

  test('getPeriod sends the period query and reports failures', () async {
    final seen = <Uri>[];
    final client = MockClient((request) async {
      seen.add(request.url);
      if (request.url.queryParameters.containsKey('period')) {
        return http.Response(jsonEncode({'error': 'invalid_month'}), 422);
      }
      return http.Response(
          jsonEncode({'currency': 'PKR', 'income': '1', 'spending': '2'}), 200);
    });
    final service = CashFlowService(client: client);

    final month = await service.getPeriod(
        accessToken: 't', period: Period.month(DateTime(2026, 10)));
    expect(month['success'], isTrue);
    expect(seen.last.queryParameters, {'month': '2026-10-01'});

    final all = await service.getPeriod(
        accessToken: 't', period: const Period.allTime());
    expect(all['success'], isFalse);
    expect(seen.last.queryParameters, {'period': 'all_time'});
  });
}
