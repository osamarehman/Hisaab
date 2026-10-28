import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import 'api_config.dart';

/// Public pages the stores and the AGPL require the app to link to. Legal
/// pages live on the server the user signs in to, since it holds their data.
class LegalLinks {
  static const sourceCodeUrl = 'https://github.com/osamarehman/sure-redesign';
  static const contactEmail = 'osamarehmanmughal@gmail.com';

  static Uri get privacy => Uri.parse('${ApiConfig.baseUrl}/privacy');
  static Uri get terms => Uri.parse('${ApiConfig.baseUrl}/terms');
  static Uri get accountDeletion =>
      Uri.parse('${ApiConfig.baseUrl}/account-deletion');
  static Uri get sourceCode => Uri.parse(sourceCodeUrl);
  static Uri get contact => Uri(scheme: 'mailto', path: contactEmail);

  static Future<void> open(BuildContext context, Uri uri) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text(l.legalOpenLinkError)));
    }
  }
}
