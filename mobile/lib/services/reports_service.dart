import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'api_config.dart';
import 'transactions_service.dart';

/// Result of a report download: the PDF bytes, or an error message.
class ReportDownload {
  const ReportDownload.success(this.bytes, this.filename) : error = null;
  const ReportDownload.failure([this.error])
      : bytes = null,
        filename = null;

  final Uint8List? bytes;
  final String? filename;

  /// [unauthorized], [offline], the server's message, or null when the
  /// server gave none.
  final String? error;

  static const unauthorized = 'unauthorized';
  static const offline = 'offline';

  bool get ok => bytes != null;
}

/// `GET /api/v1/reports/export.pdf`: the household PDF report.
class ReportsService {
  ReportsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final _date = DateFormat('yyyy-MM-dd');

  /// [categoryIds] null means every label; otherwise only those labels, plus
  /// unlabelled rows when [includeUnlabelled]. [accountIds] null means every
  /// account.
  Uri exportUri({
    required DateTime start,
    required DateTime end,
    List<String>? categoryIds,
    bool includeUnlabelled = true,
    List<String>? accountIds,
  }) {
    final base = Uri.parse('${ApiConfig.baseUrl}/api/v1/reports/export.pdf');
    return base.replace(queryParameters: {
      'start_date': _date.format(start),
      'end_date': _date.format(end),
      if (categoryIds != null) ...{
        'category_ids[]': categoryIds,
        'include_uncategorized': includeUnlabelled.toString(),
      },
      if (accountIds != null) 'account_ids[]': accountIds,
    });
  }

  Future<ReportDownload> download({
    required String accessToken,
    required DateTime start,
    required DateTime end,
    List<String>? categoryIds,
    bool includeUnlabelled = true,
    List<String>? accountIds,
  }) async {
    final uri = exportUri(
      start: start,
      end: end,
      categoryIds: categoryIds,
      includeUnlabelled: includeUnlabelled,
      accountIds: accountIds,
    );
    try {
      final response = await _client.get(uri, headers: {
        ...ApiConfig.getAuthHeaders(accessToken),
        'Accept': 'application/pdf',
      }).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return ReportDownload.success(
          response.bodyBytes,
          'hisaab-report-${_date.format(start)}-to-${_date.format(end)}.pdf',
        );
      }
      if (response.statusCode == 401) {
        return const ReportDownload.failure(ReportDownload.unauthorized);
      }
      final message = TransactionsService.errorMessageFromResponseBody(
        response.body,
        fallback: '',
      );
      return ReportDownload.failure(message.isEmpty ? null : message);
    } catch (_) {
      return const ReportDownload.failure(ReportDownload.offline);
    }
  }
}
