import 'package:intl/intl.dart';

/// The columns a statement CSV maps to. Money is either one signed [amount]
/// column or separate [debit] (money out) and [credit] (money in) columns.
class CsvMapping {
  const CsvMapping({
    required this.headerRow,
    this.date,
    this.description,
    this.amount,
    this.debit,
    this.credit,
    this.dateFormat,
    this.amountOutIsNegative = true,
  });

  /// Index of the header row; rows above it are the bank's preamble.
  final int headerRow;
  final int? date;
  final int? description;
  final int? amount;
  final int? debit;
  final int? credit;

  /// An intl pattern such as `d MMM yyyy`.
  final String? dateFormat;

  /// For a single [amount] column: money out is written as a negative number.
  final bool amountOutIsNegative;

  bool get separateColumns => debit != null || credit != null;

  CsvMapping copyWith({
    int? headerRow,
    int? Function()? date,
    int? Function()? description,
    int? Function()? amount,
    int? Function()? debit,
    int? Function()? credit,
    String? Function()? dateFormat,
    bool? amountOutIsNegative,
  }) =>
      CsvMapping(
        headerRow: headerRow ?? this.headerRow,
        date: date != null ? date() : this.date,
        description: description != null ? description() : this.description,
        amount: amount != null ? amount() : this.amount,
        debit: debit != null ? debit() : this.debit,
        credit: credit != null ? credit() : this.credit,
        dateFormat: dateFormat != null ? dateFormat() : this.dateFormat,
        amountOutIsNegative: amountOutIsNegative ?? this.amountOutIsNegative,
      );
}

/// One statement line after mapping. [amount] is positive for money in.
class StatementLine {
  const StatementLine(this.date, this.description, this.amount);

  final DateTime date;
  final String description;
  final double amount;
}

/// Reads a bank statement CSV in the app: finds the header row under the
/// bank's preamble, guesses the columns from their names, and turns the lines
/// into a plain `date,name,amount` CSV the server imports without any column
/// matching.
class StatementCsv {
  StatementCsv._(this.rows);

  /// Parses [text]; a leading byte order mark is ignored.
  factory StatementCsv.parse(String text) =>
      StatementCsv._(_parseRows(text.replaceFirst('﻿', '')));

  final List<List<String>> rows;

  /// Date patterns tried in order; day-first comes before month-first.
  static const dateFormats = [
    'd MMM yyyy',
    'd-MMM-yyyy',
    'd MMM yy',
    'd-MMM-yy',
    'd MMMM yyyy',
    'dd/MM/yyyy',
    'dd-MM-yyyy',
    'dd.MM.yyyy',
    'yyyy-MM-dd',
    'yyyy/MM/dd',
    'MM/dd/yyyy',
    'MMM d, yyyy',
    'dd/MM/yy',
  ];

  static final _date = RegExp(
      r'\b(booking|posting|transaction|txn|trans|value)?\s*date\b|^date$|tarikh',
      caseSensitive: false);
  static final _preferredDate =
      RegExp(r'booking|posting|transaction|txn|trans', caseSensitive: false);
  static final _description = RegExp(
      r'descr|narrat|details?|particular|memo|remark|payee|beneficiary|reference|\bname\b',
      caseSensitive: false);
  static final _debit = RegExp(
      r'debit|withdraw|paid\s*out|money\s*out|outflow|\bdr\b',
      caseSensitive: false);
  static final _credit = RegExp(
      r'credit|deposit|paid\s*in|money\s*in|inflow|\bcr\b',
      caseSensitive: false);
  static final _amount =
      RegExp(r'amount|\bamt\b|\bvalue\b', caseSensitive: false);
  static final _balance = RegExp(r'balance', caseSensitive: false);

  /// The header row and the columns its names point to.
  CsvMapping detect() {
    final header = _findHeaderRow();
    final names = header < rows.length ? rows[header] : const <String>[];

    int? find(RegExp pattern, {RegExp? prefer, Set<int> skip = const {}}) {
      int? first;
      for (var i = 0; i < names.length; i++) {
        final name = names[i].trim();
        if (name.isEmpty || skip.contains(i) || _balance.hasMatch(name)) {
          continue;
        }
        if (!pattern.hasMatch(name)) continue;
        if (prefer == null || prefer.hasMatch(name)) return i;
        first ??= i;
      }
      return first;
    }

    Set<int> used(List<int?> columns) => columns.whereType<int>().toSet();

    final date = find(_date, prefer: _preferredDate);
    final debit = find(_debit, skip: used([date]));
    final credit = find(_credit, skip: used([date, debit]));
    final amount = (debit == null && credit == null)
        ? find(_amount, skip: used([date]))
        : null;
    final description =
        find(_description, skip: used([date, debit, credit, amount]));

    final mapping = CsvMapping(
      headerRow: header,
      date: date,
      description: description,
      amount: amount,
      debit: debit,
      credit: credit,
    );
    return mapping.copyWith(dateFormat: () => _detectDateFormat(mapping));
  }

