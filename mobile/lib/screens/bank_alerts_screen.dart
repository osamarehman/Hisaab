import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../providers/auth_provider.dart';
import '../services/accounts_service.dart';
import '../services/bank_alerts_service.dart';
import '../utils/money_format.dart';
import '../widgets/ledger/ledger.dart';

/// Bank email alerts: the household's forwarding address, setup steps,
/// the senders whose mail is read, and alerts waiting for review.
class BankAlertsScreen extends StatefulWidget {
  const BankAlertsScreen({
    super.key,
    this.service,
    this.tokenLoader,
    this.accounts,
  });

  /// Test seams; production uses the real service, the signed-in token and
  /// the accounts in [AccountsProvider].
  final BankAlertsService? service;
  final Future<String?> Function()? tokenLoader;
  final List<Account>? accounts;

  @override
  State<BankAlertsScreen> createState() => _BankAlertsScreenState();
}

class _BankAlertsScreenState extends State<BankAlertsScreen> {
  late final BankAlertsService _service = widget.service ?? BankAlertsService();
  final _senderController = TextEditingController();

  EmailInbox? _inbox;
  List<BankAlert> _toReview = const [];
  bool _loading = true;
  String? _loadError;
  bool _addingSender = false;
  String? _senderError;

  /// Accounts fresh from the server; the offline cache has no subtype or
  /// last 4 digits, so it can't tell cash from bank accounts.
  List<Account>? _serverAccounts;

