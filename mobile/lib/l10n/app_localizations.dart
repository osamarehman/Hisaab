import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sv'),
    Locale('ur')
  ];

  /// Application title shown in the OS task switcher.
  ///
  /// In en, this message translates to:
  /// **'Hisaab'**
  String get appTitle;

  /// Generic cancel action label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic save/confirm action label.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Generic retry action label.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get commonTryAgain;

  /// Generic delete action label.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Label for the 'All' filter chip (currency filter, category filter, etc.).
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// Generic refresh action label.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// Generic close/dismiss action label.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Generic undo action label.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// Label for the email text field on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// Validation error when email field is empty.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get loginEmailRequired;

  /// Validation error when email format is invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get loginEmailInvalid;

  /// Label for the password field on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// Validation error when password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get loginPasswordRequired;

  /// Primary sign-in button label.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignIn;

  /// Google SSO button label.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginSignInWithGoogle;

  /// Label for the MFA code input field.
  ///
  /// In en, this message translates to:
  /// **'Authentication Code'**
  String get loginMfaLabel;

  /// Bottom navigation label for the Home (dashboard) tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label for the Intro tab.
  ///
  /// In en, this message translates to:
  /// **'Intro'**
  String get navIntro;

  /// Bottom navigation label for the AI assistant tab.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get navAssistant;

  /// Bottom navigation label for the More tab.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// Snackbar message when a sync attempt fails.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get dashboardSyncError;

  /// Snackbar message when a sync attempt fails with retry instruction.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Please try again.'**
  String get dashboardSyncFailed;

  /// Snackbar message while accounts are being refreshed after a transaction.
  ///
  /// In en, this message translates to:
  /// **'Refreshing accounts…'**
  String get dashboardRefreshing;

  /// Snackbar message shown after accounts refresh completes.
  ///
  /// In en, this message translates to:
  /// **'Accounts updated'**
  String get dashboardAccountsUpdated;

  /// Snackbar message while sync is in progress.
  ///
  /// In en, this message translates to:
  /// **'Syncing data from server…'**
  String get dashboardSyncing;

  /// Label shown in the sync status indicator after a successful sync.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get dashboardSynced;

  /// Error state message when accounts fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load accounts'**
  String get dashboardErrorLoadingAccounts;

  /// Empty state message when no accounts exist.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get dashboardNoAccounts;

  /// Empty state subtitle when no accounts exist.
  ///
  /// In en, this message translates to:
  /// **'Add accounts in the web app to see them here.'**
  String get dashboardNoAccountsSubtitle;

  /// Empty state when the active account filter returns no results.
  ///
  /// In en, this message translates to:
  /// **'No accounts match the current filter'**
  String get dashboardFilterEmpty;

  /// FAB tooltip for creating a new chat.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get chatListNewChat;

  /// Empty-state subtitle on the chat list screen.
  ///
  /// In en, this message translates to:
  /// **'Nothing asked yet. Your questions will show here.'**
  String get chatListEmptySubtitle;

  /// Title for the delete-chat confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get chatListDeleteTitle;

  /// Placeholder title for a new conversation before it is saved.
  ///
  /// In en, this message translates to:
  /// **'New question'**
  String get chatConversationNewTitle;

  /// Hint text inside the chat message input field.
  ///
  /// In en, this message translates to:
  /// **'Ask about your money…'**
  String get chatConversationMessageHint;

  /// Greeting shown in a new conversation when the user's first name is known.
  ///
  /// In en, this message translates to:
  /// **'Hi {firstName}, how can I help?'**
  String chatConversationGreetingWithName(String firstName);

  /// Greeting shown in a new conversation when the user's first name is not available.
  ///
  /// In en, this message translates to:
  /// **'Hi there, how can I help?'**
  String get chatConversationGreetingNoName;

  /// App bar title for the new-transaction form.
  ///
  /// In en, this message translates to:
  /// **'New Transaction'**
  String get transactionFormNewTitle;

  /// Label for the transaction type segmented control.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get transactionFormTypeLabel;

  /// Segment label for an expense transaction.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionFormTypeExpense;

  /// Segment label for an income transaction.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionFormTypeIncome;

  /// Label for the amount input field.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionFormAmountLabel;

  /// Validation error when amount is empty.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get transactionFormAmountRequired;

  /// Validation error when amount is not a number.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get transactionFormAmountInvalid;

  /// Label for the date picker field.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionFormDateLabel;

  /// Label for the transaction name/payee field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get transactionFormNameLabel;

  /// Label for the category picker field.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionFormCategoryLabel;

  /// App bar title for the edit-transaction screen.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get transactionEditTitle;

  /// Label for the name field in the edit form.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get transactionEditNameLabel;

  /// Validation error when name is empty in edit form.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get transactionEditNameRequired;

  /// Label for the notes field in the edit form.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get transactionEditNotesLabel;

  /// Label for the category field in the edit form.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionEditCategoryLabel;

  /// Label for the merchant field in the edit form.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get transactionEditMerchantLabel;

  /// Label for the tags field in the edit form.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get transactionEditTagsLabel;

  /// In-progress label shown on the save button while saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get transactionEditSaving;

  /// Title for the single-transaction delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get transactionsListDeleteTitle;

  /// Body of the delete confirmation dialog for a named transaction.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String transactionsListDeleteSingleContent(String name);

  /// Title for the multi-transaction delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete Transactions'**
  String get transactionsListDeleteMultiTitle;

  /// Body of the multi-transaction delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected transactions?'**
  String get transactionsListDeleteMultiContent;

  /// Empty-state message when no transactions exist.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get transactionsListEmpty;

  /// Snackbar message when the API returns an auth failure.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed: Please log in again'**
  String get transactionsListAuthFailed;

  /// Empty-state heading when an account has no transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get transactionsListNoTransactionsYet;

  /// Empty-state subtitle prompting the user to add their first transaction.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first transaction'**
  String get transactionsListEmptyAddFirst;

  /// Empty state shown when category filter returns no transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions match this category'**
  String get transactionsListNoCategoryMatch;

  /// Button label on the transactions error state.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get transactionsListRetry;

  /// Snackbar after a single transaction is deleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionsListDeletedSuccess;

  /// Snackbar when deleting a single transaction fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete transaction'**
  String get transactionsListSingleDeleteFailed;

  /// Snackbar message after multiple transactions are deleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Deleted {count} transaction} other{Deleted {count} transactions}}'**
  String transactionsListDeletedMulti(int count);

  /// Snackbar when multi-delete fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete transactions'**
  String get transactionsListDeleteFailed;

  /// Snackbar when delete fails due to missing token.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: No access token'**
  String get transactionsListDeleteNoToken;

  /// Title for the undo-transaction dialog.
  ///
  /// In en, this message translates to:
  /// **'Undo Transaction'**
  String get transactionsListUndoTitle;

  /// Confirmation question for removing a pending transaction.
  ///
  /// In en, this message translates to:
  /// **'Remove this pending transaction?'**
  String get transactionsListUndoRemovePending;

  /// Confirmation question for restoring a transaction.
  ///
  /// In en, this message translates to:
  /// **'Restore this transaction?'**
  String get transactionsListUndoRestoreConfirm;

  /// Snackbar after a pending transaction is removed.
  ///
  /// In en, this message translates to:
  /// **'Pending transaction removed'**
  String get transactionsListUndoPendingRemoved;

  /// Snackbar after a transaction is restored.
  ///
  /// In en, this message translates to:
  /// **'Transaction restored'**
  String get transactionsListUndoRestored;

  /// Snackbar when undoing a transaction fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to undo transaction'**
  String get transactionsListUndoFailed;

  /// Settings section header for display/appearance options.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsSectionDisplay;

  /// Settings section header for server/connection options.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsSectionConnection;

  /// Settings section header for data import/export options.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get settingsSectionDataManagement;

  /// Settings section header for security options.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSectionSecurity;

  /// Settings section header for destructive actions.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get settingsSectionDangerZone;

  /// Label for the theme picker setting.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeLabel;

  /// Theme option: follow system setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Theme option: light mode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Theme option: dark mode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Label for the custom proxy headers setting.
  ///
  /// In en, this message translates to:
  /// **'Custom Proxy Headers'**
  String get settingsProxyHeadersLabel;

  /// Label for the toggle that masks monetary amounts across the app.
  ///
  /// In en, this message translates to:
  /// **'Hide amounts'**
  String get settingsPrivacyHideAmountsLabel;

  /// Subtitle describing the hide-amounts toggle.
  ///
  /// In en, this message translates to:
  /// **'Mask money values across the app'**
  String get settingsPrivacyHideAmountsContent;

  /// Label for the biometric lock toggle.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get settingsBiometricLabel;

  /// Title of the dialog to enable biometric lock.
  ///
  /// In en, this message translates to:
  /// **'Enable biometric lock?'**
  String get settingsBiometricEnable;

  /// Body text of the enable-biometric dialog.
  ///
  /// In en, this message translates to:
  /// **'Require biometric authentication when resuming the app.'**
  String get settingsBiometricEnableContent;

  /// Label for the check-for-updates action.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get settingsCheckForUpdates;

  /// Title for the update-available dialog.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get settingsUpdateAvailableTitle;

  /// Body text for the update-available dialog.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available. Update now?'**
  String settingsUpdateAvailableContent(String version);

  /// Fallback used in the update-available dialog when the store version number is unknown (e.g. 'Version a newer version is available').
  ///
  /// In en, this message translates to:
  /// **'a newer version'**
  String get settingsUpdateNewerVersionFallback;

  /// Confirm button in the update-available dialog.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get settingsUpdateNow;

  /// Snackbar when no update is available.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version.'**
  String get settingsNoUpdateAvailable;

  /// Snackbar when the update check fails.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates.'**
  String get settingsUpdateError;

  /// Title for the clear-all-data confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get settingsClearDataTitle;

  /// Body text for the clear-all-data dialog.
  ///
  /// In en, this message translates to:
  /// **'This will remove all locally cached data. Your data on the server will not be affected.'**
  String get settingsClearDataContent;

  /// Confirm button in the clear-data dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get settingsClearData;

  /// Snackbar after local data is cleared.
  ///
  /// In en, this message translates to:
  /// **'Local data cleared'**
  String get settingsClearDataSuccess;

  /// Title for the delete-account confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccountTitle;

  /// Confirm button in the delete-account dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccount;

  /// Title for the sign-out confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOutTitle;

  /// Body text for the sign-out dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get settingsSignOutContent;

  /// Confirm button in the sign-out dialog and settings list tile label.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// Label for the debug logs navigation tile.
  ///
  /// In en, this message translates to:
  /// **'Debug Logs'**
  String get settingsDebugLogs;

  /// App bar title for the SSO onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Link Your Account'**
  String get ssoOnboardingTitle;

  /// Tab label for linking an existing Hisaab account via SSO.
  ///
  /// In en, this message translates to:
  /// **'Link existing'**
  String get ssoOnboardingTabLink;

  /// Tab label for creating a new Hisaab account via SSO.
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get ssoOnboardingTabCreate;

  /// Label for the first-name field on the SSO onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get ssoOnboardingFirstNameLabel;

  /// Label for the last-name field on the SSO onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get ssoOnboardingLastNameLabel;

  /// Button label to link an existing account.
  ///
  /// In en, this message translates to:
  /// **'Link Account'**
  String get ssoOnboardingLinkButton;

  /// Button label to create a new account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get ssoOnboardingCreateButton;

  /// Tab and submit button label when the user has a pending household invitation to accept.
  ///
  /// In en, this message translates to:
  /// **'Accept Invitation'**
  String get ssoOnboardingAcceptInvitation;

  /// Menu item title for Recent Transactions in the More screen.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get moreRecentTransactions;

  /// Subtitle for the Recent Transactions menu item.
  ///
  /// In en, this message translates to:
  /// **'View recent transactions across all accounts'**
  String get moreRecentTransactionsSubtitle;

  /// Heading shown on the biometric lock screen.
  ///
  /// In en, this message translates to:
  /// **'App Locked'**
  String get biometricTitle;

  /// Subtitle shown on the biometric lock screen.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to continue'**
  String get biometricSubtitle;

  /// Button label when biometric prompt is ready.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get biometricUnlock;

  /// Button label while the biometric prompt is in progress.
  ///
  /// In en, this message translates to:
  /// **'Authenticating…'**
  String get biometricAuthenticating;

  /// Button to log out from the biometric lock screen.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get biometricLogOut;

  /// Headline on the backend configuration screen.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get backendConfigTitle;

  /// Subtitle below the headline on the backend configuration screen.
  ///
  /// In en, this message translates to:
  /// **'Update your Hisaab server URL'**
  String get backendConfigSubtitle;

  /// Label for the example URLs info box on the config screen.
  ///
  /// In en, this message translates to:
  /// **'Example URLs'**
  String get backendConfigExampleUrlsLabel;

  /// Label for the server URL field on the config screen.
  ///
  /// In en, this message translates to:
  /// **'Hisaab server URL'**
  String get backendConfigUrlLabel;

  /// Hint text for the server URL field.
  ///
  /// In en, this message translates to:
  /// **'https://app.sure.am'**
  String get backendConfigUrlHint;

  /// Label for the custom proxy headers section on the config screen.
  ///
  /// In en, this message translates to:
  /// **'Custom proxy headers'**
  String get backendConfigProxyHeadersLabel;

  /// Subtitle for the proxy headers expansion tile when no headers are configured.
  ///
  /// In en, this message translates to:
  /// **'Optional headers for a reverse proxy or auth gateway'**
  String get backendConfigProxyHeadersSubtitle;

  /// Subtitle for the proxy headers expansion tile when headers are configured.
  ///
  /// In en, this message translates to:
  /// **'{count} configured'**
  String backendConfigProxyHeadersCount(int count);

  /// Label on the test-connection button while the test is in progress.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get backendConfigTesting;

  /// Button label to test the server connection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get backendConfigTestButton;

  /// Button label to proceed after saving configuration.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get backendConfigContinueButton;

  /// Helper text below the config form.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in the settings.'**
  String get backendConfigChangeHint;

  /// App bar title for the recent transactions screen.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactionsTitle;

  /// Empty-state message on the recent transactions screen.
  ///
  /// In en, this message translates to:
  /// **'No Transactions'**
  String get recentTransactionsEmpty;

  /// Tooltip for the display-limit popup menu on the recent transactions screen.
  ///
  /// In en, this message translates to:
  /// **'Display Limit'**
  String get recentTransactionsDisplayLimit;

  /// Menu item label to show N recent transactions.
  ///
  /// In en, this message translates to:
  /// **'Show {count}'**
  String recentTransactionsShowN(int count);

  /// Empty-state subtitle prompting the user to pull to refresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get recentTransactionsPullToRefresh;

  /// App bar title for the log viewer screen.
  ///
  /// In en, this message translates to:
  /// **'Debug Logs'**
  String get logViewerTitle;

  /// Log level filter chip: show all log entries.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get logViewerFilterAll;

  /// Log level filter chip: show info entries only.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get logViewerFilterInfo;

  /// Log level filter chip: show warning entries only.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get logViewerFilterWarning;

  /// Log level filter chip: show error entries only.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get logViewerFilterError;

  /// Log level filter chip: show debug entries only.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get logViewerFilterDebug;

  /// Tooltip for the auto-scroll toggle button when auto-scroll is off.
  ///
  /// In en, this message translates to:
  /// **'Enable auto-scroll'**
  String get logViewerAutoScrollEnable;

  /// Tooltip for the auto-scroll toggle button when auto-scroll is on.
  ///
  /// In en, this message translates to:
  /// **'Disable auto-scroll'**
  String get logViewerAutoScrollDisable;

  /// Tooltip for the copy-logs action button.
  ///
  /// In en, this message translates to:
  /// **'Copy logs'**
  String get logViewerCopyLogs;

  /// Tooltip for the clear-logs action button.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get logViewerClearLogs;

  /// Snackbar message after logs are copied to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard'**
  String get logViewerLogsCopied;

  /// Empty-state message shown when there are no log entries to display.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get logViewerEmpty;

  /// Message shown in the connectivity banner when the device has no network.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get connectivityOffline;

  /// Connectivity banner message showing how many transactions are queued for sync.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} transaction pending sync} other{{count} transactions pending sync}}'**
  String connectivityPendingSync(int count);

  /// Button label in the connectivity banner to trigger an immediate sync.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get connectivitySyncNow;

  /// Button label to add a new custom proxy header.
  ///
  /// In en, this message translates to:
  /// **'Add header'**
  String get proxyHeadersAddHeader;

  /// Label for the header-name input field.
  ///
  /// In en, this message translates to:
  /// **'Header name'**
  String get proxyHeadersNameLabel;

  /// Hint text for the header-name input (example header name).
  ///
  /// In en, this message translates to:
  /// **'X-Auth-Token'**
  String get proxyHeadersNameHint;

  /// Label for the header-value input field.
  ///
  /// In en, this message translates to:
  /// **'Header value'**
  String get proxyHeadersValueLabel;

  /// Tooltip for the remove-header icon button.
  ///
  /// In en, this message translates to:
  /// **'Remove header'**
  String get proxyHeadersRemove;

  /// Tooltip for the refresh button on the account detail header.
  ///
  /// In en, this message translates to:
  /// **'Refresh account details'**
  String get accountDetailRefreshTooltip;

  /// Section heading for the balance history chart in the account detail header.
  ///
  /// In en, this message translates to:
  /// **'Recent balance history'**
  String get accountDetailRecentBalanceHistory;

  /// Section heading for the top holdings list in the account detail header.
  ///
  /// In en, this message translates to:
  /// **'Top holdings'**
  String get accountDetailTopHoldings;

  /// Fallback label when a holding has no name.
  ///
  /// In en, this message translates to:
  /// **'Holding'**
  String get accountDetailHoldingFallback;

  /// Label for the cash position chip in the account detail header.
  ///
  /// In en, this message translates to:
  /// **'Cash {amount}'**
  String accountDetailCashChip(String amount);

  /// Snackbar shown on the biometric lock screen when authentication fails.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Tap Unlock to try again.'**
  String get biometricLockFailedRetry;

  /// Reason shown in the system biometric prompt when enabling app lock from settings.
  ///
  /// In en, this message translates to:
  /// **'Verify biometric to enable app lock'**
  String get settingsBiometricVerifyReason;

  /// Snackbar shown when biometric verification fails while enabling app lock.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed.'**
  String get settingsBiometricFailed;

  /// Snackbar shown when the app store update link cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Unable to open store link'**
  String get settingsUpdateOpenStoreError;

  /// Snackbar shown when clearing local data fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear local data.'**
  String get settingsClearDataFailed;

  /// Snackbar shown after local data is cleared, prompting the user to pull to refresh.
  ///
  /// In en, this message translates to:
  /// **'Local data cleared successfully. Pull to refresh to sync from server.'**
  String get settingsClearDataSuccessDetailed;

  /// Snackbar shown when the contact/Discord link cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Unable to open link'**
  String get settingsContactOpenLinkError;

  /// Body text for the reset-account confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Resetting your account will delete all your accounts, categories, merchants, tags, and other data, but keep your user account intact.\n\nThis action cannot be undone. Are you sure?'**
  String get settingsResetAccountContent;

  /// Title and confirm button label for the reset-account action.
  ///
  /// In en, this message translates to:
  /// **'Reset Account'**
  String get settingsResetAccount;

  /// Snackbar shown after an account reset is initiated.
  ///
  /// In en, this message translates to:
  /// **'Account reset has been initiated. This may take a moment.'**
  String get settingsResetAccountInitiated;

  /// Snackbar shown when resetting the account fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset account'**
  String get settingsResetAccountFailed;

  /// Body text for the delete-account confirmation dialog on the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account will permanently remove all your data and cannot be undone.\n\nAre you sure you want to delete your account?'**
  String get settingsDeleteAccountConfirmContent;

  /// Snackbar shown when deleting the account fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get settingsDeleteAccountFailed;

  /// Explanatory note shown in the custom proxy headers dialog.
  ///
  /// In en, this message translates to:
  /// **'Headers are sent by the app with API requests. External browser SSO pages may not receive them.'**
  String get settingsProxyHeadersNote;

  /// Snackbar shown after custom proxy headers are saved.
  ///
  /// In en, this message translates to:
  /// **'Custom proxy headers saved'**
  String get settingsProxyHeadersSaved;

  /// Snackbar shown when saving custom proxy headers fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to save custom proxy headers.'**
  String get settingsProxyHeadersSaveFailed;

  /// App version list tile title on the settings screen.
  ///
  /// In en, this message translates to:
  /// **'App Version: {version}'**
  String settingsAppVersion(String version);

  /// Subtitle for the check-for-updates list tile.
  ///
  /// In en, this message translates to:
  /// **'See if a newer version is available'**
  String get settingsCheckForUpdatesSubtitle;

  /// Title for the contact-us list tile on the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get settingsContactUs;

  /// Accessibility label for the debug logs list tile.
  ///
  /// In en, this message translates to:
  /// **'Open debug logs'**
  String get settingsDebugLogsSemantics;

  /// Subtitle for the debug logs list tile.
  ///
  /// In en, this message translates to:
  /// **'View app diagnostic logs'**
  String get settingsDebugLogsSubtitle;

  /// Title for the group-by-account-type toggle on the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Group by Account Type'**
  String get settingsGroupByAccountType;

  /// Subtitle for the group-by-account-type toggle.
  ///
  /// In en, this message translates to:
  /// **'Group accounts by type (Crypto, Bank, etc.)'**
  String get settingsGroupByAccountTypeSubtitle;

  /// Title for the custom proxy headers list tile on the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Custom proxy headers'**
  String get settingsProxyHeadersTileTitle;

  /// Subtitle for the custom proxy headers list tile when no headers are configured.
  ///
  /// In en, this message translates to:
  /// **'Optional headers for a reverse proxy or auth gateway'**
  String get settingsProxyHeadersTileSubtitleEmpty;

  /// Subtitle for the custom proxy headers list tile when headers are configured.
  ///
  /// In en, this message translates to:
  /// **'{count} configured'**
  String settingsProxyHeadersTileSubtitleCount(int count);

  /// Subtitle for the clear-local-data list tile.
  ///
  /// In en, this message translates to:
  /// **'Remove all cached transactions and accounts'**
  String get settingsClearDataTileSubtitle;

  /// Subtitle for the reset-account list tile in the danger zone.
  ///
  /// In en, this message translates to:
  /// **'Delete all accounts, categories, merchants, and tags but keep your user account'**
  String get settingsResetAccountTileSubtitle;

  /// Subtitle for the delete-account list tile in the danger zone.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove all your data. This cannot be undone.'**
  String get settingsDeleteAccountTileSubtitle;

  /// Fallback display name when the user has no name set.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get settingsUserFallback;

  /// Error-state heading on the chat list screen.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chats'**
  String get chatListError;

  /// Relative time label for very recent chats.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get chatListJustNow;

  /// Body text for the single-chat delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String chatListDeleteSingleContent(String title);

  /// Snackbar shown when the sign-up page cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Unable to open sign up page'**
  String get loginSignUpOpenError;

  /// Leading text before the Sign Up link on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Demo account or '**
  String get loginDemoOrSignUpPrefix;

  /// Tappable Sign Up link text on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginSignUpLink;

  /// Trailing punctuation after the Sign Up link on the login screen.
  ///
  /// In en, this message translates to:
  /// **'!'**
  String get loginSignUpSuffix;

  /// Info banner shown when MFA is required during login.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication is enabled. Enter your code.'**
  String get loginMfaInfo;

  /// Validation error when the MFA code field is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your authentication code'**
  String get loginMfaCodeRequired;

  /// Divider label between primary and alternate sign-in options.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get loginOrDivider;

  /// Heading above the displayed server URL on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Hisaab server URL:'**
  String get loginServerUrlHeading;

  /// Tooltip for the backend settings button on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Backend Settings'**
  String get loginBackendSettingsTooltip;

  /// Snackbar shown when the session expires while editing a transaction.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get transactionEditSessionExpired;

  /// Snackbar shown after a transaction is updated successfully.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated'**
  String get transactionEditUpdated;

  /// Fallback snackbar shown when updating a transaction fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to update transaction'**
  String get transactionEditUpdateFailed;

  /// Validation error when the transaction name exceeds the maximum length.
  ///
  /// In en, this message translates to:
  /// **'Name must be {max} characters or fewer'**
  String transactionEditNameMaxLength(int max);

  /// Validation error when the transaction name contains control characters.
  ///
  /// In en, this message translates to:
  /// **'Name contains unsupported characters'**
  String get transactionEditNameInvalidChars;

  /// Validation error when the notes exceed the maximum length.
  ///
  /// In en, this message translates to:
  /// **'Notes must be {max} characters or fewer'**
  String transactionEditNotesMaxLength(int max);

  /// Validation error when the notes contain control characters.
  ///
  /// In en, this message translates to:
  /// **'Notes contain unsupported characters'**
  String get transactionEditNotesInvalidChars;

  /// Dropdown option representing no selected category in the edit form.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get transactionEditNoCategory;

  /// Fallback dropdown label for the currently selected category when its name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Current category'**
  String get transactionEditCurrentCategory;

  /// Dropdown option representing no selected merchant in the edit form.
  ///
  /// In en, this message translates to:
  /// **'No merchant'**
  String get transactionEditNoMerchant;

  /// Fallback dropdown label for the currently selected merchant when its name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Current merchant'**
  String get transactionEditCurrentMerchant;

  /// Message shown when no tags are available to select in the edit form.
  ///
  /// In en, this message translates to:
  /// **'No tags available'**
  String get transactionEditNoTags;

  /// Fallback label for a selected tag whose name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown tag'**
  String get transactionEditUnknownTag;

  /// Notice shown when a transaction cannot be edited because it is not yet synced.
  ///
  /// In en, this message translates to:
  /// **'Only synced transactions can be edited from mobile.'**
  String get transactionEditSyncedOnly;

  /// Helper text under the category dropdown in the edit form.
  ///
  /// In en, this message translates to:
  /// **'Choose a replacement category'**
  String get transactionEditCategoryHelper;

  /// Helper text under the merchant dropdown in the edit form.
  ///
  /// In en, this message translates to:
  /// **'Choose a replacement merchant'**
  String get transactionEditMerchantHelper;

  /// Snackbar shown when the session expires while creating a transaction.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get transactionFormSessionExpired;

  /// Validation error when the amount field is empty in the create form.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get transactionFormAmountRequiredPrompt;

  /// Validation error when the amount is not a valid number.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get transactionFormAmountInvalidNumber;

  /// Validation error when the amount is zero or negative.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get transactionFormAmountTooSmall;

  /// Snackbar shown after a transaction is created while online.
  ///
  /// In en, this message translates to:
  /// **'Transaction created successfully'**
  String get transactionFormCreateSuccessOnline;

  /// Snackbar shown after a transaction is saved while offline.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved (will sync when online)'**
  String get transactionFormCreateSuccessOffline;

  /// Snackbar shown when creating a transaction fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to create transaction'**
  String get transactionFormCreateFailed;

  /// Snackbar shown when an unexpected error occurs while creating a transaction.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String transactionFormGenericError(String error);

  /// Toggle label to hide the optional transaction fields.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get transactionFormLess;

  /// Toggle label to show the optional transaction fields.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get transactionFormMore;

  /// Helper text for the date field in the create form.
  ///
  /// In en, this message translates to:
  /// **'Optional (default: today)'**
  String get transactionFormDateHelper;

  /// Helper text for the name field in the create form.
  ///
  /// In en, this message translates to:
  /// **'Optional (default: SureApp)'**
  String get transactionFormNameHelper;

  /// Placeholder shown while categories are loading in the create form.
  ///
  /// In en, this message translates to:
  /// **'Loading categories…'**
  String get transactionFormCategoryLoading;

  /// Helper text for the category dropdown in the create form.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get transactionFormCategoryHelper;

  /// Dropdown option representing no selected category in the create form.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get transactionFormNoCategory;

  /// Submit button label on the create-transaction form.
  ///
  /// In en, this message translates to:
  /// **'Create Transaction'**
  String get transactionFormCreateButton;

  /// Helper text under the amount field indicating it is required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get transactionFormAmountHelper;

  /// Body text for the clear-logs confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all logs?'**
  String get logViewerClearConfirm;

  /// Confirm button label in the clear-logs dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get logViewerClear;

  /// Title for the edit-chat-title dialog.
  ///
  /// In en, this message translates to:
  /// **'Edit Title'**
  String get chatConversationEditTitle;

  /// Label for the chat title input field in the edit dialog.
  ///
  /// In en, this message translates to:
  /// **'Chat Title'**
  String get chatConversationTitleLabel;

  /// Tooltip for the refresh button in the chat conversation screen.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get chatConversationRefreshTooltip;

  /// Error-state heading when a chat fails to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chat'**
  String get chatConversationLoadError;

  /// Title for the dialog prompting the user to enable AI chat.
  ///
  /// In en, this message translates to:
  /// **'Turn on the assistant?'**
  String get navEnableAiChatTitle;

  /// Body text for the enable-AI-chat dialog.
  ///
  /// In en, this message translates to:
  /// **'The assistant reads your entries to answer questions about your money. It is off for your account right now.'**
  String get navEnableAiChatContent;

  /// Confirm button in the enable-AI-chat dialog.
  ///
  /// In en, this message translates to:
  /// **'Turn on AI'**
  String get navEnableAiChatConfirm;

  /// Snackbar shown when enabling AI chat fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to enable AI right now.'**
  String get navEnableAiChatFailed;

  /// Tooltip for the edit button on a transaction row.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get transactionsListEditTooltip;

  /// Snackbar shown when trying to sync without being signed in.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to sync transactions'**
  String get connectivitySignInToSync;

  /// Snackbar shown after transactions sync successfully.
  ///
  /// In en, this message translates to:
  /// **'Transactions synced successfully'**
  String get connectivitySyncSuccess;

  /// Snackbar shown when a manual sync fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync transactions. Please try again.'**
  String get connectivitySyncFailed;

  /// Snackbar shown when authentication fails during a manual sync.
  ///
  /// In en, this message translates to:
  /// **'Unable to authenticate. Please try again.'**
  String get connectivityAuthFailed;

  /// Header text on the SSO onboarding screen showing the signed-in Google email.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String ssoOnboardingSignedInAs(String email);

  /// Header text on the SSO onboarding screen when the Google email is unknown.
  ///
  /// In en, this message translates to:
  /// **'Google account verified'**
  String get ssoOnboardingGoogleVerified;

  /// Explanatory note on the link-existing form prompting the user to enter their credentials.
  ///
  /// In en, this message translates to:
  /// **'Enter your existing account credentials to link with Google Sign-In.'**
  String get ssoOnboardingLinkCredentialsNote;

  /// Explanatory note on the create form when the user has a pending household invitation.
  ///
  /// In en, this message translates to:
  /// **'You have a pending invitation. Accept it to join an existing household.'**
  String get ssoOnboardingPendingInvitationNote;

  /// Explanatory note on the create form when creating a brand-new account via Google.
  ///
  /// In en, this message translates to:
  /// **'Create a new account using your Google identity.'**
  String get ssoOnboardingCreateIdentityNote;

  /// Validation error when the first-name field is empty on the SSO onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get ssoOnboardingFirstNameRequired;

  /// Validation error when the last-name field is empty on the SSO onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get ssoOnboardingLastNameRequired;

  /// Error shown when the connection test times out.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout. Please check the URL and try again.'**
  String get backendConfigTimeout;

  /// Message shown when the connection test succeeds.
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get backendConfigSuccess;

  /// Error shown when the server returns a non-success status during the connection test.
  ///
  /// In en, this message translates to:
  /// **'Server responded with status {code}. Please check if this is a Hisaab backend server.'**
  String backendConfigServerError(int code);

  /// Error shown when the connection test fails with an exception.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String backendConfigConnectionFailed(String error);

  /// Error shown when saving the backend URL fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to save URL: {error}'**
  String backendConfigSaveFailed(String error);

  /// Validation error when the backend URL field is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a backend URL'**
  String get backendConfigUrlRequired;

  /// Validation error when the backend URL is missing an http(s) scheme.
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get backendConfigUrlScheme;

  /// Validation error when the backend URL is malformed.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get backendConfigUrlInvalid;

  /// Helper text below the custom proxy headers section on the backend config screen.
  ///
  /// In en, this message translates to:
  /// **'Headers are sent by the app with API requests. External browser SSO pages may not receive them.'**
  String get backendConfigHeadersHelp;

  /// Fallback label when a transaction's account cannot be resolved.
  ///
  /// In en, this message translates to:
  /// **'Unknown Account'**
  String get recentTransactionsUnknownAccount;

  /// Error message shown when account detail and balances both fail to load.
  ///
  /// In en, this message translates to:
  /// **'Account details are temporarily unavailable'**
  String get accountDetailUnavailable;

  /// Relative time label for a chat updated some minutes ago.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String chatListMinutesAgo(int minutes);

  /// Relative time label for a chat updated some hours ago.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String chatListHoursAgo(int hours);

  /// Relative time label for a chat updated some days ago.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String chatListDaysAgo(int days);

  /// Fallback snackbar shown when creating a new conversation from the first message fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to start conversation. Please try again.'**
  String get chatConversationStartFailed;

  /// Menu item title for Budgets in the More screen.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get moreBudgets;

  /// Subtitle for the Budgets menu item in the More screen.
  ///
  /// In en, this message translates to:
  /// **'Budgeted vs. actual spending by category'**
  String get moreBudgetsSubtitle;

  /// App bar title of the Budgets screen.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// Tooltip for the button that shows the previous month's budget.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get budgetsPreviousMonth;

  /// Tooltip for the button that shows the next month's budget.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get budgetsNextMonth;

  /// Label for the total amount budgeted for spending this month.
  ///
  /// In en, this message translates to:
  /// **'Budgeted'**
  String get budgetsBudgeted;

  /// Label for the amount actually spent this month.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get budgetsActual;

  /// Label for the amount left to spend this month.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get budgetsRemaining;

  /// Label for the month's actual income in the budget summary.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get budgetsIncome;

  /// Expected income for the month, shown next to actual income.
  ///
  /// In en, this message translates to:
  /// **'Expected {amount}'**
  String budgetsExpectedIncome(String amount);

  /// Budget limit shown after the amount spent in a category, e.g. '$120 of $300'.
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String budgetsOfAmount(String amount);

  /// Amount still available to spend in a category.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String budgetsAmountLeft(String amount);

  /// Amount by which a category's spending exceeds its budget.
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String budgetsOverBy(String amount);

  /// Unspent amount carried over from the previous month into this category.
  ///
  /// In en, this message translates to:
  /// **'+{amount} rolled over'**
  String budgetsRolledOver(String amount);

  /// Shown for a subcategory without its own limit that draws from its parent category's budget.
  ///
  /// In en, this message translates to:
  /// **'Shared budget'**
  String get budgetsSharedBudget;

  /// Shown for a category with spending but no budgeted amount.
  ///
  /// In en, this message translates to:
  /// **'No budget'**
  String get budgetsNoLimit;

  /// Heading of the per-category budget list.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get budgetsCategoriesTitle;

  /// Filter showing only categories that are over budget, with how many there are.
  ///
  /// In en, this message translates to:
  /// **'Over budget ({count})'**
  String budgetsFilterOverBudget(int count);

  /// Badge on a category that has spent more than its budget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get budgetsOverBudget;

  /// Badge on a category that has spent at least 90% of its budget.
  ///
  /// In en, this message translates to:
  /// **'Near limit'**
  String get budgetsNearLimit;

  /// Label for one of several budgets that exist for the same month (household, personal or shared).
  ///
  /// In en, this message translates to:
  /// **'Budget {number}'**
  String budgetsBudgetNumber(int number);

  /// Title shown when the server has no budget for the selected month.
  ///
  /// In en, this message translates to:
  /// **'No budget for {month}'**
  String budgetsNoBudgetTitle(String month);

  /// Explains how to create a budget when none exists for the selected month.
  ///
  /// In en, this message translates to:
  /// **'Budgets are created in Hisaab on the web. Open Budgets there to set one up for this month.'**
  String get budgetsNoBudgetMessage;

  /// Shown when a budget exists for the month but has no amounts set.
  ///
  /// In en, this message translates to:
  /// **'No spending limits are set for this month yet. Set them up in Hisaab on the web.'**
  String get budgetsNotSetUpMessage;

  /// Shown when no category line has a budget or spending.
  ///
  /// In en, this message translates to:
  /// **'No budgeted categories or spending this month.'**
  String get budgetsNoCategories;

  /// Title shown when the budget cannot be loaded without a connection.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get budgetsOfflineTitle;

  /// Shown when offline and the selected month has not been loaded yet.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to load this month\'s budget.'**
  String get budgetsOfflineMessage;

  /// Banner shown when offline and the budget shown was loaded earlier in the session.
  ///
  /// In en, this message translates to:
  /// **'Offline. Showing the figures loaded earlier.'**
  String get budgetsOfflineCached;

  /// Banner shown when refreshing a budget fails but the month loaded earlier is still on screen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh. Showing the figures loaded earlier.'**
  String get budgetsRefreshFailed;

  /// Title shown when loading budgets fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load budgets'**
  String get budgetsLoadFailed;

  /// Shown when the budgets request is rejected as unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get budgetsSessionExpired;

  /// Empty state of a budget category's transaction list.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this category for {month}.'**
  String budgetCategoryTransactionsEmpty(String month);

  /// Button that loads the next page of a budget category's transactions.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get budgetCategoryTransactionsLoadMore;

  /// Shown when a budget category's transactions fail to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load transactions'**
  String get budgetCategoryTransactionsLoadFailed;

  /// Bottom navigation label for the Activity (transactions) tab.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// Bottom navigation label for the Statements tab.
  ///
  /// In en, this message translates to:
  /// **'Statements'**
  String get navStatements;

  /// Bottom navigation label for the Accounts tab.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// Accessibility label for the centre Add button.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get navAddExpense;

  /// Spending group for transactions without a label (category).
  ///
  /// In en, this message translates to:
  /// **'No label'**
  String get homeNoLabel;

  /// Settings button tooltip and settings page title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// Home error when the month's data fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load this month.'**
  String get homeLoadFailed;

  /// Heading over the month's spending total.
  ///
  /// In en, this message translates to:
  /// **'Spent in {month}'**
  String homeSpentIn(String month);

  /// Spending compared with the previous month (higher).
  ///
  /// In en, this message translates to:
  /// **'{amount} more than {month}'**
  String homeMoreThan(String amount, String month);

  /// Spending compared with the previous month (lower).
  ///
  /// In en, this message translates to:
  /// **'{amount} less than {month}'**
  String homeLessThan(String amount, String month);

  /// Spending equal to the previous month.
  ///
  /// In en, this message translates to:
  /// **'Same as {month}'**
  String homeSameAs(String month);

  /// Label for money in this month.
  ///
  /// In en, this message translates to:
  /// **'Came in'**
  String get homeCameIn;

  /// Label for money out this month.
  ///
  /// In en, this message translates to:
  /// **'Went out'**
  String get homeWentOut;

  /// Label for money in minus money out.
  ///
  /// In en, this message translates to:
  /// **'Left over'**
  String get homeLeftOver;

  /// Section title for spending by label.
  ///
  /// In en, this message translates to:
  /// **'Where it went'**
  String get homeWhereItWent;

  /// Link to the budget screen.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get homeBudget;

  /// Empty state for spending by label.
  ///
  /// In en, this message translates to:
  /// **'Nothing spent this month yet.'**
  String get homeNothingSpent;

  /// Section title for net worth.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get homeNetWorth;

  /// Link to the accounts screen.
  ///
  /// In en, this message translates to:
  /// **'Balance sheet'**
  String get homeBalanceSheet;

  /// Net worth breakdown.
  ///
  /// In en, this message translates to:
  /// **'Assets {assets} · Owed {owed}'**
  String homeAssetsOwed(String assets, String owed);

  /// Banner linking to statement review.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 statement item needs a label} other{{count} statement items need a label}}'**
  String homeNeedLabel(int count);

  /// Banner detail line.
  ///
  /// In en, this message translates to:
  /// **'{month} · {sorted} sorted already'**
  String homeNeedLabelDetail(String month, int sorted);

  /// Filter chip and row label for transactions without a label.
  ///
  /// In en, this message translates to:
  /// **'No label'**
  String get activityNoLabel;

  /// Activity search field hint.
  ///
  /// In en, this message translates to:
  /// **'Search this month'**
  String get activitySearchHint;

  /// Tooltip for clearing the search field.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get activityClearSearch;

  /// Activity note when offline.
  ///
  /// In en, this message translates to:
  /// **'Offline. Showing what is saved on this phone.'**
  String get activityOfflineNote;

  /// Activity note when the server fetch fails.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Showing what is saved on this phone.'**
  String get activityLoadFailedNote;

  /// Activity empty state.
  ///
  /// In en, this message translates to:
  /// **'Nothing here for this month.'**
  String get activityEmpty;

  /// Activity strip: money in.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get activityIn;

  /// Activity strip: money out.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get activityOut;

  /// Activity strip: number of transactions.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get activityEntries;

  /// Row status for a transaction saved offline.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get activityWaitingToSync;

  /// Row status for a transaction deleted offline.
  ///
  /// In en, this message translates to:
  /// **'Will be deleted'**
  String get activityWaitingToDelete;

  /// Row label for a transfer between accounts.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get activityTransfer;

  /// Accessibility label for the paperclip icon.
  ///
  /// In en, this message translates to:
  /// **'Has receipt'**
  String get activityHasReceipt;

  /// Tooltip for the delete button on the transaction detail screen.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get detailDelete;

  /// Shown under an income amount.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get detailMoneyIn;

  /// Shown under an expense amount.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get detailMoneyOut;

  /// Label for the note field.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get detailNote;

  /// Hint for the note field.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get detailNoteHint;

  /// Receipt section title.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get detailReceipt;

  /// Action to attach a receipt.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get detailAttachReceipt;

  /// Action to replace the receipt.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get detailReplaceReceipt;

  /// Shown when a transaction has no receipt.
  ///
  /// In en, this message translates to:
  /// **'No receipt attached.'**
  String get detailNoReceipt;

  /// More attachments beyond the one shown.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String detailMoreReceipts(int count);

  /// Tooltip for removing a receipt.
  ///
  /// In en, this message translates to:
  /// **'Remove receipt'**
  String get receiptRemove;

  /// Shown when attaching while offline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to attach a receipt.'**
  String get receiptNeedsInternet;

  /// Receipt upload error.
  ///
  /// In en, this message translates to:
  /// **'Could not attach the receipt.'**
  String get receiptUploadFailed;

  /// Receipt delete error.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the receipt.'**
  String get receiptRemoveFailed;

  /// Open the camera for a receipt.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get receiptTakePhoto;

  /// Pick a receipt from the gallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get receiptFromGallery;

  /// Add screen toggle: expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get formTypeExpense;

  /// Add screen toggle: income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get formTypeIncome;

  /// Label (category) picker title.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get formLabel;

  /// Link to the labels screen.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get formManage;

  /// Chip that opens the labels screen to add one.
  ///
  /// In en, this message translates to:
  /// **'+ New label'**
  String get formNewLabel;

  /// Label for the transaction name field.
  ///
  /// In en, this message translates to:
  /// **'What for'**
  String get formWhatFor;

  /// Hint for the transaction name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Imtiaz Supermarket'**
  String get formWhatForHint;

  /// Account picker label for an expense.
  ///
  /// In en, this message translates to:
  /// **'Paid from'**
  String get formPaidFrom;

  /// Account picker label for income.
  ///
  /// In en, this message translates to:
  /// **'Paid into'**
  String get formPaidInto;

  /// Shown when there are no accounts to pick.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get formNoAccounts;

  /// Hint for optional fields.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get formOptional;

  /// Receipt section title on the add screen.
  ///
  /// In en, this message translates to:
  /// **'Receipt or screenshot'**
  String get formReceipt;

  /// Save button for an expense.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get formSaveExpense;

  /// Save button for income.
  ///
  /// In en, this message translates to:
  /// **'Save income'**
  String get formSaveIncome;

  /// Shown when saving without an account.
  ///
  /// In en, this message translates to:
  /// **'Choose an account first.'**
  String get formPickAccount;

  /// Confirmation after saving.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get formSaved;

  /// Saved offline with a receipt.
  ///
  /// In en, this message translates to:
  /// **'Saved. The receipt was not attached because you are offline.'**
  String get formSavedReceiptOffline;

  /// Tagline under the wordmark on sign in.
  ///
  /// In en, this message translates to:
  /// **'Every rupee, month by month.'**
  String get loginTagline;

  /// Label for the server row on sign in.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get loginServer;

  /// Action to change the server.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get loginServerChange;

  /// Tooltip for the password visibility toggle.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get loginShowPassword;

  /// Prefix before the create-account link.
  ///
  /// In en, this message translates to:
  /// **'New here? '**
  String get loginNewHere;

  /// Link to sign up.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get loginCreateAccount;

  /// Activity view toggle: list of entries.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get activityViewList;

  /// Activity view toggle: month calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get activityViewCalendar;

  /// Activity header link to the statement upload screen.
  ///
  /// In en, this message translates to:
  /// **'Import statement'**
  String get activityImportStatement;

  /// Calendar hint when no day is selected.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to see its payments.'**
  String get activityPickDay;

  /// Calendar day header: number of payments (money going out).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No payments} one{1 payment} other{{count} payments}}'**
  String activityPayments(int count);

  /// Calendar: selected day has no entries.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day.'**
  String get activityNothingThisDay;

  /// Home link to the statements screen.
  ///
  /// In en, this message translates to:
  /// **'Add a bank or card statement'**
  String get homeStatementsHint;

  /// Home section listing generated insights.
  ///
  /// In en, this message translates to:
  /// **'Notes for you'**
  String get homeNotesForYou;

  /// First Assistant question when a Home note is tapped.
  ///
  /// In en, this message translates to:
  /// **'Tell me more: {title}'**
  String homeInsightAsk(String title);

  /// Assistant tab intro line.
  ///
  /// In en, this message translates to:
  /// **'Ask about your money in plain words. Answers come from your own entries.'**
  String get assistantIntro;

  /// Assistant tab: past conversations header.
  ///
  /// In en, this message translates to:
  /// **'Earlier questions'**
  String get assistantEarlier;

  /// Header over suggested questions.
  ///
  /// In en, this message translates to:
  /// **'Try asking'**
  String get assistantTryAsking;

  /// Shown while the assistant writes a reply.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get assistantThinking;

  /// Accessibility label for the send button.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get assistantSend;

  /// Quiet note that the assistant used a tool, e.g. 'Looked up transactions'.
  ///
  /// In en, this message translates to:
  /// **'Looked up {subject}'**
  String assistantLookedUp(String subject);

  /// Suggested assistant question.
  ///
  /// In en, this message translates to:
  /// **'How much did we spend on groceries this month?'**
  String get chatSuggestionGroceries;

  /// Suggested assistant question.
  ///
  /// In en, this message translates to:
  /// **'What did I pay on 15 October?'**
  String get chatSuggestionDay;

  /// Suggested assistant question.
  ///
  /// In en, this message translates to:
  /// **'Which bills went up compared to last month?'**
  String get chatSuggestionBills;

  /// Suggested assistant question.
  ///
  /// In en, this message translates to:
  /// **'Where can we save next month?'**
  String get chatSuggestionSave;

  /// Link to the server's public privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacy;

  /// Link to the server's public terms of service.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalTerms;

  /// Snackbar shown when a link cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link'**
  String get legalOpenLinkError;

  /// App bar title of the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpTitle;

  /// Intro text on the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Keep your household\'s spending in one place. Your account is created on the server shown on the sign-in screen.'**
  String get signUpSubtitle;

  /// Password requirements on the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters with upper and lower case letters, a number and a symbol.'**
  String get signUpPasswordRules;

  /// Label of the repeat-password field.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get signUpConfirmPasswordLabel;

  /// Validation error when the two passwords differ.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get signUpPasswordsDoNotMatch;

  /// Submit button on the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpSubmit;

  /// Text before the Terms link under the sign-up button.
  ///
  /// In en, this message translates to:
  /// **'By creating an account you agree to the '**
  String get signUpAgreementPrefix;

  /// Joins the Terms and Privacy links.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get signUpAgreementAnd;

  /// Settings tile linking to the app's source code.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get settingsSourceCode;

  /// Subtitle of the source code tile.
  ///
  /// In en, this message translates to:
  /// **'Hisaab is based on Sure and licensed under AGPL-3.0'**
  String get settingsSourceCodeSubtitle;

  /// Snackbar after the account is deleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get settingsDeleteAccountDone;

  /// Title of the second delete-account confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete account for good?'**
  String get settingsDeleteAccountFinalTitle;

  /// Final destructive button of account deletion.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get settingsDeleteAccountFinalButton;

  /// Body of the second delete-account confirmation.
  ///
  /// In en, this message translates to:
  /// **'Your accounts, transactions, receipt photos, statements and chats will be deleted. If you are the last member of your household, the whole household is deleted.\n\nType {word} to confirm.'**
  String settingsDeleteAccountFinalContent(String word);

  /// Button on the iOS login screen that signs in with an Apple ID.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get loginSignInWithApple;

  /// Shown when Sign in with Apple fails for a reason other than the user cancelling.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in didn\'t work. Please try again.'**
  String get loginAppleFailed;

  /// Button on the login screen that signs in with a saved passkey.
  ///
  /// In en, this message translates to:
  /// **'Sign in with passkey'**
  String get loginSignInWithPasskey;

  /// Shown when the phone has no passkey for the server.
  ///
  /// In en, this message translates to:
  /// **'No passkey for this server on this phone. Sign in with your password, then add one in Settings.'**
  String get loginPasskeyNotFound;

  /// Fallback error for a failed passkey sign-in.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in with a passkey. Please try again.'**
  String get loginPasskeyFailed;

  /// Settings row that opens passkey management.
  ///
  /// In en, this message translates to:
  /// **'Passkeys'**
  String get settingsPasskeysTitle;

  /// Subtitle of the passkeys settings row.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your fingerprint or screen lock'**
  String get settingsPasskeysSubtitle;

  /// Intro text on the passkeys screen.
  ///
  /// In en, this message translates to:
  /// **'A passkey lets you sign in with your fingerprint, face or screen lock instead of your password. It is saved in your phone\'s password manager.'**
  String get passkeysIntro;

  /// Heading of the add-passkey form.
  ///
  /// In en, this message translates to:
  /// **'Add a passkey'**
  String get passkeysAddHeading;

  /// Label for the passkey name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get passkeysNameLabel;

  /// Hint for the passkey name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Pixel'**
  String get passkeysNameHint;

  /// Label for the password that confirms adding a passkey.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get passkeysPasswordLabel;

  /// Label for the two-factor code that confirms adding a passkey.
  ///
  /// In en, this message translates to:
  /// **'Authenticator or backup code'**
  String get passkeysCodeLabel;

  /// Button that creates a passkey.
  ///
  /// In en, this message translates to:
  /// **'Add passkey'**
  String get passkeysAddButton;

  /// Heading above the list of passkeys.
  ///
  /// In en, this message translates to:
  /// **'Your passkeys'**
  String get passkeysListHeading;

  /// Shown when the user has no passkeys.
  ///
  /// In en, this message translates to:
  /// **'No passkeys yet. Add one above.'**
  String get passkeysEmpty;

  /// When a passkey was added.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String passkeysAdded(String date);

  /// When a passkey was last used to sign in.
  ///
  /// In en, this message translates to:
  /// **'Last used {date}'**
  String passkeysLastUsed(String date);

  /// Button that removes a passkey.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get passkeysRemove;

  /// Title of the remove-passkey confirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove this passkey?'**
  String get passkeysRemoveTitle;

  /// Body of the remove-passkey confirmation.
  ///
  /// In en, this message translates to:
  /// **'You will no longer be able to sign in with \"{name}\". Also delete it from your phone\'s password manager.'**
  String passkeysRemoveBody(String name);

  /// Snackbar after adding a passkey.
  ///
  /// In en, this message translates to:
  /// **'Passkey added.'**
  String get passkeysAddedToast;

  /// Snackbar after removing a passkey.
  ///
  /// In en, this message translates to:
  /// **'Passkey removed.'**
  String get passkeysRemovedToast;

  /// Shown when the device cannot use passkeys.
  ///
  /// In en, this message translates to:
  /// **'This phone cannot use passkeys. They need Android 11 or newer with Google Play services.'**
  String get passkeysUnsupported;

  /// Shown when the account has nothing to confirm a new passkey with.
  ///
  /// In en, this message translates to:
  /// **'Set a password or turn on two-factor authentication on the web before adding a passkey.'**
  String get passkeysNoStepUp;

  /// Error when the passkey list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your passkeys. Pull down to try again.'**
  String get passkeysLoadFailed;

  /// Fallback error when adding a passkey fails.
  ///
  /// In en, this message translates to:
  /// **'Could not add the passkey.'**
  String get passkeysAddFailed;

  /// Error when removing a passkey fails.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the passkey.'**
  String get passkeysRemoveFailed;

  /// Validation error when the confirmation field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter it to confirm it\'s you.'**
  String get passkeysConfirmRequired;

  /// Tooltip for the composer button that attaches a PDF/CSV statement.
  ///
  /// In en, this message translates to:
  /// **'Attach a statement'**
  String get assistantAttachTooltip;

  /// Tooltip for the composer microphone button.
  ///
  /// In en, this message translates to:
  /// **'Voice note: tap to start, or hold and talk'**
  String get assistantMicTooltip;

  /// Shown when microphone permission is denied.
  ///
  /// In en, this message translates to:
  /// **'Hisaab needs the microphone to record a voice note. You can allow it in your phone\'s settings.'**
  String get assistantMicPermissionDenied;

  /// Shown when the recorder fails to start.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording. Please try again.'**
  String get assistantMicFailed;

  /// Shown when a voice note is shorter than the minimum length.
  ///
  /// In en, this message translates to:
  /// **'That was too short. Hold the mic while you talk, or tap it once to start.'**
  String get assistantVoiceTooShort;

  /// Hint while recording with the mic held down.
  ///
  /// In en, this message translates to:
  /// **'Release to send · slide away to cancel'**
  String get assistantRecordingHold;

  /// Hint while recording when the finger has slid away from the mic.
  ///
  /// In en, this message translates to:
  /// **'Release to cancel'**
  String get assistantRecordingReleaseToCancel;

  /// Hint while recording in tap-to-start mode.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic again to send'**
  String get assistantRecordingTap;

  /// Tooltip of the button that discards the current recording.
  ///
  /// In en, this message translates to:
  /// **'Cancel recording'**
  String get assistantRecordingCancel;

  /// Accessibility label for the recording timer.
  ///
  /// In en, this message translates to:
  /// **'Recording {elapsed} of {limit}'**
  String assistantRecordingLabel(String elapsed, String limit);

  /// Shown while a voice note is uploaded and turned into text.
  ///
  /// In en, this message translates to:
  /// **'Transcribing…'**
  String get assistantTranscribing;

  /// Title of a new chat started with a voice note.
  ///
  /// In en, this message translates to:
  /// **'Voice note'**
  String get assistantVoiceNoteTitle;

  /// Fallback error when a voice note upload fails.
  ///
  /// In en, this message translates to:
  /// **'Could not send the voice note. Please try again.'**
  String get assistantVoiceNoteFailed;

  /// Shown while the assistant reads an attached statement.
  ///
  /// In en, this message translates to:
  /// **'Reading your statement…'**
  String get assistantReadingStatement;

  /// Shown when the statement reply did not start within the wait limit.
  ///
  /// In en, this message translates to:
  /// **'The statement is taking a while. Tap refresh in a minute to see the reply.'**
  String get assistantStatementSlow;

  /// Fallback error when attaching a statement fails.
  ///
  /// In en, this message translates to:
  /// **'Could not send the statement. Please try again.'**
  String get assistantStatementFailed;

  /// Shown when the picked file cannot be read.
  ///
  /// In en, this message translates to:
  /// **'Could not read that file.'**
  String get assistantFileUnreadable;

  /// Shown when the picked file is not a PDF or CSV.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF or CSV statement.'**
  String get assistantFileType;

  /// Title of the account picker for an attached statement.
  ///
  /// In en, this message translates to:
  /// **'Which account is this statement for?'**
  String get assistantChooseAccount;

  /// Shown when there is no account to attach a statement to.
  ///
  /// In en, this message translates to:
  /// **'Add a bank account first, then attach its statement.'**
  String get assistantNoAccounts;

  /// Shown when accounts fail to load for a statement.
  ///
  /// In en, this message translates to:
  /// **'Could not load your accounts. Please try again.'**
  String get assistantAccountsFailed;

  /// Button that saves a proposed change.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get pendingActionSave;

  /// Button that discards a proposed change.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pendingActionCancel;

  /// Status of a proposed change that was saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get pendingActionSaved;

  /// Status of a proposed change that was discarded.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get pendingActionCancelled;

  /// Button that saves every open row of a statement batch.
  ///
  /// In en, this message translates to:
  /// **'Save all ({count})'**
  String pendingActionSaveAll(int count);

  /// Button that discards every open row of a statement batch.
  ///
  /// In en, this message translates to:
  /// **'Cancel all'**
  String get pendingActionCancelAll;

  /// Header of a card listing several proposed entries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry to check} other{{count} entries to check}}'**
  String pendingActionBatchTitle(int count);

  /// Shown on a proposed entry that has no label.
  ///
  /// In en, this message translates to:
  /// **'Needs a label'**
  String get pendingActionNeedsLabel;

  /// Tag on a statement row that looks already recorded.
  ///
  /// In en, this message translates to:
  /// **'Already recorded?'**
  String get pendingActionDuplicate;

  /// Tooltip of the button that removes one row from a batch.
  ///
  /// In en, this message translates to:
  /// **'Remove this row'**
  String get pendingActionRemove;

  /// Relative date for today on a proposed change.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get pendingActionToday;

  /// Relative date for yesterday on a proposed change.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get pendingActionYesterday;

  /// Fallback error on a proposed change that failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save.'**
  String get pendingActionSaveFailed;

  /// Shown when a save/cancel request fails.
  ///
  /// In en, this message translates to:
  /// **'Could not update. Please try again.'**
  String get pendingActionRequestFailed;

  /// Heading of a proposed new entry.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get pendingActionKindAdd;

  /// Heading of a proposed edit to an entry.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get pendingActionKindUpdate;

  /// Heading of a proposed deletion of an entry.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get pendingActionKindDelete;

  /// Heading of a proposed account balance update.
  ///
  /// In en, this message translates to:
  /// **'Set balance'**
  String get pendingActionKindBalance;

  /// Heading of a proposed new account.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get pendingActionKindAccount;

  /// Heading of a proposed new label.
  ///
  /// In en, this message translates to:
  /// **'New label'**
  String get pendingActionKindLabel;

  /// Heading of any other proposed change.
  ///
  /// In en, this message translates to:
  /// **'Proposed change'**
  String get pendingActionKindOther;

  /// Title of the PDF report screen and links to it.
  ///
  /// In en, this message translates to:
  /// **'Download report'**
  String get reportTitle;

  /// Short hint next to the report link on Home and Settings.
  ///
  /// In en, this message translates to:
  /// **'PDF of any period, to keep or share'**
  String get reportHint;

  /// Intro text on the report screen.
  ///
  /// In en, this message translates to:
  /// **'Pick a period and the labels to include. Hisaab makes a PDF with the totals and every entry, ready to save or send.'**
  String get reportIntro;

  /// Section header for the date range choice.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportPeriod;

  /// Date range preset.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get reportThisMonth;

  /// Date range preset.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get reportLastMonth;

  /// Date range preset: this month and the two before it.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get reportLast3Months;

  /// Date range preset that opens a date range picker.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reportCustom;

  /// Section header for the label (category) choice.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get reportLabels;

  /// Chip that includes every label and unlabelled entries.
  ///
  /// In en, this message translates to:
  /// **'All labels'**
  String get reportAllLabels;

  /// Chip for entries without a label.
  ///
  /// In en, this message translates to:
  /// **'Unlabelled'**
  String get reportUnlabelled;

  /// Section header for the account choice.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get reportAccounts;

  /// Chip that includes every account.
  ///
  /// In en, this message translates to:
  /// **'All accounts'**
  String get reportAllAccounts;

  /// Primary button: downloads the PDF and opens the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Make PDF and share'**
  String get reportDownload;

  /// Validation message when no label is selected.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one label.'**
  String get reportPickLabel;

  /// Validation message when no account is selected.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one account.'**
  String get reportPickAccount;

  /// Validation message for a custom range that is too long.
  ///
  /// In en, this message translates to:
  /// **'A report can cover at most 24 months.'**
  String get reportTooLong;

  /// Generic error when the report download fails.
  ///
  /// In en, this message translates to:
  /// **'Could not make the report. Try again.'**
  String get reportFailed;

  /// Error when the report request fails to connect.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection and try again.'**
  String get reportOffline;

  /// Confirmation after the PDF is saved on the phone.
  ///
  /// In en, this message translates to:
  /// **'Saved as {filename}'**
  String reportSaved(String filename);

  /// Settings row title for the app language picker. Shows both languages so it is findable whichever language is active.
  ///
  /// In en, this message translates to:
  /// **'Language · زبان'**
  String get settingsLanguageLabel;

  /// Language option that follows the device language.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// Language option for English. Always written in English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// Language option for Urdu. Always written in Urdu script.
  ///
  /// In en, this message translates to:
  /// **'اردو'**
  String get settingsLanguageUrdu;

  /// Generic back button/link label.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Dismiss button in a delete confirmation dialog: keep the item.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get commonKeep;

  /// Error shown when the session token is missing or expired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get commonSignInAgain;

  /// Title of a delete confirmation dialog for a named item (account or label).
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String commonDeleteNamed(String name);

  /// Account kind: current/checking bank account.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get accountKindBank;

  /// Explanation under the bank account kind.
  ///
  /// In en, this message translates to:
  /// **'Current account you spend from, e.g. HBL, Meezan'**
  String get accountKindBankHint;

  /// Account kind: savings bank account.
  ///
  /// In en, this message translates to:
  /// **'Savings account'**
  String get accountKindSavings;

  /// Explanation under the savings account kind.
  ///
  /// In en, this message translates to:
  /// **'Money you keep aside in the bank'**
  String get accountKindSavingsHint;

  /// Account kind: cash; also the default name prefilled for a new cash account.
  ///
  /// In en, this message translates to:
  /// **'Cash in hand'**
  String get accountKindCash;

  /// Explanation under the cash account kind.
  ///
  /// In en, this message translates to:
  /// **'Money in your purse or at home'**
  String get accountKindCashHint;

  /// Account kind: credit card.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get accountKindCreditCard;

  /// Explanation under the credit card account kind.
  ///
  /// In en, this message translates to:
  /// **'What you owe on the card'**
  String get accountKindCreditCardHint;

  /// Account kind: loan or other money owed.
  ///
  /// In en, this message translates to:
  /// **'Loan / money owed'**
  String get accountKindLoan;

  /// Explanation under the loan account kind.
  ///
  /// In en, this message translates to:
  /// **'Money you owe a bank, a relative or a shop'**
  String get accountKindLoanHint;

  /// Account kind: other assets such as gold and savings certificates.
  ///
  /// In en, this message translates to:
  /// **'Gold & savings certificates'**
  String get accountKindAssets;

  /// Explanation under the other-assets account kind.
  ///
  /// In en, this message translates to:
  /// **'Gold, prize bonds, national savings'**
  String get accountKindAssetsHint;

  /// Validation error when the account name is empty.
  ///
  /// In en, this message translates to:
  /// **'Give the account a name.'**
  String get accountFormNameRequired;

  /// Validation error when the balance is negative.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount without a minus sign.'**
  String get accountFormBalanceNegative;

  /// Validation error when the balance is not a number.
  ///
  /// In en, this message translates to:
  /// **'Enter a number, like 25,000.'**
  String get accountFormBalanceInvalid;

  /// Error when saving a new account without picking a kind.
  ///
  /// In en, this message translates to:
  /// **'Choose what kind of account this is.'**
  String get accountFormKindRequired;

  /// Fallback error when saving an account fails.
  ///
  /// In en, this message translates to:
  /// **'Could not save the account.'**
  String get accountFormSaveFailed;

  /// Body of the delete-account confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Everything recorded in this account is deleted too. This cannot be undone.'**
  String get accountFormDeleteBody;

  /// Fallback error when deleting an account fails.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account.'**
  String get accountFormDeleteFailed;

  /// Title of the account form when editing.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountFormEditTitle;

  /// Title and save button of the account form when adding.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountFormAddTitle;

  /// Header above the list of account kinds.
  ///
  /// In en, this message translates to:
  /// **'What kind of account?'**
  String get accountFormKindHeader;

  /// Hint in the account name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Meezan Bank, Cash in hand'**
  String get accountFormNameHint;

  /// Balance field label for a liability account.
  ///
  /// In en, this message translates to:
  /// **'How much is owed?'**
  String get accountFormOwedLabel;

  /// Balance field label for an asset account.
  ///
  /// In en, this message translates to:
  /// **'How much is in it now?'**
  String get accountFormBalanceLabel;

  /// Help text under the balance field when editing an account.
  ///
  /// In en, this message translates to:
  /// **'Change this to match your bank or purse today.'**
  String get accountFormBalanceEditHelp;

  /// Help text under the balance field when adding an account.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if you are not sure. You can change it later.'**
  String get accountFormBalanceNewHelp;

  /// Button on the account form that deletes the account.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountFormDeleteButton;

  /// Error when the accounts list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your accounts. Pull down to try again.'**
  String get accountsLoadFailed;

  /// Accounts screen group header: bank accounts.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountsGroupBank;

  /// Accounts screen group header: credit cards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get accountsGroupCards;

  /// Accounts screen group header: loans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get accountsGroupLoans;

  /// Accounts screen group header: other liabilities.
  ///
  /// In en, this message translates to:
  /// **'Other money owed'**
  String get accountsGroupOtherOwed;

  /// Accounts screen group header: property and vehicles.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get accountsGroupProperty;

  /// Accounts screen group header: other assets.
  ///
  /// In en, this message translates to:
  /// **'Savings & gold'**
  String get accountsGroupSavings;

  /// Button that opens the statements screen.
  ///
  /// In en, this message translates to:
  /// **'Add statement'**
  String get accountsAddStatement;

  /// Button that opens the add-account form.
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get accountsAdd;

  /// Shown on the 'what we owe' side when there are no liabilities.
  ///
  /// In en, this message translates to:
  /// **'Nothing owed.'**
  String get accountsNothingOwed;

  /// Shown on the 'what we have' side when there are no asset accounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet.'**
  String get accountsEmpty;

  /// Toggle side showing asset accounts and their total.
  ///
  /// In en, this message translates to:
  /// **'What we have'**
  String get accountsWhatWeHave;

  /// Toggle side showing liability accounts and their total.
  ///
  /// In en, this message translates to:
  /// **'What we owe'**
  String get accountsWhatWeOwe;

  /// Hint on an account row that tapping edits it.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get accountsEdit;

  /// Title of the labels screen.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labelsTitle;

  /// Error when labels fail to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your labels. Pull down to try again.'**
  String get labelsLoadFailed;

  /// Error when adding or saving a label with no name.
  ///
  /// In en, this message translates to:
  /// **'Give the label a name.'**
  String get labelsNameRequired;

  /// Fallback error when creating a label fails.
  ///
  /// In en, this message translates to:
  /// **'Could not add the label.'**
  String get labelsAddFailed;

  /// Snackbar after a label is created.
  ///
  /// In en, this message translates to:
  /// **'Added \"{name}\".'**
  String labelsAdded(String name);

  /// Snackbar after a label is created but some auto-label keywords failed.
  ///
  /// In en, this message translates to:
  /// **'Added \"{name}\", but some keywords were not saved.'**
  String labelsAddedKeywordsFailed(String name);

  /// Heading of the new-label form.
  ///
  /// In en, this message translates to:
  /// **'New label'**
  String get labelsNewLabel;

  /// Hint in the new label name field.
  ///
  /// In en, this message translates to:
  /// **'e.g. Committee, Doodh wala'**
  String get labelsNameHint;

  /// Label above the auto-label keywords field.
  ///
  /// In en, this message translates to:
  /// **'Auto-label statement lines containing'**
  String get labelsKeywordsLabel;

  /// Hint in the auto-label keywords field. Keep the comma as typed by the user.
  ///
  /// In en, this message translates to:
  /// **'e.g. ASLAM, DOODH'**
  String get labelsKeywordsHint;

  /// Button that creates a label.
  ///
  /// In en, this message translates to:
  /// **'Add label'**
  String get labelsAddButton;

  /// Header above the list of labels.
  ///
  /// In en, this message translates to:
  /// **'Your labels'**
  String get labelsYourLabels;

  /// Column header for how many times each label was used this month.
  ///
  /// In en, this message translates to:
  /// **'uses this month'**
  String get labelsUsesThisMonth;

  /// Empty state of the labels list.
  ///
  /// In en, this message translates to:
  /// **'No labels yet. Add one above.'**
  String get labelsEmpty;

  /// Shown under a label without auto-label keywords.
  ///
  /// In en, this message translates to:
  /// **'No auto rule'**
  String get labelsNoAutoRule;

  /// Shown under a label with its auto-label keywords.
  ///
  /// In en, this message translates to:
  /// **'Auto: {keywords}'**
  String labelsAutoKeywords(String keywords);

  /// Fallback error when saving a label fails.
  ///
  /// In en, this message translates to:
  /// **'Could not save the label.'**
  String get labelsSaveFailed;

  /// Error when an auto-label keyword could not be removed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove {keyword}.'**
  String labelsKeywordRemoveFailed(String keyword);

  /// Error when an auto-label keyword could not be added.
  ///
  /// In en, this message translates to:
  /// **'Could not add {keyword}.'**
  String labelsKeywordAddFailed(String keyword);

  /// Body of the delete-label confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Lines with this label become unlabelled. Its auto-label keywords stop working.'**
  String get labelsDeleteBody;

  /// Fallback error when deleting a label fails.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the label.'**
  String get labelsDeleteFailed;

  /// Title of the edit-label sheet.
  ///
  /// In en, this message translates to:
  /// **'Edit label'**
  String get labelsEditTitle;

  /// Hint in the keywords field of the edit-label sheet. Keep the comma between the examples.
  ///
  /// In en, this message translates to:
  /// **'Comma separated, e.g. K-ELECTRIC, SSGC'**
  String get labelsKeywordsEditHint;

  /// Button in the edit-label sheet that deletes the label.
  ///
  /// In en, this message translates to:
  /// **'Delete label'**
  String get labelsDeleteButton;

  /// Intro text on the statements screen.
  ///
  /// In en, this message translates to:
  /// **'Add a bank statement. Hisaab reads every line, files each one under the right month and suggests a label.'**
  String get statementsIntro;

  /// Fallback error when uploading a statement fails.
  ///
  /// In en, this message translates to:
  /// **'Upload failed.'**
  String get statementsUploadFailed;

  /// Fallback error when publishing statement lines fails.
  ///
  /// In en, this message translates to:
  /// **'Could not add the lines.'**
  String get statementsPublishFailed;

  /// Button to pick a statement file.
  ///
  /// In en, this message translates to:
  /// **'Choose statement file'**
  String get statementsChooseFile;

  /// Shown while a statement uploads.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get statementsUploading;

  /// Hint under the choose-file button.
  ///
  /// In en, this message translates to:
  /// **'PDF or CSV · up to 6 months in one file'**
  String get statementsFileHint;

  /// Fallback account name when none is selected.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get statementsAccountFallback;

  /// Header of the month coverage strip for an account.
  ///
  /// In en, this message translates to:
  /// **'{name} · last 6 months'**
  String statementsCoverageTitle(String name);

  /// Shown while month coverage loads.
  ///
  /// In en, this message translates to:
  /// **'Checking months…'**
  String get statementsCheckingMonths;

  /// Coverage legend: month with every line labelled.
  ///
  /// In en, this message translates to:
  /// **'All labelled'**
  String get statementsLegendAllLabelled;

  /// Coverage legend: month with unlabelled lines.
  ///
  /// In en, this message translates to:
  /// **'Needs labels'**
  String get statementsLegendNeedsLabels;

  /// Coverage legend: month with no statement lines.
  ///
  /// In en, this message translates to:
  /// **'No statement'**
  String get statementsLegendNoStatement;

  /// Coverage cell: unlabelled lines left in a month.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String statementsMonthLeft(int count);

  /// Fallback file name for a PDF statement.
  ///
  /// In en, this message translates to:
  /// **'PDF statement'**
  String get statementsPdfStatement;

  /// Fallback file name for a CSV statement.
  ///
  /// In en, this message translates to:
  /// **'CSV statement'**
  String get statementsCsvStatement;

  /// Shown when a statement import failed without a server message.
  ///
  /// In en, this message translates to:
  /// **'Hisaab could not read this statement. Try another file.'**
  String get statementsReadFailed;

  /// Progress text while statement lines are published.
  ///
  /// In en, this message translates to:
  /// **'Adding the lines to your books…'**
  String get statementsAddingLines;

  /// Progress text while a statement is parsed.
  ///
  /// In en, this message translates to:
  /// **'Hisaab is reading every line. This can take a minute.'**
  String get statementsReading;

  /// Caption under the number of lines found in a statement.
  ///
  /// In en, this message translates to:
  /// **'lines found'**
  String get statementsLinesFound;

  /// Shown when a CSV import needs column mapping on the web.
  ///
  /// In en, this message translates to:
  /// **'This file needs its columns matched on the Hisaab website before the lines can be added.'**
  String get statementsNeedsColumnMapping;

  /// Button that publishes the parsed statement lines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add this 1 line} other{Add these {count} lines}}'**
  String statementsAddLines(int count);

  /// Caption under the number of lines labelled automatically.
  ///
  /// In en, this message translates to:
  /// **'auto-labelled'**
  String get statementsAutoLabelled;

  /// Caption under the number of lines that need the user to label them.
  ///
  /// In en, this message translates to:
  /// **'need you'**
  String get statementsNeedYou;

  /// Button that opens the statement review screen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Label the 1 item} other{Label the {count} items}}'**
  String statementsLabelItems(int count);

  /// Shown when no imported lines need a label.
  ///
  /// In en, this message translates to:
  /// **'Everything is labelled.'**
  String get statementsAllLabelled;

  /// Statement import status: failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statementsStatusFailed;

  /// Statement import status: lines added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get statementsStatusAdded;

  /// Statement import status: lines being added.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get statementsStatusAdding;

  /// Statement import status: being parsed.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get statementsStatusReading;

  /// Statement import status: parsed and ready to add.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get statementsStatusRead;

  /// Statement import status: queued.
  ///
  /// In en, this message translates to:
  /// **'Waiting…'**
  String get statementsStatusWaiting;

  /// Header of the recent statements list.
  ///
  /// In en, this message translates to:
  /// **'Recent statements'**
  String get statementsRecent;

  /// Fallback account name in the recent statements list.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get statementsStatementFallback;

  /// When a recent statement was uploaded.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String statementsAddedOn(String date);

  /// Number of lines in a recent statement.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line} other{{count} lines}}'**
  String statementsLinesCount(int count);

  /// Error when the lines to review fail to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load the statement lines.'**
  String get statementReviewLoadFailed;

  /// Snackbar when a line was labelled but its auto-label rule failed.
  ///
  /// In en, this message translates to:
  /// **'Labelled this one. The keyword was not saved: {error}'**
  String statementReviewKeywordFailed(String error);

  /// Fallback error detail when the server gives none.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get statementReviewUnknownError;

  /// Shown when there were no unlabelled lines to start with.
  ///
  /// In en, this message translates to:
  /// **'Nothing to label. Every line has a label.'**
  String get statementReviewNothingToLabel;

  /// Shown after the last line is labelled.
  ///
  /// In en, this message translates to:
  /// **'All done. Every line has a label.'**
  String get statementReviewAllDone;

  /// Button that leaves the review screen.
  ///
  /// In en, this message translates to:
  /// **'Done for now'**
  String get statementReviewDoneForNow;

  /// Progress counter in the review screen header.
  ///
  /// In en, this message translates to:
  /// **'{position} of {total}'**
  String statementReviewPosition(int position, int total);

  /// Question above the labels for an incoming line.
  ///
  /// In en, this message translates to:
  /// **'Where did this come from?'**
  String get statementReviewWhereFrom;

  /// Question above the labels for an outgoing line.
  ///
  /// In en, this message translates to:
  /// **'What was this?'**
  String get statementReviewWhatWasThis;

  /// Choice that excludes the line instead of labelling it.
  ///
  /// In en, this message translates to:
  /// **'Not an expense'**
  String get statementReviewNotExpense;

  /// Link that opens the labels screen.
  ///
  /// In en, this message translates to:
  /// **'+ Make a new label'**
  String get statementReviewNewLabel;

  /// Checkbox to label every similar line; the number is shown in bold.
  ///
  /// In en, this message translates to:
  /// **'Label all {count} like this'**
  String statementReviewLabelAllSimilar(int count);

  /// Checkbox to create an auto-label rule when there are no similar lines yet.
  ///
  /// In en, this message translates to:
  /// **'Auto-label future lines like this'**
  String get statementReviewAutoLabelFuture;

  /// Label before the auto-label keyword field.
  ///
  /// In en, this message translates to:
  /// **'Lines containing'**
  String get statementReviewLinesContaining;

  /// Button that skips the current line.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get statementReviewSkip;

  /// Button that saves the label and shows the next line.
  ///
  /// In en, this message translates to:
  /// **'Save & next'**
  String get statementReviewSaveNext;

  /// Title of the budget screen.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetsScreenTitle;

  /// Budget summary note when spending exceeds the plan.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}.'**
  String budgetsOverByNote(String amount);

  /// Budget summary note during the month.
  ///
  /// In en, this message translates to:
  /// **'{amount} left for the last {days, plural, =1{1 day} other{{days} days}}. Blue line is today.'**
  String budgetsLeftForDays(String amount, int days);

  /// Budget summary note outside the current month.
  ///
  /// In en, this message translates to:
  /// **'{amount} left.'**
  String budgetsLeftNote(String amount);

  /// Caption above the amount spent when a plan exists.
  ///
  /// In en, this message translates to:
  /// **'Spent of {amount} planned'**
  String budgetsSpentOfPlanned(String amount);

  /// Caption above the amount spent when no plan exists.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetsSpent;

  /// Which day of the budget period today is.
  ///
  /// In en, this message translates to:
  /// **'day {day} of {days}'**
  String budgetsDayOf(int day, int days);

  /// Category row note when the category has no budget.
  ///
  /// In en, this message translates to:
  /// **'No limit set'**
  String get budgetsNoLimitSet;

  /// Category row note when spending exceeds its budget.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String budgetsOverByLine(String amount);

  /// Title and button of the prompt shown when there are no accounts.
  ///
  /// In en, this message translates to:
  /// **'Add your first account'**
  String get noAccountsTitle;

  /// Explanation in the no-accounts prompt. The quoted name matches accountKindCash.
  ///
  /// In en, this message translates to:
  /// **'Accounts are where money is paid from and into. Start with \"Cash in hand\", then add your bank account.'**
  String get noAccountsBody;

  /// Title of the app-update prompt.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get upgradeTitle;

  /// Body of the app-update prompt.
  ///
  /// In en, this message translates to:
  /// **'{appName} {storeVersion} is now available — you have {installedVersion}.\n\nWhat\'s new? Check the store for release notes.'**
  String upgradeBody(
      String appName, String storeVersion, String installedVersion);

  /// Button in the app-update prompt.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get upgradeNow;

  /// Button that dismisses the app-update prompt.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get upgradeLater;

  /// Accessibility name of the black label color.
  ///
  /// In en, this message translates to:
  /// **'Ink'**
  String get swatchInk;

  /// Accessibility name of the cobalt blue label color.
  ///
  /// In en, this message translates to:
  /// **'Cobalt'**
  String get swatchCobalt;

  /// Accessibility name of the amber label color.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get swatchAmber;

  /// Accessibility name of the olive label color.
  ///
  /// In en, this message translates to:
  /// **'Olive'**
  String get swatchOlive;

  /// Accessibility name of the plum label color.
  ///
  /// In en, this message translates to:
  /// **'Plum'**
  String get swatchPlum;

  /// Accessibility name of the steel blue label color.
  ///
  /// In en, this message translates to:
  /// **'Steel'**
  String get swatchSteel;

  /// Accessibility name of the stone grey label color.
  ///
  /// In en, this message translates to:
  /// **'Stone'**
  String get swatchStone;

  /// Button in the transaction form's account row when the user has no accounts yet.
  ///
  /// In en, this message translates to:
  /// **'+ Add an account'**
  String get transactionFormAddFirstAccount;

  /// Last option in the transaction form's account dropdown; opens the add-account form.
  ///
  /// In en, this message translates to:
  /// **'+ New account'**
  String get transactionFormNewAccountOption;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sv', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sv':
      return AppLocalizationsSv();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
