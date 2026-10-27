import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/account.dart';
import '../models/offline_transaction.dart';
import '../models/transaction.dart';
import '../providers/accounts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/transactions_provider.dart';
import '../services/connectivity_service.dart';
import '../services/log_service.dart';
import '../services/transactions_service.dart';
import '../widgets/ledger/ledger.dart';
import 'transaction_edit_screen.dart';

/// Sentinel filter values shared by Home and Activity.
class TransactionsFilter {
  const TransactionsFilter._();

  /// Show only transactions without a label.
  static const String noLabel = '__no_label__';
}

/// A row in Activity: a server transaction or a local one waiting to sync.
class _Row {
  _Row(this.tx, {this.local});
  final Transaction tx;
  final OfflineTransaction? local;

  bool get pendingCreate =>
      local != null &&
      (local!.syncStatus == SyncStatus.pending ||
          local!.syncStatus == SyncStatus.failed);
  bool get pendingDelete => local?.syncStatus == SyncStatus.pendingDelete;
}

/// Activity: one month of transactions, searchable and filterable by label.
/// With [account], shows only that account's transactions.
class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key, this.account});

  final Account? account;

  @override
  State<TransactionsListScreen> createState() => TransactionsListScreenState();
}

class TransactionsListScreenState extends State<TransactionsListScreen> {
  final _service = TransactionsService();
  final _searchController = TextEditingController();
  final _log = LogService.instance;

  DateTime _month = MonthSwitcher.firstOf(DateTime.now());
  String? _filter; // null = All, a category id, or TransactionsFilter.noLabel
  bool _loading = true;
  bool _offline = false;
  String? _error;
  int _loadToken = 0;
  List<Transaction> _server = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Switch to [month] (and optionally a label filter), then load.
  void showMonth(DateTime month, {String? categoryId}) {
    setState(() {
      _month = MonthSwitcher.firstOf(month);
      _filter = categoryId;
      _searchController.clear();
    });
    reload();
  }

