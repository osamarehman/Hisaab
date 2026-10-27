import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Household questions offered on an empty Assistant conversation.
List<String> suggestedQuestions(BuildContext context) {
  final l = AppLocalizations.of(context);
  return [
    l.chatSuggestionGroceries,
    l.chatSuggestionDay,
    l.chatSuggestionBills,
    l.chatSuggestionSave,
  ];
}
