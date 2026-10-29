import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/pending_action.dart';
import '../../theme/sure_tokens.dart';
import '../../utils/money_format.dart';
import '../ledger/ledger.dart';

/// "today" / "yesterday" / "29 Oct 2026" for a proposed change.
String pendingActionDate(
  AppLocalizations l,
  DateTime date,
  DateTime now, {
  bool short = false,
}) {
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return l.pendingActionToday;
  if (diff == 1) return l.pendingActionYesterday;
  return DateFormat(short ? 'd MMM' : 'd MMM yyyy', 'en_US').format(date);
}

/// Confirm-before-saving card for the changes one assistant message proposed:
/// a single detailed card for one action, a row list with "Save all" for a
/// batch (statement lines).
class PendingActionsCard extends StatelessWidget {
  const PendingActionsCard({
    super.key,
    required this.actions,
    required this.isBusy,
    required this.onConfirm,
    required this.onCancel,
    this.now,
  });

  final List<PendingAction> actions;
  final bool Function(String id) isBusy;
  final void Function(List<String> ids) onConfirm;
  final void Function(List<String> ids) onCancel;

  /// Reference "now" for today/yesterday; defaults to the clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LedgerPanel(
        padding: const EdgeInsets.all(14),
        child: actions.length == 1
            ? _SingleAction(
                action: actions.first,
                busy: isBusy(actions.first.id),
                now: now ?? DateTime.now(),
                onConfirm: onConfirm,
                onCancel: onCancel,
              )
            : _BatchActions(
                actions: actions,
                isBusy: isBusy,
                now: now ?? DateTime.now(),
                onConfirm: onConfirm,
                onCancel: onCancel,
              ),
      ),
    );
  }
}

String _kindTitle(AppLocalizations l, String kind) {
  switch (kind) {
    case 'create_entry':
    case 'statement_entry':
      return l.pendingActionKindAdd;
    case 'update_entry':
      return l.pendingActionKindUpdate;
    case 'delete_entry':
      return l.pendingActionKindDelete;
    case 'update_balance':
      return l.pendingActionKindBalance;
    case 'create_account':
      return l.pendingActionKindAccount;
    case 'create_label':
      return l.pendingActionKindLabel;
    default:
      return l.pendingActionKindOther;
  }
}

Color _amountColor(LedgerColors c, PendingActionDetails d) =>
    d.isIn ? c.moneyIn : (d.isOut ? c.moneyOut : c.ink);

/// Amount in mono figures, masked in privacy mode when it parses.
Widget _amount(LedgerColors c, PendingActionDetails d,
    {required double size, TextDecoration? decoration}) {
  final color = _amountColor(c, d);
  if (d.amount != null && decoration == null) {
    return RupeeAmount(d.amount!.abs(),
        size: size, color: color, weight: FontWeight.w500);
  }
  return Text(
    d.amountFormatted ??
        (d.amount == null ? '' : MoneyFormat.format(d.amount!.abs())),
    style: LedgerText.figures(size: size, color: color, weight: FontWeight.w500)
        .copyWith(decoration: decoration),
  );
}

/// Read-only status line for a non-pending action; null while pending.
Widget? _statusLine(AppLocalizations l, LedgerColors c, PendingAction a) {
  if (a.isApplied) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check, size: 16, color: c.moneyIn),
        const SizedBox(width: 4),
        Text(l.pendingActionSaved,
            style: LedgerText.body(
                size: 13, weight: FontWeight.w600, color: c.moneyIn)),
      ],
    );
  }
  if (a.isCancelled) {
    return Text(l.pendingActionCancelled,
        style: LedgerText.body(size: 13, color: c.muted));
  }
  if (a.isFailed) {
    return Text(a.error ?? l.pendingActionSaveFailed,
        style: LedgerText.body(size: 13, color: c.danger));
  }
  return null;
}

class _SingleAction extends StatelessWidget {
  const _SingleAction({
    required this.action,
    required this.busy,
    required this.now,
    required this.onConfirm,
    required this.onCancel,
  });

  final PendingAction action;
  final bool busy;
  final DateTime now;
  final void Function(List<String> ids) onConfirm;
  final void Function(List<String> ids) onCancel;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final d = action.details;
    final struck = action.isCancelled ? TextDecoration.lineThrough : null;
    final hasAmount = d.amount != null || d.amountFormatted != null;

