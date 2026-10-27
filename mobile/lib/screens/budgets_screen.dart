import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/budget.dart';
import '../providers/auth_provider.dart';
import '../providers/budgets_provider.dart';
import '../providers/privacy_provider.dart';
import '../services/connectivity_service.dart';
import '../utils/money_masker.dart';
import '../utils/money_format.dart';
import '../widgets/ledger/ledger.dart';
import 'budget_category_transactions_screen.dart';

/// Monthly budget in the ledger style: month switcher, spent of planned with
/// a today marker, then one row per label with its progress; over-budget in
/// amber. Tapping a row opens its transactions. Limits are edited on web.
class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key, this.provider, this.accessTokenLoader});

  /// Injected for tests; otherwise the screen owns its provider.
  final BudgetsProvider? provider;

  /// Injected for tests; defaults to [AuthProvider.getValidAccessToken].
  final Future<String?> Function()? accessTokenLoader;

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late final BudgetsProvider _provider;
  late final bool _ownsProvider;

  @override
  void initState() {
    super.initState();
    _ownsProvider = widget.provider == null;
    _provider = widget.provider ??
        BudgetsProvider(
          isOffline: () {
            if (!mounted) return false;
            try {
              return context.read<ConnectivityService>().isOffline;
            } on ProviderNotFoundException {
              return false;
            }
          },
        );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    if (_ownsProvider) _provider.dispose();
    super.dispose();
  }

  Future<String?> _accessToken() {
    final loader = widget.accessTokenLoader;
    if (loader != null) return loader();
    return context.read<AuthProvider>().getValidAccessToken();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final token = await _accessToken();
    if (!mounted) return;
    if (token == null) {
      _provider.markUnauthorized();
      return;
    }
    await _provider.loadMonth(accessToken: token, forceRefresh: forceRefresh);
  }

  void _changeMonth(VoidCallback change) {
    change();
    _load();
  }

  Future<void> _selectBudget(String budgetId) async {
    final token = await _accessToken();
    if (!mounted) return;
    if (token == null) {
      _provider.markUnauthorized();
      return;
    }
    await _provider.selectBudget(accessToken: token, budgetId: budgetId);
  }

  void _openCategory(Budget budget, BudgetCategory bc, List<String> ids) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetCategoryTransactionsScreen(
          title: bc.name,
          periodLabel: _periodLabel(context, budget.startDate, budget),
          categoryIds: ids,
          startDate: budget.startDate,
          endDate: budget.endDate,
          accessTokenLoader: widget.accessTokenLoader,
        ),
      ),
    );
  }

  static String _periodLabel(BuildContext context, DateTime month, Budget? b) {
    // The server name covers families with a custom month start
    // ("Oct 15 - Nov 14, 2026"); otherwise format the month locally.
    if (b != null && b.name.isNotEmpty) return b.name;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMM(locale).format(month);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BudgetsProvider>.value(
      value: _provider,
      child: Consumer<BudgetsProvider>(
        builder: (context, provider, _) => _buildScaffold(context, provider),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, BudgetsProvider provider) {
    final c = LedgerColors.of(context);
    final hideAmounts = context.watch<PrivacyProvider>().hidden;

    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(
          children: [
            if (Navigator.of(context).canPop()) const LedgerBackHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(forceRefresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    _buildTitleRow(context, provider),
                    const SizedBox(height: 24),
                    ..._buildBody(context, provider, hideAmounts),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, BudgetsProvider provider) {
    final c = LedgerColors.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Row(
      children: [
        Expanded(child: Text('Budget', style: LedgerText.title(color: c.ink))),
        MonthSwitcher(
          month: provider.month,
          label: DateFormat.yMMM(locale).format(provider.month),
          canGoNext: provider.canGoNext,
          onChanged: (m) => _changeMonth(m.isBefore(provider.month)
              ? provider.previousMonth
              : provider.nextMonth),
        ),
      ],
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    BudgetsProvider provider,
    bool hideAmounts,
  ) {
    final l = AppLocalizations.of(context);

    if (provider.isLoading && !provider.hasLoadedMonth) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 64),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    // A failed refresh keeps the month already loaded on screen (with a
    // banner); only a month never loaded gets the full-screen error.
    switch (provider.refreshFailed ? null : provider.error) {
      case BudgetsLoadError.offline:
        return [
          _message(context,
              title: l.budgetsOfflineTitle,
              body: l.budgetsOfflineMessage,
              onRetry: () => _load(forceRefresh: true)),
        ];
      case BudgetsLoadError.unauthorized:
        return [
          _message(context,
              title: l.budgetsLoadFailed, body: l.budgetsSessionExpired),
        ];
      case BudgetsLoadError.failed:
        return [
          _message(context,
              title: l.budgetsLoadFailed,
              onRetry: () => _load(forceRefresh: true)),
        ];
      case null:
        break;
    }

    if (!provider.hasLoadedMonth) return const [];

    final budget = provider.budget;
    if (budget == null) {
      final locale = Localizations.localeOf(context).toString();
      return [
        _message(
          context,
          title: l.budgetsNoBudgetTitle(
            DateFormat.yMMMM(locale).format(provider.month),
          ),
          body: l.budgetsNoBudgetMessage,
        ),
      ];
    }

    final c = LedgerColors.of(context);
    final widgets = <Widget>[];

    void notice(String text, {VoidCallback? onRetry}) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child:
                  Text(text, style: LedgerText.body(size: 13, color: c.muted)),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(l.commonTryAgain)),
          ],
        ),
      ));
    }

    if (provider.showingCachedWhileOffline) notice(l.budgetsOfflineCached);
    if (provider.refreshFailed) {
      notice(l.budgetsRefreshFailed, onRetry: () => _load(forceRefresh: true));
    }

    if (provider.monthBudgets.length > 1) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < provider.monthBudgets.length; i++)
              ChoiceChip(
                label: Text(l.budgetsBudgetNumber(i + 1)),
                selected: provider.monthBudgets[i].id == budget.id,
                shape: const RoundedRectangleBorder(),
                onSelected: (_) => _selectBudget(provider.monthBudgets[i].id),
              ),
          ],
        ),
      ));
    }

    if (provider.isLoading) {
      widgets.add(LinearProgressIndicator(
          minHeight: 2, color: c.ink, backgroundColor: c.hairline));
      widgets.add(const SizedBox(height: 8));
    }

    widgets.add(_Summary(budget: budget, hidden: hideAmounts));

    if (!budget.initialized) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(Text(l.budgetsNotSetUpMessage,
          style: LedgerText.body(size: 14, color: c.muted)));
    }

    widgets.add(const SizedBox(height: 24));
    widgets.addAll(_buildRows(context, provider, budget, hideAmounts));
    return widgets;
  }

  List<Widget> _buildRows(
    BuildContext context,
    BudgetsProvider provider,
    Budget budget,
    bool hideAmounts,
  ) {
    final rows = <Widget>[];
    for (final group in provider.visibleGroups) {
      // Like the web, a parent that isn't itself visible only exists as the
      // container of its visible subcategories: no row, no indent.
      final showParent = provider.showsAllCategories || group.parent.isVisible;
      if (showParent) {
        rows.add(_BudgetLine(
          key: ValueKey('budget-category-${group.parent.id}'),
          line: group.parent,
          currency: budget.currency,
          hidden: hideAmounts,
          onTap: () => _openCategory(budget, group.parent, group.categoryIds),
        ));
      }
      for (final child in group.children) {
        rows.add(_BudgetLine(
          key: ValueKey('budget-category-${child.id}'),
          line: child,
          currency: budget.currency,
          hidden: hideAmounts,
          indented: showParent,
          onTap: () => _openCategory(budget, child, [child.category.id]),
        ));
      }
    }
    if (rows.isEmpty) {
      final c = LedgerColors.of(context);
      return [
        Text(AppLocalizations.of(context).budgetsNoCategories,
            style: LedgerText.body(color: c.muted)),
      ];
    }
    return rows;
  }

  Widget _message(
    BuildContext context, {
    required String title,
    String? body,
    VoidCallback? onRetry,
  }) {
    final c = LedgerColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LedgerSectionHeader(title: title),
          if (body != null && body.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(body, style: LedgerText.body(size: 15, color: c.muted)),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlineInkButton(
              label: AppLocalizations.of(context).commonTryAgain,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

String _money(int cents, String currency, bool hidden) =>
    MoneyMasker.mask(MoneyFormat.format(cents / 100, currency: currency),
        hidden: hidden);

/// "Spent of Rs 200,000 planned", big spent figure, bar with today marker.
class _Summary extends StatelessWidget {
  const _Summary({required this.budget, required this.hidden});

  final Budget budget;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final planned =
        budget.budgetedSpendingCents ?? budget.allocatedSpendingCents ?? 0;
    final spent = budget.actualSpendingCents ?? 0;
    final left = budget.availableToSpendCents ?? (planned - spent);
    final currency = budget.currency;

    final today = DateUtils.dateOnly(DateTime.now());
    final start = DateUtils.dateOnly(budget.startDate);
    final end = DateUtils.dateOnly(budget.endDate);
    final days = end.difference(start).inDays + 1;
    final inPeriod = !today.isBefore(start) && !today.isAfter(end);
    final day = today.difference(start).inDays + 1;
    final daysLeft = days - day;

    final String note;
    if (left < 0) {
      note = 'Over by ${_money(-left, currency, hidden)}.';
    } else if (inPeriod) {
      note = '${_money(left, currency, hidden)} left for the last '
          '$daysLeft ${daysLeft == 1 ? 'day' : 'days'}. Blue line is today.';
    } else {
      note = '${_money(left, currency, hidden)} left.';
    }

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.ink)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  planned > 0
                      ? 'Spent of ${_money(planned, currency, hidden)} planned'
                      : 'Spent',
                  style: LedgerText.body(size: 14, color: c.muted),
                ),
              ),
              if (inPeriod)
                Text('day $day of $days',
                    style: LedgerText.figures(size: 13, color: c.muted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_money(spent, currency, hidden),
              style: LedgerText.figures(
                  size: 30, weight: FontWeight.w500, color: c.ink)),
          const SizedBox(height: 8),
          if (!hidden)
            SizedBox(
              height: 24,
              child: LayoutBuilder(builder: (context, box) {
                final share =
                    planned <= 0 ? 0.0 : (spent / planned).clamp(0.0, 1.0);
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 5,
                      height: 14,
                      child: ColoredBox(color: c.hairline),
                    ),
                    Positioned(
                      left: 0,
                      top: 5,
                      height: 14,
                      width: box.maxWidth * share,
                      child: ColoredBox(color: left < 0 ? c.moneyOut : c.ink),
                    ),
                    if (inPeriod)
                      Positioned(
                        left: (box.maxWidth * day / days) - 1,
                        top: 0,
                        bottom: 0,
                        width: 2,
                        child: ColoredBox(color: c.moneyIn),
                      ),
                  ],
                );
              }),
            ),
          const SizedBox(height: 8),
          Text(
            note,
            style: LedgerText.body(
                size: 14,
                weight: left < 0 ? FontWeight.w600 : FontWeight.w400,
                color: left < 0 ? c.moneyOut : c.muted),
          ),
        ],
      ),
    );
  }
}

