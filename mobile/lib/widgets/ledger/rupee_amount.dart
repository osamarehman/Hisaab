import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/privacy_provider.dart';
import '../../utils/money_format.dart';
import '../../utils/money_masker.dart';
import 'ledger_style.dart';

/// Keeps money strings in left-to-right order when the app runs in Urdu.
String _ltr(BuildContext context, String text) =>
    Directionality.of(context) == TextDirection.rtl
        ? MoneyFormat.ltrIsolate(text)
        : text;

bool _hidden(BuildContext context) {
  try {
    return context.select<PrivacyProvider, bool>((p) => p.hidden);
  } on ProviderNotFoundException {
    return false;
  }
}

/// Mono tabular amount ("Rs 182,400"), masked in privacy mode; [signed] adds "+ "/"− ".
class RupeeAmount extends StatelessWidget {
  const RupeeAmount(
    this.value, {
    super.key,
    this.currency,
    this.signed = false,
    this.size = 16,
    this.color,
    this.weight,
    this.textAlign,
  });

  final double value;
  final String? currency;
  final bool signed;
  final double size;
  final Color? color;
  final FontWeight? weight;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final text = MoneyFormat.format(value, currency: currency, signed: signed);
    return Text(
      _ltr(context, _hidden(context) ? MoneyMasker.mask(text) : text),
      textAlign: textAlign,
      style: LedgerText.figures(
        size: size,
        color: color ?? LedgerColors.of(context).ink,
        weight: weight,
      ),
    );
  }
}

/// Big Bricolage headline amount with a half-size muted currency prefix.
class HeadlineAmount extends StatelessWidget {
  const HeadlineAmount(
    this.value, {
    super.key,
    this.currency,
    this.size = 48,
  });

  final double value;
  final String? currency;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final number =
        _hidden(context) ? MoneyMasker.maskedNumber : MoneyFormat.number(value);
    final sign = value < 0 ? '−' : '';
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          // In RTL the two spans form one LTR isolate (LRI … PDI).
          text: '${rtl ? '\u2066' : ''}$sign${MoneyFormat.symbol(currency)} ',
          style: LedgerText.display(size: size / 2, color: c.muted),
        ),
        TextSpan(
          text: rtl ? '$number\u2069' : number,
          style: LedgerText.display(
            size: size,
            color: c.ink,
            letterSpacing: -size * 0.035,
            height: 1,
          ),
        ),
      ]),
    );
  }
}
