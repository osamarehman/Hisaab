import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// A note the server generated about the family's money (`GET /api/v1/insights`).
class Insight {
  const Insight({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.priority,
    this.generatedAt,
  });

  final String id;
  final String title;
  final String body;
  final String? type;
  final String? priority;
  final DateTime? generatedAt;

  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        type: json['type']?.toString(),
        priority: json['priority']?.toString(),
        generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? ''),
      );

  /// Parses an index response body: titled insights, newest first.
  static List<Insight> listFromResponse(String body) {
    final data = jsonDecode(body);
    final raw = data is Map ? data['insights'] : null;
    if (raw is! List) return const [];
    final insights = raw
        .whereType<Map>()
        .map((m) => Insight.fromJson(Map<String, dynamic>.from(m)))
        .where((i) => i.title.trim().isNotEmpty)
        .toList();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    insights.sort(
        (a, b) => (b.generatedAt ?? epoch).compareTo(a.generatedAt ?? epoch));
    return insights;
  }
}

class InsightsService {
  InsightsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Returns `{'success': true, 'insights': List<Insight>}` or an error map.
  Future<Map<String, dynamic>> getInsights({
    required String accessToken,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/insights');
    try {
      final response = await _client
          .get(url, headers: ApiConfig.getAuthHeaders(accessToken))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return {
          'success': true,
          'insights': Insight.listFromResponse(response.body),
        };
      }
      if (response.statusCode == 401) {
        return {'success': false, 'error': 'unauthorized'};
      }
      return {'success': false, 'error': 'Failed to fetch insights'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
