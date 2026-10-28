// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hisaab';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonTryAgain => 'Try Again';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAll => 'All';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonClose => 'Close';

  @override
  String get commonUndo => 'Undo';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailRequired => 'Email is required';

  @override
  String get loginEmailInvalid => 'Please enter a valid email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordRequired => 'Password is required';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginSignInWithGoogle => 'Sign in with Google';

  @override
  String get loginMfaLabel => 'Authentication Code';

  @override
  String get navHome => 'Home';

  @override
  String get navIntro => 'Intro';

  @override
  String get navAssistant => 'Assistant';

  @override
  String get navMore => 'More';

  @override
  String get dashboardSyncError => 'Sync failed';

  @override
  String get dashboardSyncFailed => 'Sync failed. Please try again.';

  @override
  String get dashboardRefreshing => 'Refreshing accounts…';

  @override
  String get dashboardAccountsUpdated => 'Accounts updated';

  @override
  String get dashboardSyncing => 'Syncing data from server…';

  @override
  String get dashboardSynced => 'Synced';

  @override
  String get dashboardErrorLoadingAccounts => 'Failed to load accounts';

  @override
  String get dashboardNoAccounts => 'No accounts yet';

  @override
  String get dashboardNoAccountsSubtitle =>
      'Add accounts in the web app to see them here.';

  @override
  String get dashboardFilterEmpty => 'No accounts match the current filter';

  @override
  String get chatListNewChat => 'Ask a question';

  @override
  String get chatListEmptySubtitle =>
      'Nothing asked yet. Your questions will show here.';

  @override
  String get chatListDeleteTitle => 'Delete Chat';

  @override
  String get chatConversationNewTitle => 'New question';

  @override
  String get chatConversationMessageHint => 'Ask about your money…';

  @override
  String chatConversationGreetingWithName(String firstName) {
    return 'Hi $firstName, how can I help?';
  }

  @override
  String get chatConversationGreetingNoName => 'Hi there, how can I help?';

  @override
  String get transactionFormNewTitle => 'New Transaction';

  @override
  String get transactionFormTypeLabel => 'Type';

  @override
  String get transactionFormTypeExpense => 'Expense';

  @override
  String get transactionFormTypeIncome => 'Income';

  @override
  String get transactionFormAmountLabel => 'Amount';

  @override
  String get transactionFormAmountRequired => 'Amount is required';

  @override
  String get transactionFormAmountInvalid => 'Please enter a valid amount';

  @override
  String get transactionFormDateLabel => 'Date';

  @override
  String get transactionFormNameLabel => 'Name';

  @override
  String get transactionFormCategoryLabel => 'Category';

  @override
  String get transactionEditTitle => 'Edit Transaction';

  @override
  String get transactionEditNameLabel => 'Name';

  @override
  String get transactionEditNameRequired => 'Name is required';

  @override
  String get transactionEditNotesLabel => 'Notes';

  @override
  String get transactionEditCategoryLabel => 'Category';

  @override
  String get transactionEditMerchantLabel => 'Merchant';

  @override
  String get transactionEditTagsLabel => 'Tags';

  @override
  String get transactionEditSaving => 'Saving…';

  @override
  String get transactionsListDeleteTitle => 'Delete Transaction';

  @override
  String transactionsListDeleteSingleContent(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get transactionsListDeleteMultiTitle => 'Delete Transactions';

  @override
  String get transactionsListDeleteMultiContent =>
      'Are you sure you want to delete the selected transactions?';

  @override
  String get transactionsListEmpty => 'No transactions';

  @override
  String get transactionsListAuthFailed =>
      'Authentication failed: Please log in again';

  @override
  String get transactionsListNoTransactionsYet => 'No transactions yet';

  @override
  String get transactionsListEmptyAddFirst =>
      'Tap + to add your first transaction';

  @override
  String get transactionsListNoCategoryMatch =>
      'No transactions match this category';

  @override
  String get transactionsListRetry => 'Retry';

  @override
  String get transactionsListDeletedSuccess => 'Transaction deleted';

  @override
  String get transactionsListSingleDeleteFailed =>
      'Failed to delete transaction';

  @override
  String transactionsListDeletedMulti(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count transactions',
      one: 'Deleted $count transaction',
    );
    return '$_temp0';
  }

  @override
  String get transactionsListDeleteFailed => 'Failed to delete transactions';

  @override
  String get transactionsListDeleteNoToken =>
      'Failed to delete: No access token';

  @override
  String get transactionsListUndoTitle => 'Undo Transaction';

  @override
  String get transactionsListUndoRemovePending =>
      'Remove this pending transaction?';

  @override
  String get transactionsListUndoRestoreConfirm => 'Restore this transaction?';

  @override
  String get transactionsListUndoPendingRemoved =>
      'Pending transaction removed';

  @override
  String get transactionsListUndoRestored => 'Transaction restored';

  @override
  String get transactionsListUndoFailed => 'Failed to undo transaction';

  @override
  String get settingsSectionDisplay => 'Display';

  @override
  String get settingsSectionConnection => 'Connection';

  @override
  String get settingsSectionDataManagement => 'Data Management';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsSectionDangerZone => 'Danger Zone';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsProxyHeadersLabel => 'Custom Proxy Headers';

  @override
  String get settingsPrivacyHideAmountsLabel => 'Hide amounts';

  @override
  String get settingsPrivacyHideAmountsContent =>
      'Mask money values across the app';

  @override
  String get settingsBiometricLabel => 'Biometric Lock';

  @override
  String get settingsBiometricEnable => 'Enable biometric lock?';

  @override
  String get settingsBiometricEnableContent =>
      'Require biometric authentication when resuming the app.';

  @override
  String get settingsCheckForUpdates => 'Check for Updates';

  @override
  String get settingsUpdateAvailableTitle => 'Update Available';

  @override
  String settingsUpdateAvailableContent(String version) {
    return 'Version $version is available. Update now?';
  }

  @override
  String get settingsUpdateNewerVersionFallback => 'a newer version';

  @override
  String get settingsUpdateNow => 'Update Now';

  @override
  String get settingsNoUpdateAvailable => 'You\'re on the latest version.';

  @override
  String get settingsUpdateError => 'Could not check for updates.';

  @override
  String get settingsClearDataTitle => 'Clear All Data';

  @override
  String get settingsClearDataContent =>
      'This will remove all locally cached data. Your data on the server will not be affected.';

  @override
  String get settingsClearData => 'Clear Data';

  @override
  String get settingsClearDataSuccess => 'Local data cleared';

  @override
  String get settingsDeleteAccountTitle => 'Delete Account';

  @override
  String get settingsDeleteAccount => 'Delete Account';

  @override
  String get settingsSignOutTitle => 'Sign Out';

  @override
  String get settingsSignOutContent => 'Are you sure you want to sign out?';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsDebugLogs => 'Debug Logs';

  @override
  String get ssoOnboardingTitle => 'Link Your Account';

  @override
  String get ssoOnboardingTabLink => 'Link existing';

  @override
  String get ssoOnboardingTabCreate => 'Create new';

  @override
  String get ssoOnboardingFirstNameLabel => 'First Name';

  @override
  String get ssoOnboardingLastNameLabel => 'Last Name';

  @override
  String get ssoOnboardingLinkButton => 'Link Account';

  @override
  String get ssoOnboardingCreateButton => 'Create Account';

  @override
  String get ssoOnboardingAcceptInvitation => 'Accept Invitation';

  @override
  String get moreRecentTransactions => 'Recent Transactions';

  @override
  String get moreRecentTransactionsSubtitle =>
      'View recent transactions across all accounts';

  @override
  String get biometricTitle => 'App Locked';

  @override
  String get biometricSubtitle => 'Authenticate to continue';

  @override
  String get biometricUnlock => 'Unlock';

  @override
  String get biometricAuthenticating => 'Authenticating…';

  @override
  String get biometricLogOut => 'Log out';

  @override
  String get backendConfigTitle => 'Configuration';

  @override
  String get backendConfigSubtitle => 'Update your Hisaab server URL';

  @override
  String get backendConfigExampleUrlsLabel => 'Example URLs';

  @override
  String get backendConfigUrlLabel => 'Hisaab server URL';

  @override
  String get backendConfigUrlHint => 'https://app.sure.am';

  @override
  String get backendConfigProxyHeadersLabel => 'Custom proxy headers';

  @override
  String get backendConfigProxyHeadersSubtitle =>
      'Optional headers for a reverse proxy or auth gateway';

  @override
  String backendConfigProxyHeadersCount(int count) {
    return '$count configured';
  }

  @override
  String get backendConfigTesting => 'Testing…';

  @override
  String get backendConfigTestButton => 'Test Connection';

  @override
  String get backendConfigContinueButton => 'Continue';

  @override
  String get backendConfigChangeHint =>
      'You can change this later in the settings.';

  @override
  String get recentTransactionsTitle => 'Recent Transactions';

  @override
  String get recentTransactionsEmpty => 'No Transactions';

  @override
  String get recentTransactionsDisplayLimit => 'Display Limit';

  @override
  String recentTransactionsShowN(int count) {
    return 'Show $count';
  }

  @override
  String get recentTransactionsPullToRefresh => 'Pull to refresh';

  @override
  String get logViewerTitle => 'Debug Logs';

  @override
  String get logViewerFilterAll => 'All';

  @override
  String get logViewerFilterInfo => 'Info';

  @override
  String get logViewerFilterWarning => 'Warning';

  @override
  String get logViewerFilterError => 'Error';

  @override
  String get logViewerFilterDebug => 'Debug';

  @override
  String get logViewerAutoScrollEnable => 'Enable auto-scroll';

  @override
  String get logViewerAutoScrollDisable => 'Disable auto-scroll';

  @override
  String get logViewerCopyLogs => 'Copy logs';

  @override
  String get logViewerClearLogs => 'Clear logs';

  @override
  String get logViewerLogsCopied => 'Logs copied to clipboard';

  @override
  String get logViewerEmpty => 'No logs yet';

  @override
  String get connectivityOffline => 'You are offline';

  @override
  String connectivityPendingSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions pending sync',
      one: '$count transaction pending sync',
    );
    return '$_temp0';
  }

  @override
  String get connectivitySyncNow => 'Sync Now';

  @override
  String get proxyHeadersAddHeader => 'Add header';

  @override
  String get proxyHeadersNameLabel => 'Header name';

  @override
  String get proxyHeadersNameHint => 'X-Auth-Token';

  @override
  String get proxyHeadersValueLabel => 'Header value';

  @override
  String get proxyHeadersRemove => 'Remove header';

  @override
  String get accountDetailRefreshTooltip => 'Refresh account details';

  @override
  String get accountDetailRecentBalanceHistory => 'Recent balance history';

  @override
  String get accountDetailTopHoldings => 'Top holdings';

  @override
  String get accountDetailHoldingFallback => 'Holding';

  @override
  String accountDetailCashChip(String amount) {
    return 'Cash $amount';
  }

  @override
  String get biometricLockFailedRetry =>
      'Authentication failed. Tap Unlock to try again.';

  @override
  String get settingsBiometricVerifyReason =>
      'Verify biometric to enable app lock';

  @override
  String get settingsBiometricFailed => 'Biometric authentication failed.';

  @override
  String get settingsUpdateOpenStoreError => 'Unable to open store link';

  @override
  String get settingsClearDataFailed => 'Failed to clear local data.';

  @override
  String get settingsClearDataSuccessDetailed =>
      'Local data cleared successfully. Pull to refresh to sync from server.';

  @override
  String get settingsContactOpenLinkError => 'Unable to open link';

  @override
  String get settingsResetAccountContent =>
      'Resetting your account will delete all your accounts, categories, merchants, tags, and other data, but keep your user account intact.\n\nThis action cannot be undone. Are you sure?';

  @override
  String get settingsResetAccount => 'Reset Account';

  @override
  String get settingsResetAccountInitiated =>
      'Account reset has been initiated. This may take a moment.';

  @override
  String get settingsResetAccountFailed => 'Failed to reset account';

  @override
  String get settingsDeleteAccountConfirmContent =>
      'Deleting your account will permanently remove all your data and cannot be undone.\n\nAre you sure you want to delete your account?';

  @override
  String get settingsDeleteAccountFailed => 'Failed to delete account';

  @override
  String get settingsProxyHeadersNote =>
      'Headers are sent by the app with API requests. External browser SSO pages may not receive them.';

  @override
  String get settingsProxyHeadersSaved => 'Custom proxy headers saved';

  @override
  String get settingsProxyHeadersSaveFailed =>
      'Failed to save custom proxy headers.';

  @override
  String settingsAppVersion(String version) {
    return 'App Version: $version';
  }

  @override
  String get settingsCheckForUpdatesSubtitle =>
      'See if a newer version is available';

  @override
  String get settingsContactUs => 'Contact us';

  @override
  String get settingsDebugLogsSemantics => 'Open debug logs';

  @override
  String get settingsDebugLogsSubtitle => 'View app diagnostic logs';

  @override
  String get settingsGroupByAccountType => 'Group by Account Type';

  @override
  String get settingsGroupByAccountTypeSubtitle =>
      'Group accounts by type (Crypto, Bank, etc.)';

  @override
  String get settingsProxyHeadersTileTitle => 'Custom proxy headers';

  @override
  String get settingsProxyHeadersTileSubtitleEmpty =>
      'Optional headers for a reverse proxy or auth gateway';

  @override
  String settingsProxyHeadersTileSubtitleCount(int count) {
    return '$count configured';
  }

  @override
  String get settingsClearDataTileSubtitle =>
      'Remove all cached transactions and accounts';

  @override
  String get settingsResetAccountTileSubtitle =>
      'Delete all accounts, categories, merchants, and tags but keep your user account';

  @override
  String get settingsDeleteAccountTileSubtitle =>
      'Permanently remove all your data. This cannot be undone.';

  @override
  String get settingsUserFallback => 'User';

  @override
  String get chatListError => 'Failed to load chats';

  @override
  String get chatListJustNow => 'Just now';

  @override
  String chatListDeleteSingleContent(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get loginSignUpOpenError => 'Unable to open sign up page';

  @override
  String get loginDemoOrSignUpPrefix => 'Demo account or ';

  @override
  String get loginSignUpLink => 'Sign Up';

  @override
  String get loginSignUpSuffix => '!';

  @override
  String get loginMfaInfo =>
      'Two-factor authentication is enabled. Enter your code.';

  @override
  String get loginMfaCodeRequired => 'Please enter your authentication code';

  @override
  String get loginOrDivider => 'or';

  @override
  String get loginServerUrlHeading => 'Hisaab server URL:';

  @override
  String get loginBackendSettingsTooltip => 'Backend Settings';

  @override
  String get transactionEditSessionExpired =>
      'Session expired. Please login again.';

  @override
  String get transactionEditUpdated => 'Transaction updated';

  @override
  String get transactionEditUpdateFailed => 'Failed to update transaction';

  @override
  String transactionEditNameMaxLength(int max) {
    return 'Name must be $max characters or fewer';
  }

  @override
  String get transactionEditNameInvalidChars =>
      'Name contains unsupported characters';

  @override
  String transactionEditNotesMaxLength(int max) {
    return 'Notes must be $max characters or fewer';
  }

  @override
  String get transactionEditNotesInvalidChars =>
      'Notes contain unsupported characters';

  @override
  String get transactionEditNoCategory => 'No category';

  @override
  String get transactionEditCurrentCategory => 'Current category';

  @override
  String get transactionEditNoMerchant => 'No merchant';

  @override
  String get transactionEditCurrentMerchant => 'Current merchant';

  @override
  String get transactionEditNoTags => 'No tags available';

  @override
  String get transactionEditUnknownTag => 'Unknown tag';

  @override
  String get transactionEditSyncedOnly =>
      'Only synced transactions can be edited from mobile.';

  @override
  String get transactionEditCategoryHelper => 'Choose a replacement category';

  @override
  String get transactionEditMerchantHelper => 'Choose a replacement merchant';

  @override
  String get transactionFormSessionExpired =>
      'Session expired. Please login again.';

  @override
  String get transactionFormAmountRequiredPrompt => 'Please enter an amount';

  @override
  String get transactionFormAmountInvalidNumber =>
      'Please enter a valid number';

  @override
  String get transactionFormAmountTooSmall => 'Amount must be greater than 0';

  @override
  String get transactionFormCreateSuccessOnline =>
      'Transaction created successfully';

  @override
  String get transactionFormCreateSuccessOffline =>
      'Transaction saved (will sync when online)';

  @override
  String get transactionFormCreateFailed => 'Failed to create transaction';

  @override
  String transactionFormGenericError(String error) {
    return 'Error: $error';
  }

  @override
  String get transactionFormLess => 'Less';

  @override
  String get transactionFormMore => 'More';

  @override
  String get transactionFormDateHelper => 'Optional (default: today)';

  @override
  String get transactionFormNameHelper => 'Optional (default: SureApp)';

  @override
  String get transactionFormCategoryLoading => 'Loading categories…';

  @override
  String get transactionFormCategoryHelper => 'Optional';

  @override
  String get transactionFormNoCategory => 'No category';

  @override
  String get transactionFormCreateButton => 'Create Transaction';

  @override
  String get transactionFormAmountHelper => 'Required';

  @override
  String get logViewerClearConfirm =>
      'Are you sure you want to clear all logs?';

  @override
  String get logViewerClear => 'Clear';

  @override
  String get chatConversationEditTitle => 'Edit Title';

  @override
  String get chatConversationTitleLabel => 'Chat Title';

  @override
  String get chatConversationRefreshTooltip => 'Refresh';

  @override
  String get chatConversationLoadError => 'Failed to load chat';

  @override
  String get navEnableAiChatTitle => 'Turn on the assistant?';

  @override
  String get navEnableAiChatContent =>
      'The assistant reads your entries to answer questions about your money. It is off for your account right now.';

  @override
  String get navEnableAiChatConfirm => 'Turn on AI';

  @override
  String get navEnableAiChatFailed => 'Unable to enable AI right now.';

  @override
  String get transactionsListEditTooltip => 'Edit transaction';

  @override
  String get connectivitySignInToSync => 'Please sign in to sync transactions';

  @override
  String get connectivitySyncSuccess => 'Transactions synced successfully';

  @override
  String get connectivitySyncFailed =>
      'Failed to sync transactions. Please try again.';

  @override
  String get connectivityAuthFailed =>
      'Unable to authenticate. Please try again.';

  @override
  String ssoOnboardingSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get ssoOnboardingGoogleVerified => 'Google account verified';

  @override
  String get ssoOnboardingLinkCredentialsNote =>
      'Enter your existing account credentials to link with Google Sign-In.';

  @override
  String get ssoOnboardingPendingInvitationNote =>
      'You have a pending invitation. Accept it to join an existing household.';

  @override
  String get ssoOnboardingCreateIdentityNote =>
      'Create a new account using your Google identity.';

  @override
  String get ssoOnboardingFirstNameRequired => 'First name is required';

  @override
  String get ssoOnboardingLastNameRequired => 'Last name is required';

  @override
  String get backendConfigTimeout =>
      'Connection timeout. Please check the URL and try again.';

  @override
  String get backendConfigSuccess => 'Connection successful!';

  @override
  String backendConfigServerError(int code) {
    return 'Server responded with status $code. Please check if this is a Hisaab backend server.';
  }

  @override
  String backendConfigConnectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String backendConfigSaveFailed(String error) {
    return 'Failed to save URL: $error';
  }

  @override
  String get backendConfigUrlRequired => 'Please enter a backend URL';

  @override
  String get backendConfigUrlScheme =>
      'URL must start with http:// or https://';

  @override
  String get backendConfigUrlInvalid => 'Please enter a valid URL';

  @override
  String get backendConfigHeadersHelp =>
      'Headers are sent by the app with API requests. External browser SSO pages may not receive them.';

  @override
  String get recentTransactionsUnknownAccount => 'Unknown Account';

  @override
  String get accountDetailUnavailable =>
      'Account details are temporarily unavailable';

  @override
  String chatListMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String chatListHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String chatListDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get chatConversationStartFailed =>
      'Failed to start conversation. Please try again.';

  @override
  String get moreBudgets => 'Budgets';

  @override
  String get moreBudgetsSubtitle => 'Budgeted vs. actual spending by category';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get budgetsPreviousMonth => 'Previous month';

  @override
  String get budgetsNextMonth => 'Next month';

  @override
  String get budgetsBudgeted => 'Budgeted';

  @override
  String get budgetsActual => 'Actual';

  @override
  String get budgetsRemaining => 'Remaining';

  @override
  String get budgetsIncome => 'Income';

  @override
  String budgetsExpectedIncome(String amount) {
    return 'Expected $amount';
  }

  @override
  String budgetsOfAmount(String amount) {
    return 'of $amount';
  }

  @override
  String budgetsAmountLeft(String amount) {
    return '$amount left';
  }

  @override
  String budgetsOverBy(String amount) {
    return '$amount over';
  }

  @override
  String budgetsRolledOver(String amount) {
    return '+$amount rolled over';
  }

  @override
  String get budgetsSharedBudget => 'Shared budget';

  @override
  String get budgetsNoLimit => 'No budget';

  @override
  String get budgetsCategoriesTitle => 'Categories';

  @override
  String budgetsFilterOverBudget(int count) {
    return 'Over budget ($count)';
  }

  @override
  String get budgetsOverBudget => 'Over budget';

  @override
  String get budgetsNearLimit => 'Near limit';

  @override
  String budgetsBudgetNumber(int number) {
    return 'Budget $number';
  }

  @override
  String budgetsNoBudgetTitle(String month) {
    return 'No budget for $month';
  }

  @override
  String get budgetsNoBudgetMessage =>
      'Budgets are created in Hisaab on the web. Open Budgets there to set one up for this month.';

  @override
  String get budgetsNotSetUpMessage =>
      'No spending limits are set for this month yet. Set them up in Hisaab on the web.';

  @override
  String get budgetsNoCategories =>
      'No budgeted categories or spending this month.';

  @override
  String get budgetsOfflineTitle => 'You\'re offline';

  @override
  String get budgetsOfflineMessage =>
      'Connect to the internet to load this month\'s budget.';

  @override
  String get budgetsOfflineCached =>
      'Offline. Showing the figures loaded earlier.';

  @override
  String get budgetsRefreshFailed =>
      'Couldn\'t refresh. Showing the figures loaded earlier.';

  @override
  String get budgetsLoadFailed => 'Couldn\'t load budgets';

  @override
  String get budgetsSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String budgetCategoryTransactionsEmpty(String month) {
    return 'No transactions in this category for $month.';
  }

  @override
  String get budgetCategoryTransactionsLoadMore => 'Load more';

  @override
  String get budgetCategoryTransactionsLoadFailed =>
      'Couldn\'t load transactions';

  @override
  String get navActivity => 'Activity';

  @override
  String get navStatements => 'Statements';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navAddExpense => 'Add expense';

  @override
  String get homeNoLabel => 'No label';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeLoadFailed => 'Could not load this month.';

  @override
  String homeSpentIn(String month) {
    return 'Spent in $month';
  }

  @override
  String homeMoreThan(String amount, String month) {
    return '$amount more than $month';
  }

  @override
  String homeLessThan(String amount, String month) {
    return '$amount less than $month';
  }

  @override
  String homeSameAs(String month) {
    return 'Same as $month';
  }

  @override
  String get homeCameIn => 'Came in';

  @override
  String get homeWentOut => 'Went out';

  @override
  String get homeLeftOver => 'Left over';

  @override
  String get homeWhereItWent => 'Where it went';

  @override
  String get homeBudget => 'Budget';

  @override
  String get homeNothingSpent => 'Nothing spent this month yet.';

  @override
  String get homeNetWorth => 'Net worth';

  @override
  String get homeBalanceSheet => 'Balance sheet';

  @override
  String homeAssetsOwed(String assets, String owed) {
    return 'Assets $assets · Owed $owed';
  }

  @override
  String homeNeedLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count statement items need a label',
      one: '1 statement item needs a label',
    );
    return '$_temp0';
  }

  @override
  String homeNeedLabelDetail(String month, int sorted) {
    return '$month · $sorted sorted already';
  }

  @override
  String get activityNoLabel => 'No label';

  @override
  String get activitySearchHint => 'Search this month';

  @override
  String get activityClearSearch => 'Clear search';

  @override
  String get activityOfflineNote =>
      'Offline. Showing what is saved on this phone.';

  @override
  String get activityLoadFailedNote =>
      'Could not reach the server. Showing what is saved on this phone.';

  @override
  String get activityEmpty => 'Nothing here for this month.';

  @override
  String get activityIn => 'In';

  @override
  String get activityOut => 'Out';

  @override
  String get activityEntries => 'Entries';

  @override
  String get activityWaitingToSync => 'Waiting to sync';

  @override
  String get activityWaitingToDelete => 'Will be deleted';

  @override
  String get activityTransfer => 'Transfer';

  @override
  String get activityHasReceipt => 'Has receipt';

  @override
  String get detailDelete => 'Delete transaction';

  @override
  String get detailMoneyIn => 'Money in';

  @override
  String get detailMoneyOut => 'Money out';

  @override
  String get detailNote => 'Note';

  @override
  String get detailNoteHint => 'Add a note';

  @override
  String get detailReceipt => 'Receipt';

  @override
  String get detailAttachReceipt => 'Attach';

  @override
  String get detailReplaceReceipt => 'Replace';

  @override
  String get detailNoReceipt => 'No receipt attached.';

  @override
  String detailMoreReceipts(int count) {
    return '+$count more';
  }

  @override
  String get receiptRemove => 'Remove receipt';

  @override
  String get receiptNeedsInternet =>
      'Connect to the internet to attach a receipt.';

  @override
  String get receiptUploadFailed => 'Could not attach the receipt.';

  @override
  String get receiptRemoveFailed => 'Could not remove the receipt.';

  @override
  String get receiptTakePhoto => 'Take photo';

  @override
  String get receiptFromGallery => 'From gallery';

  @override
  String get formTypeExpense => 'Expense';

  @override
  String get formTypeIncome => 'Income';

  @override
  String get formLabel => 'Label';

  @override
  String get formManage => 'Manage';

  @override
  String get formNewLabel => '+ New label';

  @override
  String get formWhatFor => 'What for';

  @override
  String get formWhatForHint => 'e.g. Imtiaz Supermarket';

  @override
  String get formPaidFrom => 'Paid from';

  @override
  String get formPaidInto => 'Paid into';

  @override
  String get formNoAccounts => 'No accounts yet';

  @override
  String get formOptional => 'Optional';

  @override
  String get formReceipt => 'Receipt or screenshot';

  @override
  String get formSaveExpense => 'Save expense';

  @override
  String get formSaveIncome => 'Save income';

  @override
  String get formPickAccount => 'Choose an account first.';

  @override
  String get formSaved => 'Saved';

  @override
  String get formSavedReceiptOffline =>
      'Saved. The receipt was not attached because you are offline.';

  @override
  String get loginTagline => 'Every rupee, month by month.';

  @override
  String get loginServer => 'Server';

  @override
  String get loginServerChange => 'Change';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginNewHere => 'New here? ';

  @override
  String get loginCreateAccount => 'Create an account';

  @override
  String get activityViewList => 'List';

  @override
  String get activityViewCalendar => 'Calendar';

  @override
  String get activityImportStatement => 'Import statement';

  @override
  String get activityPickDay => 'Tap a day to see its payments.';

  @override
  String activityPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
      zero: 'No payments',
    );
    return '$_temp0';
  }

  @override
  String get activityNothingThisDay => 'Nothing on this day.';

  @override
  String get homeStatementsHint => 'Add a bank or card statement';

  @override
  String get homeNotesForYou => 'Notes for you';

  @override
  String homeInsightAsk(String title) {
    return 'Tell me more: $title';
  }

  @override
  String get assistantIntro =>
      'Ask about your money in plain words. Answers come from your own entries.';

  @override
  String get assistantEarlier => 'Earlier questions';

  @override
  String get assistantTryAsking => 'Try asking';

  @override
  String get assistantThinking => 'Thinking';

  @override
  String get assistantSend => 'Send';

  @override
  String assistantLookedUp(String subject) {
    return 'Looked up $subject';
  }

  @override
  String get chatSuggestionGroceries =>
      'How much did we spend on groceries this month?';

  @override
  String get chatSuggestionDay => 'What did I pay on 15 October?';

  @override
  String get chatSuggestionBills =>
      'Which bills went up compared to last month?';

  @override
  String get chatSuggestionSave => 'Where can we save next month?';

  @override
  String get legalPrivacy => 'Privacy Policy';

  @override
  String get legalTerms => 'Terms of Service';

  @override
  String get legalOpenLinkError => 'Couldn\'t open the link';

  @override
  String get signUpTitle => 'Create account';

  @override
  String get signUpSubtitle =>
      'Keep your household\'s spending in one place. Your account is created on the server shown on the sign-in screen.';

  @override
  String get signUpPasswordRules =>
      'At least 8 characters with upper and lower case letters, a number and a symbol.';

  @override
  String get signUpConfirmPasswordLabel => 'Confirm password';

  @override
  String get signUpPasswordsDoNotMatch => 'Passwords don\'t match';

  @override
  String get signUpSubmit => 'Create account';

  @override
  String get signUpAgreementPrefix =>
      'By creating an account you agree to the ';

  @override
  String get signUpAgreementAnd => ' and ';

  @override
  String get settingsSourceCode => 'Source code';

  @override
  String get settingsSourceCodeSubtitle =>
      'Hisaab is based on Sure and licensed under AGPL-3.0';

  @override
  String get settingsDeleteAccountDone => 'Your account has been deleted.';

  @override
  String get settingsDeleteAccountFinalTitle => 'Delete account for good?';

  @override
  String get settingsDeleteAccountFinalButton => 'Delete my account';

  @override
  String settingsDeleteAccountFinalContent(String word) {
    return 'Your accounts, transactions, receipt photos, statements and chats will be deleted. If you are the last member of your household, the whole household is deleted.\n\nType $word to confirm.';
  }

  @override
  String get loginSignInWithPasskey => 'Sign in with passkey';

  @override
  String get loginPasskeyNotFound =>
      'No passkey for this server on this phone. Sign in with your password, then add one in Settings.';

  @override
  String get loginPasskeyFailed =>
      'Could not sign in with a passkey. Please try again.';

  @override
  String get settingsPasskeysTitle => 'Passkeys';

  @override
  String get settingsPasskeysSubtitle =>
      'Sign in with your fingerprint or screen lock';

  @override
  String get passkeysIntro =>
      'A passkey lets you sign in with your fingerprint, face or screen lock instead of your password. It is saved in your phone\'s password manager.';

  @override
  String get passkeysAddHeading => 'Add a passkey';

  @override
  String get passkeysNameLabel => 'Name';

  @override
  String get passkeysNameHint => 'e.g. My Pixel';

  @override
  String get passkeysPasswordLabel => 'Current password';

  @override
  String get passkeysCodeLabel => 'Authenticator or backup code';

  @override
  String get passkeysAddButton => 'Add passkey';

  @override
  String get passkeysListHeading => 'Your passkeys';

  @override
  String get passkeysEmpty => 'No passkeys yet. Add one above.';

  @override
  String passkeysAdded(String date) {
    return 'Added $date';
  }

  @override
  String passkeysLastUsed(String date) {
    return 'Last used $date';
  }

  @override
  String get passkeysRemove => 'Remove';

  @override
  String get passkeysRemoveTitle => 'Remove this passkey?';

  @override
  String passkeysRemoveBody(String name) {
    return 'You will no longer be able to sign in with \"$name\". Also delete it from your phone\'s password manager.';
  }

  @override
  String get passkeysAddedToast => 'Passkey added.';

  @override
  String get passkeysRemovedToast => 'Passkey removed.';

  @override
  String get passkeysUnsupported =>
      'This phone cannot use passkeys. They need Android 11 or newer with Google Play services.';

  @override
  String get passkeysNoStepUp =>
      'Set a password or turn on two-factor authentication on the web before adding a passkey.';

  @override
  String get passkeysLoadFailed =>
      'Could not load your passkeys. Pull down to try again.';

  @override
  String get passkeysAddFailed => 'Could not add the passkey.';

  @override
  String get passkeysRemoveFailed => 'Could not remove the passkey.';

  @override
  String get passkeysConfirmRequired => 'Enter it to confirm it\'s you.';
}
