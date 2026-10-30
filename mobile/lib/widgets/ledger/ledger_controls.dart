import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/sure_tokens.dart';
import 'ledger_style.dart';

/// Full-width ink button (primary action).
class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 50,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final enabled = onPressed != null && !busy;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          backgroundColor: enabled ? c.ink : c.track,
          foregroundColor: enabled ? c.onInk : c.muted,
          disabledForegroundColor: c.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SureTokens.radiusMd),
          ),
        ),
        child: busy
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.ink),
              )
            : Text(
                label,
                style: LedgerText.body(
                  color: enabled ? c.onInk : c.muted,
                  weight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Outlined (1px ink) secondary button.
class OutlineInkButton extends StatelessWidget {
  const OutlineInkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.ink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SureTokens.radiusMd),
          ),
        ),
        child: Text(label,
            style: LedgerText.body(color: c.ink, weight: FontWeight.w500)),
      ),
    );
  }
}

/// Text field decoration for ledger inputs (1px ink border, cobalt on focus).
InputDecoration ledgerInputDecoration(BuildContext context,
    {String? hint, Color? fill}) {
  final c = LedgerColors.of(context);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(SureTokens.radiusMd),
    borderSide: BorderSide(color: c.ink),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: LedgerText.body(color: c.muted),
    isDense: true,
    filled: true,
    fillColor: fill ?? c.paper,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: c.moneyIn, width: 2),
    ),
  );
}

/// Bordered panel ("card" without shadow).
class LedgerPanel extends StatelessWidget {
  const LedgerPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.sheet,
        border: Border.all(color: c.ink),
        borderRadius: BorderRadius.circular(SureTokens.radiusMd),
      ),
      child: child,
    );
  }
}

/// "‹ Back" link header for pushed screens.
class LedgerBackHeader extends StatelessWidget {
  const LedgerBackHeader({super.key, this.label});

  /// Defaults to the localized "Back".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left, size: 22, color: c.moneyIn),
                Text(label ?? AppLocalizations.of(context).commonBack,
                    style: LedgerText.body(color: c.moneyIn)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
