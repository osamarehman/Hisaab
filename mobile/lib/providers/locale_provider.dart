import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/preferences_service.dart';

/// The app language chosen in Settings.
///
/// A null [locale] means "follow the device language", which is what
/// `MaterialApp` does when its `locale` is null.
class LocaleProvider extends ChangeNotifier {
  /// Languages offered in the Settings picker, in display order.
  static const List<Locale> selectableLocales = [Locale('en'), Locale('ur')];

  static const String _systemValue = 'system';

  Locale? _locale;

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      _locale = _fromString(await PreferencesService.instance.getLocale());
    } catch (_) {
      _locale = null;
    }
    notifyListeners();
  }

  /// Applies [locale] immediately and persists it; null restores the device
  /// language.
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    await PreferencesService.instance
        .setLocale(locale?.languageCode ?? _systemValue);
  }

  static Locale? _fromString(String code) {
    if (code == _systemValue) return null;
    final isSupported = AppLocalizations.supportedLocales
        .any((supported) => supported.languageCode == code);
    return isSupported ? Locale(code) : null;
  }
}
