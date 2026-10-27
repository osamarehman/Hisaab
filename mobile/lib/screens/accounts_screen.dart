import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../providers/auth_provider.dart';
import '../providers/privacy_provider.dart';
import '../services/accounts_service.dart';
import '../services/balance_sheet_service.dart';
import '../utils/money_masker.dart';
import '../widgets/household/household_style.dart';
import 'statements_screen.dart';

/// Balance sheet: net worth, then "what we have" / "what we owe" grouped by
/// kind of account. Bank and card accounts offer "Add statement".
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _Group {
  _Group(this.name);
  final String name;
  final List<Account> accounts = [];
  int get totalCents =>
      accounts.fold(0, (sum, a) => sum + (a.balanceCents ?? 0).abs());
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Account> _accounts = const [];
  num? _netWorth;
  num? _assets;
  num? _liabilities;
  String _currency = 'PKR';
  bool _showOwed = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = await context.read<AuthProvider>().getValidAccessToken();
    if (!mounted) return;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Please sign in again.';
      });
      return;
    }
    final results = await Future.wait([
      AccountsService().getAccounts(accessToken: token, perPage: 100),
      BalanceSheetService().getBalanceSheet(accessToken: token),
    ]);
    if (!mounted) return;
    final accounts = results[0];
    final sheet = results[1];
    setState(() {
      _loading = false;
      if (accounts['success'] != true) {
        _error = 'Could not load your accounts. Pull down to try again.';
        return;
      }
      _error = null;
      _accounts = (accounts['accounts'] as List).cast<Account>();
      if (sheet['success'] == true) {
        _currency = sheet['currency'] as String? ?? _currency;
        _netWorth = _amount(sheet['net_worth']);
        _assets = _amount(sheet['assets']);
        _liabilities = _amount(sheet['liabilities']);
      }
    });
  }

  /// Money#as_json: `{"amount": "123.45", "currency": "PKR", ...}`.
  static num? _amount(dynamic money) {
    if (money is! Map) return null;
    final raw = money['amount'];
    return raw is num ? raw : num.tryParse('${raw ?? ''}');
  }

  static String _groupName(Account a) {
    switch (a.accountType) {
      case 'depository':
        return 'Bank';
      case 'credit_card':
        return 'Cards';
      case 'loan':
        return 'Loans';
      case 'other_liability':
        return 'Other money owed';
      case 'property':
      case 'vehicle':
        return 'Property';
      default:
        return 'Savings & gold';
    }
  }

  static bool _takesStatements(Account a) =>
      a.accountType == 'depository' || a.accountType == 'credit_card';

  List<_Group> _groups({required bool owed}) {
    final groups = <String, _Group>{};
    for (final a in _accounts) {
      if (a.isLiability != owed) continue;
      groups
          .putIfAbsent(_groupName(a), () => _Group(_groupName(a)))
          .accounts
          .add(a);
    }
    return groups.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = HouseholdColors.of(context);
    final hidden = context.watch<PrivacyProvider>().hidden;
    String money(num? v) => v == null
        ? '–'
        : MoneyMasker.mask(formatMoney(v, _currency), hidden: hidden);

    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
            children: [
              Text('Accounts', style: HouseholdText.title(c.ink)),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Text(_error!, style: HouseholdText.body(c.amber))
              else ...[
                _netWorthBlock(c, hidden),
                const SizedBox(height: 24),
                _sideToggle(c, money),
                const SizedBox(height: 24),
                for (final g in _groups(owed: _showOwed)) ...[
                  _groupSection(c, g, hidden),
                  const SizedBox(height: 24),
                ],
                if (_groups(owed: _showOwed).isEmpty)
                  Text(
                    _showOwed ? 'Nothing owed.' : 'No accounts yet.',
                    style: HouseholdText.body(c.muted),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _netWorthBlock(HouseholdColors c, bool hidden) {
    final value = _netWorth;
    final text = value == null
        ? '–'
        : MoneyMasker.mask(groupDigits(value), hidden: hidden);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Net worth', style: HouseholdText.body(c.muted, size: 14)),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: value != null && value < 0 ? '- Rs ' : 'Rs ',
              style: HouseholdText.bigNumber(c.muted, size: 22),
            ),
            TextSpan(text: text, style: HouseholdText.bigNumber(c.ink)),
          ]),
        ),
      ],
    );
  }

  Widget _sideToggle(HouseholdColors c, String Function(num?) money) {
    Widget side(String label, num? total, bool owed) {
      final on = _showOwed == owed;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: InkWell(
            onTap: () => setState(() => _showOwed = owed),
            child: Container(
              constraints: const BoxConstraints(minHeight: 68),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: on ? c.ink : Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style:
                          HouseholdText.body(on ? c.onInk : c.ink, size: 13)),
                  const SizedBox(height: 2),
                  Text(money(total),
                      style:
                          HouseholdText.mono(on ? c.onInk : c.ink, size: 18)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: c.ink)),
      ),
      child: Row(
        children: [
          side('What we have', _assets, false),
          side('What we owe', _liabilities, true),
        ],
      ),
    );
  }

  Widget _groupSection(HouseholdColors c, _Group g, bool hidden) {
    String cents(int v, String currency) =>
        MoneyMasker.mask(formatMoneyCents(v, currency), hidden: hidden);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LedgerCapsHead(
          label: g.name,
          trailing: cents(g.totalCents, _currency),
        ),
        for (final a in g.accounts)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.hairline)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name, style: HouseholdText.body(c.ink)),
                      const SizedBox(height: 2),
                      Text(
                        a.institutionName ?? a.displayAccountType,
                        style: HouseholdText.body(c.muted, size: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      a.balanceCents == null
                          ? MoneyMasker.mask(a.balance, hidden: hidden)
                          : cents(a.balanceCents!.abs(), a.currency),
                      style: HouseholdText.mono(c.ink, size: 16),
                    ),
                    if (_takesStatements(a))
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                StatementsScreen(initialAccountId: a.id),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 36),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        child: Text('Add statement',
                            style: HouseholdText.body(c.cobalt, size: 13)),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Manual',
                            style: HouseholdText.body(c.muted, size: 13)),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
