import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../models/import_job.dart';
import '../providers/auth_provider.dart';
import '../services/accounts_service.dart';
import '../services/imports_service.dart';
import '../services/transactions_service.dart';
import '../theme/sure_tokens.dart';
import '../widgets/ledger/ledger.dart';
import '../widgets/no_accounts_prompt.dart';
import 'account_form_screen.dart';
import 'statement_review_screen.dart';

/// Statements tab: pick an account, upload a PDF/CSV statement, watch the
/// server read it, publish it, then label what the rules didn't.
class StatementsScreen extends StatefulWidget {
  const StatementsScreen({super.key, this.initialAccountId});

  /// Preselects the account (e.g. from "Add statement" on Accounts).
  final String? initialAccountId;

  @override
  State<StatementsScreen> createState() => _StatementsScreenState();
}

class _MonthCoverage {
  const _MonthCoverage(this.month, this.total, this.unlabelled);
  final DateTime month;
  final int total;
  final int unlabelled;
}

class _StatementsScreenState extends State<StatementsScreen> {
  static const _pollEvery = Duration(seconds: 3);
  static const _maxPolls = 100;

  final _imports = ImportsService();
  final _transactions = TransactionsService();

  List<Account> _accounts = const [];
  String? _accountId;
  bool _loading = true;
  String? _error;

  List<ImportJob> _recent = const [];
  List<_MonthCoverage> _coverage = const [];

  ImportJob? _current;
  bool _uploading = false;
  bool _publishing = false;
  bool _published = false;
  int? _needYou;
  Timer? _poll;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    _accountId = widget.initialAccountId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<String?> _token() =>
      context.read<AuthProvider>().getValidAccessToken();

