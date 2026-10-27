import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/services/insights_service.dart';

void main() {
  final body = jsonEncode({
    'insights': [
      {
        'id': 'i1',
        'type': 'spending_spike',
        'title': 'Groceries are up',
        'body': 'You spent Rs 4,000 more than usual.',
        'priority': 'high',
        'status': 'active',
        'generated_at': '2026-10-20T08:00:00Z',
      },
      {
        'id': 'i2',
        'type': 'bill_change',
        'title': 'Electricity bill rose',
        'body': 'Up 18% on last month.',
        'priority': 'low',
        'status': 'read',
        'generated_at': '2026-10-26T08:00:00Z',
      },
      {'id': 'i3', 'title': '  ', 'body': 'No title'},
    ],
  });

  group('Insight.listFromResponse', () {
    test('parses fields and sorts newest first', () {
      final insights = Insight.listFromResponse(body);

      expect(insights.map((i) => i.id), ['i2', 'i1']);
      final first = insights.first;
      expect(first.title, 'Electricity bill rose');
      expect(first.body, 'Up 18% on last month.');
      expect(first.type, 'bill_change');
      expect(first.priority, 'low');
      expect(first.generatedAt, DateTime.utc(2026, 10, 26, 8));
    });

    test('returns empty for an unexpected shape', () {
      expect(Insight.listFromResponse('[]'), isEmpty);
      expect(Insight.listFromResponse('{"insights": null}'), isEmpty);
    });
  });

  group('InsightsService', () {
    test('fetches insights', () async {
      late Uri url;
      final service = InsightsService(
        client: MockClient((request) async {
          url = request.url;
          return http.Response(body, 200);
        }),
      );

      final result = await service.getInsights(accessToken: 'token');

      expect(url.path, '/api/v1/insights');
      expect(result['success'], isTrue);
      expect((result['insights'] as List<Insight>).length, 2);
    });

    test('reports a disabled feature as a failure', () async {
      final service = InsightsService(
        client: MockClient(
            (_) async => http.Response('{"error":"feature_disabled"}', 403)),
      );

      final result = await service.getInsights(accessToken: 'token');
      expect(result['success'], isFalse);
    });

    test('flags unauthorized', () async {
      final service = InsightsService(
        client: MockClient((_) async => http.Response('', 401)),
      );

      final result = await service.getInsights(accessToken: 'token');
      expect(result['error'], 'unauthorized');
    });
  });
}
