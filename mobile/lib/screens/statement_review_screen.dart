import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/rule.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../services/accounts_service.dart';
import '../services/categories_service.dart';
import '../services/rules_service.dart';
import '../services/transactions_service.dart';
import '../theme/sure_tokens.dart';
import '../utils/amount_parser.dart';
import '../utils/money_format.dart';
import '../widgets/ledger/ledger.dart';
import 'labels_screen.dart';

/// Label imported statement lines one at a time, newest first.
class StatementReviewScreen extends StatefulWidget {
  const StatementReviewScreen({
    super.key,
    this.accountId,
    this.startDate,
    this.endDate,
  });

  /// Optional filters; with none, every unlabelled line is reviewed.
  final String? accountId;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  State<StatementReviewScreen> createState() => _StatementReviewScreenState();
}

class _StatementReviewScreenState extends State<StatementReviewScreen> {
  static const _pageSize = 50;

  final _transactions = TransactionsService();
  final _rules = RulesService();
  final _keywordController = TextEditingController();

  List<Category> _labels = const [];
  Map<String, String> _accountNames = const {};
  final List<Transaction> _queue = [];
  int _index = 0;
  int _handled = 0;
  int _total = 0;
  bool _hasMore = true;

  /// Lines skipped or labelled here; never re-queued (rules may relabel
  /// in the background, so the server can still list them for a while).
  final Set<String> _seen = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? _pickedId;

  // Pseudo-label: marks the line excluded (e.g. ATM cash, own-account moves)
  // instead of giving it a category.
  static const _notExpenseId = '__not_an_expense__';
  bool _labelAll = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<String?> _token() =>
      context.read<AuthProvider>().getValidAccessToken();

  Transaction? get _item => _index < _queue.length ? _queue[_index] : null;

  static String? _day(DateTime? d) =>
      d == null ? null : DateFormat('yyyy-MM-dd').format(d);

