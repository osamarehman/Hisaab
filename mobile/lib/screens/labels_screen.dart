import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/category.dart';
import '../models/rule.dart';
import '../providers/auth_provider.dart';
import '../services/categories_service.dart';
import '../services/rules_service.dart';
import '../services/transactions_service.dart';
import '../widgets/ledger/ledger.dart';

/// Labels (Sure categories) with their auto-label keywords (Sure rules).
class LabelsScreen extends StatefulWidget {
  const LabelsScreen({super.key});

  @override
  State<LabelsScreen> createState() => _LabelsScreenState();
}

class _LabelsScreenState extends State<LabelsScreen> {
  final _categories = CategoriesService();
  final _rules = RulesService();
  final _transactions = TransactionsService();

  final _nameController = TextEditingController();
  final _keywordsController = TextEditingController();
  String _color = labelSwatches[3].$2;

  List<Category> _labels = const [];
  Map<String, List<LabelRule>> _rulesByLabel = const {};
  Map<String, int> _uses = const {};
  bool _loading = true;
  bool _adding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  Future<String?> _token() =>
      context.read<AuthProvider>().getValidAccessToken();

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
      _categories.getCategories(accessToken: token, perPage: 100),
      _rules.getRules(accessToken: token),
    ]);
    if (!mounted) return;
    if (results[0]['success'] != true) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).labelsLoadFailed;
      });
      return;
    }
    final labels = (results[0]['categories'] as List).cast<Category>();
    final byLabel = <String, List<LabelRule>>{};
    if (results[1]['success'] == true) {
      for (final rule in (results[1]['rules'] as List).cast<LabelRule>()) {
        if (rule.active && rule.isKeywordLabel) {
          byLabel.putIfAbsent(rule.categoryId!, () => []).add(rule);
        }
      }
    }
    setState(() {
      _labels = labels;
      _rulesByLabel = byLabel;
      _loading = false;
      _error = null;
    });
    await _loadUses(token, labels);
  }

  Future<void> _loadUses(String token, List<Category> labels) async {
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');
    final counts = await Future.wait(labels.map((label) async {
      final result = await _transactions.getTransactions(
        accessToken: token,
        categoryIds: [label.id],
        startDate: fmt.format(DateTime(now.year, now.month)),
        endDate: fmt.format(now),
        perPage: 1,
      );
      final pagination = result['pagination'];
      if (result['success'] == true &&
          pagination is Map &&
          pagination['total_count'] is num) {
        return (pagination['total_count'] as num).toInt();
      }
      return (result['transactions'] as List?)?.length ?? 0;
    }));
    if (!mounted) return;
    setState(() {
      _uses = {
        for (var i = 0; i < labels.length; i++) labels[i].id: counts[i],
      };
    });
  }

  Future<bool> _addKeywords(
      String token, String categoryId, Iterable<String> keywords) async {
    var ok = true;
    for (final keyword in keywords) {
      final result = await _rules.createRule(
        accessToken: token,
        keyword: keyword,
        categoryId: categoryId,
      );
      ok = ok && result['success'] == true;
    }
    return ok;
  }

  Future<void> _addLabel() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast(AppLocalizations.of(context).labelsNameRequired);
      return;
    }
    final token = await _token();
    if (token == null || !mounted) return;
    setState(() => _adding = true);
    final result = await _categories.createCategory(
      accessToken: token,
      name: name,
      color: _color,
    );
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() => _adding = false);
      _toast(result['error']?.toString() ??
          AppLocalizations.of(context).labelsAddFailed);
      return;
    }
    final label = result['category'] as Category;
    final keywordsOk = await _addKeywords(
      token,
      label.id,
      KeywordSuggester.parseList(_keywordsController.text),
    );
    if (!mounted) return;
    _nameController.clear();
    _keywordsController.clear();
    setState(() => _adding = false);
    final l = AppLocalizations.of(context);
    _toast(keywordsOk
        ? l.labelsAdded(name)
        : l.labelsAddedKeywordsFailed(name));
    await _load();
  }

  Future<void> _edit(Category label) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LedgerColors.of(context).paper,
      shape: const RoundedRectangleBorder(),
      builder: (_) => _EditLabelSheet(
        label: label,
        rules: _rulesByLabel[label.id] ?? const [],
        categories: _categories,
        rulesService: _rules,
        tokenLoader: _token,
      ),
    );
    if (changed == true && mounted) await _load();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    Text(l.labelsTitle, style: LedgerText.title(color: c.ink)),
                    const SizedBox(height: 24),
                    _newLabelForm(c, l),
                    const SizedBox(height: 24),
                    ..._labelList(c, l),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newLabelForm(LedgerColors c, AppLocalizations l) {
    final labelStyle =
        LedgerText.body(size: 14, weight: FontWeight.w500, color: c.ink);
    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.labelsNewLabel, style: labelStyle),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            style: LedgerText.body(color: c.ink),
            decoration: ledgerInputDecoration(context,
                hint: l.labelsNameHint),
          ),
          const SizedBox(height: 12),
          SwatchPicker(
            selected: _color,
            onChanged: (hex) => setState(() => _color = hex),
          ),
          const SizedBox(height: 12),
          Text(l.labelsKeywordsLabel, style: labelStyle),
          const SizedBox(height: 6),
          TextField(
            controller: _keywordsController,
            textCapitalization: TextCapitalization.characters,
            style: LedgerText.figures(size: 16, color: c.ink),
            decoration:
                ledgerInputDecoration(context, hint: l.labelsKeywordsHint),
          ),
          const SizedBox(height: 12),
          InkButton(
            label: l.labelsAddButton,
            height: 48,
            busy: _adding,
            onPressed: _addLabel,
          ),
        ],
      ),
    );
  }

  List<Widget> _labelList(LedgerColors c, AppLocalizations l) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_error != null) {
      return [Text(_error!, style: LedgerText.body(color: c.moneyOut))];
    }
    return [
      LedgerCapsHeader(
          label: l.labelsYourLabels, trailing: l.labelsUsesThisMonth),
      for (final label in _labels) _labelRow(c, l, label),
      if (_labels.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(l.labelsEmpty,
              style: LedgerText.body(color: c.muted)),
        ),
    ];
  }

  Widget _labelRow(LedgerColors c, AppLocalizations l, Category label) {
    final keywords =
        (_rulesByLabel[label.id] ?? const []).map((r) => r.keyword!).toList();
    final uses = _uses[label.id];
    return InkWell(
      onTap: () => _edit(label),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.hairline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: LabelDot(
                color: parseHexColor(label.color, c.muted),
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.displayName, style: LedgerText.body(color: c.ink)),
                  const SizedBox(height: 4),
                  Text(
                    keywords.isEmpty
                        ? l.labelsNoAutoRule
                        : l.labelsAutoKeywords(keywords.join(', ')),
                    style: LedgerText.figures(size: 12, color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(uses == null ? '' : '$uses',
                style: LedgerText.figures(size: 14, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to rename, recolor, change keywords or delete a label.
/// Pops `true` when anything changed.
class _EditLabelSheet extends StatefulWidget {
  const _EditLabelSheet({
    required this.label,
    required this.rules,
    required this.categories,
    required this.rulesService,
    required this.tokenLoader,
  });

  final Category label;
  final List<LabelRule> rules;
  final CategoriesService categories;
  final RulesService rulesService;
  final Future<String?> Function() tokenLoader;

  @override
  State<_EditLabelSheet> createState() => _EditLabelSheetState();
}

class _EditLabelSheetState extends State<_EditLabelSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.label.name);
  late final TextEditingController _keywords = TextEditingController(
    text: widget.rules.map((r) => r.keyword).join(', '),
  );
  late String _color = widget.label.color ?? labelSwatches.first.$2;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _keywords.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).labelsNameRequired);
      return;
    }
    final token = await widget.tokenLoader();
    if (token == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final l = AppLocalizations.of(context);
    final errors = <String>[];
    if (name != widget.label.name ||
        _color.toUpperCase() != (widget.label.color ?? '').toUpperCase()) {
      final result = await widget.categories.updateCategory(
        accessToken: token,
        categoryId: widget.label.id,
        name: name,
        color: _color,
      );
      if (result['success'] != true) {
        errors.add(result['error']?.toString() ?? l.labelsSaveFailed);
      }
    }

    final wanted = KeywordSuggester.parseList(_keywords.text);
    final existing = {
      for (final r in widget.rules) KeywordSuggester.normalize(r.keyword!): r,
    };
    for (final entry in existing.entries) {
      if (!wanted.contains(entry.key)) {
        final result = await widget.rulesService
            .deleteRule(accessToken: token, ruleId: entry.value.id);
        if (result['success'] != true) {
          errors.add(l.labelsKeywordRemoveFailed(entry.key));
        }
      }
    }
    for (final keyword in wanted.where((k) => !existing.containsKey(k))) {
      final result = await widget.rulesService.createRule(
        accessToken: token,
        keyword: keyword,
        categoryId: widget.label.id,
      );
      if (result['success'] != true) {
        errors.add(l.labelsKeywordAddFailed(keyword));
      }
    }

    if (!mounted) return;
    if (errors.isEmpty) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = errors.join(' ');
      });
    }
  }

  Future<void> _delete() async {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: Text(l.commonDeleteNamed(widget.label.name)),
        content: Text(l.labelsDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonKeep),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.commonDelete, style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = await widget.tokenLoader();
    if (token == null || !mounted) return;
    setState(() => _busy = true);
    // Rules pointing at a deleted category would be left dangling.
    for (final rule in widget.rules) {
      await widget.rulesService.deleteRule(accessToken: token, ruleId: rule.id);
    }
    final result = await widget.categories
        .deleteCategory(accessToken: token, categoryId: widget.label.id);
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = result['error']?.toString() ?? l.labelsDeleteFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final labelStyle =
        LedgerText.body(size: 14, weight: FontWeight.w500, color: c.ink);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LedgerSectionHeader(title: l.labelsEditTitle),
            const SizedBox(height: 16),
            Text(l.transactionEditNameLabel, style: labelStyle),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              style: LedgerText.body(color: c.ink),
              decoration: ledgerInputDecoration(context),
            ),
            const SizedBox(height: 12),
            SwatchPicker(
              selected: _color,
              onChanged: (hex) => setState(() => _color = hex),
            ),
            const SizedBox(height: 12),
            Text(l.labelsKeywordsLabel, style: labelStyle),
            const SizedBox(height: 6),
            TextField(
              controller: _keywords,
              textCapitalization: TextCapitalization.characters,
              style: LedgerText.figures(size: 16, color: c.ink),
              decoration: ledgerInputDecoration(context,
                  hint: l.labelsKeywordsEditHint),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: LedgerText.body(size: 14, color: c.moneyOut)),
            ],
            const SizedBox(height: 16),
            InkButton(label: l.commonSave, busy: _busy, onPressed: _save),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _delete,
              style: TextButton.styleFrom(minimumSize: const Size(44, 48)),
              child: Text(l.labelsDeleteButton,
                  style: LedgerText.body(size: 15, color: c.danger)),
            ),
          ],
        ),
      ),
    );
  }
}
