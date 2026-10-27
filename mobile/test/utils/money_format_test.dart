import 'package:flutter_test/flutter_test.dart';
import 'package:sure_mobile/utils/money_format.dart';

void main() {
  group('MoneyFormat', () {
    test('formats PKR with Rs, en-US grouping and no decimals when whole', () {
      expect(MoneyFormat.format(182400), 'Rs 182,400');
      expect(MoneyFormat.format(182400, currency: 'PKR'), 'Rs 182,400');
      expect(MoneyFormat.format(4812650.0), 'Rs 4,812,650');
      expect(MoneyFormat.format(0), 'Rs 0');
    });

    test('keeps two decimals only when the value is not whole', () {
      expect(MoneyFormat.format(2450.5), 'Rs 2,450.50');
      expect(MoneyFormat.format(99.999), 'Rs 100');
    });

    test('signs with a true minus and a plus when asked', () {
      expect(MoneyFormat.format(-3250), '− Rs 3,250');
      expect(MoneyFormat.format(250000, signed: true), '+ Rs 250,000');
      expect(MoneyFormat.format(-800, signed: true), '− Rs 800');
      expect(MoneyFormat.format(0, signed: true), 'Rs 0');
    });

    test('compact shortens figures for calendar cells', () {
      expect(MoneyFormat.compact(850), '850');
      expect(MoneyFormat.compact(4800), '4.8k');
      expect(MoneyFormat.compact(5000), '5k');
      expect(MoneyFormat.compact(48200), '48k');
      expect(MoneyFormat.compact(-1250000), '1.3M');
    });

    test('uses symbols for other currencies', () {
      expect(MoneyFormat.format(1234.5, currency: 'USD'), r'$1,234.50');
      expect(MoneyFormat.symbol(null), 'Rs');
    });

    test('number groups without a currency', () {
      expect(MoneyFormat.number(-1234567), '1,234,567');
    });
  });
}
