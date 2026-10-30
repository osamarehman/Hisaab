import 'package:intl/intl.dart';

/// Household money formatting: "Rs 182,400" (en-US grouping, decimals only
/// when the value is not whole). Family currency defaults to PKR.
class MoneyFormat {
  const MoneyFormat._();

  static const String defaultCurrency = 'PKR';

  static final NumberFormat _whole = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _fraction = NumberFormat('#,##0.00', 'en_US');

  /// Currency prefix: "Rs" for PKR, the intl symbol otherwise ("$", "€").
  static String symbol(String? currency) {
    final code = (currency == null || currency.isEmpty)
        ? defaultCurrency
        : currency.toUpperCase();
    if (code == 'PKR') return 'Rs';
    try {
      return NumberFormat.simpleCurrency(name: code, locale: 'en_US')
          .currencySymbol;
    } catch (_) {
      return code;
    }
  }

  /// Grouped number without currency: 182400 → "182,400", 12.5 → "12.50".
  static String number(double value) {
    final abs = value.abs();
    final rounded = (abs * 100).roundToDouble() / 100;
    return rounded == rounded.truncateToDouble()
        ? _whole.format(rounded)
        : _fraction.format(rounded);
  }

  /// Short unsigned figure for tight spaces: 850 → "850", 4800 → "4.8k",
  /// 48200 → "48k", 1250000 → "1.3M".
  static String compact(double value) {
    final v = value.abs();
    String trim(double x) {
      final s = x.toStringAsFixed(1);
      return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
    }

    if (v < 1000) return v.round().toString();
    if (v < 10000) return '${trim(v / 1000)}k';
    if (v < 999500) return '${(v / 1000).round()}k';
    return '${trim(v / 1000000)}M';
  }

  /// "Rs 182,400". With [signed], prefixes "+ " or "− " (true minus sign).
  static String format(double value, {String? currency, bool signed = false}) {
    final sym = symbol(currency);
    // Letter symbols ("Rs", "CHF") read better with a space; "$" does not.
    final sep = RegExp(r'[A-Za-z]$').hasMatch(sym) ? ' ' : '';
    final body = '$sym$sep${number(value)}';
    if (signed && value != 0) {
      return value > 0 ? '+ $body' : '− $body';
    }
    return value < 0 ? '− $body' : body;
  }

  /// Wraps [text] in a Unicode left-to-right isolate so a money string keeps
  /// its "− Rs 1,200" order inside right-to-left (Urdu) text; the leading sign
  /// is direction-neutral and would otherwise jump to the far end.
  static String ltrIsolate(String text) => '\u2066$text\u2069';
}
