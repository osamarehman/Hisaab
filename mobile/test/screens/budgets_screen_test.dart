import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/providers/budgets_provider.dart';
import 'package:sure_mobile/providers/privacy_provider.dart';
import 'package:sure_mobile/screens/budget_category_transactions_screen.dart';
import 'package:sure_mobile/screens/budgets_screen.dart';
import 'package:sure_mobile/services/budgets_service.dart';
import 'package:sure_mobile/services/preferences_service.dart';
import 'package:sure_mobile/theme/sure_theme.dart';

import '../support/budget_fixtures.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.resetForTest();
  });

  BudgetsProvider buildProvider({List<Map<String, dynamic>>? budgets}) {
    return BudgetsProvider(
      service: BudgetsService(client: budgetsMockClient(budgets: budgets)),
      clock: () => DateTime(2026, 10, 19),
    );
  }

  Widget harness(
    BudgetsProvider provider, {
    required bool hidden,
    Future<String?> Function()? loader,
    Locale locale = const Locale('en'),
  }) {
    return ChangeNotifierProvider<PrivacyProvider>(
      create: (_) => PrivacyProvider(initialHidden: hidden),
      child: MaterialApp(
        theme: SureTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BudgetsScreen(
          provider: provider,
          accessTokenLoader: loader ?? () async => 'token',
        ),
      ),
    );
  }

  final lineRows = find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('budget-category-'),
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    BudgetsProvider provider, {
    bool hidden = false,
    Future<String?> Function()? loader,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      harness(provider, hidden: hidden, loader: loader, locale: locale),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows totals, nested categories and over-budget state',
      (tester) async {
    await pumpScreen(tester, buildProvider());

    expect(find.text('Oct 2026'), findsOneWidget);
    expect(find.text(r'Spent of $2,000 planned'), findsOneWidget);
    expect(find.text(r'$1,500'), findsOneWidget);
    expect(find.textContaining(r'$500 left'), findsOneWidget);

    expect(lineRows, findsNWidgets(4));
    expect(find.text('Gifts'), findsNothing);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text(r'Over by $120'), findsOneWidget);

    // Planned future months stay reachable from the current month.
    await tester.tap(find.text('›'));
    await tester.pumpAndSettle();
    expect(find.text('Nov 2026'), findsOneWidget);
  });

  testWidgets('privacy mode masks every amount and hides the bars',
      (tester) async {
    await pumpScreen(tester, buildProvider(), hidden: true);

    expect(find.text(r'$1,500'), findsNothing);
    expect(find.textContaining(r'$2,000'), findsNothing);
    expect(find.text(r'$••••'), findsWidgets);
    expect(find.text(r'Over by $••••'), findsOneWidget);
    expect(find.byType(FractionallySizedBox), findsNothing);
  });

  testWidgets('formats the month in Swedish without extra date setup',
      (tester) async {
    await pumpScreen(
      tester,
      buildProvider(budgets: []),
      locale: const Locale('sv'),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('oktober 2026'), findsWidgets);
  });

  testWidgets('month without a budget shows the empty state', (tester) async {
    await pumpScreen(tester, buildProvider(budgets: []));

    expect(find.text('No budget for October 2026'), findsOneWidget);
    expect(lineRows, findsNothing);
  });

  testWidgets('previous month loads that month', (tester) async {
    await pumpScreen(tester, buildProvider());

    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();

    expect(find.text('No budget for September 2026'), findsOneWidget);
    expect(find.text('›'), findsOneWidget);
  });

  testWidgets('tapping a parent opens its transactions with subcategories',
      (tester) async {
    await pumpScreen(tester, buildProvider());

    await tester.tap(find.text('Food'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final screen = tester.widget<BudgetCategoryTransactionsScreen>(
      find.byType(BudgetCategoryTransactionsScreen),
    );
    expect(screen.categoryIds, [
      'cat_food',
      'cat_groceries',
      'cat_restaurants',
    ]);
    expect(screen.startDate, DateTime(2026, 10, 1));
    expect(screen.endDate, DateTime(2026, 10, 31));
  });

  testWidgets('a failed refresh keeps the loaded month with a banner',
      (tester) async {
    final inner = budgetsMockHandler();
    var fail = false;
    final provider = BudgetsProvider(
      service: BudgetsService(
        client: MockClient((request) async {
          if (fail) throw http.ClientException('connection reset');
          return inner(request);
        }),
      ),
      clock: () => DateTime(2026, 10, 19),
    );
    await pumpScreen(tester, provider);
    expect(find.text(r'$1,500'), findsOneWidget);

    fail = true;
    await provider.loadMonth(accessToken: 'token', forceRefresh: true);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load budgets"), findsNothing);
    expect(find.text(r'$1,500'), findsOneWidget);
    expect(
      find.text("Couldn't refresh. Showing the figures loaded earlier."),
      findsOneWidget,
    );

    fail = false;
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't refresh. Showing the figures loaded earlier."),
      findsNothing,
    );
  });

  testWidgets('without an access token shows the session-expired state',
      (tester) async {
    await pumpScreen(tester, buildProvider(), loader: () async => null);

    expect(
      find.text('Your session has expired. Please sign in again.'),
      findsOneWidget,
    );
  });

  testWidgets('switching budgets after the session expired says so',
      (tester) async {
    String? token = 'token';
    await pumpScreen(
      tester,
      buildProvider(
        budgets: [
          budgetJson(id: 'budget_oct'),
          budgetJson(id: 'budget_oct_personal', actualCents: 1000),
        ],
      ),
      loader: () async => token,
    );

    token = null;
    await tester.tap(find.text('Budget 2'));
    await tester.pumpAndSettle();

    expect(
      find.text('Your session has expired. Please sign in again.'),
      findsOneWidget,
    );
  });
}
