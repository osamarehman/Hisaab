import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/models/account.dart';
import 'package:sure_mobile/services/accounts_service.dart';

Map<String, dynamic> accountJson({
  String id = 'acc-1',
  String name = 'Cash in hand',
  String type = 'depository',
  String classification = 'asset',
}) =>
    {
      'id': id,
      'name': name,
      'balance': 'Rs 5,000.00',
      'balance_cents': 500000,
      'currency': 'PKR',
      'classification': classification,
      'account_type': type,
      'subtype': 'cash',
      'status': 'active',
    };

void main() {
  test('createAccount posts the account payload as JSON', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(jsonEncode(accountJson()), 201);
    });

    final result = await AccountsService(client: client).createAccount(
      accessToken: 'token',
      name: 'Cash in hand',
      accountableType: 'Depository',
      subtype: 'cash',
      balance: '5000',
    );

    expect(result['success'], isTrue);
    expect((result['account'] as Account).name, 'Cash in hand');
    expect(sent.method, 'POST');
    expect(sent.url.path, '/api/v1/accounts');
    expect(sent.headers['Content-Type'], contains('application/json'));
    expect(jsonDecode(sent.body), {
      'account': {
        'name': 'Cash in hand',
        'accountable_type': 'Depository',
        'subtype': 'cash',
        'balance': '5000',
      },
    });
  });

  test('createAccount omits a missing subtype', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(
        jsonEncode(
            accountJson(type: 'other_liability', classification: 'liability')),
        201,
      );
    });

    await AccountsService(client: client).createAccount(
      accessToken: 'token',
      name: 'Loan from Bilal',
      accountableType: 'OtherLiability',
      balance: '50000',
    );

    final account = (jsonDecode(sent.body) as Map)['account'] as Map;
    expect(account.containsKey('subtype'), isFalse);
    expect(account['accountable_type'], 'OtherLiability');
  });

  test('createAccount surfaces the server message on 422', () async {
    final client = MockClient((_) async => http.Response(
          jsonEncode({
            'error': 'validation_failed',
            'message': 'Name is required',
            'errors': ['Name is required'],
          }),
          422,
        ));

    final result = await AccountsService(client: client).createAccount(
      accessToken: 'token',
      name: '',
      accountableType: 'Depository',
      balance: '0',
    );

    expect(result['success'], isFalse);
    expect(result['error'], 'Name is required');
  });

  test('updateAccount patches only the given fields', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(jsonEncode(accountJson(name: 'Purse')), 200);
    });

    final result = await AccountsService(client: client).updateAccount(
      accessToken: 'token',
      accountId: 'acc-1',
      balance: '1200.50',
    );

    expect(result['success'], isTrue);
    expect(sent.method, 'PATCH');
    expect(sent.url.path, '/api/v1/accounts/acc-1');
    expect(jsonDecode(sent.body), {
      'account': {'balance': '1200.50'},
    });
  });

  test('deleteAccount sends DELETE and treats 204 as success', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response('', 204);
    });

    final result = await AccountsService(client: client)
        .deleteAccount(accessToken: 'token', accountId: 'acc-1');

    expect(result['success'], isTrue);
    expect(sent.method, 'DELETE');
    expect(sent.url.path, '/api/v1/accounts/acc-1');
  });
}