  /// Alerts with a request in flight, so their buttons disable.
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _senderController.dispose();
    super.dispose();
  }

  Future<String?> _token() => widget.tokenLoader != null
      ? widget.tokenLoader!()
      : context.read<AuthProvider>().getValidAccessToken();

  String _errorText(AppLocalizations l, String? error) {
    switch (error) {
      case BankAlertsResult.offline:
        return l.bankAlertsOffline;
      case BankAlertsResult.unsupported:
        return l.bankAlertsUnsupported;
      case BankAlertsResult.unauthorized:
        return l.commonSignInAgain;
      case null:
      case '':
        return l.bankAlertsActionFailed;
      default:
        return error;
    }
  }

  Future<void> _load() async {
    final l = AppLocalizations.of(context);
    final token = await _token();
    if (!mounted) return;
    if (token == null) {
      setState(() {
        _loading = false;
        _loadError = l.commonSignInAgain;
      });
      return;
    }
    if (widget.accounts == null) _loadAccounts(token);
    final results = await Future.wait([
      _service.getInbox(accessToken: token),
      _service.listAlerts(accessToken: token, perPage: 100),
    ]);
    if (!mounted) return;
    final inbox = results[0] as BankAlertsResult<EmailInbox>;
    final alerts = results[1] as BankAlertsResult<List<BankAlert>>;
    setState(() {
      _loading = false;
      if (!inbox.ok) {
        _loadError = _errorText(l, inbox.error);
        return;
      }
      _loadError = null;
      _inbox = inbox.value;
      final all = alerts.value ?? inbox.value!.recent;
      _toReview = all.where((a) => a.needsReview).toList();
    });
  }

  Future<void> _loadAccounts(String token) async {
    final result =
        await AccountsService().getAccounts(accessToken: token, perPage: 100);
    if (!mounted || result['success'] != true) return;
    _serverAccounts = result['accounts'] as List<Account>;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyAddress() async {
    final l = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: _inbox!.address));
    if (mounted) _toast(l.bankAlertsCopied);
  }

  Future<void> _shareAddress() async {
    await SharePlus.instance.share(ShareParams(text: _inbox!.address));
  }

  Future<void> _openConfirmation(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _rotate() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.bankAlertsRotateTitle),
        content: Text(l.bankAlertsRotateBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.bankAlertsRotateConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = await _token();
    if (token == null || !mounted) return;
    final result = await _service.rotateAddress(accessToken: token);
    if (!mounted) return;
    if (result.ok) {
      setState(() => _inbox = result.value);
      _toast(l.bankAlertsRotated);
    } else {
      _toast(_errorText(l, result.error));
    }
  }

  Future<void> _addSender([String? pattern]) async {
    final l = AppLocalizations.of(context);
    final text = (pattern ?? _senderController.text).trim().toLowerCase();
    if (text.isEmpty) {
      setState(() => _senderError = l.bankAlertsSenderRequired);
      return;
    }
    final token = await _token();
    if (token == null || !mounted) return;
    setState(() {
      _addingSender = true;
      _senderError = null;
    });
    final result = await _service.addSender(accessToken: token, pattern: text);
    if (!mounted) return;
    setState(() {
      _addingSender = false;
      if (result.ok) {
        _senderController.clear();
        _inbox = EmailInbox(
          address: _inbox!.address,
          confirmation: _inbox!.confirmation,
          senders: [..._inbox!.senders, result.value!],
          recent: _inbox!.recent,
        );
      } else {
        _senderError = _errorText(l, result.error);
      }
    });
    if (result.ok && pattern != null) _toast(l.bankAlertsSenderAdded(text));
  }

  Future<void> _removeSender(EmailSender sender) async {
    final l = AppLocalizations.of(context);
    final token = await _token();
    if (token == null || !mounted) return;
    final result =
        await _service.removeSender(accessToken: token, senderId: sender.id);
    if (!mounted) return;
    if (result.ok) {
      setState(() => _inbox = EmailInbox(
            address: _inbox!.address,
            confirmation: _inbox!.confirmation,
            senders: _inbox!.senders.where((s) => s.id != sender.id).toList(),
            recent: _inbox!.recent,
          ));
    } else {
      _toast(_errorText(l, result.error));
    }
  }

  List<Account> _matchableAccounts() {
    final all = widget.accounts ??
        _serverAccounts ??
        context.read<AccountsProvider>().accounts;
    return all
        .where((a) =>
            a.accountType == 'credit_card' ||
            (a.accountType == 'depository' && a.subtype != 'cash'))
        .toList();
  }

  Future<String?> _pickAccount(BankAlert alert) {
    final l = AppLocalizations.of(context);
    final c = LedgerColors.of(context);
    final accounts = _matchableAccounts();
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(l.bankAlertsPickAccount,
                  style: LedgerText.title(color: c.ink)),
            ),
            if (alert.last4 != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(l.bankAlertsPickAccountHelp(alert.last4!),
                    style: LedgerText.body(size: 14, color: c.muted)),
              ),
            if (accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l.bankAlertsNoAccounts,
                    style: LedgerText.body(color: c.muted)),
              ),
            for (final account in accounts)
              ListTile(
                key: ValueKey('bank-alert-account-${account.id}'),
                title: Text(account.name),
                subtitle: account.numberLast4 == null
                    ? null
                    : Text('•••• ${account.numberLast4}',
                        textDirection: TextDirection.ltr),
                onTap: () => Navigator.pop(sheetContext, account.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BankAlert alert) async {
    final l = AppLocalizations.of(context);
    String? accountId;
    if (alert.status == BankAlert.needsAccount) {
      accountId = await _pickAccount(alert);
      if (accountId == null || !mounted) return;
    }
    await _decide(alert, l.bankAlertsKept, (token) {
      return _service.approve(
          accessToken: token, alertId: alert.id, accountId: accountId);
    });
  }

  Future<void> _reject(BankAlert alert) {
    final l = AppLocalizations.of(context);
    return _decide(alert, l.bankAlertsDiscarded, (token) {
      return _service.reject(accessToken: token, alertId: alert.id);
    });
  }

  Future<void> _decide(
    BankAlert alert,
    String doneMessage,
    Future<BankAlertsResult<BankAlert>> Function(String token) call,
  ) async {
    final l = AppLocalizations.of(context);
    final token = await _token();
    if (token == null || !mounted) return;
    setState(() => _busy.add(alert.id));
    final result = await call(token);
    if (!mounted) return;
    setState(() {
      _busy.remove(alert.id);
      if (result.ok) {
        _toReview = _toReview.where((a) => a.id != alert.id).toList();
      }
    });
    _toast(result.ok ? doneMessage : _errorText(l, result.error));
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(
          children: [
            if (Navigator.of(context).canPop()) const LedgerBackHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    Text(l.bankAlertsTitle,
                        style: LedgerText.title(color: c.ink)),
                    const SizedBox(height: 12),
                    Text(l.bankAlertsIntro,
                        style: LedgerText.body(color: c.muted)),
                    const SizedBox(height: 24),
                    ..._content(c, l),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(LedgerColors c, AppLocalizations l) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_loadError != null) {
      return [
        Text(_loadError!,
            key: const Key('bankAlertsError'),
            style: LedgerText.body(color: c.danger)),
        const SizedBox(height: 16),
        OutlineInkButton(
          label: l.commonTryAgain,
          height: 48,
          onPressed: () {
            setState(() => _loading = true);
            _load();
          },
        ),
      ];
    }
    final inbox = _inbox!;
    final history = inbox.recent.where((a) => !a.needsReview).toList();
    return [
      if (_toReview.isNotEmpty) ...[
        LedgerCapsHeader(label: l.bankAlertsToReview(_toReview.length)),
        for (final alert in _toReview) _reviewCard(c, l, alert),
        const SizedBox(height: 24),
      ],
      LedgerCapsHeader(label: l.bankAlertsAddressHeader),
      _addressPanel(c, l, inbox),
      const SizedBox(height: 24),
      LedgerCapsHeader(label: l.bankAlertsSetupHeader),
      _setupSteps(c, l),
      const SizedBox(height: 24),
      LedgerCapsHeader(label: l.bankAlertsSendersHeader),
      _senders(c, l, inbox),
      const SizedBox(height: 24),
      LedgerCapsHeader(label: l.bankAlertsRecentHeader),
      if (history.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(l.bankAlertsRecentEmpty,
              key: const Key('bankAlertsRecentEmpty'),
              style: LedgerText.body(size: 14, color: c.muted)),
        )
      else
        for (final alert in history) _historyRow(c, l, alert, inbox),
      const SizedBox(height: 24),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          key: const Key('bankAlertsRotate'),
          onPressed: _rotate,
          child: Text(l.bankAlertsRotate),
        ),
      ),
    ];
  }

  Widget _addressPanel(LedgerColors c, AppLocalizations l, EmailInbox inbox) {
    final confirmation = inbox.confirmation;
    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            inbox.address,
            key: const Key('bankAlertsAddress'),
            textDirection: TextDirection.ltr,
            style: LedgerText.figures(size: 15, color: c.ink),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlineInkButton(
                  key: const Key('bankAlertsCopy'),
                  label: l.bankAlertsCopy,
                  height: 44,
                  onPressed: _copyAddress,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlineInkButton(
                  label: l.bankAlertsShare,
                  height: 44,
                  onPressed: _shareAddress,
                ),
              ),
            ],
          ),
          if (confirmation?.code != null) ...[
            const SizedBox(height: 16),
            Text(l.bankAlertsGmailCode,
                style: LedgerText.body(size: 14, color: c.muted)),
            const SizedBox(height: 4),
            SelectableText(
              confirmation!.code!,
              key: const Key('bankAlertsGmailCode'),
              textDirection: TextDirection.ltr,
              style: LedgerText.figures(
                  size: 22, weight: FontWeight.w600, color: c.ink),
            ),
            if (confirmation.url != null) ...[
              const SizedBox(height: 8),
              InkButton(
                label: l.bankAlertsGmailOpen,
                height: 44,
                onPressed: () => _openConfirmation(confirmation.url!),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _setupSteps(LedgerColors c, AppLocalizations l) {
    Widget steps(String title, String body) => ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(title,
              style: LedgerText.body(weight: FontWeight.w500, color: c.ink)),
          children: [
            Text(body, style: LedgerText.body(size: 14, color: c.ink))
          ],
        );
    return Column(
      children: [
        steps(l.bankAlertsGmailTitle, l.bankAlertsGmailSteps),
        steps(l.bankAlertsOutlookTitle, l.bankAlertsOutlookSteps),
      ],
    );
  }

  Widget _senders(LedgerColors c, AppLocalizations l, EmailInbox inbox) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (inbox.senders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l.bankAlertsSendersEmpty,
                style: LedgerText.body(size: 14, color: c.muted)),
          ),
        for (final sender in inbox.senders)
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.hairline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(sender.pattern,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                      style: LedgerText.body(color: c.ink)),
                ),
                IconButton(
                  key: ValueKey('bank-sender-remove-${sender.id}'),
                  tooltip: l.bankAlertsSenderRemove,
                  icon: Icon(Icons.close, color: c.muted),
                  onPressed: () => _removeSender(sender),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const Key('bankAlertsSenderField'),
                controller: _senderController,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                autocorrect: false,
                style: LedgerText.body(color: c.ink),
                decoration:
                    ledgerInputDecoration(context, hint: 'alerts@yourbank.com')
                        .copyWith(errorText: _senderError),
                onSubmitted: (_) => _addSender(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: InkButton(
                key: const Key('bankAlertsSenderAdd'),
                label: l.bankAlertsSenderAdd,
                height: 48,
                busy: _addingSender,
                onPressed: () => _addSender(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(l.bankAlertsSendersHelp(MoneyFormat.ltrIsolate('@bank.com')),
            style: LedgerText.body(size: 13, color: c.muted)),
      ],
    );
  }

  static String _when(DateTime? at) => at == null
      ? ''
      : DateFormat('d MMM, h:mm a', 'en_US').format(at.toLocal());

  Widget _reviewCard(LedgerColors c, AppLocalizations l, BankAlert alert) {
    final busy = _busy.contains(alert.id);
    final out = alert.direction != 'in';
    final amount = alert.amount == null
        ? ''
        : MoneyFormat.format(out ? -alert.amount! : alert.amount!,
            currency: alert.currency, signed: true);
    final where = alert.status == BankAlert.needsAccount
        ? l.bankAlertsNoMatch(alert.last4 ?? '????')
        : (alert.accountName ?? '');
    return Container(
      key: ValueKey('bank-alert-${alert.id}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.payee ?? alert.subject ?? alert.from ?? '',
                        style: LedgerText.body(
                            weight: FontWeight.w500, color: c.ink)),
                    const SizedBox(height: 2),
                    Text(
                      [where, _when(alert.occurredAt ?? alert.receivedAt)]
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: LedgerText.body(
                          size: 13,
                          color: alert.status == BankAlert.needsAccount
                              ? c.danger
                              : c.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                MoneyFormat.ltrIsolate(amount),
                style: LedgerText.figures(
                    size: 16,
                    weight: FontWeight.w600,
                    color: out ? c.ink : c.moneyIn),
              ),
            ],
          ),
          if (alert.senderVerified == false) ...[
            const SizedBox(height: 8),
            Row(
              key: ValueKey('bank-alert-unverified-${alert.id}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: c.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.bankAlertsUnverified(MoneyFormat.ltrIsolate(
                        alert.senderDomain ?? alert.from ?? '')),
                    style: LedgerText.body(size: 13, color: c.danger),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlineInkButton(
                  key: ValueKey('bank-alert-reject-${alert.id}'),
                  label: l.bankAlertsDiscard,
                  height: 40,
                  onPressed: busy ? null : () => _reject(alert),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkButton(
                  key: ValueKey('bank-alert-approve-${alert.id}'),
                  label: alert.status == BankAlert.needsAccount
                      ? l.bankAlertsChooseAccount
                      : l.bankAlertsKeep,
                  height: 40,
                  busy: busy,
                  onPressed: () => _approve(alert),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyRow(
      LedgerColors c, AppLocalizations l, BankAlert alert, EmailInbox inbox) {
    final status = switch (alert.status) {
      BankAlert.approved => l.bankAlertsStatusApproved,
      BankAlert.rejected => l.bankAlertsStatusRejected,
      BankAlert.unparsed => l.bankAlertsStatusUnparsed,
      BankAlert.ignored => l.bankAlertsStatusIgnored,
      _ => alert.status,
    };
    final from = alert.from ?? '';
    final allowed = inbox.senders.any((s) =>
        s.pattern.toLowerCase() == from.toLowerCase() ||
        (s.pattern.startsWith('@') &&
            from.toLowerCase().endsWith(s.pattern.toLowerCase())));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alert.subject ?? from,
              style: LedgerText.body(size: 15, color: c.ink)),
          const SizedBox(height: 2),
          Text(
            '${MoneyFormat.ltrIsolate(from)} · ${_when(alert.receivedAt)}',
            style: LedgerText.body(size: 13, color: c.muted),
          ),
          const SizedBox(height: 2),
          Text(status, style: LedgerText.body(size: 13, color: c.muted)),
          if (alert.status == BankAlert.ignored && from.isNotEmpty && !allowed)
            TextButton(
              key: ValueKey('bank-alert-allow-${alert.id}'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => _addSender(from),
              child: Text(l.bankAlertsAllowSender),
            ),
        ],
      ),
    );
  }
}
