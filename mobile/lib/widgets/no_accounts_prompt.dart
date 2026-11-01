import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/account.dart';
import '../screens/account_form_screen.dart';
import 'ledger/ledger.dart';

/// Shown when the household has no accounts yet: nothing can be recorded
/// until there is an account to pay from or into.
class NoAccountsPrompt extends StatelessWidget {
  const NoAccountsPrompt(
      {super.key, this.kind = AccountKind.cash, this.onCreated});

  /// The kind the form starts on.
  final AccountKind kind;

  /// Called with the account the user just added.
  final ValueChanged<Account>? onCreated;

  Future<void> _add(BuildContext context) async {
    final account = await openAccountForm(context, kind: kind);
    if (account != null) onCreated?.call(account);
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    return LedgerPanel(
      key: const ValueKey('no-accounts-prompt'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.noAccountsTitle,
              style: LedgerText.display(size: 22, color: c.ink)),
          const SizedBox(height: 8),
          Text(
            l.noAccountsBody,
            style: LedgerText.body(size: 15, color: c.muted),
          ),
          const SizedBox(height: 16),
          InkButton(
            label: l.noAccountsTitle,
            onPressed: () => _add(context),
          ),
        ],
      ),
    );
  }
}
