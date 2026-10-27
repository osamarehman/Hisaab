import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../providers/auth_provider.dart';
import '../services/accounts_service.dart';
import '../utils/amount_parser.dart';
import '../utils/money_format.dart';
import '../widgets/ledger/ledger.dart';
import 'transaction_form_screen.dart' show GroupedAmountFormatter;

/// The kinds of account a household adds, in plain words, mapped to the
/// server's account types.
enum AccountKind {
  bank(
    label: 'Bank account',
    hint: 'Current account you spend from, e.g. HBL, Meezan',
    accountableType: 'Depository',
    subtype: 'checking',
  ),
  savings(
    label: 'Savings account',
    hint: 'Money you keep aside in the bank',
    accountableType: 'Depository',
    subtype: 'savings',
  ),
  cash(
    label: 'Cash in hand',
    hint: 'Money in your purse or at home',
    accountableType: 'Depository',
    subtype: 'cash',
    defaultName: 'Cash in hand',
  ),
  creditCard(
    label: 'Credit card',
    hint: 'What you owe on the card',
    accountableType: 'CreditCard',
    subtype: 'credit_card',
    owed: true,
  ),
  loan(
    label: 'Loan / money owed',
    hint: 'Money you owe a bank, a relative or a shop',
    accountableType: 'OtherLiability',
    owed: true,
  ),
  assets(
    label: 'Gold & savings certificates',
    hint: 'Gold, prize bonds, national savings',
    accountableType: 'OtherAsset',
  );

  const AccountKind({
    required this.label,
    required this.hint,
    required this.accountableType,
    this.subtype,
    this.defaultName,
    this.owed = false,
  });

  final String label;
  final String hint;
  final String accountableType;
  final String? subtype;
  final String? defaultName;

  /// A liability: the balance is how much is owed.
  final bool owed;
}

/// What the account form pops with.
class AccountFormResult {
  const AccountFormResult.saved(Account this.account) : deletedId = null;
  const AccountFormResult.deleted(String this.deletedId) : account = null;

  final Account? account;
  final String? deletedId;
}

/// Opens the add/edit account form and updates [AccountsProvider] with the
/// outcome so every screen sees the change. Returns the saved account, or
/// null when the form was closed or the account deleted.
Future<Account?> openAccountForm(
  BuildContext context, {
  Account? account,
  AccountKind? kind,
}) async {
  final accounts = context.read<AccountsProvider>();
  final auth = context.read<AuthProvider>();
  final result = await Navigator.of(context).push<AccountFormResult>(
    MaterialPageRoute(
      builder: (_) => AccountFormScreen(account: account, initialKind: kind),
    ),
  );
  if (result == null) return null;

  if (result.account != null) {
    await accounts.upsertAccount(result.account!);
  } else if (result.deletedId != null) {
    await accounts.removeAccount(result.deletedId!);
  }
  final token = await auth.getValidAccessToken();
  if (token != null) {
    // Refreshes balances and net worth; the list is already up to date.
    unawaited(accounts.fetchAccounts(
        accessToken: token, forceSync: true, perPage: 100));
  }
  return result.account;
}

