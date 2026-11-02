import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/services/bank_alerts_service.dart';

const _alert = {
  'id': 'a1',
  'status': 'needs_account',
  'received_at': '2026-11-02T13:06:00Z',
  'from': 'no-reply@meezanbank.com',
  'subject': 'Debit Transaction Alert',
  'parser': 'meezan',
  'amount': '10000.0',
  'currency': 'PKR',
  'direction': 'out',
  'last4': '9483',
  'occurred_at': '2026-11-02T18:05:00+05:00',
  'payee': 'O.REHMAN',
  'account': null,
  'transaction_id': null,
  'error': null,
};

void main() {
  late List<http.Request> requests;

  BankAlertsService service(http.Response Function(http.Request) respond) {
    requests = [];
    return BankAlertsService(
      client: MockClient((request) async {
        requests.add(request);
        return respond(request);
      }),
    );
  }

  test('parses the inbox with its confirmation, senders and alerts', () async {
    final s = service((_) => http.Response(
        jsonEncode({
          'address': 'k7f3q9x2m4@in.hisaab.shipdeck.dev',
          'confirmation': {'code': '123456789', 'url': 'https://example.test'},
          'senders': [
            {'id': 's1', 'pattern': 'no-reply@meezanbank.com'}
          ],
          'recent': [_alert],
        }),
        200));

    final result = await s.getInbox(accessToken: 't');

    expect(result.ok, isTrue);
    final inbox = result.value!;
    expect(inbox.address, 'k7f3q9x2m4@in.hisaab.shipdeck.dev');
    expect(inbox.confirmation!.code, '123456789');
    expect(inbox.senders.single.pattern, 'no-reply@meezanbank.com');
    final alert = inbox.recent.single;
    expect(alert.amount, 10000);
    expect(alert.direction, 'out');
    expect(alert.last4, '9483');
    expect(alert.accountId, isNull);
    expect(alert.needsReview, isTrue);
    expect(requests.single.url.path, '/api/v1/email_inbox');
  });

  test('an older server without the inbox reports unsupported', () async {
    final s = service((_) => http.Response('{"error":"not_found"}', 404));
    final result = await s.getInbox(accessToken: 't');
    expect(result.error, BankAlertsResult.unsupported);
  });

  test('approve sends the chosen account', () async {
    final s = service((_) =>
        http.Response(jsonEncode({..._alert, 'status': 'approved'}), 200));

    final result =
        await s.approve(accessToken: 't', alertId: 'a1', accountId: 'acc1');

    expect(result.value!.status, BankAlert.approved);
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/api/v1/bank_alerts/a1/approve');
    expect(jsonDecode(requests.single.body), {'account_id': 'acc1'});
  });

  test('lists alerts by status', () async {
    final s = service((_) => http.Response(
        jsonEncode({
          'bank_alerts': [_alert],
          'pagination': {'total_count': 1}
        }),
        200));

    final result =
        await s.listAlerts(accessToken: 't', status: BankAlert.pending);

    expect(result.value, hasLength(1));
    expect(requests.single.url.queryParameters['status'], 'pending');
  });

  test('a rejected sender pattern returns the server message', () async {
    final s = service((_) => http.Response(
        jsonEncode(
            {'error': 'validation_failed', 'message': 'Pattern is invalid'}),
        422));
    final result = await s.addSender(accessToken: 't', pattern: 'nope');
    expect(result.error, 'Pattern is invalid');
  });

  test('removing a sender accepts an empty 204', () async {
    final s = service((_) => http.Response('', 204));
    final result = await s.removeSender(accessToken: 't', senderId: 's1');
    expect(result.ok, isTrue);
    expect(requests.single.method, 'DELETE');
  });
}
