import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/models/import_job.dart';
import 'package:sure_mobile/services/imports_service.dart';

void main() {
  test('fileKind maps PDF and CSV, rejects others', () {
    expect(ImportsService.fileKind('Meezan_May-Oct.PDF')?.type, 'PdfImport');
    expect(ImportsService.fileKind('hbl.csv')?.type, 'TransactionImport');
    expect(ImportsService.fileKind('hbl.csv')?.mime, 'text/csv');
    expect(ImportsService.fileKind('statement.xlsx'), isNull);
  });

  test('uploadStatement sends a multipart PdfImport with the PDF part type',
      () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(
        jsonEncode({
          'data': {'id': 'imp-1', 'type': 'PdfImport', 'status': 'importing'},
        }),
        202,
      );
    });

    final result = await ImportsService(client: client).uploadStatement(
      accessToken: 'token',
      accountId: 'acc-1',
      fileName: 'oct.pdf',
      bytes: Uint8List.fromList(utf8.encode('%PDF-1.7 test')),
    );

    expect(result['success'], isTrue);
    final job = result['import'] as ImportJob;
    expect(job.status, ImportStatus.importing);
    expect(job.fileName, 'oct.pdf');

    expect(sent.method, 'POST');
    expect(sent.url.path, '/api/v1/imports');
    final contentType = sent.headers['Content-Type']!;
    expect(contentType, startsWith('multipart/form-data; boundary='));
    final boundary = contentType.split('boundary=').last;
    final body = latin1.decode(sent.bodyBytes);
    expect(body, contains('name="type"\r\n\r\nPdfImport\r\n'));
    expect(body, contains('name="account_id"\r\n\r\nacc-1\r\n'));
    expect(body, contains('name="file"; filename="oct.pdf"'));
    expect(
      body,
      contains('Content-Type: application/pdf\r\n\r\n%PDF-1.7 test'),
    );
    expect(body, endsWith('--$boundary--\r\n'));
  });

  test('uploadStatement surfaces the server message on 422', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': 'invalid_file_type',
          'message': 'Invalid file. Please upload a PDF statement.',
        }),
        422,
      ),
    );
    final result = await ImportsService(client: client).uploadStatement(
      accessToken: 'token',
      accountId: 'acc-1',
      fileName: 'oct.pdf',
      bytes: Uint8List(0),
    );
    expect(result['success'], isFalse);
    expect(result['error'], 'Invalid file. Please upload a PDF statement.');
  });
}