    final meta = [
      if (d.label != null) d.label!,
      if (d.date != null) pendingActionDate(l, d.date!, now),
      if (d.account != null) d.account!,
    ].join(' · ');
    final hasDetails = hasAmount || d.name != null || meta.isNotEmpty;
    final status = _statusLine(l, c, action);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LedgerCapsHeader(label: _kindTitle(l, action.kind)),
        if (hasAmount) ...[
          const SizedBox(height: 4),
          _amount(c, d, size: 28, decoration: struck),
        ],
        if (d.name != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(d.name!,
                style: LedgerText.display(color: c.ink)
                    .copyWith(decoration: struck)),
          ),
        if (d.description != null && d.description != d.name)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(d.description!,
                style: LedgerText.body(size: 15, color: c.ink)
                    .copyWith(decoration: struck)),
          ),
        if (meta.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(meta,
                style: LedgerText.body(size: 14, color: c.muted)
                    .copyWith(decoration: struck)),
          ),
        if (!hasDetails && action.summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(action.summary,
                style: LedgerText.body(size: 15, color: c.ink)
                    .copyWith(decoration: struck)),
          ),
        if (d.note != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(d.note!,
                style: LedgerText.body(size: 14, color: c.muted)
                    .copyWith(fontStyle: FontStyle.italic)),
          ),
        if (status != null) ...[
          const SizedBox(height: 10),
          status,
        ],
        if (action.isOpen) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkButton(
                  key: ValueKey('pending-save-${action.id}'),
                  label: l.pendingActionSave,
                  height: 44,
                  busy: busy,
                  onPressed: () => onConfirm([action.id]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlineInkButton(
                  key: ValueKey('pending-cancel-${action.id}'),
                  label: l.pendingActionCancel,
                  height: 44,
                  onPressed: busy ? null : () => onCancel([action.id]),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BatchActions extends StatelessWidget {
  const _BatchActions({
    required this.actions,
    required this.isBusy,
    required this.now,
    required this.onConfirm,
    required this.onCancel,
  });

  final List<PendingAction> actions;
  final bool Function(String id) isBusy;
  final DateTime now;
  final void Function(List<String> ids) onConfirm;
  final void Function(List<String> ids) onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final open = [
      for (final a in actions)
        if (a.isOpen) a.id
    ];
    final anyBusy = actions.any((a) => isBusy(a.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LedgerCapsHeader(label: l.pendingActionBatchTitle(actions.length)),
        for (final a in actions)
          _BatchRow(
            action: a,
            now: now,
            busy: anyBusy,
            onRemove: () => onCancel([a.id]),
          ),
        if (open.isNotEmpty) ...[
          const SizedBox(height: 12),
          InkButton(
            key: const ValueKey('pending-save-all'),
            label: l.pendingActionSaveAll(open.length),
            height: 44,
            busy: anyBusy,
            onPressed: () => onConfirm(open),
          ),
          const SizedBox(height: 8),
          OutlineInkButton(
            key: const ValueKey('pending-cancel-all'),
            label: l.pendingActionCancelAll,
            height: 44,
            onPressed: anyBusy ? null : () => onCancel(open),
          ),
        ],
      ],
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({
    required this.action,
    required this.now,
    required this.busy,
    required this.onRemove,
  });

  final PendingAction action;
  final DateTime now;
  final bool busy;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final d = action.details;
    final struck = action.isCancelled ? TextDecoration.lineThrough : null;
    final muted = !action.isOpen;
    final status = action.isPending ? null : _statusLine(l, c, action);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              d.date == null
                  ? ''
                  : pendingActionDate(l, d.date!, now, short: true),
              style: LedgerText.figures(size: 12, color: c.muted),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.description ?? d.name ?? action.summary,
                  style:
                      LedgerText.body(size: 15, color: muted ? c.muted : c.ink)
                          .copyWith(decoration: struck),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      d.label ?? l.pendingActionNeedsLabel,
                      style: LedgerText.body(
                          size: 13,
                          color: d.label == null ? c.moneyOut : c.muted),
                    ),
                    if (d.duplicate) _Tag(text: l.pendingActionDuplicate),
                    if (status != null) status,
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _amount(c, d, size: 15, decoration: struck),
          if (action.isOpen)
            SizedBox(
              width: 36,
              height: 28,
              child: IconButton(
                key: ValueKey('pending-remove-${action.id}'),
                padding: EdgeInsets.zero,
                iconSize: 18,
                tooltip: l.pendingActionRemove,
                onPressed: busy ? null : onRemove,
                icon: Icon(Icons.close, color: c.muted),
              ),
            )
          else
            const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: c.moneyOut),
        borderRadius: BorderRadius.circular(SureTokens.radiusMd),
      ),
      child: Text(text,
          style: LedgerText.body(
              size: 12, weight: FontWeight.w500, color: c.moneyOut)),
    );
  }
}
