import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:sure_mobile/l10n/app_localizations.dart';
import 'package:sure_mobile/models/pending_action.dart';
import 'package:sure_mobile/providers/chat_provider.dart';
import 'package:sure_mobile/services/chat_service.dart';
import 'package:sure_mobile/theme/sure_theme.dart';
import 'package:sure_mobile/widgets/assistant/pending_actions_card.dart';

final _now = DateTime(2026, 10, 29, 12);

Map<String, dynamic> _actionJson(
  String id, {
  String status = 'pending',
  String? label = 'Groceries',
  String date = '2026-10-29',
  String direction = 'out',
  String amount = '2500.0',
  String description = 'Imtiaz groceries',
  bool duplicate = false,
}) =>
    {
      'id': id,
      'message_id': 'msg-1',
      'kind': 'statement_entry',
      'status': status,
      'summary': 'Add $amount',
      'details': {
        'direction': direction,
        'amount': amount,
        'date': date,
        'description': description,
        'label': label,
        'account': 'Cash in hand',
        'duplicate': duplicate,
      },
    };

PendingAction _action(String id,
        {String status = 'pending',
        String? label = 'Groceries',
        String date = '2026-10-29',
        String direction = 'out',
        String amount = '2500.0',
        String description = 'Imtiaz groceries',
        bool duplicate = false}) =>
    PendingAction.fromJson(_actionJson(id,
        status: status,
        label: label,
        date: date,
        direction: direction,
        amount: amount,
        description: description,
        duplicate: duplicate));

Widget _wrap(Widget child) => MaterialApp(
      theme: SureTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('single action shows amount, label · today · account and Save',
      (tester) async {
    final confirmed = <List<String>>[];
    final cancelled = <List<String>>[];
    await tester.pumpWidget(_wrap(PendingActionsCard(
      actions: [_action('pa-1')],
      isBusy: (_) => false,
      now: _now,
      onConfirm: confirmed.add,
      onCancel: cancelled.add,
    )));

    expect(find.text('ADD'), findsOneWidget);
    expect(find.text('Rs 2,500'), findsOneWidget);
    expect(find.text('Groceries · today · Cash in hand'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pending-save-pa-1')));
    expect(confirmed, [
      ['pa-1'],
    ]);
    await tester.tap(find.byKey(const ValueKey('pending-cancel-pa-1')));
    expect(cancelled, [
      ['pa-1'],
    ]);
  });

  testWidgets('applied action is read-only and says Saved', (tester) async {
    await tester.pumpWidget(_wrap(PendingActionsCard(
      actions: [_action('pa-1', status: 'applied', date: '2026-10-28')],
      isBusy: (_) => false,
      now: _now,
      onConfirm: (_) => fail('should not confirm'),
      onCancel: (_) => fail('should not cancel'),
    )));

    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Groceries · yesterday · Cash in hand'), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-save-pa-1')), findsNothing);
  });

  testWidgets('batch lists rows, flags duplicates and saves all open ones',
      (tester) async {
    final confirmed = <List<String>>[];
    final cancelled = <List<String>>[];
    await tester.pumpWidget(_wrap(PendingActionsCard(
      actions: [
        _action('pa-1'),
        _action('pa-2',
            label: null,
            direction: 'in',
            amount: '40000',
            description: 'Salary',
            date: '2026-10-01',
            duplicate: true),
        _action('pa-3', status: 'applied', description: 'Milk'),
      ],
      isBusy: (_) => false,
      now: _now,
      onConfirm: confirmed.add,
      onCancel: cancelled.add,
    )));

    expect(find.text('3 ENTRIES TO CHECK'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Needs a label'), findsOneWidget);
    expect(find.text('Already recorded?'), findsOneWidget);
    expect(find.text('1 Oct'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-remove-pa-3')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pending-remove-pa-2')));
    expect(cancelled, [
      ['pa-2'],
    ]);

    await tester.tap(find.text('Save all (2)'));
    expect(confirmed, [
      ['pa-1', 'pa-2'],
    ]);
  });

  testWidgets('Save goes through ChatProvider to the confirm endpoint',
      (tester) async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/pending_actions/confirm')) {
        return http.Response(
          jsonEncode({
            'pending_actions': [_actionJson('pa-1', status: 'applied')],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'id': 'chat-1',
          'title': 'Groceries',
          'created_at': '2026-10-29T10:00:00Z',
          'updated_at': '2026-10-29T10:00:00Z',
          'messages': [],
          'pending_actions': [
            _actionJson('pa-1', status: requests.length > 1 ? 'applied' : 'pending'),
          ],
        }),
        200,
      );
    });
    final provider = ChatProvider(chatService: ChatService(client: client));
    await provider.fetchChat(accessToken: 'token', chatId: 'chat-1');

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: _wrap(Consumer<ChatProvider>(
        builder: (context, p, _) => PendingActionsCard(
          actions: p.currentChat!.pendingActions,
          isBusy: p.isActionBusy,
          now: _now,
          onConfirm: (ids) => p.confirmActions(
              accessToken: 'token', chatId: 'chat-1', ids: ids),
          onCancel: (ids) => p.cancelActions(
              accessToken: 'token', chatId: 'chat-1', ids: ids),
        ),
      )),
    ));

    await tester.tap(find.byKey(const ValueKey('pending-save-pa-1')));
    await tester.pumpAndSettle();

    final confirm = requests.firstWhere(
        (r) => r.url.path == '/api/v1/chats/chat-1/pending_actions/confirm');
    expect(jsonDecode(confirm.body), {
      'ids': ['pa-1'],
    });
    expect(find.text('Saved'), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-save-pa-1')), findsNothing);
  });
}
