import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/screens/currency_screen.dart';
import 'package:sure_mobile/services/family_settings_service.dart';
import 'package:sure_mobile/theme/sure_theme.dart';

void main() {
  late List<http.Request> requests;
  late String currency;
  late http.Response Function(http.Request) patchResponse;

  setUp(() {
    requests = [];
    currency = 'PKR';
    patchResponse = (request) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      currency = (body['currency'] as String).toUpperCase();
      return http.Response(
          jsonEncode({'currency': currency, 'enabled_currencies': []}), 200);
    };
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'PATCH') return patchResponse(request);
      return http.Response(jsonEncode({'currency': currency}), 200);
    });
    await tester.pumpWidget(MaterialApp(
      theme: SureTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CurrencyScreen(
        service: FamilySettingsService(client: client),
        tokenLoader: () async => 'token',
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('currencySearch')), text);
    await tester.pumpAndSettle();
  }

  testWidgets('marks the household currency and searches by name or code',
      (tester) async {
    await pumpScreen(tester);
    await search(tester, 'pakistan');

    final pkr = find.byKey(const ValueKey('currency-PKR'));
    expect(pkr, findsOneWidget);
    expect(find.descendant(of: pkr, matching: find.byIcon(Icons.check)),
        findsOneWidget);

    await search(tester, 'aed');
    expect(find.text('United Arab Emirates Dirham'), findsOneWidget);

    await search(tester, 'zzzz');
    expect(find.text('No currency matches your search.'), findsOneWidget);
  });

  testWidgets('changes the currency after confirming', (tester) async {
    await pumpScreen(tester);
    await search(tester, 'USD');
    await tester.tap(find.byKey(const ValueKey('currency-USD')));
    await tester.pumpAndSettle();

    expect(find.text('Use USD for your household?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('currencyConfirm')));
    await tester.pumpAndSettle();

    expect(requests.last.method, 'PATCH');
    expect(jsonDecode(requests.last.body), {'currency': 'USD'});
    expect(find.text('Household currency is now USD'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('currency-USD')),
            matching: find.byIcon(Icons.check)),
        findsOneWidget);
  });

  testWidgets('a member who is not an admin keeps the old currency',
      (tester) async {
    patchResponse = (_) => http.Response(
        jsonEncode({'error': 'forbidden', 'message': 'Admins only'}), 403);
    await pumpScreen(tester);
    await search(tester, 'EUR');
    await tester.tap(find.byKey(const ValueKey('currency-EUR')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currencyConfirm')));
    await tester.pumpAndSettle();

    expect(find.text('Only a household admin can change the currency.'),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('currency-EUR')),
            matching: find.byIcon(Icons.check)),
        findsNothing);
  });

  testWidgets('cancelling the dialog sends nothing', (tester) async {
    await pumpScreen(tester);
    await search(tester, 'GBP');
    await tester.tap(find.byKey(const ValueKey('currency-GBP')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(requests.where((r) => r.method == 'PATCH'), isEmpty);
  });
}
