import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/models/account.dart';
import 'package:sure_mobile/screens/account_form_screen.dart';
import 'package:sure_mobile/services/accounts_service.dart';
import 'package:sure_mobile/theme/sure_theme.dart';

class _Harness {
  final requests = <http.Request>[];
  AccountFormResult? popped;

  late final AccountsService service = AccountsService(
    client: MockClient((request) async {
      requests.add(request);
      final body = (jsonDecode(request.body) as Map)['account'] as Map;
      return http.Response(
        jsonEncode({
          'id': 'acc-new',
          'name': body['name'] ?? 'Meezan Bank',
          'balance': 'Rs 25,000.00',
          'balance_cents': 2500000,
          'currency': 'PKR',
          'classification': 'asset',
          'account_type': 'depository',
          'subtype': body['subtype'],
        }),
        request.method == 'POST' ? 201 : 200,
      );
    }),
  );

  Widget app({Account? account, AccountKind? kind}) => MaterialApp(
        theme: SureTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<AccountFormResult>(
                  MaterialPageRoute(
                    builder: (_) => AccountFormScreen(
                      account: account,
                      initialKind: kind,
                      service: service,
                      tokenLoader: () async => 'token',
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
}

Future<void> _open(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  final save = find.byKey(const ValueKey('account-save'));
  await tester.scrollUntilVisible(save, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asks for a kind and a name before saving', (tester) async {
    final h = _Harness();
    await _open(tester, h.app());

    await _save(tester);
    expect(find.text('Choose what kind of account this is.'), findsOneWidget);

    await tester.ensureVisible(find.text('Bank account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank account'));
    await tester.pump();
    await _save(tester);
    expect(find.text('Choose what kind of account this is.'), findsNothing);
    expect(find.text('Give the account a name.'), findsOneWidget);
    expect(h.requests, isEmpty);
  });

  testWidgets('cash in hand prefills its name and saves with subtype cash',
      (tester) async {
    final h = _Harness();
    await _open(tester, h.app());

    await tester.tap(find.text('Cash in hand').first);
    await tester.pump();
    final name = tester
        .widget<TextFormField>(find.byKey(const ValueKey('account-name')));
    expect(name.controller!.text, 'Cash in hand');

    await tester.enterText(
        find.byKey(const ValueKey('account-balance')), '5000');
    await _save(tester);

    expect(h.requests, hasLength(1));
    expect(jsonDecode(h.requests.single.body), {
      'account': {
        'name': 'Cash in hand',
        'accountable_type': 'Depository',
        'subtype': 'cash',
        'balance': '5000',
      },
    });
    expect(h.popped?.account?.id, 'acc-new');
  });

  testWidgets('liabilities ask how much is owed', (tester) async {
    final h = _Harness();
    await _open(tester, h.app(kind: AccountKind.loan));

    expect(find.text('How much is owed?'), findsOneWidget);
    expect(find.text('How much is in it now?'), findsNothing);
  });

  testWidgets('edit sends only what changed and offers delete', (tester) async {
    final h = _Harness();
    final account = Account(
      id: 'acc-1',
      name: 'Meezan Bank',
      balance: 'Rs 25,000.00',
      balanceCents: 2500000,
      currency: 'PKR',
      classification: 'asset',
      accountType: 'depository',
    );
    await _open(tester, h.app(account: account));

    expect(find.text('Edit account'), findsOneWidget);
    expect(find.text('Bank account'), findsNothing);
    expect(find.text('Delete account'), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('account-balance')), '30000');
    await _save(tester);

    expect(h.requests.single.method, 'PATCH');
    expect(jsonDecode(h.requests.single.body), {
      'account': {'balance': '30000'},
    });
  });
}
