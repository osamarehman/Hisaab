import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../providers/accounts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../services/reports_service.dart';
import '../widgets/ledger/ledger.dart';

enum ReportPreset { thisMonth, lastMonth, last3Months, custom }

/// Saves the PDF and hands it to the user (share sheet by default).
typedef ReportDelivery = Future<void> Function(
    String filename, Uint8List bytes);

/// "Download report": pick a period, labels and accounts, then fetch the
/// household PDF from the server, save it and open the share sheet.
class ReportExportScreen extends StatefulWidget {
  const ReportExportScreen({
    super.key,
    this.month,
    this.today,
    this.service,
    this.accessTokenLoader,
    this.deliver,
    this.labels,
    this.accounts,
  });

  /// Month the user was looking at; preselects that month.
  final DateTime? month;

  /// Overrides for tests; the defaults come from providers and the platform.
  final DateTime? today;
  final ReportsService? service;
  final Future<String?> Function()? accessTokenLoader;
  final ReportDelivery? deliver;
  final List<Category>? labels;
  final List<Account>? accounts;

  /// [start, end] of a preset relative to [today] (whole calendar months).
  static DateTimeRange rangeFor(ReportPreset preset, DateTime today) {
    final month = DateTime(today.year, today.month);
    DateTime endOf(DateTime m) => DateTime(m.year, m.month + 1, 0);
    switch (preset) {
      case ReportPreset.lastMonth:
        final last = DateTime(month.year, month.month - 1);
        return DateTimeRange(start: last, end: endOf(last));
      case ReportPreset.last3Months:
        return DateTimeRange(
          start: DateTime(month.year, month.month - 2),
          end: endOf(month),
        );
      case ReportPreset.thisMonth:
      case ReportPreset.custom:
        return DateTimeRange(start: month, end: endOf(month));
    }
  }

  @override
  State<ReportExportScreen> createState() => _ReportExportScreenState();
}

class _ReportExportScreenState extends State<ReportExportScreen> {
  static const _maxMonths = 24;

  late final ReportsService _service = widget.service ?? ReportsService();
  late final DateTime _today = widget.today ?? DateTime.now();

  late ReportPreset _preset;
  late DateTimeRange _custom;

  /// null = every label (and unlabelled rows).
  Set<String>? _labelIds;
  bool _unlabelled = true;

  /// null = every account.
  Set<String>? _accountIds;

  bool _busy = false;
  String? _error;
  String? _saved;

