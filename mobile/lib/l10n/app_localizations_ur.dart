// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'حساب';

  @override
  String get commonCancel => 'منسوخ کریں';

  @override
  String get commonSave => 'محفوظ کریں';

  @override
  String get commonTryAgain => 'دوبارہ کوشش کریں';

  @override
  String get commonDelete => 'حذف کریں';

  @override
  String get commonAll => 'سب';

  @override
  String get commonRefresh => 'تازہ کریں';

  @override
  String get commonClose => 'بند کریں';

  @override
  String get commonUndo => 'واپس لیں';

  @override
  String get loginEmailLabel => 'ای میل';

  @override
  String get loginEmailRequired => 'ای میل ضروری ہے';

  @override
  String get loginEmailInvalid => 'براہ کرم درست ای میل درج کریں';

  @override
  String get loginPasswordLabel => 'پاس ورڈ';

  @override
  String get loginPasswordRequired => 'پاس ورڈ ضروری ہے';

  @override
  String get loginSignIn => 'سائن ان';

  @override
  String get loginSignInWithGoogle => 'Google کے ساتھ سائن ان کریں';

  @override
  String get loginMfaLabel => 'تصدیقی کوڈ';

  @override
  String get navHome => 'ہوم';

  @override
  String get navIntro => 'تعارف';

  @override
  String get navAssistant => 'اسسٹنٹ';

  @override
  String get navMore => 'مزید';

  @override
  String get dashboardSyncError => 'سنک ناکام ہو گیا';

  @override
  String get dashboardSyncFailed =>
      'سنک ناکام ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get dashboardRefreshing => 'اکاؤنٹس تازہ ہو رہے ہیں…';

  @override
  String get dashboardAccountsUpdated => 'اکاؤنٹس اپ ڈیٹ ہو گئے';

  @override
  String get dashboardSyncing => 'سرور سے ڈیٹا سنک ہو رہا ہے…';

  @override
  String get dashboardSynced => 'سنک ہو گیا';

  @override
  String get dashboardErrorLoadingAccounts => 'اکاؤنٹس لوڈ نہیں ہو سکے';

  @override
  String get dashboardNoAccounts => 'ابھی کوئی اکاؤنٹ نہیں';

  @override
  String get dashboardNoAccountsSubtitle =>
      'یہاں دیکھنے کے لیے ویب ایپ میں اکاؤنٹس شامل کریں۔';

  @override
  String get dashboardFilterEmpty => 'موجودہ فلٹر سے کوئی اکاؤنٹ نہیں ملا';

  @override
  String get chatListNewChat => 'سوال پوچھیں';

  @override
  String get chatListEmptySubtitle =>
      'ابھی کچھ نہیں پوچھا گیا۔ آپ کے سوالات یہاں نظر آئیں گے۔';

  @override
  String get chatListDeleteTitle => 'چیٹ حذف کریں';

  @override
  String get chatConversationNewTitle => 'نیا سوال';

  @override
  String get chatConversationMessageHint => 'اپنے پیسوں کے بارے میں پوچھیں…';

  @override
  String chatConversationGreetingWithName(String firstName) {
    return 'السلام علیکم $firstName، میں کیا مدد کر سکتا ہوں؟';
  }

  @override
  String get chatConversationGreetingNoName =>
      'السلام علیکم، میں کیا مدد کر سکتا ہوں؟';

  @override
  String get transactionFormNewTitle => 'نیا لین دین';

  @override
  String get transactionFormTypeLabel => 'قسم';

  @override
  String get transactionFormTypeExpense => 'خرچ';

  @override
  String get transactionFormTypeIncome => 'آمدنی';

  @override
  String get transactionFormAmountLabel => 'رقم';

  @override
  String get transactionFormAmountRequired => 'رقم ضروری ہے';

  @override
  String get transactionFormAmountInvalid => 'براہ کرم درست رقم درج کریں';

  @override
  String get transactionFormDateLabel => 'تاریخ';

  @override
  String get transactionFormNameLabel => 'نام';

  @override
  String get transactionFormCategoryLabel => 'زمرہ';

  @override
  String get transactionEditTitle => 'لین دین میں ترمیم کریں';

  @override
  String get transactionEditNameLabel => 'نام';

  @override
  String get transactionEditNameRequired => 'نام ضروری ہے';

  @override
  String get transactionEditNotesLabel => 'نوٹس';

  @override
  String get transactionEditCategoryLabel => 'زمرہ';

  @override
  String get transactionEditMerchantLabel => 'دکاندار';

  @override
  String get transactionEditTagsLabel => 'ٹیگز';

  @override
  String get transactionEditSaving => 'محفوظ ہو رہا ہے…';

  @override
  String get transactionsListDeleteTitle => 'لین دین حذف کریں';

  @override
  String transactionsListDeleteSingleContent(String name) {
    return 'کیا آپ واقعی \"$name\" حذف کرنا چاہتے ہیں؟';
  }

  @override
  String get transactionsListDeleteMultiTitle => 'لین دین حذف کریں';

  @override
  String get transactionsListDeleteMultiContent =>
      'کیا آپ واقعی منتخب لین دین حذف کرنا چاہتے ہیں؟';

  @override
  String get transactionsListEmpty => 'کوئی لین دین نہیں';

  @override
  String get transactionsListAuthFailed =>
      'تصدیق ناکام: براہ کرم دوبارہ سائن ان کریں';

  @override
  String get transactionsListNoTransactionsYet => 'ابھی کوئی لین دین نہیں';

  @override
  String get transactionsListEmptyAddFirst =>
      'اپنا پہلا لین دین شامل کرنے کے لیے + دبائیں';

  @override
  String get transactionsListNoCategoryMatch => 'اس زمرے میں کوئی لین دین نہیں';

  @override
  String get transactionsListRetry => 'دوبارہ کوشش کریں';

  @override
  String get transactionsListDeletedSuccess => 'لین دین حذف ہو گیا';

  @override
  String get transactionsListSingleDeleteFailed => 'لین دین حذف نہیں ہو سکا';

  @override
  String transactionsListDeletedMulti(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لین دین حذف ہو گئے',
      one: '$count لین دین حذف ہو گیا',
    );
    return '$_temp0';
  }

  @override
  String get transactionsListDeleteFailed => 'لین دین حذف نہیں ہو سکے';

  @override
  String get transactionsListDeleteNoToken =>
      'حذف نہیں ہو سکا: رسائی ٹوکن موجود نہیں';

  @override
  String get transactionsListUndoTitle => 'لین دین واپس لیں';

  @override
  String get transactionsListUndoRemovePending =>
      'یہ زیرِ التوا لین دین ہٹا دیں؟';

  @override
  String get transactionsListUndoRestoreConfirm => 'یہ لین دین بحال کریں؟';

  @override
  String get transactionsListUndoPendingRemoved =>
      'زیرِ التوا لین دین ہٹا دیا گیا';

  @override
  String get transactionsListUndoRestored => 'لین دین بحال ہو گیا';

  @override
  String get transactionsListUndoFailed => 'لین دین واپس نہیں ہو سکا';

  @override
  String get settingsSectionDisplay => 'ڈسپلے';

  @override
  String get settingsSectionConnection => 'کنکشن';

  @override
  String get settingsSectionDataManagement => 'ڈیٹا کا انتظام';

  @override
  String get settingsSectionSecurity => 'سیکیورٹی';

  @override
  String get settingsSectionDangerZone => 'خطرناک اقدامات';

  @override
  String get settingsThemeLabel => 'تھیم';

  @override
  String get settingsThemeSystem => 'سسٹم کے مطابق';

  @override
  String get settingsThemeLight => 'لائٹ';

  @override
  String get settingsThemeDark => 'ڈارک';

  @override
  String get settingsProxyHeadersLabel => 'کسٹم پراکسی ہیڈرز';

  @override
  String get settingsPrivacyHideAmountsLabel => 'رقمیں چھپائیں';

  @override
  String get settingsPrivacyHideAmountsContent => 'پوری ایپ میں رقمیں چھپا دیں';

  @override
  String get settingsBiometricLabel => 'بایومیٹرک لاک';

  @override
  String get settingsBiometricEnable => 'بایومیٹرک لاک آن کریں؟';

  @override
  String get settingsBiometricEnableContent =>
      'ایپ دوبارہ کھولنے پر بایومیٹرک تصدیق ضروری ہو گی۔';

  @override
  String get settingsCheckForUpdates => 'اپ ڈیٹس چیک کریں';

  @override
  String get settingsUpdateAvailableTitle => 'اپ ڈیٹ دستیاب ہے';

  @override
  String settingsUpdateAvailableContent(String version) {
    return 'ورژن $version دستیاب ہے۔ ابھی اپ ڈیٹ کریں؟';
  }

  @override
  String get settingsUpdateNewerVersionFallback => 'نیا ورژن';

  @override
  String get settingsUpdateNow => 'ابھی اپ ڈیٹ کریں';

  @override
  String get settingsNoUpdateAvailable => 'آپ کے پاس تازہ ترین ورژن ہے۔';

  @override
  String get settingsUpdateError => 'اپ ڈیٹس چیک نہیں ہو سکیں۔';

  @override
  String get settingsClearDataTitle => 'تمام ڈیٹا صاف کریں';

  @override
  String get settingsClearDataContent =>
      'اس سے فون پر محفوظ تمام ڈیٹا ہٹ جائے گا۔ سرور پر آپ کا ڈیٹا متاثر نہیں ہو گا۔';

  @override
  String get settingsClearData => 'ڈیٹا صاف کریں';

  @override
  String get settingsClearDataSuccess => 'مقامی ڈیٹا صاف ہو گیا';

  @override
  String get settingsDeleteAccountTitle => 'اکاؤنٹ حذف کریں';

  @override
  String get settingsDeleteAccount => 'اکاؤنٹ حذف کریں';

  @override
  String get settingsSignOutTitle => 'سائن آؤٹ';

  @override
  String get settingsSignOutContent => 'کیا آپ واقعی سائن آؤٹ کرنا چاہتے ہیں؟';

  @override
  String get settingsSignOut => 'سائن آؤٹ';

  @override
  String get settingsDebugLogs => 'ڈیبگ لاگز';

  @override
  String get ssoOnboardingTitle => 'اپنا اکاؤنٹ لنک کریں';

  @override
  String get ssoOnboardingTabLink => 'موجودہ لنک کریں';

  @override
  String get ssoOnboardingTabCreate => 'نیا بنائیں';

  @override
  String get ssoOnboardingFirstNameLabel => 'پہلا نام';

  @override
  String get ssoOnboardingLastNameLabel => 'آخری نام';

  @override
  String get ssoOnboardingLinkButton => 'اکاؤنٹ لنک کریں';

  @override
  String get ssoOnboardingCreateButton => 'اکاؤنٹ بنائیں';

  @override
  String get ssoOnboardingAcceptInvitation => 'دعوت قبول کریں';

  @override
  String get moreRecentTransactions => 'حالیہ لین دین';

  @override
  String get moreRecentTransactionsSubtitle =>
      'تمام اکاؤنٹس کے حالیہ لین دین دیکھیں';

  @override
  String get biometricTitle => 'ایپ لاک ہے';

  @override
  String get biometricSubtitle => 'جاری رکھنے کے لیے تصدیق کریں';

  @override
  String get biometricUnlock => 'ان لاک کریں';

  @override
  String get biometricAuthenticating => 'تصدیق ہو رہی ہے…';

  @override
  String get biometricLogOut => 'سائن آؤٹ';

  @override
  String get backendConfigTitle => 'کنفیگریشن';

  @override
  String get backendConfigSubtitle => 'اپنا حساب سرور URL اپ ڈیٹ کریں';

  @override
  String get backendConfigExampleUrlsLabel => 'مثالی URLs';

  @override
  String get backendConfigUrlLabel => 'حساب سرور URL';

  @override
  String get backendConfigUrlHint => 'https://app.sure.am';

  @override
  String get backendConfigProxyHeadersLabel => 'حسب ضرورت پراکسی ہیڈرز';

  @override
  String get backendConfigProxyHeadersSubtitle =>
      'ریورس پراکسی یا تصدیقی گیٹ وے کے لیے اختیاری ہیڈرز';

  @override
  String backendConfigProxyHeadersCount(int count) {
    return '$count ترتیب شدہ';
  }

  @override
  String get backendConfigTesting => 'جانچ ہو رہی ہے…';

  @override
  String get backendConfigTestButton => 'کنکشن جانچیں';

  @override
  String get backendConfigContinueButton => 'جاری رکھیں';

  @override
  String get backendConfigChangeHint =>
      'آپ اسے بعد میں ترتیبات میں تبدیل کر سکتے ہیں۔';

  @override
  String get recentTransactionsTitle => 'حالیہ لین دین';

  @override
  String get recentTransactionsEmpty => 'کوئی لین دین نہیں';

  @override
  String get recentTransactionsDisplayLimit => 'دکھانے کی حد';

  @override
  String recentTransactionsShowN(int count) {
    return '$count دکھائیں';
  }

  @override
  String get recentTransactionsPullToRefresh => 'تازہ کرنے کے لیے نیچے کھینچیں';

  @override
  String get logViewerTitle => 'ڈیبگ لاگز';

  @override
  String get logViewerFilterAll => 'سب';

  @override
  String get logViewerFilterInfo => 'معلومات';

  @override
  String get logViewerFilterWarning => 'انتباہ';

  @override
  String get logViewerFilterError => 'خرابی';

  @override
  String get logViewerFilterDebug => 'ڈیبگ';

  @override
  String get logViewerAutoScrollEnable => 'خودکار اسکرول آن کریں';

  @override
  String get logViewerAutoScrollDisable => 'خودکار اسکرول بند کریں';

  @override
  String get logViewerCopyLogs => 'لاگز کاپی کریں';

  @override
  String get logViewerClearLogs => 'لاگز صاف کریں';

  @override
  String get logViewerLogsCopied => 'لاگز کلپ بورڈ پر کاپی ہو گئے';

  @override
  String get logViewerEmpty => 'ابھی کوئی لاگ نہیں';

  @override
  String get connectivityOffline => 'آپ آف لائن ہیں';

  @override
  String connectivityPendingSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لین دین سنک کے منتظر',
      one: '$count لین دین سنک کا منتظر',
    );
    return '$_temp0';
  }

  @override
  String get connectivitySyncNow => 'ابھی سنک کریں';

  @override
  String get proxyHeadersAddHeader => 'ہیڈر شامل کریں';

  @override
  String get proxyHeadersNameLabel => 'ہیڈر کا نام';

  @override
  String get proxyHeadersNameHint => 'X-Auth-Token';

  @override
  String get proxyHeadersValueLabel => 'ہیڈر کی ویلیو';

  @override
  String get proxyHeadersRemove => 'ہیڈر ہٹائیں';

  @override
  String get accountDetailRefreshTooltip => 'اکاؤنٹ کی تفصیلات تازہ کریں';

  @override
  String get accountDetailRecentBalanceHistory => 'حالیہ بیلنس کی تاریخچہ';

  @override
  String get accountDetailTopHoldings => 'نمایاں سرمایہ کاریاں';

  @override
  String get accountDetailHoldingFallback => 'سرمایہ کاری';

  @override
  String accountDetailCashChip(String amount) {
    return 'نقد $amount';
  }

  @override
  String get biometricLockFailedRetry =>
      'تصدیق ناکام ہو گئی۔ دوبارہ کوشش کے لیے اَن لاک پر ٹیپ کریں۔';

  @override
  String get settingsBiometricVerifyReason =>
      'ایپ لاک آن کرنے کے لیے بایومیٹرک تصدیق کریں';

  @override
  String get settingsBiometricFailed => 'بایومیٹرک تصدیق ناکام ہو گئی۔';

  @override
  String get settingsUpdateOpenStoreError => 'اسٹور کا لنک نہیں کھل سکا';

  @override
  String get settingsClearDataFailed => 'مقامی ڈیٹا صاف نہیں ہو سکا۔';

  @override
  String get settingsClearDataSuccessDetailed =>
      'مقامی ڈیٹا صاف ہو گیا۔ سرور سے سنک کرنے کے لیے نیچے کھینچ کر تازہ کریں۔';

  @override
  String get settingsContactOpenLinkError => 'لنک نہیں کھل سکا';

  @override
  String get settingsResetAccountContent =>
      'اکاؤنٹ ری سیٹ کرنے سے آپ کے تمام اکاؤنٹس، زمرے، دکاندار، ٹیگز اور دیگر ڈیٹا حذف ہو جائے گا، لیکن آپ کا یوزر اکاؤنٹ برقرار رہے گا۔\n\nیہ عمل واپس نہیں ہو سکتا۔ کیا آپ کو یقین ہے؟';

  @override
  String get settingsResetAccount => 'اکاؤنٹ ری سیٹ کریں';

  @override
  String get settingsResetAccountInitiated =>
      'اکاؤنٹ ری سیٹ شروع ہو گیا ہے۔ اس میں کچھ لمحے لگ سکتے ہیں۔';

  @override
  String get settingsResetAccountFailed => 'اکاؤنٹ ری سیٹ نہیں ہو سکا';

  @override
  String get settingsDeleteAccountConfirmContent =>
      'اکاؤنٹ حذف کرنے سے آپ کا تمام ڈیٹا ہمیشہ کے لیے ختم ہو جائے گا اور یہ واپس نہیں ہو سکتا۔\n\nکیا آپ واقعی اپنا اکاؤنٹ حذف کرنا چاہتے ہیں؟';

  @override
  String get settingsDeleteAccountFailed => 'اکاؤنٹ حذف نہیں ہو سکا';

  @override
  String get settingsProxyHeadersNote =>
      'ایپ یہ ہیڈرز API درخواستوں کے ساتھ بھیجتی ہے۔ بیرونی براؤزر کے SSO صفحات کو شاید یہ موصول نہ ہوں۔';

  @override
  String get settingsProxyHeadersSaved => 'حسب ضرورت پراکسی ہیڈرز محفوظ ہو گئے';

  @override
  String get settingsProxyHeadersSaveFailed =>
      'حسب ضرورت پراکسی ہیڈرز محفوظ نہیں ہو سکے۔';

  @override
  String settingsAppVersion(String version) {
    return 'ایپ ورژن: $version';
  }

  @override
  String get settingsCheckForUpdatesSubtitle =>
      'دیکھیں کہ نیا ورژن دستیاب ہے یا نہیں';

  @override
  String get settingsContactUs => 'ہم سے رابطہ کریں';

  @override
  String get settingsDebugLogsSemantics => 'ڈیبگ لاگز کھولیں';

  @override
  String get settingsDebugLogsSubtitle => 'ایپ کے تشخیصی لاگز دیکھیں';

  @override
  String get settingsGroupByAccountType => 'اکاؤنٹ کی قسم کے لحاظ سے گروپ کریں';

  @override
  String get settingsGroupByAccountTypeSubtitle =>
      'اکاؤنٹس کو قسم کے لحاظ سے گروپ کریں (کرپٹو، بینک وغیرہ)';

  @override
  String get settingsProxyHeadersTileTitle => 'حسب ضرورت پراکسی ہیڈرز';

  @override
  String get settingsProxyHeadersTileSubtitleEmpty =>
      'ریورس پراکسی یا تصدیقی گیٹ وے کے لیے اختیاری ہیڈرز';

  @override
  String settingsProxyHeadersTileSubtitleCount(int count) {
    return '$count ترتیب شدہ';
  }

  @override
  String get settingsClearDataTileSubtitle =>
      'محفوظ شدہ تمام لین دین اور اکاؤنٹس ہٹائیں';

  @override
  String get settingsResetAccountTileSubtitle =>
      'تمام اکاؤنٹس، زمرے، دکاندار اور ٹیگز حذف کریں لیکن یوزر اکاؤنٹ برقرار رکھیں';

  @override
  String get settingsDeleteAccountTileSubtitle =>
      'اپنا تمام ڈیٹا ہمیشہ کے لیے ختم کریں۔ یہ واپس نہیں ہو سکتا۔';

  @override
  String get settingsUserFallback => 'صارف';

  @override
  String get chatListError => 'چیٹس لوڈ نہیں ہو سکیں';

  @override
  String get chatListJustNow => 'ابھی ابھی';

  @override
  String chatListDeleteSingleContent(String title) {
    return 'کیا آپ واقعی \"$title\" حذف کرنا چاہتے ہیں؟';
  }

  @override
  String get loginSignUpOpenError => 'سائن اپ صفحہ نہیں کھل سکا';

  @override
  String get loginDemoOrSignUpPrefix => 'ڈیمو اکاؤنٹ یا ';

  @override
  String get loginSignUpLink => 'سائن اپ';

  @override
  String get loginSignUpSuffix => '!';

  @override
  String get loginMfaInfo => 'دو مرحلہ تصدیق فعال ہے۔ اپنا کوڈ درج کریں۔';

  @override
  String get loginMfaCodeRequired => 'براہ کرم اپنا تصدیقی کوڈ درج کریں';

  @override
  String get loginOrDivider => 'یا';

  @override
  String get loginServerUrlHeading => 'حساب سرور URL:';

  @override
  String get loginBackendSettingsTooltip => 'بیک اینڈ ترتیبات';

  @override
  String get transactionEditSessionExpired =>
      'سیشن ختم ہو گیا۔ براہ کرم دوبارہ سائن ان کریں۔';

  @override
  String get transactionEditUpdated => 'لین دین اپ ڈیٹ ہو گیا';

  @override
  String get transactionEditUpdateFailed => 'لین دین اپ ڈیٹ نہیں ہو سکا';

  @override
  String transactionEditNameMaxLength(int max) {
    return 'نام $max حروف یا اس سے کم ہونا چاہیے';
  }

  @override
  String get transactionEditNameInvalidChars => 'نام میں غیر معاون حروف ہیں';

  @override
  String transactionEditNotesMaxLength(int max) {
    return 'نوٹس $max حروف یا اس سے کم ہونے چاہئیں';
  }

  @override
  String get transactionEditNotesInvalidChars => 'نوٹس میں غیر معاون حروف ہیں';

  @override
  String get transactionEditNoCategory => 'کوئی زمرہ نہیں';

  @override
  String get transactionEditCurrentCategory => 'موجودہ زمرہ';

  @override
  String get transactionEditNoMerchant => 'کوئی دکاندار نہیں';

  @override
  String get transactionEditCurrentMerchant => 'موجودہ دکاندار';

  @override
  String get transactionEditNoTags => 'کوئی ٹیگ دستیاب نہیں';

  @override
  String get transactionEditUnknownTag => 'نامعلوم ٹیگ';

  @override
  String get transactionEditSyncedOnly =>
      'موبائل سے صرف سنک شدہ لین دین میں ترمیم ہو سکتی ہے۔';

  @override
  String get transactionEditCategoryHelper => 'متبادل زمرہ منتخب کریں';

  @override
  String get transactionEditMerchantHelper => 'متبادل دکاندار منتخب کریں';

  @override
  String get transactionFormSessionExpired =>
      'سیشن ختم ہو گیا۔ براہ کرم دوبارہ سائن ان کریں۔';

  @override
  String get transactionFormAmountRequiredPrompt => 'براہ کرم رقم درج کریں';

  @override
  String get transactionFormAmountInvalidNumber => 'براہ کرم درست عدد درج کریں';

  @override
  String get transactionFormAmountTooSmall => 'رقم 0 سے زیادہ ہونی چاہیے';

  @override
  String get transactionFormCreateSuccessOnline => 'لین دین بن گیا';

  @override
  String get transactionFormCreateSuccessOffline =>
      'لین دین محفوظ ہو گیا (آن لائن ہونے پر سنک ہو گا)';

  @override
  String get transactionFormCreateFailed => 'لین دین نہیں بن سکا';

  @override
  String transactionFormGenericError(String error) {
    return 'خرابی: $error';
  }

  @override
  String get transactionFormLess => 'کم';

  @override
  String get transactionFormMore => 'مزید';

  @override
  String get transactionFormDateHelper => 'اختیاری (طے شدہ: آج)';

  @override
  String get transactionFormNameHelper => 'اختیاری (طے شدہ: SureApp)';

  @override
  String get transactionFormCategoryLoading => 'زمرے لوڈ ہو رہے ہیں…';

  @override
  String get transactionFormCategoryHelper => 'اختیاری';

  @override
  String get transactionFormNoCategory => 'کوئی زمرہ نہیں';

  @override
  String get transactionFormCreateButton => 'لین دین بنائیں';

  @override
  String get transactionFormAmountHelper => 'ضروری';

  @override
  String get logViewerClearConfirm =>
      'کیا آپ واقعی تمام لاگز صاف کرنا چاہتے ہیں؟';

  @override
  String get logViewerClear => 'صاف کریں';

  @override
  String get chatConversationEditTitle => 'عنوان میں ترمیم کریں';

  @override
  String get chatConversationTitleLabel => 'چیٹ کا عنوان';

  @override
  String get chatConversationRefreshTooltip => 'تازہ کریں';

  @override
  String get chatConversationLoadError => 'چیٹ لوڈ نہیں ہو سکی';

  @override
  String get navEnableAiChatTitle => 'اسسٹنٹ آن کریں؟';

  @override
  String get navEnableAiChatContent =>
      'اسسٹنٹ آپ کے پیسوں سے متعلق سوالوں کے جواب دینے کے لیے آپ کے اندراجات پڑھتا ہے۔ ابھی یہ آپ کے اکاؤنٹ کے لیے بند ہے۔';

  @override
  String get navEnableAiChatConfirm => 'AI آن کریں';

  @override
  String get navEnableAiChatFailed => 'ابھی AI آن نہیں ہو سکا۔';

  @override
  String get transactionsListEditTooltip => 'لین دین میں ترمیم کریں';

  @override
  String get connectivitySignInToSync =>
      'لین دین سنک کرنے کے لیے براہ کرم سائن ان کریں';

  @override
  String get connectivitySyncSuccess => 'لین دین سنک ہو گئے';

  @override
  String get connectivitySyncFailed =>
      'لین دین سنک نہیں ہو سکے۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get connectivityAuthFailed =>
      'تصدیق نہیں ہو سکی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String ssoOnboardingSignedInAs(String email) {
    return '$email کے طور پر سائن ان';
  }

  @override
  String get ssoOnboardingGoogleVerified => 'Google اکاؤنٹ کی تصدیق ہو گئی';

  @override
  String get ssoOnboardingLinkCredentialsNote =>
      'Google سائن ان سے جوڑنے کے لیے اپنے موجودہ اکاؤنٹ کی تفصیلات درج کریں۔';

  @override
  String get ssoOnboardingPendingInvitationNote =>
      'آپ کے لیے ایک دعوت نامہ زیرِ التوا ہے۔ کسی موجودہ گھرانے میں شامل ہونے کے لیے اسے قبول کریں۔';

  @override
  String get ssoOnboardingCreateIdentityNote =>
      'اپنی Google شناخت سے نیا اکاؤنٹ بنائیں۔';

  @override
  String get ssoOnboardingFirstNameRequired => 'پہلا نام ضروری ہے';

  @override
  String get ssoOnboardingLastNameRequired => 'آخری نام ضروری ہے';

  @override
  String get backendConfigTimeout =>
      'کنکشن کا وقت ختم ہو گیا۔ براہِ کرم URL چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get backendConfigSuccess => 'کنکشن کامیاب!';

  @override
  String backendConfigServerError(int code) {
    return 'سرور نے اسٹیٹس $code بھیجا۔ براہِ کرم چیک کریں کہ یہ حساب کا بیک اینڈ سرور ہے۔';
  }

  @override
  String backendConfigConnectionFailed(String error) {
    return 'کنکشن ناکام: $error';
  }

  @override
  String backendConfigSaveFailed(String error) {
    return 'URL محفوظ نہیں ہو سکا: $error';
  }

  @override
  String get backendConfigUrlRequired => 'براہِ کرم بیک اینڈ URL درج کریں';

  @override
  String get backendConfigUrlScheme =>
      'URL کا آغاز http:// یا https:// سے ہونا چاہیے';

  @override
  String get backendConfigUrlInvalid => 'براہِ کرم درست URL درج کریں';

  @override
  String get backendConfigHeadersHelp =>
      'ایپ یہ ہیڈرز API درخواستوں کے ساتھ بھیجتی ہے۔ بیرونی براؤزر کے SSO صفحات کو شاید یہ نہ ملیں۔';

  @override
  String get recentTransactionsUnknownAccount => 'نامعلوم اکاؤنٹ';

  @override
  String get accountDetailUnavailable =>
      'اکاؤنٹ کی تفصیلات عارضی طور پر دستیاب نہیں';

  @override
  String chatListMinutesAgo(int minutes) {
    return '$minutes منٹ پہلے';
  }

  @override
  String chatListHoursAgo(int hours) {
    return '$hours گھنٹے پہلے';
  }

  @override
  String chatListDaysAgo(int days) {
    return '$days دن پہلے';
  }

  @override
  String get chatConversationStartFailed =>
      'گفتگو شروع نہیں ہو سکی۔ براہِ کرم دوبارہ کوشش کریں۔';

  @override
  String get moreBudgets => 'بجٹ';

  @override
  String get moreBudgetsSubtitle => 'زمرہ وار بجٹ بمقابلہ اصل خرچ';

  @override
  String get budgetsTitle => 'بجٹ';

  @override
  String get budgetsPreviousMonth => 'پچھلا مہینہ';

  @override
  String get budgetsNextMonth => 'اگلا مہینہ';

  @override
  String get budgetsBudgeted => 'بجٹ';

  @override
  String get budgetsActual => 'اصل';

  @override
  String get budgetsRemaining => 'باقی';

  @override
  String get budgetsIncome => 'آمدنی';

  @override
  String budgetsExpectedIncome(String amount) {
    return 'متوقع $amount';
  }

  @override
  String budgetsOfAmount(String amount) {
    return '$amount میں سے';
  }

  @override
  String budgetsAmountLeft(String amount) {
    return '$amount باقی';
  }

  @override
  String budgetsOverBy(String amount) {
    return '$amount زیادہ';
  }

  @override
  String budgetsRolledOver(String amount) {
    return '+$amount پچھلے مہینے سے';
  }

  @override
  String get budgetsSharedBudget => 'مشترکہ بجٹ';

  @override
  String get budgetsNoLimit => 'کوئی بجٹ نہیں';

  @override
  String get budgetsCategoriesTitle => 'زمرے';

  @override
  String budgetsFilterOverBudget(int count) {
    return 'بجٹ سے زیادہ ($count)';
  }

  @override
  String get budgetsOverBudget => 'بجٹ سے زیادہ';

  @override
  String get budgetsNearLimit => 'حد کے قریب';

  @override
  String budgetsBudgetNumber(int number) {
    return 'بجٹ $number';
  }

  @override
  String budgetsNoBudgetTitle(String month) {
    return '$month کا کوئی بجٹ نہیں';
  }

  @override
  String get budgetsNoBudgetMessage =>
      'بجٹ ویب پر حساب میں بنائے جاتے ہیں۔ اس مہینے کا بجٹ بنانے کے لیے وہاں بجٹ کھولیں۔';

  @override
  String get budgetsNotSetUpMessage =>
      'اس مہینے کے لیے ابھی خرچ کی کوئی حد مقرر نہیں۔ انہیں ویب پر حساب میں مقرر کریں۔';

  @override
  String get budgetsNoCategories => 'اس مہینے کوئی بجٹ والا زمرہ یا خرچ نہیں۔';

  @override
  String get budgetsOfflineTitle => 'آپ آف لائن ہیں';

  @override
  String get budgetsOfflineMessage =>
      'اس مہینے کا بجٹ لوڈ کرنے کے لیے انٹرنیٹ سے جڑیں۔';

  @override
  String get budgetsOfflineCached =>
      'آف لائن۔ پہلے لوڈ کیے گئے اعداد دکھائے جا رہے ہیں۔';

  @override
  String get budgetsRefreshFailed =>
      'تازہ نہیں ہو سکا۔ پہلے لوڈ کیے گئے اعداد دکھائے جا رہے ہیں۔';

  @override
  String get budgetsLoadFailed => 'بجٹ لوڈ نہیں ہو سکے';

  @override
  String get budgetsSessionExpired =>
      'آپ کا سیشن ختم ہو گیا ہے۔ براہِ کرم دوبارہ سائن ان کریں۔';

  @override
  String budgetCategoryTransactionsEmpty(String month) {
    return '$month میں اس زمرے میں کوئی لین دین نہیں۔';
  }

  @override
  String get budgetCategoryTransactionsLoadMore => 'مزید دیکھیں';

  @override
  String get budgetCategoryTransactionsLoadFailed => 'لین دین لوڈ نہیں ہو سکے';

  @override
  String get navActivity => 'سرگرمی';

  @override
  String get navStatements => 'اسٹیٹمنٹس';

  @override
  String get navAccounts => 'اکاؤنٹس';

  @override
  String get navAddExpense => 'خرچ شامل کریں';

  @override
  String get homeNoLabel => 'بغیر لیبل';

  @override
  String get homeSettings => 'ترتیبات';

  @override
  String get homeLoadFailed => 'اس مہینے کا ڈیٹا لوڈ نہیں ہو سکا۔';

  @override
  String homeSpentIn(String month) {
    return '$month میں خرچ';
  }

  @override
  String homeMoreThan(String amount, String month) {
    return '$month سے $amount زیادہ';
  }

  @override
  String homeLessThan(String amount, String month) {
    return '$month سے $amount کم';
  }

  @override
  String homeSameAs(String month) {
    return '$month جتنا';
  }

  @override
  String get homeCameIn => 'آیا';

  @override
  String get homeWentOut => 'گیا';

  @override
  String get homeLeftOver => 'بچا';

  @override
  String get homeWhereItWent => 'پیسہ کہاں گیا';

  @override
  String get homeBudget => 'بجٹ';

  @override
  String get homeNothingSpent => 'اس مہینے ابھی کوئی خرچ نہیں ہوا۔';

  @override
  String get homeNetWorth => 'کل مالیت';

  @override
  String get homeBalanceSheet => 'بیلنس شیٹ';

  @override
  String homeAssetsOwed(String assets, String owed) {
    return 'اثاثے $assets · واجب الادا $owed';
  }

  @override
  String homeNeedLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اسٹیٹمنٹ کی $count انٹریز کو لیبل چاہیے',
      one: 'اسٹیٹمنٹ کی 1 انٹری کو لیبل چاہیے',
    );
    return '$_temp0';
  }

  @override
  String homeNeedLabelDetail(String month, int sorted) {
    return '$month · $sorted پہلے ہی ترتیب شدہ';
  }

  @override
  String get activityNoLabel => 'بغیر لیبل';

  @override
  String get activitySearchHint => 'اس مہینے میں تلاش کریں';

  @override
  String get activityClearSearch => 'تلاش صاف کریں';

  @override
  String get activityOfflineNote =>
      'آف لائن۔ اس فون پر محفوظ ڈیٹا دکھایا جا رہا ہے۔';

  @override
  String get activityLoadFailedNote =>
      'سرور سے رابطہ نہیں ہو سکا۔ اس فون پر محفوظ ڈیٹا دکھایا جا رہا ہے۔';

  @override
  String get activityEmpty => 'اس مہینے یہاں کچھ نہیں۔';

  @override
  String get activityIn => 'آمد';

  @override
  String get activityOut => 'خرچ';

  @override
  String get activityEntries => 'اندراجات';

  @override
  String get activityWaitingToSync => 'سنک کا انتظار';

  @override
  String get activityWaitingToDelete => 'حذف ہو جائے گا';

  @override
  String get activityTransfer => 'منتقلی';

  @override
  String get activityHasReceipt => 'رسید موجود ہے';

  @override
  String get detailDelete => 'لین دین حذف کریں';

  @override
  String get detailMoneyIn => 'آمد';

  @override
  String get detailMoneyOut => 'خرچ';

  @override
  String get detailNote => 'نوٹ';

  @override
  String get detailNoteHint => 'نوٹ لکھیں';

  @override
  String get detailReceipt => 'رسید';

  @override
  String get detailAttachReceipt => 'منسلک کریں';

  @override
  String get detailReplaceReceipt => 'تبدیل کریں';

  @override
  String get detailNoReceipt => 'کوئی رسید منسلک نہیں۔';

  @override
  String detailMoreReceipts(int count) {
    return '+$count مزید';
  }

  @override
  String get receiptRemove => 'رسید ہٹائیں';

  @override
  String get receiptNeedsInternet => 'رسید منسلک کرنے کے لیے انٹرنیٹ سے جڑیں۔';

  @override
  String get receiptUploadFailed => 'رسید منسلک نہیں ہو سکی۔';

  @override
  String get receiptRemoveFailed => 'رسید ہٹائی نہیں جا سکی۔';

  @override
  String get receiptTakePhoto => 'تصویر لیں';

  @override
  String get receiptFromGallery => 'گیلری سے';

  @override
  String get formTypeExpense => 'خرچ';

  @override
  String get formTypeIncome => 'آمدنی';

  @override
  String get formLabel => 'لیبل';

  @override
  String get formManage => 'انتظام';

  @override
  String get formNewLabel => '+ نیا لیبل';

  @override
  String get formWhatFor => 'کس لیے';

  @override
  String get formWhatForHint => 'مثلاً Imtiaz Supermarket';

  @override
  String get formPaidFrom => 'کس سے ادا کیا';

  @override
  String get formPaidInto => 'کس میں آیا';

  @override
  String get formNoAccounts => 'ابھی کوئی اکاؤنٹ نہیں';

  @override
  String get formOptional => 'اختیاری';

  @override
  String get formReceipt => 'رسید یا اسکرین شاٹ';

  @override
  String get formSaveExpense => 'خرچ محفوظ کریں';

  @override
  String get formSaveIncome => 'آمدنی محفوظ کریں';

  @override
  String get formPickAccount => 'پہلے اکاؤنٹ منتخب کریں۔';

  @override
  String get formSaved => 'محفوظ ہو گیا';

  @override
  String get formSavedReceiptOffline =>
      'محفوظ ہو گیا۔ آپ آف لائن ہیں اس لیے رسید منسلک نہیں ہوئی۔';

  @override
  String get loginTagline => 'ہر روپیہ، مہینہ بہ مہینہ۔';

  @override
  String get loginServer => 'سرور';

  @override
  String get loginServerChange => 'تبدیل کریں';

  @override
  String get loginShowPassword => 'پاس ورڈ دکھائیں';

  @override
  String get loginNewHere => 'نئے ہیں؟ ';

  @override
  String get loginCreateAccount => 'اکاؤنٹ بنائیں';

  @override
  String get activityViewList => 'فہرست';

  @override
  String get activityViewCalendar => 'کیلنڈر';

  @override
  String get activityImportStatement => 'اسٹیٹمنٹ درآمد کریں';

  @override
  String get activityPickDay => 'ادائیگیاں دیکھنے کے لیے کسی دن پر ٹیپ کریں۔';

  @override
  String activityPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ادائیگیاں',
      one: '1 ادائیگی',
      zero: 'کوئی ادائیگی نہیں',
    );
    return '$_temp0';
  }

  @override
  String get activityNothingThisDay => 'اس دن کچھ نہیں۔';

  @override
  String get homeStatementsHint => 'بینک یا کارڈ کی اسٹیٹمنٹ شامل کریں';

  @override
  String get homeNotesForYou => 'آپ کے لیے نوٹس';

  @override
  String homeInsightAsk(String title) {
    return 'مزید بتائیں: $title';
  }

  @override
  String get assistantIntro =>
      'اپنے پیسوں کے بارے میں سادہ الفاظ میں پوچھیں۔ جواب آپ کے اپنے اندراجات سے آتے ہیں۔';

  @override
  String get assistantEarlier => 'پچھلے سوالات';

  @override
  String get assistantTryAsking => 'یہ پوچھ کر دیکھیں';

  @override
  String get assistantThinking => 'سوچ رہا ہے';

  @override
  String get assistantSend => 'بھیجیں';

  @override
  String assistantLookedUp(String subject) {
    return '$subject دیکھے';
  }

  @override
  String get chatSuggestionGroceries => 'اس مہینے ہم نے راشن پر کتنا خرچ کیا؟';

  @override
  String get chatSuggestionDay => '15 اکتوبر کو میں نے کیا ادا کیا؟';

  @override
  String get chatSuggestionBills =>
      'پچھلے مہینے کے مقابلے میں کون سے بل بڑھ گئے؟';

  @override
  String get chatSuggestionSave => 'اگلے مہینے ہم کہاں بچت کر سکتے ہیں؟';

  @override
  String get legalPrivacy => 'رازداری کی پالیسی';

  @override
  String get legalTerms => 'سروس کی شرائط';

  @override
  String get legalOpenLinkError => 'لنک نہیں کھل سکا';

  @override
  String get signUpTitle => 'اکاؤنٹ بنائیں';

  @override
  String get signUpSubtitle =>
      'اپنے گھر کے سارے خرچ ایک جگہ رکھیں۔ آپ کا اکاؤنٹ اسی سرور پر بنے گا جو سائن ان اسکرین پر دکھایا گیا ہے۔';

  @override
  String get signUpPasswordRules =>
      'کم از کم 8 حروف، جن میں بڑے اور چھوٹے حروف، ایک ہندسہ اور ایک علامت ہو۔';

  @override
  String get signUpConfirmPasswordLabel => 'پاس ورڈ کی تصدیق کریں';

  @override
  String get signUpPasswordsDoNotMatch => 'پاس ورڈ آپس میں نہیں ملتے';

  @override
  String get signUpSubmit => 'اکاؤنٹ بنائیں';

  @override
  String get signUpAgreementPrefix => 'اکاؤنٹ بنا کر آپ ان سے متفق ہیں: ';

  @override
  String get signUpAgreementAnd => ' اور ';

  @override
  String get settingsSourceCode => 'سورس کوڈ';

  @override
  String get settingsSourceCodeSubtitle =>
      'حساب، Sure پر مبنی ہے اور AGPL-3.0 کے تحت لائسنس یافتہ ہے';

  @override
  String get settingsDeleteAccountDone => 'آپ کا اکاؤنٹ حذف کر دیا گیا ہے۔';

  @override
  String get settingsDeleteAccountFinalTitle => 'اکاؤنٹ ہمیشہ کے لیے حذف کریں؟';

  @override
  String get settingsDeleteAccountFinalButton => 'میرا اکاؤنٹ حذف کریں';

  @override
  String settingsDeleteAccountFinalContent(String word) {
    return 'آپ کے اکاؤنٹس، لین دین، رسیدوں کی تصاویر، اسٹیٹمنٹس اور چیٹس حذف ہو جائیں گی۔ اگر آپ اپنے گھرانے کے آخری رکن ہیں تو پورا گھرانہ حذف ہو جائے گا۔\n\nتصدیق کے لیے $word لکھیں۔';
  }

  @override
  String get loginSignInWithPasskey => 'پاس کی سے سائن ان کریں';

  @override
  String get loginPasskeyNotFound =>
      'اس فون پر اس سرور کی کوئی پاس کی نہیں۔ اپنے پاس ورڈ سے سائن ان کریں، پھر ترتیبات میں پاس کی شامل کریں۔';

  @override
  String get loginPasskeyFailed =>
      'پاس کی سے سائن ان نہیں ہو سکا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get settingsPasskeysTitle => 'پاس کیز';

  @override
  String get settingsPasskeysSubtitle =>
      'فنگر پرنٹ یا اسکرین لاک سے سائن ان کریں';

  @override
  String get passkeysIntro =>
      'پاس کی کے ذریعے آپ پاس ورڈ کے بجائے اپنے فنگر پرنٹ، چہرے یا اسکرین لاک سے سائن ان کر سکتے ہیں۔ یہ آپ کے فون کے پاس ورڈ مینیجر میں محفوظ ہوتی ہے۔';

  @override
  String get passkeysAddHeading => 'پاس کی شامل کریں';

  @override
  String get passkeysNameLabel => 'نام';

  @override
  String get passkeysNameHint => 'مثلاً My Pixel';

  @override
  String get passkeysPasswordLabel => 'موجودہ پاس ورڈ';

  @override
  String get passkeysCodeLabel => 'تصدیقی ایپ یا بیک اپ کوڈ';

  @override
  String get passkeysAddButton => 'پاس کی شامل کریں';

  @override
  String get passkeysListHeading => 'آپ کی پاس کیز';

  @override
  String get passkeysEmpty => 'ابھی کوئی پاس کی نہیں۔ اوپر سے شامل کریں۔';

  @override
  String passkeysAdded(String date) {
    return '$date کو شامل کی گئی';
  }

  @override
  String passkeysLastUsed(String date) {
    return 'آخری استعمال $date';
  }

  @override
  String get passkeysRemove => 'ہٹائیں';

  @override
  String get passkeysRemoveTitle => 'یہ پاس کی ہٹائیں؟';

  @override
  String passkeysRemoveBody(String name) {
    return 'آپ \"$name\" سے مزید سائن ان نہیں کر سکیں گے۔ اسے اپنے فون کے پاس ورڈ مینیجر سے بھی حذف کر دیں۔';
  }

  @override
  String get passkeysAddedToast => 'پاس کی شامل ہو گئی۔';

  @override
  String get passkeysRemovedToast => 'پاس کی ہٹا دی گئی۔';

  @override
  String get passkeysUnsupported =>
      'یہ فون پاس کیز استعمال نہیں کر سکتا۔ اس کے لیے Android 11 یا نیا ورژن اور Google Play سروسز ضروری ہیں۔';

  @override
  String get passkeysNoStepUp =>
      'پاس کی شامل کرنے سے پہلے ویب پر پاس ورڈ بنائیں یا دو مرحلہ تصدیق آن کریں۔';

  @override
  String get passkeysLoadFailed =>
      'آپ کی پاس کیز لوڈ نہیں ہو سکیں۔ دوبارہ کوشش کے لیے نیچے کھینچیں۔';

  @override
  String get passkeysAddFailed => 'پاس کی شامل نہیں ہو سکی۔';

  @override
  String get passkeysRemoveFailed => 'پاس کی ہٹائی نہیں جا سکی۔';

  @override
  String get passkeysConfirmRequired =>
      'تصدیق کے لیے یہ درج کریں کہ یہ آپ ہی ہیں۔';

  @override
  String get assistantAttachTooltip => 'اسٹیٹمنٹ منسلک کریں';

  @override
  String get assistantMicTooltip =>
      'وائس نوٹ: شروع کرنے کے لیے ٹیپ کریں، یا دبا کر بولیں';

  @override
  String get assistantMicPermissionDenied =>
      'وائس نوٹ ریکارڈ کرنے کے لیے حساب کو مائیکروفون کی ضرورت ہے۔ آپ فون کی ترتیبات میں اجازت دے سکتے ہیں۔';

  @override
  String get assistantMicFailed =>
      'ریکارڈنگ شروع نہیں ہو سکی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get assistantVoiceTooShort =>
      'یہ بہت مختصر تھا۔ بولتے وقت مائیک دبائے رکھیں، یا شروع کرنے کے لیے ایک بار ٹیپ کریں۔';

  @override
  String get assistantRecordingHold =>
      'بھیجنے کے لیے چھوڑیں · منسوخ کرنے کے لیے ہٹائیں';

  @override
  String get assistantRecordingReleaseToCancel => 'منسوخ کرنے کے لیے چھوڑیں';

  @override
  String get assistantRecordingTap => 'بھیجنے کے لیے مائیک دوبارہ ٹیپ کریں';

  @override
  String get assistantRecordingCancel => 'ریکارڈنگ منسوخ کریں';

  @override
  String assistantRecordingLabel(String elapsed, String limit) {
    return 'ریکارڈنگ $elapsed از $limit';
  }

  @override
  String get assistantTranscribing => 'تحریر میں بدلا جا رہا ہے…';

  @override
  String get assistantVoiceNoteTitle => 'وائس نوٹ';

  @override
  String get assistantVoiceNoteFailed =>
      'وائس نوٹ نہیں بھیجا جا سکا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get assistantReadingStatement => 'آپ کی اسٹیٹمنٹ پڑھی جا رہی ہے…';

  @override
  String get assistantStatementSlow =>
      'اسٹیٹمنٹ میں کچھ وقت لگ رہا ہے۔ جواب دیکھنے کے لیے ایک منٹ بعد تازہ کریں پر ٹیپ کریں۔';

  @override
  String get assistantStatementFailed =>
      'اسٹیٹمنٹ نہیں بھیجی جا سکی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get assistantFileUnreadable => 'یہ فائل پڑھی نہیں جا سکی۔';

  @override
  String get assistantFileType => 'PDF یا CSV اسٹیٹمنٹ منتخب کریں۔';

  @override
  String get assistantChooseAccount => 'یہ اسٹیٹمنٹ کس اکاؤنٹ کی ہے؟';

  @override
  String get assistantNoAccounts =>
      'پہلے بینک اکاؤنٹ شامل کریں، پھر اس کی اسٹیٹمنٹ منسلک کریں۔';

  @override
  String get assistantAccountsFailed =>
      'آپ کے اکاؤنٹس لوڈ نہیں ہو سکے۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get pendingActionSave => 'محفوظ کریں';

  @override
  String get pendingActionCancel => 'منسوخ کریں';

  @override
  String get pendingActionSaved => 'محفوظ ہو گیا';

  @override
  String get pendingActionCancelled => 'منسوخ ہو گیا';

  @override
  String pendingActionSaveAll(int count) {
    return 'سب محفوظ کریں ($count)';
  }

  @override
  String get pendingActionCancelAll => 'سب منسوخ کریں';

  @override
  String pendingActionBatchTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اندراجات چیک کرنے ہیں',
      one: '1 اندراج چیک کرنا ہے',
    );
    return '$_temp0';
  }

  @override
  String get pendingActionNeedsLabel => 'لیبل درکار ہے';

  @override
  String get pendingActionDuplicate => 'پہلے سے درج ہے؟';

  @override
  String get pendingActionRemove => 'یہ قطار ہٹائیں';

  @override
  String get pendingActionToday => 'آج';

  @override
  String get pendingActionYesterday => 'کل';

  @override
  String get pendingActionSaveFailed => 'محفوظ نہیں ہو سکا۔';

  @override
  String get pendingActionRequestFailed =>
      'اپ ڈیٹ نہیں ہو سکا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get pendingActionKindAdd => 'شامل کریں';

  @override
  String get pendingActionKindUpdate => 'تبدیلی';

  @override
  String get pendingActionKindDelete => 'حذف کریں';

  @override
  String get pendingActionKindBalance => 'بیلنس مقرر کریں';

  @override
  String get pendingActionKindAccount => 'نیا اکاؤنٹ';

  @override
  String get pendingActionKindLabel => 'نیا لیبل';

  @override
  String get pendingActionKindOther => 'مجوزہ تبدیلی';

  @override
  String get reportTitle => 'رپورٹ ڈاؤن لوڈ کریں';

  @override
  String get reportHint => 'کسی بھی مدت کی PDF، رکھنے یا شیئر کرنے کے لیے';

  @override
  String get reportIntro =>
      'مدت اور شامل کیے جانے والے لیبل منتخب کریں۔ حساب کل رقوم اور ہر اندراج کے ساتھ PDF بنا دیتا ہے، جسے آپ محفوظ کر سکتے ہیں یا بھیج سکتے ہیں۔';

  @override
  String get reportPeriod => 'مدت';

  @override
  String get reportThisMonth => 'اس مہینے';

  @override
  String get reportLastMonth => 'پچھلے مہینے';

  @override
  String get reportLast3Months => 'پچھلے 3 مہینے';

  @override
  String get reportCustom => 'اپنی مرضی کی';

  @override
  String get reportLabels => 'لیبل';

  @override
  String get reportAllLabels => 'تمام لیبل';

  @override
  String get reportUnlabelled => 'بغیر لیبل';

  @override
  String get reportAccounts => 'اکاؤنٹس';

  @override
  String get reportAllAccounts => 'تمام اکاؤنٹس';

  @override
  String get reportDownload => 'PDF بنائیں اور شیئر کریں';

  @override
  String get reportPickLabel => 'کم از کم ایک لیبل منتخب کریں۔';

  @override
  String get reportPickAccount => 'کم از کم ایک اکاؤنٹ منتخب کریں۔';

  @override
  String get reportTooLong => 'رپورٹ زیادہ سے زیادہ 24 مہینوں کی ہو سکتی ہے۔';

  @override
  String get reportFailed => 'رپورٹ نہیں بن سکی۔ دوبارہ کوشش کریں۔';

  @override
  String get reportOffline =>
      'سرور سے رابطہ نہیں ہو سکا۔ اپنا کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String reportSaved(String filename) {
    return '$filename کے نام سے محفوظ ہو گئی';
  }

  @override
  String get settingsLanguageLabel => 'زبان · Language';

  @override
  String get settingsLanguageSystem => 'سسٹم';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageUrdu => 'اردو';

  @override
  String get commonBack => 'واپس';

  @override
  String get commonKeep => 'رہنے دیں';

  @override
  String get commonSignInAgain => 'براہِ کرم دوبارہ سائن ان کریں۔';

  @override
  String commonDeleteNamed(String name) {
    return '\"$name\" حذف کریں؟';
  }

  @override
  String get accountKindBank => 'بینک اکاؤنٹ';

  @override
  String get accountKindBankHint =>
      'کرنٹ اکاؤنٹ جس سے آپ خرچ کرتے ہیں، مثلاً HBL، Meezan';

  @override
  String get accountKindSavings => 'سیونگز اکاؤنٹ';

  @override
  String get accountKindSavingsHint => 'بینک میں الگ رکھی ہوئی رقم';

  @override
  String get accountKindCash => 'نقد رقم';

  @override
  String get accountKindCashHint => 'پرس میں یا گھر پر رکھی رقم';

  @override
  String get accountKindCreditCard => 'کریڈٹ کارڈ';

  @override
  String get accountKindCreditCardHint => 'کارڈ پر آپ کے ذمے رقم';

  @override
  String get accountKindLoan => 'قرض / واجب الادا رقم';

  @override
  String get accountKindLoanHint => 'بینک، کسی رشتے دار یا دکان کا آپ پر قرض';

  @override
  String get accountKindAssets => 'سونا اور بچت سرٹیفکیٹ';

  @override
  String get accountKindAssetsHint => 'سونا، پرائز بانڈ، قومی بچت';

  @override
  String get accountFormNameRequired => 'اکاؤنٹ کا نام لکھیں۔';

  @override
  String get accountFormBalanceNegative => 'رقم مائنس کے نشان کے بغیر لکھیں۔';

  @override
  String get accountFormBalanceInvalid => 'کوئی عدد لکھیں، جیسے 25,000۔';

  @override
  String get accountFormKindRequired => 'منتخب کریں کہ یہ کس قسم کا اکاؤنٹ ہے۔';

  @override
  String get accountFormSaveFailed => 'اکاؤنٹ محفوظ نہیں ہو سکا۔';

  @override
  String get accountFormDeleteBody =>
      'اس اکاؤنٹ میں درج سب کچھ بھی حذف ہو جائے گا۔ یہ عمل واپس نہیں ہو سکتا۔';

  @override
  String get accountFormDeleteFailed => 'اکاؤنٹ حذف نہیں ہو سکا۔';

  @override
  String get accountFormEditTitle => 'اکاؤنٹ میں ترمیم کریں';

  @override
  String get accountFormAddTitle => 'اکاؤنٹ شامل کریں';

  @override
  String get accountFormKindHeader => 'کس قسم کا اکاؤنٹ؟';

  @override
  String get accountFormNameHint => 'مثلاً Meezan Bank، نقد رقم';

  @override
  String get accountFormOwedLabel => 'کتنی رقم واجب الادا ہے؟';

  @override
  String get accountFormBalanceLabel => 'اس میں ابھی کتنی رقم ہے؟';

  @override
  String get accountFormBalanceEditHelp =>
      'اسے اپنے بینک یا پرس میں آج کی رقم کے مطابق کر دیں۔';

  @override
  String get accountFormBalanceNewHelp =>
      'اگر یقین نہیں تو خالی چھوڑ دیں۔ آپ اسے بعد میں بدل سکتے ہیں۔';

  @override
  String get accountFormDeleteButton => 'اکاؤنٹ حذف کریں';

  @override
  String get accountsLoadFailed =>
      'آپ کے اکاؤنٹس لوڈ نہیں ہو سکے۔ دوبارہ کوشش کے لیے نیچے کھینچیں۔';

  @override
  String get accountsGroupBank => 'بینک';

  @override
  String get accountsGroupCards => 'کارڈز';

  @override
  String get accountsGroupLoans => 'قرضے';

  @override
  String get accountsGroupOtherOwed => 'دیگر واجب الادا رقم';

  @override
  String get accountsGroupProperty => 'جائیداد';

  @override
  String get accountsGroupSavings => 'بچت اور سونا';

  @override
  String get accountsAddStatement => 'اسٹیٹمنٹ شامل کریں';

  @override
  String get accountsAdd => '+ شامل کریں';

  @override
  String get accountsNothingOwed => 'کوئی رقم واجب الادا نہیں۔';

  @override
  String get accountsEmpty => 'ابھی کوئی اکاؤنٹ نہیں۔';

  @override
  String get accountsWhatWeHave => 'ہمارے پاس کیا ہے';

  @override
  String get accountsWhatWeOwe => 'ہم پر کیا واجب ہے';

  @override
  String get accountsEdit => 'ترمیم کریں';

  @override
  String get labelsTitle => 'لیبلز';

  @override
  String get labelsLoadFailed =>
      'آپ کے لیبلز لوڈ نہیں ہو سکے۔ دوبارہ کوشش کے لیے نیچے کھینچیں۔';

  @override
  String get labelsNameRequired => 'لیبل کا نام لکھیں۔';

  @override
  String get labelsAddFailed => 'لیبل شامل نہیں ہو سکا۔';

  @override
  String labelsAdded(String name) {
    return '\"$name\" شامل ہو گیا۔';
  }

  @override
  String labelsAddedKeywordsFailed(String name) {
    return '\"$name\" شامل ہو گیا، لیکن کچھ کی ورڈز محفوظ نہیں ہو سکے۔';
  }

  @override
  String get labelsNewLabel => 'نیا لیبل';

  @override
  String get labelsNameHint => 'مثلاً کمیٹی، دودھ والا';

  @override
  String get labelsKeywordsLabel =>
      'اسٹیٹمنٹ کی وہ لائنیں خود لیبل کریں جن میں یہ ہو';

  @override
  String get labelsKeywordsHint => 'مثلاً ASLAM, DOODH';

  @override
  String get labelsAddButton => 'لیبل شامل کریں';

  @override
  String get labelsYourLabels => 'آپ کے لیبلز';

  @override
  String get labelsUsesThisMonth => 'اس مہینے استعمال';

  @override
  String get labelsEmpty => 'ابھی کوئی لیبل نہیں۔ اوپر سے شامل کریں۔';

  @override
  String get labelsNoAutoRule => 'کوئی خودکار اصول نہیں';

  @override
  String labelsAutoKeywords(String keywords) {
    return 'خودکار: $keywords';
  }

  @override
  String get labelsSaveFailed => 'لیبل محفوظ نہیں ہو سکا۔';

  @override
  String labelsKeywordRemoveFailed(String keyword) {
    return '$keyword ہٹایا نہیں جا سکا۔';
  }

  @override
  String labelsKeywordAddFailed(String keyword) {
    return '$keyword شامل نہیں ہو سکا۔';
  }

  @override
  String get labelsDeleteBody =>
      'اس لیبل والی لائنیں بغیر لیبل کے ہو جائیں گی۔ اس کے خودکار کی ورڈز کام کرنا بند کر دیں گے۔';

  @override
  String get labelsDeleteFailed => 'لیبل حذف نہیں ہو سکا۔';

  @override
  String get labelsEditTitle => 'لیبل میں ترمیم کریں';

  @override
  String get labelsKeywordsEditHint =>
      'کاما سے الگ کریں، مثلاً K-ELECTRIC, SSGC';

  @override
  String get labelsDeleteButton => 'لیبل حذف کریں';

  @override
  String get statementsIntro =>
      'بینک اسٹیٹمنٹ شامل کریں۔ حساب ہر لائن پڑھتا ہے، اسے صحیح مہینے میں درج کرتا ہے اور لیبل تجویز کرتا ہے۔';

  @override
  String get statementsUploadFailed => 'اپ لوڈ نہیں ہو سکا۔';

  @override
  String get statementsPublishFailed => 'لائنیں شامل نہیں ہو سکیں۔';

  @override
  String get statementsChooseFile => 'اسٹیٹمنٹ فائل منتخب کریں';

  @override
  String get statementsUploading => 'اپ لوڈ ہو رہی ہے…';

  @override
  String get statementsFileHint =>
      'PDF یا CSV · ایک فائل میں زیادہ سے زیادہ 6 مہینے';

  @override
  String get statementsAccountFallback => 'اکاؤنٹ';

  @override
  String statementsCoverageTitle(String name) {
    return '$name · پچھلے 6 مہینے';
  }

  @override
  String get statementsCheckingMonths => 'مہینے دیکھے جا رہے ہیں…';

  @override
  String get statementsLegendAllLabelled => 'سب پر لیبل';

  @override
  String get statementsLegendNeedsLabels => 'لیبل درکار';

  @override
  String get statementsLegendNoStatement => 'کوئی اسٹیٹمنٹ نہیں';

  @override
  String statementsMonthLeft(int count) {
    return '$count باقی';
  }

  @override
  String get statementsPdfStatement => 'PDF اسٹیٹمنٹ';

  @override
  String get statementsCsvStatement => 'CSV اسٹیٹمنٹ';

  @override
  String get statementsReadFailed =>
      'حساب یہ اسٹیٹمنٹ نہیں پڑھ سکا۔ کوئی اور فائل آزمائیں۔';

  @override
  String get statementsAddingLines => 'لائنیں آپ کے حساب میں شامل ہو رہی ہیں…';

  @override
  String get statementsReading =>
      'حساب ہر لائن پڑھ رہا ہے۔ اس میں ایک منٹ لگ سکتا ہے۔';

  @override
  String get statementsLinesFound => 'لائنیں ملیں';

  @override
  String get statementsNeedsColumnMapping =>
      'لائنیں شامل کرنے سے پہلے اس فائل کے کالم حساب کی ویب سائٹ پر ملانے ہوں گے۔';

  @override
  String statementsAddLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'یہ $count لائنیں شامل کریں',
      one: 'یہ 1 لائن شامل کریں',
    );
    return '$_temp0';
  }

  @override
  String get statementsAutoLabelled => 'خود لیبل ہوئیں';

  @override
  String get statementsNeedYou => 'آپ کی منتظر';

  @override
  String statementsLabelItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count انٹریز کو لیبل کریں',
      one: '1 انٹری کو لیبل کریں',
    );
    return '$_temp0';
  }

  @override
  String get statementsAllLabelled => 'سب پر لیبل لگ چکا ہے۔';

  @override
  String get statementsStatusFailed => 'ناکام';

  @override
  String get statementsStatusAdded => 'شامل ہو گئی';

  @override
  String get statementsStatusAdding => 'شامل ہو رہی ہے…';

  @override
  String get statementsStatusReading => 'پڑھی جا رہی ہے…';

  @override
  String get statementsStatusRead => 'پڑھ لی گئی';

  @override
  String get statementsStatusWaiting => 'انتظار…';

  @override
  String get statementsRecent => 'حالیہ اسٹیٹمنٹس';

  @override
  String get statementsStatementFallback => 'اسٹیٹمنٹ';

  @override
  String statementsAddedOn(String date) {
    return '$date کو شامل کی گئی';
  }

  @override
  String statementsLinesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لائنیں',
      one: '1 لائن',
    );
    return '$_temp0';
  }

  @override
  String get statementReviewLoadFailed =>
      'اسٹیٹمنٹ کی لائنیں لوڈ نہیں ہو سکیں۔';

  @override
  String statementReviewKeywordFailed(String error) {
    return 'یہ لائن لیبل ہو گئی۔ کی ورڈ محفوظ نہیں ہوا: $error';
  }

  @override
  String get statementReviewUnknownError => 'نامعلوم خرابی';

  @override
  String get statementReviewNothingToLabel =>
      'لیبل کرنے کو کچھ نہیں۔ ہر لائن پر لیبل ہے۔';

  @override
  String get statementReviewAllDone => 'سب ہو گیا۔ ہر لائن پر لیبل ہے۔';

  @override
  String get statementReviewDoneForNow => 'ابھی کے لیے بس';

  @override
  String statementReviewPosition(int position, int total) {
    return '$total میں سے $position';
  }

  @override
  String get statementReviewWhereFrom => 'یہ رقم کہاں سے آئی؟';

  @override
  String get statementReviewWhatWasThis => 'یہ کس چیز کا تھا؟';

  @override
  String get statementReviewNotExpense => 'یہ خرچ نہیں';

  @override
  String get statementReviewNewLabel => '+ نیا لیبل بنائیں';

  @override
  String statementReviewLabelAllSimilar(int count) {
    return 'ایسی تمام $count لائنیں لیبل کریں';
  }

  @override
  String get statementReviewAutoLabelFuture =>
      'آئندہ ایسی لائنیں خود لیبل کریں';

  @override
  String get statementReviewLinesContaining => 'جن لائنوں میں ہو';

  @override
  String get statementReviewSkip => 'چھوڑیں';

  @override
  String get statementReviewSaveNext => 'محفوظ کریں، اگلی';

  @override
  String get budgetsScreenTitle => 'بجٹ';

  @override
  String budgetsOverByNote(String amount) {
    return '$amount زیادہ خرچ ہو گیا۔';
  }

  @override
  String budgetsLeftForDays(String amount, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'آخری $days دنوں',
      one: 'آخری 1 دن',
    );
    return '$_temp0 کے لیے $amount باقی۔ نیلی لکیر آج کا دن ہے۔';
  }

  @override
  String budgetsLeftNote(String amount) {
    return '$amount باقی۔';
  }

  @override
  String budgetsSpentOfPlanned(String amount) {
    return '$amount کے منصوبے میں سے خرچ';
  }

  @override
  String get budgetsSpent => 'خرچ';

  @override
  String budgetsDayOf(int day, int days) {
    return '$days میں سے دن $day';
  }

  @override
  String get budgetsNoLimitSet => 'کوئی حد مقرر نہیں';

  @override
  String budgetsOverByLine(String amount) {
    return '$amount زیادہ';
  }

  @override
  String get noAccountsTitle => 'اپنا پہلا اکاؤنٹ شامل کریں';

  @override
  String get noAccountsBody =>
      'اکاؤنٹ وہ جگہ ہے جہاں سے رقم دی جاتی ہے اور جہاں آتی ہے۔ پہلے \"نقد رقم\" سے شروع کریں، پھر اپنا بینک اکاؤنٹ شامل کریں۔';

  @override
  String get upgradeTitle => 'اپ ڈیٹ دستیاب ہے';

  @override
  String upgradeBody(
      String appName, String storeVersion, String installedVersion) {
    return '$appName $storeVersion اب دستیاب ہے — آپ کے پاس $installedVersion ہے۔\n\nنیا کیا ہے؟ ریلیز نوٹس کے لیے اسٹور دیکھیں۔';
  }

  @override
  String get upgradeNow => 'ابھی اپ ڈیٹ کریں';

  @override
  String get upgradeLater => 'بعد میں';

  @override
  String get swatchInk => 'سیاہ';

  @override
  String get swatchCobalt => 'گہرا نیلا';

  @override
  String get swatchAmber => 'عنبری';

  @override
  String get swatchOlive => 'زیتونی';

  @override
  String get swatchPlum => 'جامنی';

  @override
  String get swatchSteel => 'فولادی نیلا';

  @override
  String get swatchStone => 'سرمئی';

  @override
  String get transactionFormAddFirstAccount => '+ اکاؤنٹ شامل کریں';

  @override
  String get transactionFormNewAccountOption => '+ نیا اکاؤنٹ';
}
