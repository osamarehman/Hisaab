import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/accounts_provider.dart';
import '../providers/auth_provider.dart';
import '../services/family_settings_service.dart';
import '../utils/currencies.dart';
import '../utils/money_format.dart';
import '../widgets/ledger/ledger.dart';

/// Household currency: a searchable list of ISO 4217 currencies. Saving
/// changes the default for new accounts and reports; existing accounts keep
/// their own currency. Only a household admin can change it.
class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key, this.service, this.tokenLoader});

  /// Test seams; production uses the real service and the signed-in token.
  final FamilySettingsService? service;
  final Future<String?> Function()? tokenLoader;

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  late final FamilySettingsService _service =
      widget.service ?? FamilySettingsService();
  final _search = TextEditingController();

  String? _current;
  String? _saving;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<String?> _token() => widget.tokenLoader != null
      ? widget.tokenLoader!()
      : context.read<AuthProvider>().getValidAccessToken();

  String _errorText(AppLocalizations l, String? error) => switch (error) {
        FamilySettingsResult.offline => l.currencyOffline,
        FamilySettingsResult.forbidden => l.currencyAdminOnly,
        FamilySettingsResult.unauthorized => l.commonSignInAgain,
        null || '' => l.currencySaveFailed,
        _ => error,
      };

  Future<void> _load() async {
    final l = AppLocalizations.of(context);
    final token = await _token();
    if (!mounted) return;
    final result = token == null
        ? const FamilySettingsResult.failure(FamilySettingsResult.unauthorized)
        : await _service.fetch(accessToken: token);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _current = result.currency;
      _error = result.ok ? null : _errorText(l, result.error);
    });
  }

  Future<void> _choose(CurrencyInfo currency) async {
    if (currency.code == _current || _saving != null) return;
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.currencyConfirmTitle(currency.code)),
        content: Text(l.currencyConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            key: const Key('currencyConfirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.currencyConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final token = await _token();
    if (token == null || !mounted) return;
    setState(() => _saving = currency.code);
    final result =
        await _service.setCurrency(accessToken: token, currency: currency.code);
    if (!mounted) return;
    setState(() {
      _saving = null;
      if (result.ok) _current = result.currency;
    });
    if (!result.ok) {
      _toast(_errorText(l, result.error));
      return;
    }
    final accounts = context.read<AccountsProvider?>();
    accounts?.setFamilyCurrency(result.currency!);
    _toast(l.currencySaved(result.currency!));
    accounts?.fetchAccounts(accessToken: token, forceSync: true);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<CurrencyInfo> _matches() {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return kCurrencies;
    return kCurrencies
        .where((c) =>
            c.code.toLowerCase().contains(query) ||
            c.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (Navigator.of(context).canPop()) const LedgerBackHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.currencyTitle, style: LedgerText.title(color: c.ink)),
                  const SizedBox(height: 12),
                  Text(l.currencyIntro, style: LedgerText.body(color: c.muted)),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('currencySearch'),
                    controller: _search,
                    autocorrect: false,
                    style: LedgerText.body(color: c.ink),
                    decoration: ledgerInputDecoration(context,
                            hint: l.currencySearchHint)
                        .copyWith(
                            prefixIcon: Icon(Icons.search, color: c.muted)),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        key: const Key('currencyError'),
                        style: LedgerText.body(size: 14, color: c.danger)),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(child: _list(c, l)),
          ],
        ),
      ),
    );
  }

  Widget _list(LedgerColors c, AppLocalizations l) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final matches = _matches();
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(l.currencyNoMatch,
            style: LedgerText.body(size: 14, color: c.muted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: matches.length,
      itemBuilder: (context, i) {
        final currency = matches[i];
        final selected = currency.code == _current;
        return ListTile(
          key: ValueKey('currency-${currency.code}'),
          selected: selected,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: SizedBox(
            width: 44,
            child: Text(
              MoneyFormat.symbol(currency.code),
              textDirection: TextDirection.ltr,
              style: LedgerText.figures(size: 16, color: c.ink),
            ),
          ),
          title: Text(currency.name,
              style: LedgerText.body(
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: c.ink)),
          subtitle: Text(currency.code,
              style: LedgerText.figures(size: 13, color: c.muted)),
          trailing: _saving == currency.code
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : selected
                  ? Icon(Icons.check, color: c.ink)
                  : null,
          onTap: () => _choose(currency),
        );
      },
    );
  }
}
