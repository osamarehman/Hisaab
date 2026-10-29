import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/services/reports_service.dart';

void main() {
  final start = DateTime(2026, 9, 1);
  final end = DateTime(2026, 9, 30);

  test('exportUri sends only the period when everything is included', () {
    final uri = ReportsService().exportUri(start: start, end: end);

    expect(uri.path, '/api/v1/reports/export.pdf');
    expect(uri.queryParametersAll, {
      'start_date': ['2026-09-01'],
      'end_date': ['2026-09-30'],
    });
  });

  test('exportUri repeats label and account ids', () {
    final uri = ReportsService().exportUri(
      start: start,
      end: end,
      categoryIds: ['c1', 'c2'],
      includeUnlabelled: false,
      accountIds: ['a1'],
    );

    expect(uri.queryParametersAll['category_ids[]'], ['c1', 'c2']);
    expect(uri.queryParametersAll['include_uncategorized'], ['false']);
    expect(uri.queryParametersAll['account_ids[]'], ['a1']);
  });

  test('download returns the PDF bytes and a dated filename', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response.bytes(utf8.encode('%PDF-1.7'), 200,
          headers: {'content-type': 'application/pdf'});
    });

    final result = await ReportsService(client: client)
        .download(accessToken: 'token', start: start, end: end);

    expect(result.ok, isTrue);
    expect(utf8.decode(result.bytes!), '%PDF-1.7');
    expect(result.filename, 'hisaab-report-2026-09-01-to-2026-09-30.pdf');
    expect(sent.headers['Accept'], 'application/pdf');
    expect(sent.headers['Authorization'], 'Bearer token');
  });

  test('download surfaces the server message and auth failures', () async {
    final invalid = MockClient((_) async => http.Response(
        jsonEncode({
          'error': 'invalid_period',
          'message': 'The report can cover at most 24 months',
        }),
        422));
    final expired = MockClient((_) async => http.Response('', 401));
    final offline = MockClient((_) async => throw http.ClientException('x'));

    Future<ReportDownload> run(http.Client c) => ReportsService(client: c)
        .download(accessToken: 'token', start: start, end: end);

    expect(
        (await run(invalid)).error, 'The report can cover at most 24 months');
    expect((await run(expired)).error, ReportDownload.unauthorized);
    expect((await run(offline)).error, ReportDownload.offline);
  });
}