  @override
  void initState() {
    super.initState();
    final month = widget.month;
    _preset = ReportPreset.thisMonth;
    _custom = ReportExportScreen.rangeFor(ReportPreset.thisMonth, _today);
    if (month != null) {
      final picked = DateTime(month.year, month.month);
      final last = ReportExportScreen.rangeFor(ReportPreset.lastMonth, _today);
      if (picked == last.start) {
        _preset = ReportPreset.lastMonth;
      } else if (picked != DateTime(_today.year, _today.month)) {
        _preset = ReportPreset.custom;
        _custom = DateTimeRange(
          start: picked,
          end: DateTime(picked.year, picked.month + 1, 0),
        );
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChoices());
  }

  Future<void> _loadChoices() async {
    if (widget.labels != null && widget.accounts != null) return;
    final token = await _token();
    if (token == null || !mounted) return;
    final categories = context.read<CategoriesProvider>();
    final accounts = context.read<AccountsProvider>();
    if (!categories.hasFetched) categories.fetchCategories(accessToken: token);
    if (accounts.accounts.isEmpty) accounts.fetchAccounts(accessToken: token);
  }

  Future<String?> _token() {
    final loader = widget.accessTokenLoader;
    if (loader != null) return loader();
    return context.read<AuthProvider>().getValidAccessToken();
  }

  DateTimeRange get _range => _preset == ReportPreset.custom
      ? _custom
      : ReportExportScreen.rangeFor(_preset, _today);

  List<Category> get _labels {
    final list =
        widget.labels ?? context.watch<CategoriesProvider>().categories;
    return [...list]..sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  }

  List<Account> get _accounts =>
      widget.accounts ?? context.watch<AccountsProvider>().accounts;

  Future<void> _pickCustom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(_today.year + 1, 12, 31),
      initialDateRange: _range,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _preset = ReportPreset.custom;
      _custom = picked;
      _error = null;
    });
  }

  void _toggleLabel(String id) {
    setState(() {
      final ids = _labelIds;
      if (ids == null) {
        _labelIds = {id};
        _unlabelled = false;
      } else if (!ids.remove(id)) {
        ids.add(id);
      }
      _error = null;
    });
  }

  void _toggleUnlabelled() {
    setState(() {
      if (_labelIds == null) {
        _labelIds = {};
        _unlabelled = true;
      } else {
        _unlabelled = !_unlabelled;
      }
      _error = null;
    });
  }

  void _toggleAccount(String id) {
    setState(() {
      final ids = _accountIds;
      if (ids == null) {
        _accountIds = {id};
      } else if (!ids.remove(id)) {
        ids.add(id);
      }
      _error = null;
    });
  }

  String? _validate(AppLocalizations l) {
    final ids = _labelIds;
    if (ids != null && ids.isEmpty && !_unlabelled) return l.reportPickLabel;
    if (_accountIds != null && _accountIds!.isEmpty) return l.reportPickAccount;
    final range = _range;
    final limit = DateTime(
        range.start.year, range.start.month + _maxMonths, range.start.day);
    if (!range.end.isBefore(limit)) return l.reportTooLong;
    return null;
  }

  Future<void> _download() async {
    final l = AppLocalizations.of(context);
    final invalid = _validate(l);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _saved = null;
    });

    final token = await _token();
    if (!mounted) return;
    if (token == null) {
      setState(() => _busy = false);
      await context.read<AuthProvider>().logout();
      return;
    }

    final range = _range;
    final result = await _service.download(
      accessToken: token,
      start: range.start,
      end: range.end,
      categoryIds: _labelIds?.toList(),
      includeUnlabelled: _unlabelled,
      accountIds: _accountIds?.toList(),
    );
    if (!mounted) return;

    if (!result.ok) {
      if (result.error == ReportDownload.unauthorized) {
        setState(() => _busy = false);
        await context.read<AuthProvider>().logout();
        return;
      }
      setState(() {
        _busy = false;
        _error = switch (result.error) {
          ReportDownload.offline => l.reportOffline,
          null => l.reportFailed,
          final message => message,
        };
      });
      return;
    }

    try {
      await (widget.deliver ?? _saveAndShare)(result.filename!, result.bytes!);
      if (mounted) setState(() => _saved = l.reportSaved(result.filename!));
    } catch (_) {
      if (mounted) setState(() => _error = l.reportFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveAndShare(String filename, Uint8List bytes) async {
    final dir =
        Directory('${(await getApplicationDocumentsDirectory()).path}/reports');
    await dir.create(recursive: true);
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      title: filename,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = LedgerColors.of(context);
    final range = _range;
    final format = DateFormat('d MMM yyyy', 'en_US');
    final labels = _labels;
    final accounts = _accounts;

    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(
          children: [
            if (Navigator.of(context).canPop()) const LedgerBackHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  Text(l.reportTitle, style: LedgerText.title(color: c.ink)),
                  const SizedBox(height: 8),
                  Text(
                    l.reportIntro,
                    style: LedgerText.body(size: 15, color: c.muted)
                        .copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 28),
                  LedgerCapsHeader(label: l.reportPeriod),
                  const SizedBox(height: 12),
                  _chips([
                    for (final preset in ReportPreset.values)
                      LabelChip(
                        key: ValueKey('report-preset-${preset.name}'),
                        name: _presetName(l, preset),
                        showDot: false,
                        selected: _preset == preset,
                        onTap: preset == ReportPreset.custom
                            ? _pickCustom
                            : () => setState(() {
                                  _preset = preset;
                                  _error = null;
                                }),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    '${format.format(range.start)} – ${format.format(range.end)}',
                    key: const ValueKey('report-range'),
                    style: LedgerText.figures(size: 14, color: c.ink),
                  ),
                  const SizedBox(height: 28),
                  LedgerCapsHeader(label: l.reportLabels),
                  const SizedBox(height: 12),
                  _chips([
                    LabelChip(
                      key: const ValueKey('report-labels-all'),
                      name: l.reportAllLabels,
                      showDot: false,
                      selected: _labelIds == null,
                      onTap: () => setState(() {
                        _labelIds = null;
                        _unlabelled = true;
                        _error = null;
                      }),
                    ),
                    for (final label in labels)
                      LabelChip(
                        key: ValueKey('report-label-${label.id}'),
                        name: label.displayName,
                        color: parseHexColor(label.color, c.muted),
                        selected: _labelIds?.contains(label.id) ?? false,
                        onTap: () => _toggleLabel(label.id),
                      ),
                    LabelChip(
                      key: const ValueKey('report-label-unlabelled'),
                      name: l.reportUnlabelled,
                      selected: _labelIds != null && _unlabelled,
                      onTap: _toggleUnlabelled,
                    ),
                  ]),
                  const SizedBox(height: 28),
                  LedgerCapsHeader(label: l.reportAccounts),
                  const SizedBox(height: 12),
                  _chips([
                    LabelChip(
                      key: const ValueKey('report-accounts-all'),
                      name: l.reportAllAccounts,
                      showDot: false,
                      selected: _accountIds == null,
                      onTap: () => setState(() {
                        _accountIds = null;
                        _error = null;
                      }),
                    ),
                    for (final account in accounts)
                      LabelChip(
                        key: ValueKey('report-account-${account.id}'),
                        name: account.name,
                        showDot: false,
                        selected: _accountIds?.contains(account.id) ?? false,
                        onTap: () => _toggleAccount(account.id),
                      ),
                  ]),
                  const SizedBox(height: 32),
                  if (_error != null) ...[
                    Text(_error!,
                        key: const ValueKey('report-error'),
                        style: LedgerText.body(size: 14, color: c.danger)),
                    const SizedBox(height: 12),
                  ],
                  if (_saved != null) ...[
                    Text(_saved!,
                        key: const ValueKey('report-saved'),
                        style: LedgerText.body(size: 14, color: c.muted)),
                    const SizedBox(height: 12),
                  ],
                  InkButton(
                    key: const ValueKey('report-download'),
                    label: l.reportDownload,
                    busy: _busy,
                    onPressed: _download,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chips(List<Widget> children) =>
      Wrap(spacing: 8, runSpacing: 8, children: children);

  String _presetName(AppLocalizations l, ReportPreset preset) =>
      switch (preset) {
        ReportPreset.thisMonth => l.reportThisMonth,
        ReportPreset.lastMonth => l.reportLastMonth,
        ReportPreset.last3Months => l.reportLast3Months,
        ReportPreset.custom => l.reportCustom,
      };
}
