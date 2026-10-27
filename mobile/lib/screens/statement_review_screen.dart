import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
        _error = 'Please sign in again.';
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
        setState(() => _error = 'Could not load the statement lines.');
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

    final result = await _transactions.updateTransaction(
      accessToken: token,
      transactionId: item.id!,
      categoryId: labelId,
    );
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() => _saving = false);
      _toast(result['error']?.toString() ?? 'Could not save the label.');
      return;
    }

    final keyword = _keywordController.text.trim();
    if (_labelAll && keyword.isNotEmpty) {
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
        _toast('Labelled this one. The keyword was not saved: '
            '${rule['error'] ?? 'unknown error'}');
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
    final item = _item;
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(
          children: [
            _header(c),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && item == null
                      ? _message(c, _error!)
                      : item == null
                          ? _message(
                              c,
                              _handled == 0
                                  ? 'Nothing to label. Every line has a label.'
                                  : 'All done. Every line has a label.',
                            )
                          : _itemView(c, item),
            ),
            if (!_loading && item != null) _footer(c),
          ],
        ),
      ),
    );
  }

  Widget _header(LedgerColors c) {
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
                child: Text('Done for now',
                    style: LedgerText.body(color: c.moneyIn)),
              ),
              const Spacer(),
              if (_item != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('$pos of $total',
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

  Widget _message(LedgerColors c, String text) => Center(
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
                label: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      );

  Widget _itemView(LedgerColors c, Transaction item) {
    final date = DateTime.tryParse(item.date);
    final dateText =
        date == null ? item.date : DateFormat('EEE d MMM', 'en').format(date);
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
        Text(moneyIn ? 'Where did this come from?' : 'What was this?',
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
              ],
            );
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _newLabel,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
            ),
            child: Text('+ Make a new label',
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

  Widget _footer(LedgerColors c) {
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
                          ? TextSpan(children: [
                              const TextSpan(text: 'Label all '),
                              TextSpan(
                                text: '$similar',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const TextSpan(text: ' like this'),
                            ])
                          : const TextSpan(
                              text: 'Auto-label future lines like this'),
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
                  Text('Lines containing',
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
                  label: 'Skip',
                  height: 52,
                  onPressed:
                      _saving ? null : () => _advance(removeCurrent: false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: InkButton(
                  label: 'Save & next',
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