  /// Column names of the header row.
  List<String> headers(CsvMapping mapping) => mapping.headerRow < rows.length
      ? [
          for (final (i, name) in rows[mapping.headerRow].indexed)
            name.trim().isEmpty ? 'Column ${i + 1}' : name.trim(),
        ]
      : const [];

  /// Lines below the header that have a readable date and some money.
  /// Totals and footers, which have neither, are left out.
  List<StatementLine> lines(CsvMapping mapping) {
    final dateCol = mapping.date;
    final format = mapping.dateFormat;
    if (dateCol == null || format == null) return const [];
    if (!mapping.separateColumns && mapping.amount == null) return const [];
    final parser = DateFormat(format, 'en_US');

    final result = <StatementLine>[];
    for (final row in rows.skip(mapping.headerRow + 1)) {
      String cell(int? i) => (i != null && i < row.length) ? row[i].trim() : '';
      final date = _parseDate(parser, cell(dateCol));
      if (date == null) continue;

      double? amount;
      if (mapping.separateColumns) {
        final out = parseAmount(cell(mapping.debit));
        final inn = parseAmount(cell(mapping.credit));
        if (out == null && inn == null) continue;
        amount = (inn?.abs() ?? 0) - (out?.abs() ?? 0);
      } else {
        final value = parseAmount(cell(mapping.amount));
        if (value == null) continue;
        amount = mapping.amountOutIsNegative ? value : -value;
      }
      if (amount == 0) continue;

      final description =
          cell(mapping.description).replaceAll(RegExp(r'\s+'), ' ');
      result.add(StatementLine(date, description, amount));
    }
    return result;
  }

  /// The plain CSV sent to the server: ISO dates, money in positive.
  static String toImportCsv(List<StatementLine> lines) {
    final buffer = StringBuffer('date,name,amount\n');
    final day = DateFormat('yyyy-MM-dd');
    for (final line in lines) {
      buffer
        ..write(day.format(line.date))
        ..write(',')
        ..write(_escape(line.description))
        ..write(',')
        ..write(line.amount.toStringAsFixed(2))
        ..write('\n');
    }
    return buffer.toString();
  }

  /// "1,050", "PKR 17,434.36", "(250.00)", "3,000 Dr" → numbers; blank → null.
  static double? parseAmount(String text) {
    var t = text.trim();
    if (t.isEmpty) return null;
    var negative = false;
    if (t.startsWith('(') && t.endsWith(')')) negative = true;
    if (RegExp(r'\bdr\.?$', caseSensitive: false).hasMatch(t)) negative = true;
    t = t.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (t.startsWith('-')) {
      negative = true;
      t = t.substring(1);
    }
    if (t.isEmpty || t == '.') return null;
    final value = double.tryParse(t);
    if (value == null) return null;
    return negative ? -value : value;
  }

  int _findHeaderRow() {
    for (var r = 0; r < rows.length && r < 40; r++) {
      final names = rows[r];
      final hasDate = names.any((n) => _date.hasMatch(n.trim()));
      final hasMoney = names.any((n) {
        final t = n.trim();
        return !_balance.hasMatch(t) &&
            (_debit.hasMatch(t) || _credit.hasMatch(t) || _amount.hasMatch(t));
      });
      if (hasDate && hasMoney) return r;
    }
    return 0;
  }

  String? _detectDateFormat(CsvMapping mapping) =>
      detectDateFormatFor(mapping.date, mapping);

  /// The date pattern that reads most values in column [col].
  String? detectDateFormatFor(int? col, CsvMapping mapping) {
    if (col == null) return null;
    final samples = rows
        .skip(mapping.headerRow + 1)
        .map((row) => col < row.length ? row[col].trim() : '')
        .where((s) => s.isNotEmpty && RegExp(r'\d').hasMatch(s))
        .take(30)
        .toList();
    if (samples.isEmpty) return null;

    String? best;
    var bestCount = 0;
    for (final format in dateFormats) {
      final parser = DateFormat(format, 'en_US');
      final count = samples.where((s) => _parseDate(parser, s) != null).length;
      if (count > bestCount) {
        best = format;
        bestCount = count;
      }
    }
    return best;
  }

  static DateTime? _parseDate(DateFormat parser, String text) {
    if (text.isEmpty) return null;
    try {
      final date = parser.parseStrict(text);
      return date.year >= 1970 && date.year <= 2100 ? date : null;
    } catch (_) {
      return null;
    }
  }

  static String _escape(String value) {
    if (!value.contains(RegExp(r'[",\n\r]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  /// Comma-separated rows; quoted cells may hold commas, quotes and newlines.
  static List<List<String>> _parseRows(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          cell.write(ch);
        }
      } else if (ch == '"') {
        quoted = true;
      } else if (ch == ',') {
        row.add(cell.toString());
        cell.clear();
      } else if (ch == '\n' || ch == '\r') {
        if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        row.add(cell.toString());
        cell.clear();
        if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
        row = <String>[];
      } else {
        cell.write(ch);
      }
    }
    row.add(cell.toString());
    if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
    return rows;
  }
}
