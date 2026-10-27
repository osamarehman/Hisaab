import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/models/transaction.dart';
import 'package:sure_mobile/services/transactions_service.dart';

const _txJson = {
  'id': 'tx_1',
  'account': {'id': 'acct_1', 'name': 'Cash in hand'},
  'name': 'K-Electric bill',
  'date': '2026-10-25',
  'amount': 'Rs4,820',
  'amount_decimal': '4820.0',
  'currency': 'PKR',
  'classification': 'expense',
  'kind': 'standard',
  'category': {'id': 'cat_1', 'name': 'Home & bills', 'color': '#2445C8'},
  'attachments': [
    {
      'id': 'att_1',
      'filename': 'kelectric_oct.jpg',
      'content_type': 'image/jpeg',
      'byte_size': 412000,
      'url':
          'https://finance.example/api/v1/transactions/tx_1/attachments/att_1',
    },
  ],
};

void main() {
  test('Transaction parses attachments, account name and amounts', () {
    final tx = Transaction.fromJson(jsonDecode(jsonEncode(_txJson)));
    expect(tx.hasAttachments, isTrue);
    expect(tx.attachments.single.filename, 'kelectric_oct.jpg');
    expect(tx.attachments.single.byteSize, 412000);
    expect(tx.attachments.single.isImage, isTrue);
    expect(tx.accountName, 'Cash in hand');
    expect(tx.categoryColor, '#2445C8');
    expect(tx.absAmount, 4820);
    expect(tx.isTransfer, isFalse);
  });

  test('Transaction without attachments key has none', () {
    final tx = Transaction.fromJson({'id': 'x', 'amount': '-Rs250,000'});
    expect(tx.hasAttachments, isFalse);
    expect(tx.absAmount, 250000);
  });

  test('getTransactions sends uncategorized=true', () async {
    late Uri seen;
    final service = TransactionsService(
      client: MockClient((request) async {
        seen = request.url;
        return http.Response(
          '{"transactions":[],"pagination":{"total_count":14}}',
          200,
        );
      }),
    );

    final result = await service.getTransactions(
      accessToken: 't',
      startDate: '2026-10-01',
      endDate: '2026-10-31',
      uncategorized: true,
      perPage: 1,
    );

    expect(result['success'], isTrue);
    expect(seen.queryParameters['uncategorized'], 'true');
    expect(seen.queryParameters['start_date'], '2026-10-01');
  });

  test('uploadAttachments posts multipart attachments[] with a type', () async {
    final dir = await Directory.systemTemp.createTemp('sure_receipt');
    final file = File('${dir.path}/bill.png')..writeAsBytesSync([1, 2, 3]);
    late http.Request seen;
    final service = TransactionsService(
      client: MockClient((request) async {
        seen = request;
        return http.Response(jsonEncode(_txJson), 201);
      }),
    );

    final result = await service.uploadAttachments(
      accessToken: 't',
      transactionId: 'tx_1',
      files: [file],
    );
    await dir.delete(recursive: true);

    expect(result['success'], isTrue);
    expect((result['transaction'] as Transaction).hasAttachments, isTrue);
    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/v1/transactions/tx_1/attachments');
    expect(seen.headers['Content-Type'], startsWith('multipart/form-data'));
    final body = latin1.decode(seen.bodyBytes);
    expect(body, contains('name="attachments[]"; filename="bill.png"'));
    expect(body, contains('Content-Type: image/png'));
  });

  test('deleteAttachment treats 204 as success', () async {
    final service = TransactionsService(
      client: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/transactions/tx_1/attachments/att_1');
        return http.Response('', 204);
      }),
    );
    final result = await service.deleteAttachment(
      accessToken: 't',
      transactionId: 'tx_1',
      attachmentId: 'att_1',
    );
    expect(result['success'], isTrue);
  });
}
