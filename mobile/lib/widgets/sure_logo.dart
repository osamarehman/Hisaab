import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/sure_colors.dart';

/// The Hisaab "ledger rule" mark: an H over a cobalt double rule on a paper
/// tile. The asset carries its own colours; [SvgTheme.currentColor] is kept
/// for any future single-colour variant.
class SureLogo extends StatelessWidget {
  const SureLogo({super.key, this.size = 36});

  /// Square edge length in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logomark.svg',
      width: size,
      height: size,
      theme: SvgTheme(
        currentColor: SureColors.of(context).palette.textSecondary,
      ),
    );
  }
}
