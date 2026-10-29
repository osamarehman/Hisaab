import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/models/account.dart';
import 'package:sure_mobile/models/category.dart';
import 'package:sure_mobile/screens/report_export_screen.dart';
import 'package:sure_mobile/services/reports_service.dart';
import 'package:sure_mobile/theme/sure_theme.dart';

class _FakeReports extends ReportsService {
  final calls = <Map<String, Object?>>[];
  ReportDownload result =
      ReportDownload.success(Uint8List.fromList([37, 80, 68, 70]), 'r.pdf');

  @override
  Future<ReportDownload> download({
    required String accessToken,
    required DateTime start,
    required DateTime end,
    List<String>? categoryIds,
    bool includeUnlabelled = true,
    List<String>? accountIds,
  }) async {
    calls.add({
      'start': start,
      'end': end,
      'categoryIds': categoryIds,
      'includeUnlabelled': includeUnlabelled,
      'accountIds': accountIds,
    });
    return result;
  }
}

void main() {
  final today = DateTime(2026, 10, 29);
  final labels = [
    Category(id: 'food', name: 'Groceries', color: '#2445C8'),
    Category(id: 'bills', name: 'Bills', color: '#9A4F06'),
  ];
  final accounts = [
    Account(
        id: 'cash',
        name: 'Cash in hand',
        balance: '0',
        currency: 'PKR',
        accountType: 'depository'),
  ];

  late _FakeReports service;
  late List<String> delivered;

  Future<void> pump(WidgetTester tester, {DateTime? month}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    service = _FakeReports();
    delivered = [];
    await tester.pumpWidget(MaterialApp(
      theme: SureTheme.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ReportExportScreen(
        month: month,
        today: today,
        service: service,
        accessTokenLoader: () async => 'token',
        deliver: (name, bytes) async => delivered.add(name),
        labels: labels,
        accounts: accounts,
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> download(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('report-download')));
    await tester.pumpAndSettle();
  }

  test('presets cover whole calendar months', () {
    final last3 = ReportExportScreen.rangeFor(ReportPreset.last3Months, today);
    expect(last3.start, DateTime(2026, 8, 1));
    expect(last3.end, DateTime(2026, 10, 31));
    final last = ReportExportScreen.rangeFor(
        ReportPreset.lastMonth, DateTime(2026, 1, 15));
    expect(last.start, DateTime(2025, 12, 1));
    expect(last.end, DateTime(2025, 12, 31));
  });

  testWidgets('defaults to this month, every label and account',
      (tester) async {
    await pump(tester);

    expect(find.text('1 Oct 2026 – 31 Oct 2026'), findsOneWidget);
    await download(tester);

    final call = service.calls.single;
    expect(call['start'], DateTime(2026, 10, 1));
    expect(call['categoryIds'], isNull);
    expect(call['accountIds'], isNull);
    expect(delivered, ['r.pdf']);
    expect(find.text('Saved as r.pdf'), findsOneWidget);
  });

  testWidgets('sends the chosen labels, unlabelled and account',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('report-preset-lastMonth')));
    await tester.tap(find.byKey(const ValueKey('report-label-food')));
    await tester.tap(find.byKey(const ValueKey('report-label-unlabelled')));
    await tester.tap(find.byKey(const ValueKey('report-account-cash')));
    await tester.pumpAndSettle();
    await download(tester);

    final call = service.calls.single;
    expect(call['start'], DateTime(2026, 9, 1));
    expect(call['end'], DateTime(2026, 9, 30));
    expect(call['categoryIds'], ['food']);
    expect(call['includeUnlabelled'], isTrue);
    expect(call['accountIds'], ['cash']);
  });

  testWidgets('opens on the month the user was viewing', (tester) async {
    await pump(tester, month: DateTime(2026, 5, 1));

    expect(find.text('1 May 2026 – 31 May 2026'), findsOneWidget);
  });

  testWidgets('needs at least one label and shows server errors',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('report-label-food')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-label-food')));
    await tester.pumpAndSettle();
    await download(tester);
    expect(find.text('Pick at least one label.'), findsOneWidget);
    expect(service.calls, isEmpty);

    await tester.tap(find.byKey(const ValueKey('report-labels-all')));
    await tester.pumpAndSettle();
    service.result = const ReportDownload.failure('Too many entries');
    await download(tester);
    expect(find.text('Too many entries'), findsOneWidget);
    expect(delivered, isEmpty);
  });
}
