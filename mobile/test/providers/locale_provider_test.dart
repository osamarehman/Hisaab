import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/providers/locale_provider.dart';
import 'package:sure_mobile/services/preferences_service.dart';
import 'package:sure_mobile/utils/money_format.dart';
import 'package:sure_mobile/widgets/ledger/rupee_amount.dart';

/// Mirrors how `SureApp` wires the provider into `MaterialApp.locale`.
Widget _app(LocaleProvider provider) {
  return ChangeNotifierProvider<LocaleProvider>.value(
    value: provider,
    child: Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) => MaterialApp(
        locale: localeProvider.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                Text(AppLocalizations.of(context).commonSave),
                const RupeeAmount(-1200, key: ValueKey('amount')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<LocaleProvider> _loadedProvider(WidgetTester tester) async {
  final provider = LocaleProvider();
  // Let the constructor's async preference read complete.
  await tester.pumpAndSettle();
  return provider;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.resetForTest();
  });

  testWidgets('defaults to the device language', (tester) async {
    final provider = await _loadedProvider(tester);
    expect(provider.locale, isNull);

    await tester.pumpWidget(_app(provider));
    // The test device is en-US.
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('switching to Urdu applies at once, flips to RTL and persists',
      (tester) async {
    final provider = await _loadedProvider(tester);
    await tester.pumpWidget(_app(provider));

    await provider.setLocale(const Locale('ur'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(Localizations.localeOf(context), const Locale('ur'));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(find.text('محفوظ کریں'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'ur');

    // Money keeps its LTR order inside RTL text.
    final amount = tester.widget<Text>(find.descendant(
      of: find.byKey(const ValueKey('amount')),
      matching: find.byType(Text),
    ));
    expect(amount.data, MoneyFormat.ltrIsolate('− Rs 1,200'));
  });

  testWidgets('choosing System clears the stored language', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'ur'});
    PreferencesService.resetForTest();
    final provider = await _loadedProvider(tester);
    expect(provider.locale, const Locale('ur'));

    await tester.pumpWidget(_app(provider));
    expect(find.text('محفوظ کریں'), findsOneWidget);

    await provider.setLocale(null);
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'system');
  });

  testWidgets('ignores an unsupported stored language', (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'xx'});
    PreferencesService.resetForTest();
    final provider = await _loadedProvider(tester);
    expect(provider.locale, isNull);
  });
}