  Account? get _account {
    for (final a in _accounts) {
      if (a.id == _accountId) return a;
    }
    return null;
  }

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
    final result =
        await AccountsService().getAccounts(accessToken: token, perPage: 100);
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() {
        _loading = false;
        _error = 'Could not load your accounts. Pull down to try again.';
      });
      return;
    }
    final all = (result['accounts'] as List).cast<Account>();
    final statementable = all
        .where((a) =>
            a.accountType == 'depository' || a.accountType == 'credit_card')
        .toList();
    setState(() {
      _accounts = statementable.isEmpty ? all : statementable;
      if (_account == null) {
        _accountId = _accounts.isEmpty ? null : _accounts.first.id;
      }
      _loading = false;
      _error = null;
    });
    await Future.wait([_loadRecent(token), _loadCoverage(token)]);
  }

  Future<void> _loadRecent(String token) async {
    final result = await _imports.listImports(accessToken: token);
    if (!mounted || result['success'] != true) return;
    final imports = (result['imports'] as List<ImportJob>)
        .where((i) => i.type == 'PdfImport' || i.type == 'TransactionImport')
        .toList();
    setState(() => _recent = imports);
  }

  static String _day(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  int _count(Map<String, dynamic> result) {
    final pagination = result['pagination'];
    if (pagination is Map && pagination['total_count'] is num) {
      return (pagination['total_count'] as num).toInt();
    }
    return (result['transactions'] as List?)?.length ?? 0;
  }

  Future<void> _loadCoverage(String token) async {
    final accountId = _accountId;
    if (accountId == null) return;
    final now = DateTime.now();
    final months = [
      for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i),
    ];
    Future<int> count(DateTime m, {required bool unlabelled}) async {
      final result = await _transactions.getTransactions(
        accessToken: token,
        accountId: accountId,
        startDate: _day(m),
        endDate: _day(DateTime(m.year, m.month + 1, 0)),
        perPage: 1,
        uncategorized: unlabelled,
      );
      return result['success'] == true ? _count(result) : 0;
    }

    final counts = await Future.wait([
      for (final m in months) ...[
        count(m, unlabelled: false),
        count(m, unlabelled: true),
      ],
    ]);
    if (!mounted || accountId != _accountId) return;
    setState(() {
      _coverage = [
        for (var i = 0; i < months.length; i++)
          _MonthCoverage(months[i], counts[i * 2], counts[i * 2 + 1]),
      ];
    });
  }

  /// Unlabelled lines in the current statement's period (last 6 months when
  /// the period is unknown).
  Future<int> _unlabelledForAccount(String token) async {
    final now = DateTime.now();
    final job = _current;
    final result = await _transactions.getTransactions(
      accessToken: token,
      accountId: _accountId,
      startDate: _day(job?.statementStart ?? DateTime(now.year, now.month - 5)),
      endDate: _day(job?.statementEnd ?? now),
      perPage: 1,
      uncategorized: true,
    );
    return result['success'] == true ? _count(result) : 0;
  }

  Future<void> _chooseFile() async {
    final accountId = _accountId;
    if (accountId == null) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'csv'],
      withData: true,
    );
    final file = picked?.files.singleOrNull;
    if (file == null || !mounted) return;
    final bytes = file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) {
      _toast('Could not read that file.');
      return;
    }
    if (ImportsService.fileKind(file.name) == null) {
      _toast('Choose a PDF or CSV statement.');
      return;
    }

    final token = await _token();
    if (token == null || !mounted) return;
    setState(() {
      _uploading = true;
      _published = false;
      _needYou = null;
    });
    final result = await _imports.uploadStatement(
      accessToken: token,
      accountId: accountId,
      fileName: file.name,
      bytes: bytes,
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    if (result['success'] != true) {
      _toast(result['error']?.toString() ?? 'Upload failed.');
      return;
    }
    _setCurrent(result['import'] as ImportJob);
    unawaited(_loadRecent(token));
  }

  void _setCurrent(ImportJob job, {bool resetPublished = false}) {
    setState(() {
      _current = job;
      if (resetPublished) {
        _published = job.status == ImportStatus.complete;
        _needYou = null;
      }
    });
    _polls = 0;
    _poll?.cancel();
    if (_shouldPoll(job)) {
      _poll = Timer.periodic(_pollEvery, (_) => _refreshCurrent());
    } else if (job.status == ImportStatus.complete) {
      _onComplete();
    }
  }

  // A fresh PDF can sit in `pending` with no rows until the extraction job
  // picks it up, and a just-published import stays `pending` until the
  // publish job starts, so keep polling both.
  bool _shouldPoll(ImportJob job) =>
      job.isWorking ||
      (job.status == ImportStatus.pending &&
          (_published || (job.rowsCount == 0 && job.error == null)));

  Future<void> _refreshCurrent() async {
    final current = _current;
    if (current == null) return;
    if (++_polls > _maxPolls) {
      _poll?.cancel();
      return;
    }
    final token = await _token();
    if (token == null || !mounted) return;
    final result =
        await _imports.getImport(accessToken: token, importId: current.id);
    if (!mounted || result['success'] != true) return;
    final job =
        (result['import'] as ImportJob).copyWith(fileName: current.fileName);
    setState(() => _current = job);
    if (!_shouldPoll(job)) {
      _poll?.cancel();
      if (job.status == ImportStatus.complete) _onComplete();
    }
  }

  Future<void> _onComplete() async {
    final token = await _token();
    if (token == null || !mounted) return;
    final need = await _unlabelledForAccount(token);
    if (!mounted) return;
    setState(() => _needYou = need);
    unawaited(_loadCoverage(token));
    unawaited(_loadRecent(token));
  }

  Future<void> _publish() async {
    final current = _current;
    if (current == null) return;
    final token = await _token();
    if (token == null || !mounted) return;
    setState(() => _publishing = true);
    final result =
        await _imports.publishImport(accessToken: token, importId: current.id);
    if (!mounted) return;
    setState(() {
      _publishing = false;
      if (result['success'] == true) _published = true;
    });
    if (result['success'] != true) {
      _toast(result['error']?.toString() ?? 'Could not add the lines.');
      return;
    }
    _setCurrent(
        (result['import'] as ImportJob).copyWith(fileName: current.fileName));
  }

  Future<void> _openReview() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatementReviewScreen(
          accountId: _accountId,
          startDate: _current?.statementStart,
          endDate: _current?.statementEnd,
        ),
      ),
    );
    if (!mounted) return;
    if (_current?.status == ImportStatus.complete) {
      await _onComplete();
    } else {
      final token = await _token();
      if (token != null) await _loadCoverage(token);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
            children: [
              if (Navigator.of(context).canPop())
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Back'),
                  ),
                ),
              Text('Statements', style: LedgerText.title(color: c.ink)),
              const SizedBox(height: 8),
              Text(
                'Add a bank statement. Sure reads every line, files each one '
                'under the right month and suggests a label.',
                style: LedgerText.body(size: 15, color: c.muted)
                    .copyWith(height: 1.45),
              ),
              const SizedBox(height: 24),
              ..._buildBody(c),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(LedgerColors c) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_error != null) {
      return [Text(_error!, style: LedgerText.body(color: c.moneyOut))];
    }
    if (_accounts.isEmpty) {
      return [
        NoAccountsPrompt(
          kind: AccountKind.bank,
          onCreated: (account) {
            _accountId = account.id;
            _load();
          },
        ),
      ];
    }
    return [
      _accountPicker(c),
      const SizedBox(height: 12),
      _fileButton(c),
      const SizedBox(height: 24),
      if (_current != null) ...[
        _importCard(c, _current!),
        const SizedBox(height: 24),
      ],
      _coverageSection(c),
      if (_recent.isNotEmpty) ...[
        const SizedBox(height: 28),
        _recentSection(c),
      ],
    ];
  }

  Widget _accountPicker(LedgerColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Bank account',
            style: LedgerText.body(
                size: 14, weight: FontWeight.w500, color: c.ink)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _accountId,
          isExpanded: true,
          decoration: ledgerInputDecoration(context, fill: c.sheet),
          style: LedgerText.body(color: c.ink),
          items: [
            for (final a in _accounts)
              DropdownMenuItem(
                value: a.id,
                child: Text(a.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (id) async {
            if (id == null || id == _accountId) return;
            setState(() {
              _accountId = id;
              _coverage = const [];
            });
            final token = await _token();
            if (token != null) await _loadCoverage(token);
          },
        ),
      ],
    );
  }

  Widget _fileButton(LedgerColors c) {
    return Semantics(
      button: true,
      label: 'Choose statement file',
      child: InkWell(
        onTap: _uploading ? null : _chooseFile,
        child: CustomPaint(
          painter: _DashedBorder(color: c.ink),
          child: Container(
            constraints: const BoxConstraints(minHeight: 120),
            color: c.sheet,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: _uploading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(strokeWidth: 2),
                      const SizedBox(height: 10),
                      Text('Uploading…',
                          style: LedgerText.body(color: c.muted)),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_outlined, size: 28, color: c.ink),
                      const SizedBox(height: 8),
                      Text('Choose statement file',
                          style: LedgerText.body(
                              size: 17, weight: FontWeight.w600, color: c.ink)),
                      const SizedBox(height: 4),
                      Text('PDF or CSV · up to 6 months in one file',
                          style: LedgerText.body(size: 13, color: c.muted)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _coverageSection(LedgerColors c) {
    final name = _account?.name ?? 'Account';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LedgerSectionHeader(title: '$name · last 6 months'),
        const SizedBox(height: 12),
        if (_coverage.isEmpty)
          SizedBox(
            height: 76,
            child: Center(
              child: Text('Checking months…',
                  style: LedgerText.body(size: 13, color: c.muted)),
            ),
          )
        else
          Row(
            children: [
              for (var i = 0; i < _coverage.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(child: _coverageCell(c, _coverage[i])),
              ],
            ],
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _legend(c, c.ink, 'All labelled'),
            _legend(c, c.moneyOut, 'Needs labels'),
            _legend(c, c.hairline, 'No statement'),
          ],
        ),
      ],
    );
  }

  Widget _coverageCell(LedgerColors c, _MonthCoverage m) {
    final color =
        m.total == 0 ? c.hairline : (m.unlabelled > 0 ? c.moneyOut : c.ink);
    final note = m.total == 0
        ? '–'
        : (m.unlabelled > 0 ? '${m.unlabelled} left' : '${m.total} ✓');
    final month = DateFormat.MMM('en').format(m.month);
    return Semantics(
      label: '$month: $note',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(height: 40, color: color),
          const SizedBox(height: 6),
          Text(month, style: LedgerText.body(size: 13, color: c.ink)),
          Text(note,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: LedgerText.figures(size: 11, color: c.muted)),
        ],
      ),
    );
  }

  Widget _legend(LedgerColors c, Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LabelDot(color: color),
          const SizedBox(width: 6),
          Text(label, style: LedgerText.body(size: 13, color: c.muted)),
        ],
      );

  Widget _importCard(LedgerColors c, ImportJob job) {
    final (statusText, statusColor) = _statusLabel(c, job);
    final children = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              job.fileName ?? (job.isPdf ? 'PDF statement' : 'CSV statement'),
              overflow: TextOverflow.ellipsis,
              style: LedgerText.figures(size: 14, color: c.ink),
            ),
          ),
          const SizedBox(width: 12),
          Text(statusText,
              style: LedgerText.body(size: 13, color: statusColor)),
        ],
      ),
    ];

    void gap() => children.add(const SizedBox(height: 14));

    if (job.status == ImportStatus.failed) {
      gap();
      children.add(Text(
        job.error ?? 'Sure could not read this statement. Try another file.',
        style: LedgerText.body(size: 14, color: c.moneyOut),
      ));
    } else if (_shouldPoll(job) || _publishing) {
      gap();
      children.add(LinearProgressIndicator(
        minHeight: 4,
        color: c.ink,
        backgroundColor: c.hairline,
      ));
      gap();
      children.add(Text(
        _published
            ? 'Adding the lines to your books…'
            : 'Sure is reading every line. This can take a minute.',
        style: LedgerText.body(size: 14, color: c.muted),
      ));
    } else if (job.status == ImportStatus.pending) {
      gap();
      children.add(_stat(c, '${job.rowsCount}', 'lines found', c.ink));
      gap();
      if (job.publishable == false) {
        children.add(Text(
          'This file needs its columns matched on the Sure website before '
          'the lines can be added.',
          style: LedgerText.body(size: 14, color: c.moneyOut),
        ));
      } else {
        children.add(InkButton(
          label: 'Add these ${job.rowsCount} lines',
          busy: _publishing,
          onPressed: job.canPublish ? _publish : null,
        ));
      }
    } else if (job.status == ImportStatus.complete) {
      final need = _needYou;
      gap();
      if (need == null) {
        children.add(_stat(c, '${job.rowsCount}', 'lines found', c.ink));
      } else {
        final auto = (job.rowsCount - need).clamp(0, job.rowsCount);
        children.add(Row(
          children: [
            Expanded(child: _stat(c, '${job.rowsCount}', 'lines found', c.ink)),
            Expanded(child: _stat(c, '$auto', 'auto-labelled', c.ink)),
            Expanded(child: _stat(c, '$need', 'need you', c.moneyOut)),
          ],
        ));
        if (auto + need > 0) {
          gap();
          children.add(SizedBox(
            height: 6,
            child: Row(
              children: [
                if (auto > 0)
                  Expanded(flex: auto, child: ColoredBox(color: c.ink)),
                if (auto > 0 && need > 0) const SizedBox(width: 2),
                if (need > 0)
                  Expanded(flex: need, child: ColoredBox(color: c.moneyOut)),
              ],
            ),
          ));
        }
        gap();
        children.add(need > 0
            ? InkButton(label: 'Label the $need items', onPressed: _openReview)
            : Text('Everything is labelled.',
                style: LedgerText.body(size: 14, color: c.moneyIn)));
      }
    }

    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  (String, Color) _statusLabel(LedgerColors c, ImportJob job) {
    switch (job.status) {
      case ImportStatus.failed:
      case ImportStatus.revertFailed:
        return ('Failed', c.moneyOut);
      case ImportStatus.complete:
        return ('Added', c.moneyIn);
      case ImportStatus.importing:
      case ImportStatus.reverting:
        return (_published ? 'Adding…' : 'Reading…', c.muted);
      case ImportStatus.pending:
        return job.rowsCount > 0 ? ('Read', c.moneyIn) : ('Waiting…', c.muted);
      case ImportStatus.unknown:
        return ('', c.muted);
    }
  }

  Widget _stat(LedgerColors c, String value, String label, Color color) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: LedgerText.figures(size: 22, color: color)),
          const SizedBox(height: 2),
          Text(label, style: LedgerText.body(size: 13, color: c.muted)),
        ],
      );

  Widget _recentSection(LedgerColors c) {
    final names = {for (final a in _accounts) a.id: a.name};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LedgerSectionHeader(title: 'Recent statements'),
        for (final job in _recent.take(6))
          InkWell(
            onTap: () => _setCurrent(job, resetPublished: true),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${job.isPdf ? 'PDF' : 'CSV'} · '
                          '${names[job.accountId] ?? 'Statement'}',
                          style: LedgerText.body(size: 15, color: c.ink),
                        ),
                        if (job.createdAt != null)
                          Text(
                            'Added ${DateFormat('d MMM yyyy', 'en').format(job.createdAt!.toLocal())}'
                            '${job.rowsCount > 0 ? ' · ${job.rowsCount} lines' : ''}',
                            style: LedgerText.body(size: 13, color: c.muted),
                          ),
                      ],
                    ),
                  ),
                  Builder(builder: (_) {
                    final (text, color) = _statusLabel(c, job);
                    return Text(text,
                        style: LedgerText.body(size: 13, color: color));
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 1px dashed rectangle for the file drop target.
class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(SureTokens.radiusMd),
    );
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
