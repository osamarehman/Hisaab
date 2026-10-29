import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../providers/accounts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/transactions_provider.dart';
import '../services/balance_sheet_service.dart';
import '../services/cash_flow_service.dart';
import '../services/insights_service.dart';
import '../services/log_service.dart';
import '../services/transactions_service.dart';
import '../utils/money_format.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/ledger/ledger.dart';
import '../widgets/no_accounts_prompt.dart';
import 'budgets_screen.dart';
import 'report_export_screen.dart';
import 'settings_screen.dart';
import 'statement_review_screen.dart';
import 'statements_screen.dart';
import 'transactions_list_screen.dart';

/// One label's share of a month's spending.
class _LabelSpend {
  _LabelSpend(this.categoryId, this.name, this.color);
  final String? categoryId;
  final String name;
  final String? color;
  double amount = 0;
}

/// Home: the month at a glance (spent, in/out, labels, net worth).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.onOpenActivity,
    this.onOpenAccounts,
    this.onAskAssistant,
  });

  /// Jump to Activity for [month], optionally filtered to a label.
  final void Function(DateTime month, String? categoryId)? onOpenActivity;
  final VoidCallback? onOpenAccounts;

  /// Open the Assistant with [question] as the first message.
  final ValueChanged<String>? onAskAssistant;

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final _transactionsService = TransactionsService();
  final _cashFlowService = CashFlowService();
  final _balanceSheetService = BalanceSheetService();
  final _insightsService = InsightsService();
  final _log = LogService.instance;

  DateTime _month = MonthSwitcher.firstOf(DateTime.now());
  bool _loading = true;
  String? _error;
  int _loadToken = 0;

  MonthCashFlow? _cashFlow;
  List<Transaction> _transactions = const [];
  int _unlabelled = 0;
  double? _netWorth;
  double? _assets;
  double? _liabilities;
  String? _currency;
  List<Insight> _insights = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  Future<void> reload() async {
    final token = ++_loadToken;
    final auth = context.read<AuthProvider>();
    final accounts = context.read<AccountsProvider>();
    final categories = context.read<CategoriesProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });

    final accessToken = await auth.getValidAccessToken();
    if (accessToken == null) {
      await auth.logout();
      return;
    }

    _loadInsights(accessToken, token);

    final month = _month;
    final start = DateFormat('yyyy-MM-dd').format(month);
    final end = DateFormat('yyyy-MM-dd')
        .format(DateTime(month.year, month.month + 1, 0));

    try {
      final results = await Future.wait<Map<String, dynamic>>([
        _cashFlowService.getMonth(accessToken: accessToken, month: month),
        _transactionsService.getAllTransactions(
          accessToken: accessToken,
          startDate: start,
          endDate: end,
        ),
        _transactionsService.getTransactions(
          accessToken: accessToken,
          startDate: start,
          endDate: end,
          uncategorized: true,
          perPage: 1,
        ),
        _balanceSheetService.getBalanceSheet(accessToken: accessToken),
      ]);
      // Fire-and-forget: shared caches other screens read.
      categories.fetchCategories(accessToken: accessToken);
      accounts.fetchAccounts(accessToken: accessToken);

      if (!mounted || token != _loadToken) return;
      if (results.any((r) => r['error'] == 'unauthorized')) {
        await auth.logout();
        return;
      }

      final txResult = results[1];
      final uncategorized = results[2];
      final sheet = results[3];
      final pagination = uncategorized['pagination'];

      setState(() {
        _cashFlow = results[0]['cash_flow'] as MonthCashFlow?;
        _transactions = txResult['success'] == true
            ? txResult['transactions'] as List<Transaction>
            : const [];
        _unlabelled = pagination is Map
            ? int.tryParse(pagination['total_count']?.toString() ?? '') ?? 0
            : (uncategorized['transactions'] as List?)?.length ?? 0;
        if (sheet['success'] == true) {
          _currency = sheet['currency'] as String?;
          _netWorth = _moneyAmount(sheet['net_worth']);
          _assets = _moneyAmount(sheet['assets']);
          _liabilities = _moneyAmount(sheet['liabilities']);
        }
        _error = (txResult['success'] != true && _cashFlow == null)
            ? txResult['error']?.toString()
            : null;
        _loading = false;
      });
    } catch (e) {
      _log.error('DashboardScreen', 'Home load failed with ${e.runtimeType}');
      if (mounted && token == _loadToken) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  /// Optional section: any failure (including preview features being off)
  /// just hides it.
  Future<void> _loadInsights(String accessToken, int token) async {
    final result = await _insightsService.getInsights(accessToken: accessToken);
    if (!mounted || token != _loadToken) return;
    setState(() {
      _insights = result['success'] == true
          ? (result['insights'] as List<Insight>).take(3).toList()
          : const [];
    });
  }

  static double? _moneyAmount(dynamic money) {
    if (money is Map) return double.tryParse(money['amount']?.toString() ?? '');
    return null;
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final transactions = context.read<TransactionsProvider>();
    final token = await auth.getValidAccessToken();
    if (token != null && transactions.hasPendingTransactions) {
      await transactions.syncTransactions(accessToken: token);
    }
    await reload();
  }

  void _changeMonth(DateTime month) {
    setState(() => _month = month);
    reload();
  }

  String get _currencyCode =>
      _cashFlow?.currency ??
      _currency ??
      context.read<AccountsProvider>().familyCurrency ??
      'PKR';

  ({double income, double spending}) get _totals {
    final flow = _cashFlow;
    if (flow != null) return (income: flow.income, spending: flow.spending);
    var income = 0.0, spending = 0.0;
    for (final t in _transactions.where((t) => !t.isTransfer)) {
      if (t.isIncome) {
        income += t.absAmount;
      } else {
        spending += t.absAmount;
      }
    }
    return (income: income, spending: spending);
  }

  List<_LabelSpend> _byLabel(AppLocalizations l) {
    final colors = {
      for (final c in context.watch<CategoriesProvider>().categories)
        c.id: c.color,
    };
    final groups = <String?, _LabelSpend>{};
    for (final t in _transactions) {
      if (t.isTransfer || !t.isExpense) continue;
      final key = t.categoryId;
      final group = groups.putIfAbsent(
        key,
        () => _LabelSpend(
          key,
          t.categoryName ?? l.homeNoLabel,
          t.categoryColor ?? colors[key],
        ),
      );
      group.amount += t.absAmount;
    }
    return groups.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
  }

  void _openSettings() {
    final l = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final route = MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(l.homeSettings)),
        body: const SettingsScreen(),
      ),
    );
    // Settings used to be a tab; as a pushed route it must close itself on
    // sign-out so the login screen underneath is not hidden.
    void closeOnSignOut() {
      if (!auth.isAuthenticated && route.isActive) {
        navigator.popUntil((r) => r.isFirst);
      }
    }

    auth.addListener(closeOnSignOut);
    navigator
        .push(route)
        .whenComplete(() => auth.removeListener(closeOnSignOut));
  }

  Future<void> _openStatements() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const StatementsScreen()),
    );
    if (mounted) reload();
  }

  Future<void> _openReview() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatementReviewScreen(
          startDate: _month,
          endDate: DateTime(_month.year, _month.month + 1, 0),
        ),
      ),
    );
    if (mounted) reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = LedgerColors.of(context);
    final monthLong = DateFormat('MMMM', 'en_US').format(_month);
    final prevMonth = DateFormat('MMMM', 'en_US')
        .format(DateTime(_month.year, _month.month - 1));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ConnectivityBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _header(l, c),
                    const SizedBox(height: 28),
                    if (_noAccounts(context)) ...[
                      NoAccountsPrompt(onCreated: (_) => reload()),
                      const SizedBox(height: 28),
                    ],
                    if (_loading && _cashFlow == null && _transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _errorBox(l, c)
                    else
                      ..._body(l, c, monthLong, prevMonth),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// True once accounts have loaded and there are none.
  bool _noAccounts(BuildContext context) {
    final accounts = context.watch<AccountsProvider>();
    return !accounts.isInitializing &&
        !accounts.isLoading &&
        accounts.errorMessage == null &&
        accounts.accounts.isEmpty;
  }

  Widget _header(AppLocalizations l, LedgerColors c) {
    return Row(
      children: [
        Text(
          l.appTitle,
          style: LedgerText.display(
            size: 26,
            weight: FontWeight.w700,
            color: c.ink,
            letterSpacing: -0.8,
          ),
        ),
        const Spacer(),
        MonthSwitcher(month: _month, onChanged: _changeMonth),
        const SizedBox(width: 4),
        IconButton(
          tooltip: l.homeSettings,
          onPressed: _openSettings,
          icon: Icon(Icons.settings_outlined, color: c.ink),
        ),
      ],
    );
  }

  Widget _errorBox(AppLocalizations l, LedgerColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: c.ink)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.homeLoadFailed, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: reload, child: Text(l.commonTryAgain)),
        ],
      ),
    );
  }

  List<Widget> _body(
    AppLocalizations l,
    LedgerColors c,
    String monthLong,
    String prevMonth,
  ) {
    final currency = _currencyCode;
    final totals = _totals;
    final left = totals.income - totals.spending;
    final delta = _cashFlow?.spendingDelta;
    String? compare;
    if (delta != null) {
      final amount = MoneyFormat.format(delta.abs(), currency: currency);
      compare = delta > 0
          ? l.homeMoreThan(amount, prevMonth)
          : delta < 0
              ? l.homeLessThan(amount, prevMonth)
              : l.homeSameAs(prevMonth);
    }
    final labels = _byLabel(l);
    final maxLabel = labels.isEmpty ? 0.0 : labels.first.amount;
    final outShare = totals.income <= 0
        ? (totals.spending > 0 ? 1.0 : 0.0)
        : (totals.spending / totals.income).clamp(0.0, 1.0);
    final sorted = _transactions
        .where((t) => !t.isTransfer && t.categoryId != null)
        .length;

    return [
      // Spent this month.
      Text(l.homeSpentIn(monthLong),
          style: TextStyle(fontSize: 14, color: c.muted)),
      const SizedBox(height: 6),
      HeadlineAmount(totals.spending, currency: currency),
      if (compare != null) ...[
        const SizedBox(height: 6),
        Text(compare, style: TextStyle(fontSize: 14, color: c.muted)),
      ],
      const SizedBox(height: 28),

      // In / out / left over.
      Container(
        padding: const EdgeInsets.only(top: 12),
        decoration:
            BoxDecoration(border: Border(top: BorderSide(color: c.ink))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _figure(l.homeCameIn, totals.income, currency, c.moneyIn, c),
            const SizedBox(width: 12),
            _figure(l.homeWentOut, totals.spending, currency, c.moneyOut, c),
            const SizedBox(width: 12),
            _figure(l.homeLeftOver, left, currency, c.ink, c),
          ],
        ),
      ),
      const SizedBox(height: 12),
      ExcludeSemantics(
        child: SizedBox(
          height: 14,
          child: Row(
            children: [
              if (outShare > 0)
                Expanded(
                  flex: (outShare * 1000).round(),
                  child: ColoredBox(color: c.moneyOut),
                ),
              if (outShare > 0 && outShare < 1) const SizedBox(width: 2),
              if (outShare < 1)
                Expanded(
                  flex: ((1 - outShare) * 1000).round(),
                  child: ColoredBox(color: c.ink),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 28),

      if (_unlabelled > 0) ...[
        _reviewBanner(l, c, sorted),
        const SizedBox(height: 4),
      ],
      _statementsLink(l, c),
      _reportLink(l, c),
      const SizedBox(height: 28),

      // Where it went.
      LedgerSectionHeader(
        title: l.homeWhereItWent,
        actionLabel: l.homeBudget,
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const BudgetsScreen()),
        ),
      ),
      if (labels.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(l.homeNothingSpent,
              style: TextStyle(fontSize: 15, color: c.muted)),
        )
      else
        for (final label in labels) _labelRow(label, maxLabel, currency, c),
      const SizedBox(height: 28),

      if (_insights.isNotEmpty) ...[
        LedgerSectionHeader(title: l.homeNotesForYou),
        for (final insight in _insights) _insightRow(insight, l, c),
        const SizedBox(height: 28),
      ],

      // Net worth.
      LedgerSectionHeader(
        title: l.homeNetWorth,
        actionLabel: l.homeBalanceSheet,
        onAction: widget.onOpenAccounts,
      ),
      InkWell(
        onTap: widget.onOpenAccounts,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _netWorth == null
                  ? Text('—', style: LedgerText.figures(size: 22))
                  : RupeeAmount(_netWorth!,
                      currency: currency, size: 22, weight: FontWeight.w500),
              if (_assets != null && _liabilities != null) ...[
                const SizedBox(height: 4),
                Text(
                  l.homeAssetsOwed(
                    MoneyFormat.format(_assets!, currency: currency),
                    MoneyFormat.format(_liabilities!, currency: currency),
                  ),
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  Widget _figure(
    String label,
    double value,
    String currency,
    Color color,
    LedgerColors c,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: c.muted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RupeeAmount(value, currency: currency, color: color),
          ),
        ],
      ),
    );
  }

  Widget _statementsLink(AppLocalizations l, LedgerColors c) => _linkRow(
        key: const ValueKey('home-statements'),
        icon: Icons.description_outlined,
        title: l.navStatements,
        hint: l.homeStatementsHint,
        onTap: _openStatements,
        c: c,
      );

  Widget _reportLink(AppLocalizations l, LedgerColors c) => _linkRow(
        key: const ValueKey('home-report'),
        icon: Icons.picture_as_pdf_outlined,
        title: l.reportTitle,
        hint: l.reportHint,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReportExportScreen(month: _month),
          ),
        ),
        c: c,
      );

  Widget _linkRow({
    required Key key,
    required IconData icon,
    required String title,
    required String hint,
    required VoidCallback onTap,
    required LedgerColors c,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.hairline)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.muted),
            const SizedBox(width: 8),
            Text(title, style: LedgerText.body(size: 15, color: c.ink)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LedgerText.body(size: 13, color: c.muted),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: c.muted),
          ],
        ),
      ),
    );
  }

  Widget _insightRow(Insight insight, AppLocalizations l, LedgerColors c) {
    final ask = widget.onAskAssistant;
    return InkWell(
      onTap: ask == null ? null : () => ask(l.homeInsightAsk(insight.title)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
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
                  Text(insight.title,
                      style: LedgerText.body(
                          color: c.ink, weight: FontWeight.w600)),
                  if (insight.body.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      insight.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: LedgerText.body(size: 14, color: c.muted),
                    ),
                  ],
                ],
              ),
            ),
            if (ask != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: c.muted),
            ],
          ],
        ),
      ),
    );
  }

  Widget _reviewBanner(AppLocalizations l, LedgerColors c, int sorted) {
    final month = DateFormat('MMM yyyy', 'en_US').format(_month);
    return Material(
      color: c.ink,
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        onTap: _openReview,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.homeNeedLabel(_unlabelled),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.onInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.homeNeedLabelDetail(month, sorted),
                      style: TextStyle(
                        fontSize: 13,
                        color: c.onInk.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.onInk),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelRow(
    _LabelSpend label,
    double max,
    String currency,
    LedgerColors c,
  ) {
    final color =
        label.categoryId == null ? null : parseHexColor(label.color, c.ink);
    final fraction = max <= 0 ? 0.0 : label.amount / max;
    return InkWell(
      onTap: widget.onOpenActivity == null
          ? null
          : () => widget.onOpenActivity!(
                _month,
                label.categoryId ?? TransactionsFilter.noLabel,
              ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.hairline)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                LabelDot(color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label.name,
                      style: TextStyle(fontSize: 16, color: c.ink)),
                ),
                RupeeAmount(label.amount, currency: currency),
              ],
            ),
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: Container(
                height: 3,
                color: c.track,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(color: color ?? c.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
