import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/screens/csv_mapping_screen.dart';
import 'package:sure_mobile/theme/sure_theme.dart';
import 'package:sure_mobile/utils/statement_csv.dart';

const _csv = 'Account,123,,,\n'
    'Booking Date,Description,Debit,Credit,Available Balance\n'
    '18 Oct 2026,Shop,1050,,100\n'
    '22 Oct 2026,Salary,,10000,10100\n';

void main() {
  Future<String?> open(WidgetTester tester, String text,
      {Locale? locale}) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? popped;
    await tester.pumpWidget(MaterialApp(
      theme: SureTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            popped = await Navigator.of(context).push<String>(
              MaterialPageRoute(
                builder: (_) => CsvMappingScreen(
                    csv: StatementCsv.parse(text), currency: 'PKR'),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return popped;
  }

  testWidgets('shows the guessed columns and a preview, then confirms',
      (tester) async {
    await open(tester, _csv);

    expect(find.text('Booking Date'), findsOneWidget);
    expect(find.text('Debit'), findsOneWidget);
    expect(find.text('Credit'), findsOneWidget);
    expect(find.textContaining('2 lines · in'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);

    await tester.tap(find.byKey(const Key('csv-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(CsvMappingScreen), findsNothing);
  });

  testWidgets('a file without a readable date column cannot be confirmed',
      (tester) async {
    await open(tester, 'Foo,Bar\n1,2\n');
    expect(find.byKey(const Key('csv-no-lines')), findsOneWidget);
    final button = tester.widget<InkWell>(find.descendant(
        of: find.byKey(const Key('csv-confirm')),
        matching: find.byType(InkWell)));
    expect(button.onTap, isNull);
  });

  testWidgets('renders in Urdu without overflow', (tester) async {
    await open(tester, _csv, locale: const Locale('ur'));
    expect(tester.takeException(), isNull);
    expect(find.text('Booking Date'), findsOneWidget);
  });
}
