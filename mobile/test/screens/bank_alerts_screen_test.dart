import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/models/account.dart';
import 'package:sure_mobile/screens/bank_alerts_screen.dart';
import 'package:sure_mobile/services/bank_alerts_service.dart';
import 'package:sure_mobile/theme/sure_theme.dart';

Map<String, dynamic> _alert(String id, String status,
        {String direction = 'out', Map<String, String>? account}) =>
    {
      'id': id,
      'status': status,
      'received_at': '2026-11-02T13:06:00Z',
      'from': 'no-reply@meezanbank.com',
      'subject': 'Debit Transaction Alert',
      'amount': '10000.0',
      'currency': 'PKR',
      'direction': direction,
      'last4': '9483',
      'payee': 'O.REHMAN',
      'account': account,
    };

void main() {
  late List<http.Request> requests;
  late Map<String, dynamic> inbox;
  late List<Map<String, dynamic>> alerts;

  setUp(() {
    requests = [];
    inbox = {
      'address': 'k7f3q9x2m4@in.hisaab.shipdeck.dev',
      'confirmation': null,
      'senders': [
        {'id': 's1', 'pattern': 'no-reply@meezanbank.com'}
      ],
      'recent': <Map<String, dynamic>>[],
    };
    alerts = [];
  });

  Future<void> pumpScreen(WidgetTester tester, {Locale? locale}) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      if (path.endsWith('/email_inbox')) {
        return http.Response(jsonEncode(inbox), 200);
      }
      if (path.endsWith('/bank_alerts')) {
        return http.Response(jsonEncode({'bank_alerts': alerts}), 200);
      }
      if (path.endsWith('/approve') || path.endsWith('/reject')) {
        final id = path.split('/')[4];
        final status = path.endsWith('/approve') ? 'approved' : 'rejected';
        return http.Response(jsonEncode(_alert(id, status)), 200);
      }
      if (path.endsWith('/email_senders') && request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
            jsonEncode({'id': 's2', 'pattern': body['pattern']}), 201);
      }
      return http.Response('', 404);
    });

    await tester.pumpWidget(MaterialApp(
      theme: SureTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BankAlertsScreen(
        service: BankAlertsService(client: client),
        tokenLoader: () async => 'token',
        accounts: [
          Account(
            id: 'acc1',
            name: 'Meezan Current',
            balance: '0',
            currency: 'PKR',
            accountType: 'depository',
            subtype: 'checking',
          ),
          Account(
            id: 'cash',
            name: 'Cash in hand',
            balance: '0',
            currency: 'PKR',
            accountType: 'depository',
            subtype: 'cash',
          ),
        ],
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the address and an empty inbox', (tester) async {
    await pumpScreen(tester);

    expect(find.text('k7f3q9x2m4@in.hisaab.shipdeck.dev'), findsOneWidget);
    expect(find.byKey(const Key('bankAlertsRecentEmpty')), findsOneWidget);
    expect(find.text('no-reply@meezanbank.com'), findsOneWidget);
    expect(find.byKey(const Key('bankAlertsGmailCode')), findsNothing);
  });

  testWidgets('shows the Gmail confirmation code once it arrives',
      (tester) async {
    inbox['confirmation'] = {'code': '123456789', 'url': 'https://x.test'};
    await pumpScreen(tester);
    expect(find.text('123456789'), findsOneWidget);
    expect(find.text('Open the confirmation link'), findsOneWidget);
  });

  testWidgets('keeps a pending alert', (tester) async {
    alerts = [
      _alert('a1', 'pending', account: {'id': 'acc1', 'name': 'Meezan Current'})
    ];
    await pumpScreen(tester);

    expect(find.text('1 TO REVIEW'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bank-alert-approve-a1')));
    await tester.pumpAndSettle();

    expect(requests.last.url.path, '/api/v1/bank_alerts/a1/approve');
    expect(find.byKey(const ValueKey('bank-alert-a1')), findsNothing);
    expect(find.text('Added to your transactions'), findsOneWidget);
  });

  testWidgets('an unmatched alert asks which account, skipping cash',
      (tester) async {
    alerts = [_alert('a2', 'needs_account')];
    await pumpScreen(tester);

    expect(find.text('No account ends in 9483 · 2 Nov, ${_localTime()}'),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bank-alert-approve-a2')));
    await tester.pumpAndSettle();

    expect(find.text('Which account is this?'), findsOneWidget);
    expect(find.byKey(const ValueKey('bank-alert-account-cash')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('bank-alert-account-acc1')));
    await tester.pumpAndSettle();

    expect(jsonDecode(requests.last.body), {'account_id': 'acc1'});
  });

  testWidgets('discards an alert', (tester) async {
    alerts = [_alert('a3', 'pending')];
    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('bank-alert-reject-a3')));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/api/v1/bank_alerts/a3/reject');
    expect(find.byKey(const ValueKey('bank-alert-a3')), findsNothing);
  });

  testWidgets('allows the sender of an ignored email', (tester) async {
    inbox['senders'] = <Map<String, dynamic>>[];
    inbox['recent'] = [
      {..._alert('a4', 'ignored'), 'from': 'alerts@hbl.com'}
    ];
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('bank-alert-allow-a4')));
    await tester.pumpAndSettle();

    expect(jsonDecode(requests.last.body), {'pattern': 'alerts@hbl.com'});
    expect(find.byKey(const ValueKey('bank-alert-allow-a4')), findsNothing);
  });

  testWidgets('an older server says the feature is not available',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: SureTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BankAlertsScreen(
        service: BankAlertsService(
            client: MockClient((_) async => http.Response('', 404))),
        tokenLoader: () async => 'token',
        accounts: const [],
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text("Your server doesn't support bank email alerts yet."),
        findsOneWidget);
  });

  testWidgets('renders in Urdu without overflow', (tester) async {
    alerts = [_alert('a5', 'needs_account')];
    await pumpScreen(tester, locale: const Locale('ur'));
    expect(tester.takeException(), isNull);
    expect(find.text('k7f3q9x2m4@in.hisaab.shipdeck.dev'), findsOneWidget);
  });
}

String _localTime() {
  final t = DateTime.parse('2026-11-02T13:06:00Z').toLocal();
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${t.hour < 12 ? 'AM' : 'PM'}';
}