  Future<void> _load() async {
    final token = await _token();
    if (!mounted) return;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).commonSignInAgain;
      });
      return;
    }
    final results = await Future.wait([
      CategoriesService().getCategories(accessToken: token, perPage: 100),
      AccountsService().getAccounts(accessToken: token, perPage: 100),
    ]);
    if (!mounted) return;
    final cats = results[0];
    final accounts = results[1];
    setState(() {
      if (cats['success'] == true) {
        _labels = (cats['categories'] as List).cast<Category>();
      }
      if (accounts['success'] == true) {
        _accountNames = {
          for (final a in (accounts['accounts'] as List).cast<Account>())
            a.id: a.name,
        };
      }
    });
    await _fetchMore(token);
    if (!mounted) return;
    setState(() => _loading = false);
    _prepareItem();
  }

  /// Adds unseen unlabelled lines to the queue. Labelling shrinks the
  /// server's result set, so page numbers shift; scan from page 1 and skip
  /// lines already queued or skipped.
  Future<void> _fetchMore(String token) async {
    for (var page = 1; page <= 10; page++) {
      final result = await _transactions.getTransactions(
        accessToken: token,
        accountId: widget.accountId,
        startDate: _day(widget.startDate),
        endDate: _day(widget.endDate),
        page: page,
        perPage: _pageSize,
        uncategorized: true,
      );
      if (!mounted) return;
      if (result['success'] != true) {
        setState(() =>
            _error = AppLocalizations.of(context).statementReviewLoadFailed);
        return;
      }
      final rows = (result['transactions'] as List).cast<Transaction>();
      final known = {..._queue.map((t) => t.id), ..._seen};
      final fresh = rows.where((t) => !known.contains(t.id)).toList();
      final pagination = result['pagination'];
      setState(() {
        _queue.addAll(fresh);
        _hasMore = rows.length == _pageSize;
        if (_total == 0) {
          _total = pagination is Map && pagination['total_count'] is num
              ? (pagination['total_count'] as num).toInt()
              : rows.length;
        }
      });
      if (fresh.isNotEmpty || !_hasMore) return;
    }
  }

  /// Resets the per-item controls and proposes a keyword for the new item.
  void _prepareItem() {
    final item = _item;
    _pickedId = null;
    if (item == null) {
      _keywordController.text = '';
      return;
    }
    final others = _queue.where((t) => t.id != item.id).map((t) => t.name);
    _keywordController.text = KeywordSuggester.suggest(item.name, others);
    _labelAll = _similarCount > 0;
  }

  /// Other loaded lines the keyword would also label.
  int get _similarCount {
    final item = _item;
    final keyword = _keywordController.text;
    if (item == null || keyword.trim().isEmpty) return 0;
    return _ahead(keyword).length;
  }

  /// Lines after the current one that [keyword] would label.
  List<Transaction> _ahead(String keyword) => _queue
      .skip(_index + 1)
      .where((t) => KeywordSuggester.matches(t.name, keyword))
      .toList();

  Future<void> _advance({required bool removeCurrent}) async {
    setState(() {
      if (removeCurrent) {
        final id = _queue.removeAt(_index).id;
        if (id != null) _seen.add(id);
      } else {
        final id = _queue[_index].id;
        if (id != null) _seen.add(id);
        _index++;
      }
      _handled++;
    });
    if (_queue.length - _index < 5 && _hasMore) {
      final token = await _token();
      if (token != null) await _fetchMore(token);
    }
    if (!mounted) return;
    setState(_prepareItem);
  }

  Future<void> _save() async {
    final item = _item;
    final labelId = _pickedId;
    if (item == null || labelId == null || item.id == null) return;
    final token = await _token();
    if (token == null || !mounted) return;
    setState(() => _saving = true);

    final notExpense = labelId == _notExpenseId;
    final result = await _transactions.updateTransaction(
      accessToken: token,
      transactionId: item.id!,
      categoryId: notExpense ? null : labelId,
      excluded: notExpense ? true : null,
    );
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() => _saving = false);
      _toast(result['error']?.toString() ??
          AppLocalizations.of(context).labelsSaveFailed);
      return;
    }

    final keyword = _keywordController.text.trim();
    if (_labelAll && keyword.isNotEmpty && !notExpense) {
      final rule = await _rules.createRule(
        accessToken: token,
        keyword: keyword,
        categoryId: labelId,
      );
      if (!mounted) return;
      if (rule['success'] == true) {
        // The server relabels the matching lines; drop them from the queue.
        final matched = _ahead(keyword);
        setState(() {
          for (final t in matched) {
            _queue.remove(t);
            if (t.id != null) _seen.add(t.id!);
          }
          _handled += matched.length;
        });
      } else {
        final l = AppLocalizations.of(context);
        _toast(l.statementReviewKeywordFailed(
            '${rule['error'] ?? l.statementReviewUnknownError}'));
      }
    }
    setState(() => _saving = false);
    await _advance(removeCurrent: true);
  }

  Future<void> _newLabel() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LabelsScreen()));
    final token = await _token();
    if (token == null || !mounted) return;
    final cats = await CategoriesService()
        .getCategories(accessToken: token, perPage: 100);
    if (!mounted || cats['success'] != true) return;
    setState(() => _labels = (cats['categories'] as List).cast<Category>());
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final item = _item;
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(
          children: [
            _header(c, l),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && item == null
                      ? _message(c, l, _error!)
                      : item == null
                          ? _message(
                              c,
                              l,
                              _handled == 0
                                  ? l.statementReviewNothingToLabel
                                  : l.statementReviewAllDone,
                            )
                          : _itemView(c, l, item),
            ),
            if (!_loading && item != null) _footer(c, l),
          ],
        ),
      ),
    );
  }

  Widget _header(LedgerColors c, AppLocalizations l) {
    final total = _total < _handled + _queue.length - _index
        ? _handled + _queue.length - _index
        : _total;
    final pos = (_handled + 1).clamp(1, total == 0 ? 1 : total);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                child: Text(l.statementReviewDoneForNow,
                    style: LedgerText.body(color: c.moneyIn)),
              ),
              const Spacer(),
              if (_item != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(l.statementReviewPosition(pos, total),
                      style: LedgerText.figures(size: 14, color: c.ink)),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: total == 0 ? 1 : (_handled / total).clamp(0.0, 1.0),
                color: c.ink,
                backgroundColor: c.hairline,
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(LedgerColors c, AppLocalizations l, String text) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text,
                  textAlign: TextAlign.center,
                  style: LedgerText.display(color: c.ink)),
              const SizedBox(height: 20),
              OutlineInkButton(
                label: l.commonBack,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      );

  Widget _itemView(LedgerColors c, AppLocalizations l, Transaction item) {
    final date = DateTime.tryParse(item.date);
    final dateText = date == null
        ? item.date
        : DateFormat('EEE d MMM', l.localeName).format(date);
    final account = _accountNames[item.accountId];
    double amount = 0;
    try {
      amount = AmountParser.parse(item.amount).value.abs();
    } on FormatException {
      amount = 0;
    }
    final moneyIn = item.nature == 'income';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LedgerPanel(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(account == null ? dateText : '$dateText · $account',
                  style: LedgerText.body(size: 13, color: c.muted)),
              const SizedBox(height: 10),
              Text.rich(
                // "+ Rs 1,200" reads left-to-right in every language.
                textDirection: TextDirection.ltr,
                TextSpan(children: [
                  TextSpan(
                    text: moneyIn ? '+ Rs ' : 'Rs ',
                    style: LedgerText.display(
                        size: 20,
                        letterSpacing: -0.700,
                        height: 1,
                        color: c.muted),
                  ),
                  TextSpan(
                    text: MoneyFormat.number(amount),
                    style: LedgerText.display(
                        size: 40,
                        letterSpacing: -1.400,
                        height: 1,
                        color: moneyIn ? c.moneyIn : c.ink),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: c.track,
                child: Text(item.name,
                    style: LedgerText.figures(size: 14, color: c.ink)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
            moneyIn
                ? l.statementReviewWhereFrom
                : l.statementReviewWhatWasThis,
            style: LedgerText.body(
                size: 15, weight: FontWeight.w500, color: c.ink)),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in _labels)
                  SizedBox(width: width, child: _labelButton(c, label)),
                SizedBox(
                  width: width,
                  child: _labelButton(
                    c,
                    Category(
                        id: _notExpenseId, name: l.statementReviewNotExpense),
                  ),
                ),
              ],
            );
          },
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: _newLabel,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
            ),
            child: Text(l.statementReviewNewLabel,
                style: LedgerText.body(size: 15, color: c.moneyIn)),
          ),
        ),
      ],
    );
  }

  Widget _labelButton(LedgerColors c, Category label) {
    final on = label.id == _pickedId;
    final dot = parseHexColor(label.color, c.muted);
    return Semantics(
      selected: on,
      button: true,
      child: InkWell(
        onTap: () => setState(() => _pickedId = label.id),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: on ? c.ink : Colors.transparent,
            border: Border.all(color: c.ink),
            borderRadius: BorderRadius.circular(SureTokens.radiusMd),
          ),
          child: Row(
            children: [
              LabelDot(color: on ? c.paper : dot),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LedgerText.body(size: 15, color: on ? c.onInk : c.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// [text] with the first occurrence of [count] in bold.
  static TextSpan _boldCount(String text, String count) {
    final i = text.indexOf(count);
    if (i < 0) return TextSpan(text: text);
    return TextSpan(children: [
      TextSpan(text: text.substring(0, i)),
      TextSpan(
        text: count,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      TextSpan(text: text.substring(i + count.length)),
    ]);
  }

  Widget _footer(LedgerColors c, AppLocalizations l) {
    final similar = _similarCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: c.sheet,
        border: Border(top: BorderSide(color: c.ink)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _labelAll = !_labelAll),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Checkbox(
                    value: _labelAll,
                    activeColor: c.ink,
                    onChanged: (v) => setState(() => _labelAll = v ?? false),
                  ),
                  Expanded(
                    child: Text.rich(
                      similar > 0
                          ? _boldCount(
                              l.statementReviewLabelAllSimilar(similar),
                              '$similar')
                          : TextSpan(text: l.statementReviewAutoLabelFuture),
                      style: LedgerText.body(size: 15, color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_labelAll)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(l.statementReviewLinesContaining,
                      style: LedgerText.body(size: 13, color: c.muted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _keywordController,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.characters,
                      style: LedgerText.figures(size: 14, color: c.ink),
                      decoration: ledgerInputDecoration(context).copyWith(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlineInkButton(
                  label: l.statementReviewSkip,
                  height: 52,
                  onPressed:
                      _saving ? null : () => _advance(removeCurrent: false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: InkButton(
                  label: l.statementReviewSaveNext,
                  height: 52,
                  busy: _saving,
                  onPressed: _pickedId == null ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
