import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../l10n/app_localizations.dart';
import '../utils/money_format.dart';
import '../utils/statement_csv.dart';
import '../widgets/ledger/ledger.dart';

/// Confirms the columns the app guessed for a statement CSV, with a preview
/// of the lines they produce. Pops with the plain `date,name,amount` CSV to
/// upload, or null when closed.
class CsvMappingScreen extends StatefulWidget {
  const CsvMappingScreen({super.key, required this.csv, this.currency});

  final StatementCsv csv;
  final String? currency;

  @override
  State<CsvMappingScreen> createState() => _CsvMappingScreenState();
}

class _CsvMappingScreenState extends State<CsvMappingScreen> {
  late CsvMapping _mapping = widget.csv.detect();
  late final List<String> _headers = widget.csv.headers(_mapping);

  /// Remembered so switching the money layout back restores the guess.
  late int? _amountGuess = _mapping.amount ?? _mapping.debit;

  void _update(CsvMapping mapping) => setState(() => _mapping = mapping);

  void _setSeparate(bool separate) {
    if (separate == _mapping.separateColumns) return;
    if (separate) {
      _amountGuess = _mapping.amount;
      _update(_mapping.copyWith(
          amount: () => null, debit: () => _amountGuess, credit: () => null));
    } else {
      _update(_mapping.copyWith(
          amount: () => _mapping.debit ?? _mapping.credit ?? _amountGuess,
          debit: () => null,
          credit: () => null));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final lines = widget.csv.lines(_mapping);
    final moneyIn =
        lines.where((x) => x.amount > 0).fold(0.0, (s, x) => s + x.amount);
    final moneyOut =
        lines.where((x) => x.amount < 0).fold(0.0, (s, x) => s - x.amount);
    final labelStyle =
        LedgerText.body(size: 14, weight: FontWeight.w500, color: c.ink);

    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(
          children: [
            const LedgerBackHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  Text(l.csvMapTitle, style: LedgerText.title(color: c.ink)),
                  const SizedBox(height: 12),
                  Text(l.csvMapIntro, style: LedgerText.body(color: c.muted)),
                  const SizedBox(height: 24),
                  _column(l.csvMapDate, _mapping.date, labelStyle,
                      key: 'csv-date',
                      onChanged: (i) => _update(_mapping.copyWith(
                          date: () => i,
                          dateFormat: () =>
                              widget.csv.detectDateFormatFor(i, _mapping)))),
                  _dateFormat(l, labelStyle),
                  _column(l.csvMapDescription, _mapping.description, labelStyle,
                      key: 'csv-description',
                      onChanged: (i) =>
                          _update(_mapping.copyWith(description: () => i))),
                  SwitchListTile(
                    key: const Key('csv-separate'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.csvMapSeparate, style: labelStyle),
                    value: _mapping.separateColumns,
                    onChanged: _setSeparate,
                  ),
                  if (_mapping.separateColumns) ...[
                    _column(l.csvMapMoneyOut, _mapping.debit, labelStyle,
                        key: 'csv-debit',
                        onChanged: (i) =>
                            _update(_mapping.copyWith(debit: () => i))),
                    _column(l.csvMapMoneyIn, _mapping.credit, labelStyle,
                        key: 'csv-credit',
                        onChanged: (i) =>
                            _update(_mapping.copyWith(credit: () => i))),
                  ] else ...[
                    _column(l.csvMapAmount, _mapping.amount, labelStyle,
                        key: 'csv-amount',
                        onChanged: (i) =>
                            _update(_mapping.copyWith(amount: () => i))),
                    SwitchListTile(
                      key: const Key('csv-negative-out'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.csvMapOutNegative, style: labelStyle),
                      value: _mapping.amountOutIsNegative,
                      onChanged: (v) =>
                          _update(_mapping.copyWith(amountOutIsNegative: v)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  LedgerCapsHeader(label: l.csvMapPreview),
                  const SizedBox(height: 8),
                  if (lines.isEmpty)
                    Text(l.csvMapNoLines,
                        key: const Key('csv-no-lines'),
                        style: LedgerText.body(size: 14, color: c.danger))
                  else ...[
                    Text(
                      l.csvMapSummary(
                        lines.length,
                        MoneyFormat.ltrIsolate(MoneyFormat.format(moneyIn,
                            currency: widget.currency)),
                        MoneyFormat.ltrIsolate(MoneyFormat.format(moneyOut,
                            currency: widget.currency)),
                      ),
                      key: const Key('csv-summary'),
                      style: LedgerText.body(size: 14, color: c.muted),
                    ),
                    const SizedBox(height: 8),
                    for (final line in lines.take(5)) _previewRow(c, line),
                  ],
                  const SizedBox(height: 24),
                  InkButton(
                    key: const Key('csv-confirm'),
                    label: l.csvMapConfirm(lines.length),
                    onPressed: lines.isEmpty
                        ? null
                        : () => Navigator.of(context)
                            .pop(StatementCsv.toImportCsv(lines)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _column(String label, int? value, TextStyle labelStyle,
      {required String key, required ValueChanged<int?> onChanged}) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 6),
          _Dropdown<int?>(
            key: ValueKey(key),
            value: value,
            items: [
              DropdownMenuItem<int?>(value: null, child: Text(l.csvMapNone)),
              for (final (i, name) in _headers.indexed)
                DropdownMenuItem<int?>(
                  value: i,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dateFormat(AppLocalizations l, TextStyle labelStyle) {
    final sample = DateTime(2026, 10, 18);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.csvMapDateFormat, style: labelStyle),
          const SizedBox(height: 6),
          _Dropdown<String?>(
            key: const ValueKey('csv-date-format'),
            value: _mapping.dateFormat,
            items: [
              for (final format in StatementCsv.dateFormats)
                DropdownMenuItem<String?>(
                  value: format,
                  child: Text(DateFormat(format, 'en_US').format(sample),
                      textDirection: TextDirection.ltr),
                ),
            ],
            onChanged: (f) => _update(_mapping.copyWith(dateFormat: () => f)),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(LedgerColors c, StatementLine line) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(DateFormat('d MMM', 'en_US').format(line.date),
                textDirection: TextDirection.ltr,
                style: LedgerText.figures(size: 13, color: c.muted)),
          ),
          Expanded(
            child: Text(line.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LedgerText.body(size: 14, color: c.ink)),
          ),
          const SizedBox(width: 8),
          Text(
            MoneyFormat.ltrIsolate(MoneyFormat.format(line.amount,
                currency: widget.currency, signed: true)),
            style: LedgerText.figures(
                size: 14, color: line.amount > 0 ? c.moneyIn : c.ink),
          ),
        ],
      ),
    );
  }
}

/// A controlled dropdown in the ledger input style: it follows [value] when
/// the parent changes it, unlike a form field's initial value.
class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: ledgerInputDecoration(context)
          .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.any((i) => i.value == value) ? value : null,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