  Future<void> reload() async {
    final token = ++_loadToken;
    final auth = context.read<AuthProvider>();
    final provider = context.read<TransactionsProvider>();
    final categories = context.read<CategoriesProvider>();
    final connectivity = context.read<ConnectivityService?>();
    setState(() {
      _loading = true;
      _error = null;
    });

    final accessToken = await auth.getValidAccessToken();
    if (accessToken == null) {
      await auth.logout();
      return;
    }
    categories.fetchCategories(accessToken: accessToken);
    // Local cache: pending rows and the offline fallback.
    await provider.fetchTransactions(
      accessToken: accessToken,
      accountId: widget.account?.id,
    );

    final month = _month;
    final online = connectivity?.isOnline ?? true;
    if (!online) {
      if (mounted && token == _loadToken) {
        setState(() {
          _offline = true;
          _loading = false;
        });
      }
      return;
    }

    final result = await _service.getAllTransactions(
      accessToken: accessToken,
      accountId: widget.account?.id,
      startDate: DateFormat('yyyy-MM-dd').format(month),
      endDate: DateFormat('yyyy-MM-dd')
          .format(DateTime(month.year, month.month + 1, 0)),
    );
    if (!mounted || token != _loadToken) return;
    if (result['error'] == 'unauthorized') {
      await auth.logout();
      return;
    }
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _server = result['transactions'] as List<Transaction>;
        _offline = false;
      } else {
        _log.warning('Activity', 'Month fetch failed; showing cached rows');
        _offline = true;
        _error = result['error']?.toString();
      }
    });
  }

  bool _inMonth(String date) {
    final d = DateTime.tryParse(date);
    return d != null && d.year == _month.year && d.month == _month.month;
  }

  List<_Row> _rows(TransactionsProvider provider) {
    final local = provider.offlineTransactions.where((t) =>
        _inMonth(t.date) &&
        (widget.account == null || t.accountId == widget.account!.id));
    final byServerId = {
      for (final t in local)
        if (t.id != null) t.id!: t,
    };

    final rows = <_Row>[];
    if (_offline) {
      rows.addAll(local.map((t) => _Row(t, local: t)));
    } else {
      rows.addAll(_server.map((t) => _Row(t, local: byServerId[t.id])));
      rows.addAll(local
          .where((t) =>
              t.syncStatus == SyncStatus.pending ||
              t.syncStatus == SyncStatus.failed)
          .map((t) => _Row(t, local: t)));
    }
    rows.sort((a, b) => b.tx.date.compareTo(a.tx.date));
    return rows;
  }

  List<_Row> _applyFilters(List<_Row> rows) {
    final q = _searchController.text.trim().toLowerCase();
    return rows.where((r) {
      final t = r.tx;
      if (_filter == TransactionsFilter.noLabel) {
        if (t.categoryId != null || t.isTransfer) return false;
      } else if (_filter != null && t.categoryId != _filter) {
        return false;
      }
      if (q.isEmpty) return true;
      return t.name.toLowerCase().contains(q) ||
          (t.categoryName?.toLowerCase().contains(q) ?? false) ||
          (t.notes?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  double _signed(Transaction t) => t.isIncome ? t.absAmount : -t.absAmount;

  Future<void> _open(_Row row) async {
    if (row.pendingCreate || row.pendingDelete) {
      await _undo(row.local!);
      return;
    }
    if (row.tx.id == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionEditScreen(transaction: row.tx),
      ),
    );
    if (changed == true && mounted) reload();
  }

  Future<void> _undo(OfflineTransaction t) async {
    final l = AppLocalizations.of(context);
    final provider = context.read<TransactionsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final isPending = t.syncStatus != SyncStatus.pendingDelete;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.transactionsListUndoTitle),
        content: Text(isPending
            ? l.transactionsListUndoRemovePending
            : l.transactionsListUndoRestoreConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.commonUndo),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await provider.undoPendingTransaction(
      localId: t.localId,
      syncStatus: t.syncStatus,
    );
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? (isPending
              ? l.transactionsListUndoPendingRemoved
              : l.transactionsListUndoRestored)
          : l.transactionsListUndoFailed),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = LedgerColors.of(context);
    final provider = context.watch<TransactionsProvider>();
    final categories = context.watch<CategoriesProvider>().categories;
    final accountNames = {
      for (final a in context.watch<AccountsProvider>().accounts) a.id: a.name,
    };
    final currency = context.watch<AccountsProvider>().familyCurrency;
    final labelColors = {for (final cat in categories) cat.id: cat.color};

    final monthRows = _rows(provider);
    final rows = _applyFilters(monthRows);
    var moneyIn = 0.0, moneyOut = 0.0;
    for (final r in monthRows) {
      if (r.tx.isTransfer || r.pendingDelete) continue;
      if (r.tx.isIncome) {
        moneyIn += r.tx.absAmount;
      } else {
        moneyOut += r.tx.absAmount;
      }
    }

    // Group by day, newest first.
    final days = <String, List<_Row>>{};
    for (final r in rows) {
      days.putIfAbsent(r.tx.date, () => []).add(r);
    }

    final filters = <(String?, String, Color?)>[
      (null, l.commonAll, null),
      (TransactionsFilter.noLabel, l.activityNoLabel, null),
      for (final cat in categories)
        (cat.id, cat.name, parseHexColor(cat.color, c.ink)),
    ];

    final title = widget.account?.name ?? l.navActivity;

    return Scaffold(
      appBar: widget.account == null ? null : AppBar(),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: reload,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    20, widget.account == null ? 16 : 0, 20, 0),
                sliver: SliverList.list(children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LedgerText.title(color: c.ink),
                        ),
                      ),
                      MonthSwitcher(
                        month: _month,
                        onChanged: (m) => showMonth(m, categoryId: _filter),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l.activitySearchHint,
                      prefixIcon: Icon(Icons.search, color: c.muted),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l.activityClearSearch,
                              icon: const Icon(Icons.close),
                              onPressed: _searchController.clear,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final (id, name, color) = filters[i];
                      return LabelChip(
                        name: name,
                        color: color,
                        showDot: color != null,
                        selected: _filter == id,
                        onTap: () => setState(() => _filter = id),
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                sliver: SliverList.list(children: [
                  _strip(l, c, moneyIn, moneyOut, monthRows.length, currency),
                  if (_offline)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error == null
                            ? l.activityOfflineNote
                            : l.activityLoadFailedNote,
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_loading && rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        l.activityEmpty,
                        style: TextStyle(fontSize: 15, color: c.muted),
                      ),
                    )
                  else
                    for (final entry in days.entries) ...[
                      _dayHeader(entry.key, entry.value, c, currency),
                      for (final r in entry.value)
                        _row(r, l, c, accountNames, labelColors, currency),
                      const SizedBox(height: 20),
                    ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _strip(
    AppLocalizations l,
    LedgerColors c,
    double moneyIn,
    double moneyOut,
    int entries,
    String? currency,
  ) {
    Widget cell(String label, Widget value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: c.muted)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: value,
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.ink),
          bottom: BorderSide(color: c.hairline),
        ),
      ),
      child: Row(
        children: [
          cell(
              l.activityIn,
              RupeeAmount(moneyIn,
                  currency: currency, size: 15, color: c.moneyIn)),
          const SizedBox(width: 12),
          cell(
              l.activityOut,
              RupeeAmount(moneyOut,
                  currency: currency, size: 15, color: c.moneyOut)),
          const SizedBox(width: 12),
          cell(
            l.activityEntries,
            Text('$entries', style: LedgerText.figures(size: 15, color: c.ink)),
          ),
        ],
      ),
    );
  }

  Widget _dayHeader(
    String date,
    List<_Row> rows,
    LedgerColors c,
    String? currency,
  ) {
    final d = DateTime.tryParse(date);
    final label = d == null
        ? date
        : DateFormat('EEE d MMM', 'en_US').format(d).toUpperCase();
    final net = rows
        .where((r) => !r.tx.isTransfer && !r.pendingDelete)
        .fold<double>(0, (sum, r) => sum + _signed(r.tx));
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: c.ink))),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: c.muted,
              ),
            ),
          ),
          RupeeAmount(net,
              currency: currency, signed: true, size: 12, color: c.muted),
        ],
      ),
    );
  }

  Widget _row(
    _Row row,
    AppLocalizations l,
    LedgerColors c,
    Map<String, String> accountNames,
    Map<String, String?> labelColors,
    String? currency,
  ) {
    final t = row.tx;
    final hasLabel = t.categoryId != null;
    final source = row.pendingCreate
        ? l.activityWaitingToSync
        : row.pendingDelete
            ? l.activityWaitingToDelete
            : (t.accountName ?? accountNames[t.accountId] ?? '');
    final label = t.isTransfer
        ? l.activityTransfer
        : (t.categoryName ?? l.activityNoLabel);
    final amountColor =
        t.isTransfer ? c.muted : (t.isIncome ? c.moneyIn : c.ink);

    return Opacity(
      opacity: row.pendingDelete ? 0.5 : 1,
      child: InkWell(
        onTap: () => _open(row),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.hairline)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: c.ink),
                    ),
                  ),
                  if (t.hasAttachments) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.attach_file,
                        size: 14,
                        color: c.muted,
                        semanticLabel: l.activityHasReceipt),
                  ],
                  const Spacer(),
                  const SizedBox(width: 12),
                  RupeeAmount(
                    _signed(t),
                    currency: t.currency.isEmpty ? currency : t.currency,
                    signed: true,
                    color: amountColor,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  LabelDot(
                    size: 9,
                    color: hasLabel
                        ? parseHexColor(
                            t.categoryColor ?? labelColors[t.categoryId],
                            c.ink,
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: c.muted)),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: row.pendingCreate ? c.moneyOut : c.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