/// Add an account (pick a kind, name it, say how much is in it) or edit one
/// (rename, set today's balance, delete). Pops an [AccountFormResult].
class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({
    super.key,
    this.account,
    this.initialKind,
    this.service,
    this.tokenLoader,
  });

  /// The account to edit; null to add a new one.
  final Account? account;
  final AccountKind? initialKind;

  /// Test seams; default to the real service and the signed-in user's token.
  final AccountsService? service;
  final Future<String?> Function()? tokenLoader;

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AccountsService _service = widget.service ?? AccountsService();
  late final TextEditingController _name =
      TextEditingController(text: widget.account?.name ?? '');
  late final TextEditingController _balance =
      TextEditingController(text: _initialBalance());

  AccountKind? _kind;
  String? _kindError;
  bool _busy = false;
  String? _error;

  bool get _editing => widget.account != null;
  bool get _owed =>
      _editing ? widget.account!.isLiability : _kind?.owed == true;

  @override
  void initState() {
    super.initState();
    if (widget.initialKind != null) _selectKind(widget.initialKind!);
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  String _initialBalance() {
    final cents = widget.account?.balanceCents;
    if (cents == null) return '';
    final value = cents.abs() / 100;
    return NumberFormat(
            value == value.roundToDouble() ? '#,##0' : '#,##0.00', 'en_US')
        .format(value);
  }

  void _selectKind(AccountKind kind) {
    final previousDefault = _kind?.defaultName;
    final name = _name.text.trim();
    // Prefill "Cash in hand" without overwriting a name the user typed.
    if (name.isEmpty || name == previousDefault) {
      _name.text = kind.defaultName ?? '';
    }
    _kind = kind;
    _kindError = null;
  }

  String? _validateName(String? value) =>
      (value ?? '').trim().isEmpty ? 'Give the account a name.' : null;

  String? _validateBalance(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null; // Treated as 0.
    try {
      if (AmountParser.parse(text, locale: 'en_US').value < 0) {
        return 'Enter the amount without a minus sign.';
      }
    } on FormatException {
      return 'Enter a number, like 25,000.';
    }
    return null;
  }

  String _canonicalBalance() {
    final text = _balance.text.trim();
    return text.isEmpty
        ? '0'
        : AmountParser.canonicalize(text, locale: 'en_US');
  }

  Future<String?> _token() => (widget.tokenLoader ??
      () => context.read<AuthProvider>().getValidAccessToken())();

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    if (!_editing && _kind == null) {
      setState(() => _kindError = 'Choose what kind of account this is.');
      return;
    }
    if (!formOk) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    final token = await _token();
    if (!mounted) return;
    if (token == null) {
      setState(() {
        _busy = false;
        _error = 'Please sign in again.';
      });
      return;
    }

    final name = _name.text.trim();
    final balance = _canonicalBalance();
    final Map<String, dynamic> result;
    if (_editing) {
      final account = widget.account!;
      final balanceChanged = balance != _canonicalOf(_initialBalance());
      result = await _service.updateAccount(
        accessToken: token,
        accountId: account.id,
        name: name == account.name ? null : name,
        balance: balanceChanged ? balance : null,
      );
    } else {
      final kind = _kind!;
      result = await _service.createAccount(
        accessToken: token,
        name: name,
        accountableType: kind.accountableType,
        subtype: kind.subtype,
        balance: balance,
      );
    }

    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.of(context)
          .pop(AccountFormResult.saved(result['account'] as Account));
    } else {
      setState(() {
        _busy = false;
        _error = result['error']?.toString() ?? 'Could not save the account.';
      });
    }
  }

  static String _canonicalOf(String text) => text.trim().isEmpty
      ? '0'
      : AmountParser.canonicalize(text, locale: 'en_US');

  Future<void> _delete() async {
    final c = LedgerColors.of(context);
    final account = widget.account!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: Text('Delete "${account.name}"?'),
        content: const Text(
          'Everything recorded in this account is deleted too. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final token = await _token();
    if (!mounted) return;
    if (token == null) {
      setState(() {
        _busy = false;
        _error = 'Please sign in again.';
      });
      return;
    }
    final result =
        await _service.deleteAccount(accessToken: token, accountId: account.id);
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.of(context).pop(AccountFormResult.deleted(account.id));
    } else {
      setState(() {
        _busy = false;
        _error = result['error']?.toString() ?? 'Could not delete the account.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final labelStyle =
        LedgerText.body(size: 14, weight: FontWeight.w500, color: c.ink);
    final currency = widget.account?.currency ??
        context.select<AccountsProvider?, String?>((p) => p?.familyCurrency);

    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(
          children: [
            const LedgerBackHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    Text(_editing ? 'Edit account' : 'Add account',
                        style: LedgerText.title(color: c.ink)),
                    const SizedBox(height: 24),
                    if (!_editing) ...[
                      const LedgerCapsHeader(label: 'What kind of account?'),
                      for (final kind in AccountKind.values) _kindRow(c, kind),
                      if (_kindError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_kindError!,
                              style:
                                  LedgerText.body(size: 14, color: c.danger)),
                        ),
                      const SizedBox(height: 24),
                    ],
                    Text('Name', style: labelStyle),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const ValueKey('account-name'),
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                      style: LedgerText.body(color: c.ink),
                      decoration: ledgerInputDecoration(context,
                          hint: 'e.g. Meezan Bank, Cash in hand'),
                    ),
                    const SizedBox(height: 20),
                    Text(_owed ? 'How much is owed?' : 'How much is in it now?',
                        style: labelStyle),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const ValueKey('account-balance'),
                      controller: _balance,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [GroupedAmountFormatter()],
                      validator: _validateBalance,
                      style: LedgerText.figures(size: 18, color: c.ink),
                      decoration:
                          ledgerInputDecoration(context, hint: '0').copyWith(
                        // prefixIcon, unlike prefixText, shows while empty.
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Text(MoneyFormat.symbol(currency),
                              style:
                                  LedgerText.figures(size: 18, color: c.muted)),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _editing
                          ? 'Change this to match your bank or purse today.'
                          : 'Leave empty if you are not sure. You can change it later.',
                      style: LedgerText.body(size: 13, color: c.muted),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: LedgerText.body(size: 14, color: c.danger)),
                    ],
                    const SizedBox(height: 24),
                    InkButton(
                      key: const ValueKey('account-save'),
                      label: _editing ? 'Save' : 'Add account',
                      busy: _busy,
                      onPressed: _save,
                    ),
                    if (_editing) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : _delete,
                        style: TextButton.styleFrom(
                            minimumSize: const Size(44, 48)),
                        child: Text('Delete account',
                            style: LedgerText.body(size: 15, color: c.danger)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kindRow(LedgerColors c, AccountKind kind) {
    final on = _kind == kind;
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? c.ink : Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectKind(kind)),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.hairline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(kind.label,
                          style: LedgerText.body(
                              weight: FontWeight.w500,
                              color: on ? c.onInk : c.ink)),
                      const SizedBox(height: 2),
                      Text(kind.hint,
                          style: LedgerText.body(
                              size: 13, color: on ? c.onInk : c.muted)),
                    ],
                  ),
                ),
                Icon(
                  on ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: on ? c.onInk : c.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
