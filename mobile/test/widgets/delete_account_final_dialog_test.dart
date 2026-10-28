import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/screens/settings_screen.dart';

void main() {
  Future<List<bool?>> openDialog(WidgetTester tester) async {
    final results = <bool?>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => results.add(await showDialog<bool>(
                context: context,
                builder: (_) => const DeleteAccountFinalDialog(),
              )),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  TextButton deleteButton(WidgetTester tester) => tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Delete my account'),
      );

  testWidgets('keeps the delete button disabled until DELETE is typed',
      (tester) async {
    final results = await openDialog(tester);

    expect(deleteButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'delet');
    await tester.pump();
    expect(deleteButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pump();
    expect(deleteButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  testWidgets('cancel returns false', (tester) async {
    final results = await openDialog(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(results, [false]);
  });
}
