import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/models/chat.dart';
import 'package:sure_mobile/models/pending_action.dart';

void main() {
  test('PendingAction.fromJson reads every field', () {
    final action = PendingAction.fromJson({
      'id': 'pa-1',
      'message_id': 'msg-1',
      'kind': 'create_entry',
      'status': 'pending',
      'summary': 'Add Rs 2,500 · Groceries · 29 Oct 2026 · Cash in hand',
      'details': {
        'direction': 'out',
        'amount': '2500.0',
        'amount_formatted': 'Rs 2,500',
        'date': '2026-10-29',
        'description': 'Imtiaz groceries',
        'label': 'Groceries',
        'account': 'Cash in hand',
        'note': null,
        'name': null,
        'duplicate': true,
      },
      'error': null,
      'created_at': '2026-10-29T10:00:00Z',
    });

    expect(action.id, 'pa-1');
    expect(action.messageId, 'msg-1');
    expect(action.kind, 'create_entry');
    expect(action.isPending, isTrue);
    expect(action.isOpen, isTrue);
    expect(action.details.isOut, isTrue);
    expect(action.details.amount, 2500.0);
    expect(action.details.amountFormatted, 'Rs 2,500');
    expect(action.details.date, DateTime(2026, 10, 29));
    expect(action.details.label, 'Groceries');
    expect(action.details.account, 'Cash in hand');
    expect(action.details.note, isNull);
    expect(action.details.duplicate, isTrue);
    expect(action.createdAt, DateTime.utc(2026, 10, 29, 10));
  });

  test('PendingAction.fromJson tolerates null details and message id', () {
    final action = PendingAction.fromJson({
      'id': 'pa-2',
      'message_id': null,
      'kind': 'other',
      'status': 'failed',
      'summary': 'Something',
      'details': null,
      'error': 'Could not save: no account',
    });

    expect(action.messageId, isNull);
    expect(action.isFailed, isTrue);
    expect(action.isOpen, isTrue);
    expect(action.error, 'Could not save: no account');
    expect(action.details.amount, isNull);
    expect(action.details.direction, isNull);
    expect(action.details.duplicate, isFalse);
  });

  test('Chat.fromJson parses pending_actions and skips malformed rows', () {
    final chat = Chat.fromJson({
      'id': 'chat-1',
      'title': 'Groceries',
      'created_at': '2026-10-29T10:00:00Z',
      'updated_at': '2026-10-29T10:00:00Z',
      'messages': [],
      'pending_actions': [
        {'id': 'pa-1', 'kind': 'create_entry', 'status': 'applied'},
        'bogus',
        {'kind': 'no id'},
      ],
    });

    expect(chat.pendingActions.map((a) => a.id), ['pa-1']);
    expect(chat.pendingActions.single.isApplied, isTrue);
    expect(Chat.fromJson({
      'id': 'chat-2',
      'title': 'Old',
      'created_at': '2026-10-29T10:00:00Z',
      'updated_at': '2026-10-29T10:00:00Z',
    }).pendingActions, isEmpty);
  });
}