/// One label row: name and spent, progress, then "left"/"over" and limit.
class _BudgetLine extends StatelessWidget {
  const _BudgetLine({
    super.key,
    required this.line,
    required this.currency,
    required this.hidden,
    required this.onTap,
    this.indented = false,
  });

  final BudgetCategory line;
  final String currency;
  final bool hidden;
  final bool indented;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final spent = line.actualSpendingCents ?? 0;
    final limit = line.inheritsParentBudget
        ? (line.sharedBudgetCents ?? line.effectiveBudgetCents)
        : spent + (line.availableToSpendCents ?? 0);
    final over = line.isOverBudget;
    final dot = parseHexColor(line.category.color, c.muted);

    final String note;
    if (!line.isBudgeted) {
      note = 'No limit set';
    } else if (over) {
      note = 'Over by ${_money(spent - limit, currency, hidden)}';
    } else {
      note = '${_money(limit - spent, currency, hidden)} left';
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(indented ? 18 : 0, 14, 0, 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.hairline)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                LabelDot(color: dot),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(line.name,
                      style: LedgerText.body(
                          size: indented ? 15 : 16, color: c.ink)),
                ),
                Text(_money(spent, currency, hidden),
                    style: LedgerText.figures(size: 15, color: c.ink)),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 6,
              child: ColoredBox(
                color: c.track,
                child: hidden
                    ? null
                    : FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: line.isBudgeted
                            ? line.spentFraction.clamp(0.0, 1.0)
                            : (spent > 0 ? 1 : 0),
                        child: ColoredBox(color: over ? c.moneyOut : c.ink),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    note,
                    style: over
                        ? LedgerText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: c.moneyOut)
                        : LedgerText.body(size: 13, color: c.muted),
                  ),
                ),
                if (line.isBudgeted)
                  Text('of ${_money(limit, currency, hidden)}',
                      style: LedgerText.figures(size: 13, color: c.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
