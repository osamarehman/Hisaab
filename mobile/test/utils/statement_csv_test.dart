import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/utils/statement_csv.dart';

// Shaped like a Meezan Bank export: a preamble above the header, separate
// Debit and Credit columns, and a running balance that must be ignored.
const _meezan = '﻿1234567890123,,,,,,\r\n'
    'Opening Balance,PKR      1000.00,,,,,\r\n'
    'Closing Balance,PKR      9950.00,,,,,\r\n'
    'Currency,Pakistan Rupee(PKR),,,,,\r\n'
    'Booking Date,Value Date,Doc No,Description,Debit,Credit,Available Balance\r\n'
    '18 Oct 2026,18 Oct 2026,,Raast transfer to A,"1,050",,-50.00\r\n'
    '22 Oct 2026,22 Oct 2026,FT1,"Money Received from B, salary",,"10,000",9950.00\r\n'
    '22 Oct 2026,22 Oct 2026,,Charges   Taxes,0,,9950.00\r\n'
    'Total,,,,1050,10000,\r\n';

const _signed = 'Date,Payee,Amount,Balance\n'
    '2026-10-01,Grocer,-45.20,954.80\n'
    '2026-10-02,Employer,3000,3954.80\n';

void main() {
  test('finds the header under the preamble and the debit/credit columns', () {
    final csv = StatementCsv.parse(_meezan);
    final m = csv.detect();

    expect(m.headerRow, 4);
    expect(csv.headers(m)[m.date!], 'Booking Date');
    expect(csv.headers(m)[m.description!], 'Description');
    expect(csv.headers(m)[m.debit!], 'Debit');
    expect(csv.headers(m)[m.credit!], 'Credit');
    expect(m.amount, isNull);
    expect(m.dateFormat, 'd MMM yyyy');
  });

  test('turns lines into signed amounts and skips zero and total rows', () {
    final csv = StatementCsv.parse(_meezan);
    final lines = csv.lines(csv.detect());

    expect(lines, hasLength(2));
    expect(lines[0].date, DateTime(2026, 10, 18));
    expect(lines[0].amount, -1050);
    expect(lines[1].description, 'Money Received from B, salary');
    expect(lines[1].amount, 10000);
  });

  test('writes a plain CSV with ISO dates and quoted descriptions', () {
    final csv = StatementCsv.parse(_meezan);
    expect(
      StatementCsv.toImportCsv(csv.lines(csv.detect())),
      'date,name,amount\n'
      '2026-10-18,Raast transfer to A,-1050.00\n'
      '2026-10-22,"Money Received from B, salary",10000.00\n',
    );
  });

  test('a single signed amount column, never the balance', () {
    final csv = StatementCsv.parse(_signed);
    final m = csv.detect();
    expect(csv.headers(m)[m.amount!], 'Amount');
    expect(csv.headers(m)[m.description!], 'Payee');
    expect(m.separateColumns, isFalse);
    expect(m.dateFormat, 'yyyy-MM-dd');

    final lines = csv.lines(m);
    expect(lines.map((l) => l.amount), [-45.2, 3000]);

    final flipped = csv.lines(m.copyWith(amountOutIsNegative: false));
    expect(flipped.map((l) => l.amount), [45.2, -3000]);
  });

  test('reads bank-style amounts', () {
    expect(StatementCsv.parseAmount('PKR 17,434.36'), 17434.36);
    expect(StatementCsv.parseAmount('(250.00)'), -250);
    expect(StatementCsv.parseAmount('3,000 Dr'), -3000);
    expect(StatementCsv.parseAmount(''), isNull);
  });
}
