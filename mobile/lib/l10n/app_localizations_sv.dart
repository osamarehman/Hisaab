// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Hisaab';

  @override
  String get commonCancel => 'Avbryt';

  @override
  String get commonSave => 'Spara';

  @override
  String get commonTryAgain => 'Försök igen';

  @override
  String get commonDelete => 'Radera';

  @override
  String get commonAll => 'Alla';

  @override
  String get commonRefresh => 'Uppdatera';

  @override
  String get commonClose => 'Stäng';

  @override
  String get commonUndo => 'Ångra';

  @override
  String get loginEmailLabel => 'E-post';

  @override
  String get loginEmailRequired => 'E-post krävs';

  @override
  String get loginEmailInvalid => 'Ange en giltig e-postadress';

  @override
  String get loginPasswordLabel => 'Lösenord';

  @override
  String get loginPasswordRequired => 'Lösenord krävs';

  @override
  String get loginSignIn => 'Logga in';

  @override
  String get loginSignInWithGoogle => 'Logga in med Google';

  @override
  String get loginMfaLabel => 'Autentiseringskod';

  @override
  String get navHome => 'Hem';

  @override
  String get navIntro => 'Intro';

  @override
  String get navAssistant => 'Assistent';

  @override
  String get navMore => 'Mer';

  @override
  String get dashboardSyncError => 'Synkningen misslyckades';

  @override
  String get dashboardSyncFailed => 'Synkningen misslyckades. Försök igen.';

  @override
  String get dashboardRefreshing => 'Uppdaterar konton…';

  @override
  String get dashboardAccountsUpdated => 'Kontona har uppdaterats';

  @override
  String get dashboardSyncing => 'Synkar data från servern…';

  @override
  String get dashboardSynced => 'Synkat';

  @override
  String get dashboardErrorLoadingAccounts =>
      'Det gick inte att läsa in konton';

  @override
  String get dashboardNoAccounts => 'Inga konton än';

  @override
  String get dashboardNoAccountsSubtitle =>
      'Lägg till konton i webbappen för att se dem här.';

  @override
  String get dashboardFilterEmpty => 'Inga konton matchar det aktuella filtret';

  @override
  String get chatListNewChat => 'Ny chatt';

  @override
  String get chatListEmptySubtitle =>
      'Starta en konversation med din AI-assistent';

  @override
  String get chatListDeleteTitle => 'Radera chatt';

  @override
  String get chatConversationNewTitle => 'Ny konversation';

  @override
  String get chatConversationMessageHint =>
      'Fråga vad som helst om din ekonomi…';

  @override
  String chatConversationGreetingWithName(String firstName) {
    return 'Hej $firstName, vad kan jag hjälpa dig med?';
  }

  @override
  String get chatConversationGreetingNoName =>
      'Hej, vad kan jag hjälpa dig med?';

  @override
  String get transactionFormNewTitle => 'Ny transaktion';

  @override
  String get transactionFormTypeLabel => 'Typ';

  @override
  String get transactionFormTypeExpense => 'Utgift';

  @override
  String get transactionFormTypeIncome => 'Inkomst';

  @override
  String get transactionFormAmountLabel => 'Belopp';

  @override
  String get transactionFormAmountRequired => 'Belopp krävs';

  @override
  String get transactionFormAmountInvalid => 'Ange ett giltigt belopp';

  @override
  String get transactionFormDateLabel => 'Datum';

  @override
  String get transactionFormNameLabel => 'Namn';

  @override
  String get transactionFormCategoryLabel => 'Kategori';

  @override
  String get transactionEditTitle => 'Redigera transaktion';

  @override
  String get transactionEditNameLabel => 'Namn';

  @override
  String get transactionEditNameRequired => 'Namn krävs';

  @override
  String get transactionEditNotesLabel => 'Anteckningar';

  @override
  String get transactionEditCategoryLabel => 'Kategori';

  @override
  String get transactionEditMerchantLabel => 'Handlare';

  @override
  String get transactionEditTagsLabel => 'Taggar';

  @override
  String get transactionEditSaving => 'Sparar…';

  @override
  String get transactionsListDeleteTitle => 'Radera transaktion';

  @override
  String transactionsListDeleteSingleContent(String name) {
    return 'Vill du verkligen radera \"$name\"?';
  }

  @override
  String get transactionsListDeleteMultiTitle => 'Radera transaktioner';

  @override
  String get transactionsListDeleteMultiContent =>
      'Vill du verkligen radera de valda transaktionerna?';

  @override
  String get transactionsListEmpty => 'Inga transaktioner';

  @override
  String get transactionsListAuthFailed =>
      'Autentiseringen misslyckades: logga in igen';

  @override
  String get transactionsListNoTransactionsYet => 'Inga transaktioner än';

  @override
  String get transactionsListEmptyAddFirst =>
      'Tryck på + för att lägga till din första transaktion';

  @override
  String get transactionsListNoCategoryMatch =>
      'Inga transaktioner matchar den här kategorin';

  @override
  String get transactionsListRetry => 'Försök igen';

  @override
  String get transactionsListDeletedSuccess => 'Transaktionen har raderats';

  @override
  String get transactionsListSingleDeleteFailed =>
      'Det gick inte att radera transaktionen';

  @override
  String transactionsListDeletedMulti(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Raderade $count transaktioner',
      one: 'Raderade $count transaktion',
    );
    return '$_temp0';
  }

  @override
  String get transactionsListDeleteFailed =>
      'Det gick inte att radera transaktionerna';

  @override
  String get transactionsListDeleteNoToken =>
      'Det gick inte att radera: ingen åtkomsttoken';

  @override
  String get transactionsListUndoTitle => 'Ångra transaktion';

  @override
  String get transactionsListUndoRemovePending =>
      'Ta bort den här väntande transaktionen?';

  @override
  String get transactionsListUndoRestoreConfirm =>
      'Återställa den här transaktionen?';

  @override
  String get transactionsListUndoPendingRemoved =>
      'Den väntande transaktionen har tagits bort';

  @override
  String get transactionsListUndoRestored => 'Transaktionen har återställts';

  @override
  String get transactionsListUndoFailed =>
      'Det gick inte att ångra transaktionen';

  @override
  String get settingsSectionDisplay => 'Visning';

  @override
  String get settingsSectionConnection => 'Anslutning';

  @override
  String get settingsSectionDataManagement => 'Datahantering';

  @override
  String get settingsSectionSecurity => 'Säkerhet';

  @override
  String get settingsSectionDangerZone => 'Riskzon';

  @override
  String get settingsThemeLabel => 'Tema';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Ljust';

  @override
  String get settingsThemeDark => 'Mörkt';

  @override
  String get settingsProxyHeadersLabel => 'Anpassade proxyheaders';

  @override
  String get settingsPrivacyHideAmountsLabel => 'Dölj belopp';

  @override
  String get settingsPrivacyHideAmountsContent => 'Maskera belopp i hela appen';

  @override
  String get settingsBiometricLabel => 'Biometriskt lås';

  @override
  String get settingsBiometricEnable => 'Aktivera biometriskt lås?';

  @override
  String get settingsBiometricEnableContent =>
      'Kräv biometrisk autentisering när du återgår till appen.';

  @override
  String get settingsCheckForUpdates => 'Sök efter uppdateringar';

  @override
  String get settingsUpdateAvailableTitle => 'Uppdatering tillgänglig';

  @override
  String settingsUpdateAvailableContent(String version) {
    return 'Version $version finns tillgänglig. Vill du uppdatera nu?';
  }

  @override
  String get settingsUpdateNewerVersionFallback => 'en nyare version';

  @override
  String get settingsUpdateNow => 'Uppdatera nu';

  @override
  String get settingsNoUpdateAvailable => 'Du har den senaste versionen.';

  @override
  String get settingsUpdateError =>
      'Det gick inte att söka efter uppdateringar.';

  @override
  String get settingsClearDataTitle => 'Rensa all data';

  @override
  String get settingsClearDataContent =>
      'Detta tar bort all lokalt cachad data. Din data på servern påverkas inte.';

  @override
  String get settingsClearData => 'Rensa data';

  @override
  String get settingsClearDataSuccess => 'Lokal data har rensats';

  @override
  String get settingsDeleteAccountTitle => 'Radera användarkonto';

  @override
  String get settingsDeleteAccount => 'Radera användarkonto';

  @override
  String get settingsSignOutTitle => 'Logga ut';

  @override
  String get settingsSignOutContent => 'Vill du verkligen logga ut?';

  @override
  String get settingsSignOut => 'Logga ut';

  @override
  String get settingsDebugLogs => 'Felsökningsloggar';

  @override
  String get ssoOnboardingTitle => 'Koppla ditt användarkonto';

  @override
  String get ssoOnboardingTabLink => 'Koppla befintligt';

  @override
  String get ssoOnboardingTabCreate => 'Skapa nytt';

  @override
  String get ssoOnboardingFirstNameLabel => 'Förnamn';

  @override
  String get ssoOnboardingLastNameLabel => 'Efternamn';

  @override
  String get ssoOnboardingLinkButton => 'Koppla användarkonto';

  @override
  String get ssoOnboardingCreateButton => 'Skapa användarkonto';

  @override
  String get ssoOnboardingAcceptInvitation => 'Acceptera inbjudan';

  @override
  String get moreRecentTransactions => 'Senaste transaktioner';

  @override
  String get moreRecentTransactionsSubtitle =>
      'Se de senaste transaktionerna för alla konton';

  @override
  String get biometricTitle => 'Appen är låst';

  @override
  String get biometricSubtitle => 'Autentisera dig för att fortsätta';

  @override
  String get biometricUnlock => 'Lås upp';

  @override
  String get biometricAuthenticating => 'Autentiserar…';

  @override
  String get biometricLogOut => 'Logga ut';

  @override
  String get backendConfigTitle => 'Konfiguration';

  @override
  String get backendConfigSubtitle =>
      'Uppdatera adressen till din Hisaab-server';

  @override
  String get backendConfigExampleUrlsLabel => 'Exempeladresser';

  @override
  String get backendConfigUrlLabel => 'Adress till Hisaab-servern';

  @override
  String get backendConfigUrlHint => 'https://app.sure.am';

  @override
  String get backendConfigProxyHeadersLabel => 'Anpassade proxyheaders';

  @override
  String get backendConfigProxyHeadersSubtitle =>
      'Valfria headers för en omvänd proxy eller autentiseringsgateway';

  @override
  String backendConfigProxyHeadersCount(int count) {
    return '$count konfigurerade';
  }

  @override
  String get backendConfigTesting => 'Testar…';

  @override
  String get backendConfigTestButton => 'Testa anslutningen';

  @override
  String get backendConfigContinueButton => 'Fortsätt';

  @override
  String get backendConfigChangeHint =>
      'Du kan ändra detta senare i inställningarna.';

  @override
  String get recentTransactionsTitle => 'Senaste transaktioner';

  @override
  String get recentTransactionsEmpty => 'Inga transaktioner';

  @override
  String get recentTransactionsDisplayLimit => 'Visningsgräns';

  @override
  String recentTransactionsShowN(int count) {
    return 'Visa $count';
  }

  @override
  String get recentTransactionsPullToRefresh => 'Dra nedåt för att uppdatera';

  @override
  String get logViewerTitle => 'Felsökningsloggar';

  @override
  String get logViewerFilterAll => 'Alla';

  @override
  String get logViewerFilterInfo => 'Info';

  @override
  String get logViewerFilterWarning => 'Varning';

  @override
  String get logViewerFilterError => 'Fel';

  @override
  String get logViewerFilterDebug => 'Felsökning';

  @override
  String get logViewerAutoScrollEnable => 'Aktivera automatisk rullning';

  @override
  String get logViewerAutoScrollDisable => 'Inaktivera automatisk rullning';

  @override
  String get logViewerCopyLogs => 'Kopiera loggar';

  @override
  String get logViewerClearLogs => 'Rensa loggar';

  @override
  String get logViewerLogsCopied => 'Loggarna har kopierats till urklipp';

  @override
  String get logViewerEmpty => 'Inga loggar än';

  @override
  String get connectivityOffline => 'Du är offline';

  @override
  String connectivityPendingSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transaktioner väntar på synkning',
      one: '$count transaktion väntar på synkning',
    );
    return '$_temp0';
  }

  @override
  String get connectivitySyncNow => 'Synka nu';

  @override
  String get proxyHeadersAddHeader => 'Lägg till header';

  @override
  String get proxyHeadersNameLabel => 'Headernamn';

  @override
  String get proxyHeadersNameHint => 'X-Auth-Token';

  @override
  String get proxyHeadersValueLabel => 'Headervärde';

  @override
  String get proxyHeadersRemove => 'Ta bort header';

  @override
  String get accountDetailRefreshTooltip => 'Uppdatera kontouppgifter';

  @override
  String get accountDetailRecentBalanceHistory => 'Senaste saldohistorik';

  @override
  String get accountDetailTopHoldings => 'Största innehav';

  @override
  String get accountDetailHoldingFallback => 'Innehav';

  @override
  String accountDetailCashChip(String amount) {
    return 'Kontanter $amount';
  }

  @override
  String get biometricLockFailedRetry =>
      'Autentiseringen misslyckades. Tryck på Lås upp för att försöka igen.';

  @override
  String get settingsBiometricVerifyReason =>
      'Verifiera med biometri för att aktivera applåset';

  @override
  String get settingsBiometricFailed =>
      'Den biometriska autentiseringen misslyckades.';

  @override
  String get settingsUpdateOpenStoreError =>
      'Det gick inte att öppna länken till butiken';

  @override
  String get settingsClearDataFailed => 'Det gick inte att rensa lokal data.';

  @override
  String get settingsClearDataSuccessDetailed =>
      'Lokal data har rensats. Dra nedåt för att synka från servern.';

  @override
  String get settingsContactOpenLinkError => 'Det gick inte att öppna länken';

  @override
  String get settingsResetAccountContent =>
      'Om du återställer ditt användarkonto raderas alla dina konton, kategorier, handlare, taggar och annan data, men själva användarkontot finns kvar.\n\nDet går inte att ångra. Är du säker?';

  @override
  String get settingsResetAccount => 'Återställ användarkonto';

  @override
  String get settingsResetAccountInitiated =>
      'Återställningen har startats. Det kan ta en stund.';

  @override
  String get settingsResetAccountFailed =>
      'Det gick inte att återställa användarkontot';

  @override
  String get settingsDeleteAccountConfirmContent =>
      'Om du raderar ditt användarkonto tas all din data bort permanent. Det går inte att ångra.\n\nVill du verkligen radera ditt användarkonto?';

  @override
  String get settingsDeleteAccountFailed =>
      'Det gick inte att radera användarkontot';

  @override
  String get settingsProxyHeadersNote =>
      'Headers skickas av appen med API-anrop. SSO-sidor i extern webbläsare får dem kanske inte.';

  @override
  String get settingsProxyHeadersSaved => 'Anpassade proxyheaders har sparats';

  @override
  String get settingsProxyHeadersSaveFailed =>
      'Det gick inte att spara anpassade proxyheaders.';

  @override
  String settingsAppVersion(String version) {
    return 'Appversion: $version';
  }

  @override
  String get settingsCheckForUpdatesSubtitle =>
      'Se om en nyare version finns tillgänglig';

  @override
  String get settingsContactUs => 'Kontakta oss';

  @override
  String get settingsDebugLogsSemantics => 'Öppna felsökningsloggar';

  @override
  String get settingsDebugLogsSubtitle => 'Visa appens diagnostikloggar';

  @override
  String get settingsGroupByAccountType => 'Gruppera efter kontotyp';

  @override
  String get settingsGroupByAccountTypeSubtitle =>
      'Gruppera konton efter typ (krypto, bank osv.)';

  @override
  String get settingsProxyHeadersTileTitle => 'Anpassade proxyheaders';

  @override
  String get settingsProxyHeadersTileSubtitleEmpty =>
      'Valfria headers för en omvänd proxy eller autentiseringsgateway';

  @override
  String settingsProxyHeadersTileSubtitleCount(int count) {
    return '$count konfigurerade';
  }

  @override
  String get settingsClearDataTileSubtitle =>
      'Ta bort alla cachade transaktioner och konton';

  @override
  String get settingsResetAccountTileSubtitle =>
      'Radera alla konton, kategorier, handlare och taggar men behåll ditt användarkonto';

  @override
  String get settingsDeleteAccountTileSubtitle =>
      'Ta bort all din data permanent. Det går inte att ångra.';

  @override
  String get settingsUserFallback => 'Användare';

  @override
  String get chatListError => 'Det gick inte att läsa in chattar';

  @override
  String get chatListJustNow => 'Nyss';

  @override
  String chatListDeleteSingleContent(String title) {
    return 'Vill du verkligen radera \"$title\"?';
  }

  @override
  String get loginSignUpOpenError =>
      'Det gick inte att öppna registreringssidan';

  @override
  String get loginDemoOrSignUpPrefix => 'Demokonto eller ';

  @override
  String get loginSignUpLink => 'Registrera dig';

  @override
  String get loginSignUpSuffix => '!';

  @override
  String get loginMfaInfo =>
      'Tvåfaktorsautentisering är aktiverad. Ange din kod.';

  @override
  String get loginMfaCodeRequired => 'Ange din autentiseringskod';

  @override
  String get loginOrDivider => 'eller';

  @override
  String get loginServerUrlHeading => 'Adress till Hisaab-servern:';

  @override
  String get loginBackendSettingsTooltip => 'Serverinställningar';

  @override
  String get transactionEditSessionExpired =>
      'Sessionen har gått ut. Logga in igen.';

  @override
  String get transactionEditUpdated => 'Transaktionen har uppdaterats';

  @override
  String get transactionEditUpdateFailed =>
      'Det gick inte att uppdatera transaktionen';

  @override
  String transactionEditNameMaxLength(int max) {
    return 'Namnet får vara högst $max tecken';
  }

  @override
  String get transactionEditNameInvalidChars =>
      'Namnet innehåller tecken som inte stöds';

  @override
  String transactionEditNotesMaxLength(int max) {
    return 'Anteckningarna får vara högst $max tecken';
  }

  @override
  String get transactionEditNotesInvalidChars =>
      'Anteckningarna innehåller tecken som inte stöds';

  @override
  String get transactionEditNoCategory => 'Ingen kategori';

  @override
  String get transactionEditCurrentCategory => 'Nuvarande kategori';

  @override
  String get transactionEditNoMerchant => 'Ingen handlare';

  @override
  String get transactionEditCurrentMerchant => 'Nuvarande handlare';

  @override
  String get transactionEditNoTags => 'Inga taggar tillgängliga';

  @override
  String get transactionEditUnknownTag => 'Okänd tagg';

  @override
  String get transactionEditSyncedOnly =>
      'Bara synkade transaktioner kan redigeras i mobilen.';

  @override
  String get transactionEditCategoryHelper => 'Välj en ny kategori';

  @override
  String get transactionEditMerchantHelper => 'Välj en ny handlare';

  @override
  String get transactionFormSessionExpired =>
      'Sessionen har gått ut. Logga in igen.';

  @override
  String get transactionFormAmountRequiredPrompt => 'Ange ett belopp';

  @override
  String get transactionFormAmountInvalidNumber => 'Ange ett giltigt tal';

  @override
  String get transactionFormAmountTooSmall => 'Beloppet måste vara större än 0';

  @override
  String get transactionFormCreateSuccessOnline => 'Transaktionen har skapats';

  @override
  String get transactionFormCreateSuccessOffline =>
      'Transaktionen har sparats (synkas när du är online)';

  @override
  String get transactionFormCreateFailed =>
      'Det gick inte att skapa transaktionen';

  @override
  String transactionFormGenericError(String error) {
    return 'Fel: $error';
  }

  @override
  String get transactionFormLess => 'Mindre';

  @override
  String get transactionFormMore => 'Mer';

  @override
  String get transactionFormDateHelper => 'Valfritt (standard: i dag)';

  @override
  String get transactionFormNameHelper => 'Valfritt (standard: SureApp)';

  @override
  String get transactionFormCategoryLoading => 'Läser in kategorier…';

  @override
  String get transactionFormCategoryHelper => 'Valfritt';

  @override
  String get transactionFormNoCategory => 'Ingen kategori';

  @override
  String get transactionFormCreateButton => 'Skapa transaktion';

  @override
  String get transactionFormAmountHelper => 'Obligatoriskt';

  @override
  String get logViewerClearConfirm => 'Vill du verkligen rensa alla loggar?';

  @override
  String get logViewerClear => 'Rensa';

  @override
  String get chatConversationEditTitle => 'Redigera titel';

  @override
  String get chatConversationTitleLabel => 'Chattitel';

  @override
  String get chatConversationRefreshTooltip => 'Uppdatera';

  @override
  String get chatConversationLoadError => 'Det gick inte att läsa in chatten';

  @override
  String get navEnableAiChatTitle => 'Aktivera AI-chatt?';

  @override
  String get navEnableAiChatContent =>
      'AI-chatt är för närvarande avstängd i dina kontoinställningar. Vill du aktivera den nu?';

  @override
  String get navEnableAiChatConfirm => 'Aktivera AI';

  @override
  String get navEnableAiChatFailed => 'Det gick inte att aktivera AI just nu.';

  @override
  String get transactionsListEditTooltip => 'Redigera transaktion';

  @override
  String get connectivitySignInToSync => 'Logga in för att synka transaktioner';

  @override
  String get connectivitySyncSuccess => 'Transaktionerna har synkats';

  @override
  String get connectivitySyncFailed =>
      'Det gick inte att synka transaktionerna. Försök igen.';

  @override
  String get connectivityAuthFailed =>
      'Det gick inte att autentisera. Försök igen.';

  @override
  String ssoOnboardingSignedInAs(String email) {
    return 'Inloggad som $email';
  }

  @override
  String get ssoOnboardingGoogleVerified => 'Google-kontot har verifierats';

  @override
  String get ssoOnboardingLinkCredentialsNote =>
      'Ange uppgifterna för ditt befintliga användarkonto för att koppla det till Google-inloggning.';

  @override
  String get ssoOnboardingPendingInvitationNote =>
      'Du har en väntande inbjudan. Acceptera den för att gå med i ett befintligt hushåll.';

  @override
  String get ssoOnboardingCreateIdentityNote =>
      'Skapa ett nytt användarkonto med din Google-identitet.';

  @override
  String get ssoOnboardingFirstNameRequired => 'Förnamn krävs';

  @override
  String get ssoOnboardingLastNameRequired => 'Efternamn krävs';

  @override
  String get backendConfigTimeout =>
      'Anslutningen tog för lång tid. Kontrollera adressen och försök igen.';

  @override
  String get backendConfigSuccess => 'Anslutningen lyckades!';

  @override
  String backendConfigServerError(int code) {
    return 'Servern svarade med status $code. Kontrollera att det är en Hisaab-server.';
  }

  @override
  String backendConfigConnectionFailed(String error) {
    return 'Anslutningen misslyckades: $error';
  }

  @override
  String backendConfigSaveFailed(String error) {
    return 'Det gick inte att spara adressen: $error';
  }

  @override
  String get backendConfigUrlRequired => 'Ange en serveradress';

  @override
  String get backendConfigUrlScheme =>
      'Adressen måste börja med http:// eller https://';

  @override
  String get backendConfigUrlInvalid => 'Ange en giltig adress';

  @override
  String get backendConfigHeadersHelp =>
      'Headers skickas av appen med API-anrop. SSO-sidor i extern webbläsare får dem kanske inte.';

  @override
  String get recentTransactionsUnknownAccount => 'Okänt konto';

  @override
  String get accountDetailUnavailable =>
      'Kontouppgifterna är tillfälligt otillgängliga';

  @override
  String chatListMinutesAgo(int minutes) {
    return 'för $minutes min sedan';
  }

  @override
  String chatListHoursAgo(int hours) {
    return 'för $hours tim sedan';
  }

  @override
  String chatListDaysAgo(int days) {
    return 'för $days d sedan';
  }

  @override
  String get chatConversationStartFailed =>
      'Det gick inte att starta konversationen. Försök igen.';

  @override
  String get moreBudgets => 'Budgetar';

  @override
  String get moreBudgetsSubtitle =>
      'Budgeterat mot faktiskt utfall per kategori';

  @override
  String get budgetsTitle => 'Budgetar';

  @override
  String get budgetsPreviousMonth => 'Föregående månad';

  @override
  String get budgetsNextMonth => 'Nästa månad';

  @override
  String get budgetsBudgeted => 'Budgeterat';

  @override
  String get budgetsActual => 'Utfall';

  @override
  String get budgetsRemaining => 'Kvar';

  @override
  String get budgetsIncome => 'Inkomster';

  @override
  String budgetsExpectedIncome(String amount) {
    return 'Förväntat $amount';
  }

  @override
  String budgetsOfAmount(String amount) {
    return 'av $amount';
  }

  @override
  String budgetsAmountLeft(String amount) {
    return '$amount kvar';
  }

  @override
  String budgetsOverBy(String amount) {
    return '$amount över';
  }

  @override
  String budgetsRolledOver(String amount) {
    return '+$amount överfört';
  }

  @override
  String get budgetsSharedBudget => 'Delad budget';

  @override
  String get budgetsNoLimit => 'Ingen budget';

  @override
  String get budgetsCategoriesTitle => 'Kategorier';

  @override
  String budgetsFilterOverBudget(int count) {
    return 'Över budget ($count)';
  }

  @override
  String get budgetsOverBudget => 'Över budget';

  @override
  String get budgetsNearLimit => 'Nära gränsen';

  @override
  String budgetsBudgetNumber(int number) {
    return 'Budget $number';
  }

  @override
  String budgetsNoBudgetTitle(String month) {
    return 'Ingen budget för $month';
  }

  @override
  String get budgetsNoBudgetMessage =>
      'Budgetar skapas i Hisaab på webben. Öppna Budgetar där för att skapa en för den här månaden.';

  @override
  String get budgetsNotSetUpMessage =>
      'Inga utgiftsgränser är satta för den här månaden än. Ställ in dem i Hisaab på webben.';

  @override
  String get budgetsNoCategories =>
      'Inga budgeterade kategorier eller utgifter den här månaden.';

  @override
  String get budgetsOfflineTitle => 'Du är offline';

  @override
  String get budgetsOfflineMessage =>
      'Anslut till internet för att läsa in den här månadens budget.';

  @override
  String get budgetsOfflineCached =>
      'Offline. Visar siffrorna som lästes in tidigare.';

  @override
  String get budgetsRefreshFailed =>
      'Kunde inte uppdatera. Visar siffrorna som lästes in tidigare.';

  @override
  String get budgetsLoadFailed => 'Kunde inte läsa in budgetar';

  @override
  String get budgetsSessionExpired => 'Din session har gått ut. Logga in igen.';

  @override
  String budgetCategoryTransactionsEmpty(String month) {
    return 'Inga transaktioner i den här kategorin för $month.';
  }

  @override
  String get budgetCategoryTransactionsLoadMore => 'Visa fler';

  @override
  String get budgetCategoryTransactionsLoadFailed =>
      'Kunde inte läsa in transaktioner';

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
  String get legalPrivacy => 'Integritetspolicy';

  @override
  String get legalTerms => 'Användarvillkor';

  @override
  String get legalOpenLinkError => 'Det gick inte att öppna länken';

  @override
  String get signUpTitle => 'Skapa konto';

  @override
  String get signUpSubtitle =>
      'Samla hushållets utgifter på ett ställe. Kontot skapas på servern som visas på inloggningsskärmen.';

  @override
  String get signUpPasswordRules =>
      'Minst 8 tecken med stora och små bokstäver, en siffra och en symbol.';

  @override
  String get signUpConfirmPasswordLabel => 'Bekräfta lösenord';

  @override
  String get signUpPasswordsDoNotMatch => 'Lösenorden matchar inte';

  @override
  String get signUpSubmit => 'Skapa konto';

  @override
  String get signUpAgreementPrefix => 'Genom att skapa ett konto godkänner du ';

  @override
  String get signUpAgreementAnd => ' och ';

  @override
  String get settingsSourceCode => 'Källkod';

  @override
  String get settingsSourceCodeSubtitle =>
      'Hisaab bygger på Sure och är licensierat under AGPL-3.0';

  @override
  String get settingsDeleteAccountDone => 'Ditt konto har raderats.';

  @override
  String get settingsDeleteAccountFinalTitle => 'Radera kontot för gott?';

  @override
  String get settingsDeleteAccountFinalButton => 'Radera mitt konto';

  @override
  String settingsDeleteAccountFinalContent(String word) {
    return 'Dina konton, transaktioner, kvittobilder, kontoutdrag och chattar raderas. Om du är den sista medlemmen i hushållet raderas hela hushållet.\n\nSkriv $word för att bekräfta.';
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

  @override
  String get assistantAttachTooltip => 'Attach a statement';

  @override
  String get assistantMicTooltip =>
      'Voice note: tap to start, or hold and talk';

  @override
  String get assistantMicPermissionDenied =>
      'Hisaab needs the microphone to record a voice note. You can allow it in your phone\'s settings.';

  @override
  String get assistantMicFailed =>
      'Could not start recording. Please try again.';

  @override
  String get assistantVoiceTooShort =>
      'That was too short. Hold the mic while you talk, or tap it once to start.';

  @override
  String get assistantRecordingHold => 'Release to send · slide away to cancel';

  @override
  String get assistantRecordingReleaseToCancel => 'Release to cancel';

  @override
  String get assistantRecordingTap => 'Tap the mic again to send';

  @override
  String get assistantRecordingCancel => 'Cancel recording';

  @override
  String assistantRecordingLabel(String elapsed, String limit) {
    return 'Recording $elapsed of $limit';
  }

  @override
  String get assistantTranscribing => 'Transcribing…';

  @override
  String get assistantVoiceNoteTitle => 'Voice note';

  @override
  String get assistantVoiceNoteFailed =>
      'Could not send the voice note. Please try again.';

  @override
  String get assistantReadingStatement => 'Reading your statement…';

  @override
  String get assistantStatementSlow =>
      'The statement is taking a while. Tap refresh in a minute to see the reply.';

  @override
  String get assistantStatementFailed =>
      'Could not send the statement. Please try again.';

  @override
  String get assistantFileUnreadable => 'Could not read that file.';

  @override
  String get assistantFileType => 'Choose a PDF or CSV statement.';

  @override
  String get assistantChooseAccount => 'Which account is this statement for?';

  @override
  String get assistantNoAccounts =>
      'Add a bank account first, then attach its statement.';

  @override
  String get assistantAccountsFailed =>
      'Could not load your accounts. Please try again.';

  @override
  String get pendingActionSave => 'Save';

  @override
  String get pendingActionCancel => 'Cancel';

  @override
  String get pendingActionSaved => 'Saved';

  @override
  String get pendingActionCancelled => 'Cancelled';

  @override
  String pendingActionSaveAll(int count) {
    return 'Save all ($count)';
  }

  @override
  String get pendingActionCancelAll => 'Cancel all';

  @override
  String pendingActionBatchTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries to check',
      one: '1 entry to check',
    );
    return '$_temp0';
  }

  @override
  String get pendingActionNeedsLabel => 'Needs a label';

  @override
  String get pendingActionDuplicate => 'Already recorded?';

  @override
  String get pendingActionRemove => 'Remove this row';

  @override
  String get pendingActionToday => 'today';

  @override
  String get pendingActionYesterday => 'yesterday';

  @override
  String get pendingActionSaveFailed => 'Could not save.';

  @override
  String get pendingActionRequestFailed =>
      'Could not update. Please try again.';

  @override
  String get pendingActionKindAdd => 'Add';

  @override
  String get pendingActionKindUpdate => 'Change';

  @override
  String get pendingActionKindDelete => 'Delete';

  @override
  String get pendingActionKindBalance => 'Set balance';

  @override
  String get pendingActionKindAccount => 'New account';

  @override
  String get pendingActionKindLabel => 'New label';

  @override
  String get pendingActionKindOther => 'Proposed change';

  @override
  String get reportTitle => 'Download report';

  @override
  String get reportHint => 'PDF of any period, to keep or share';

  @override
  String get reportIntro =>
      'Pick a period and the labels to include. Hisaab makes a PDF with the totals and every entry, ready to save or send.';

  @override
  String get reportPeriod => 'Period';

  @override
  String get reportThisMonth => 'This month';

  @override
  String get reportLastMonth => 'Last month';

  @override
  String get reportLast3Months => 'Last 3 months';

  @override
  String get reportCustom => 'Custom';

  @override
  String get reportLabels => 'Labels';

  @override
  String get reportAllLabels => 'All labels';

  @override
  String get reportUnlabelled => 'Unlabelled';

  @override
  String get reportAccounts => 'Accounts';

  @override
  String get reportAllAccounts => 'All accounts';

  @override
  String get reportDownload => 'Make PDF and share';

  @override
  String get reportPickLabel => 'Pick at least one label.';

  @override
  String get reportPickAccount => 'Pick at least one account.';

  @override
  String get reportTooLong => 'A report can cover at most 24 months.';

  @override
  String get reportFailed => 'Could not make the report. Try again.';

  @override
  String get reportOffline =>
      'Could not reach the server. Check your connection and try again.';

  @override
  String reportSaved(String filename) {
    return 'Saved as $filename';
  }

  @override
  String get settingsLanguageLabel => 'Language · زبان';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageUrdu => 'اردو';

  @override
  String get commonBack => 'Back';

  @override
  String get commonKeep => 'Keep';

  @override
  String get commonSignInAgain => 'Please sign in again.';

  @override
  String commonDeleteNamed(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get accountKindBank => 'Bank account';

  @override
  String get accountKindBankHint =>
      'Current account you spend from, e.g. HBL, Meezan';

  @override
  String get accountKindSavings => 'Savings account';

  @override
  String get accountKindSavingsHint => 'Money you keep aside in the bank';

  @override
  String get accountKindCash => 'Cash in hand';

  @override
  String get accountKindCashHint => 'Money in your purse or at home';

  @override
  String get accountKindCreditCard => 'Credit card';

  @override
  String get accountKindCreditCardHint => 'What you owe on the card';

  @override
  String get accountKindLoan => 'Loan / money owed';

  @override
  String get accountKindLoanHint =>
      'Money you owe a bank, a relative or a shop';

  @override
  String get accountKindAssets => 'Gold & savings certificates';

  @override
  String get accountKindAssetsHint => 'Gold, prize bonds, national savings';

  @override
  String get accountFormNameRequired => 'Give the account a name.';

  @override
  String get accountFormBalanceNegative =>
      'Enter the amount without a minus sign.';

  @override
  String get accountFormBalanceInvalid => 'Enter a number, like 25,000.';

  @override
  String get accountFormKindRequired => 'Choose what kind of account this is.';

  @override
  String get accountFormSaveFailed => 'Could not save the account.';

  @override
  String get accountFormDeleteBody =>
      'Everything recorded in this account is deleted too. This cannot be undone.';

  @override
  String get accountFormDeleteFailed => 'Could not delete the account.';

  @override
  String get accountFormEditTitle => 'Edit account';

  @override
  String get accountFormAddTitle => 'Add account';

  @override
  String get accountFormKindHeader => 'What kind of account?';

  @override
  String get accountFormNameHint => 'e.g. Meezan Bank, Cash in hand';

  @override
  String get accountFormOwedLabel => 'How much is owed?';

  @override
  String get accountFormBalanceLabel => 'How much is in it now?';

  @override
  String get accountFormBalanceEditHelp =>
      'Change this to match your bank or purse today.';

  @override
  String get accountFormBalanceNewHelp =>
      'Leave empty if you are not sure. You can change it later.';

  @override
  String get accountFormDeleteButton => 'Delete account';

  @override
  String get accountsLoadFailed =>
      'Could not load your accounts. Pull down to try again.';

  @override
  String get accountsGroupBank => 'Bank';

  @override
  String get accountsGroupCards => 'Cards';

  @override
  String get accountsGroupLoans => 'Loans';

  @override
  String get accountsGroupOtherOwed => 'Other money owed';

  @override
  String get accountsGroupProperty => 'Property';

  @override
  String get accountsGroupSavings => 'Savings & gold';

  @override
  String get accountsAddStatement => 'Add statement';

  @override
  String get accountsAdd => '+ Add';

  @override
  String get accountsNothingOwed => 'Nothing owed.';

  @override
  String get accountsEmpty => 'No accounts yet.';

  @override
  String get accountsWhatWeHave => 'What we have';

  @override
  String get accountsWhatWeOwe => 'What we owe';

  @override
  String get accountsEdit => 'Edit';

  @override
  String get labelsTitle => 'Labels';

  @override
  String get labelsLoadFailed =>
      'Could not load your labels. Pull down to try again.';

  @override
  String get labelsNameRequired => 'Give the label a name.';

  @override
  String get labelsAddFailed => 'Could not add the label.';

  @override
  String labelsAdded(String name) {
    return 'Added \"$name\".';
  }

  @override
  String labelsAddedKeywordsFailed(String name) {
    return 'Added \"$name\", but some keywords were not saved.';
  }

  @override
  String get labelsNewLabel => 'New label';

  @override
  String get labelsNameHint => 'e.g. Committee, Doodh wala';

  @override
  String get labelsKeywordsLabel => 'Auto-label statement lines containing';

  @override
  String get labelsKeywordsHint => 'e.g. ASLAM, DOODH';

  @override
  String get labelsAddButton => 'Add label';

  @override
  String get labelsYourLabels => 'Your labels';

  @override
  String get labelsUsesThisMonth => 'uses this month';

  @override
  String get labelsEmpty => 'No labels yet. Add one above.';

  @override
  String get labelsNoAutoRule => 'No auto rule';

  @override
  String labelsAutoKeywords(String keywords) {
    return 'Auto: $keywords';
  }

  @override
  String get labelsSaveFailed => 'Could not save the label.';

  @override
  String labelsKeywordRemoveFailed(String keyword) {
    return 'Could not remove $keyword.';
  }

  @override
  String labelsKeywordAddFailed(String keyword) {
    return 'Could not add $keyword.';
  }

  @override
  String get labelsDeleteBody =>
      'Lines with this label become unlabelled. Its auto-label keywords stop working.';

  @override
  String get labelsDeleteFailed => 'Could not delete the label.';

  @override
  String get labelsEditTitle => 'Edit label';

  @override
  String get labelsKeywordsEditHint => 'Comma separated, e.g. K-ELECTRIC, SSGC';

  @override
  String get labelsDeleteButton => 'Delete label';

  @override
  String get statementsIntro =>
      'Add a bank statement. Hisaab reads every line, files each one under the right month and suggests a label.';

  @override
  String get statementsUploadFailed => 'Upload failed.';

  @override
  String get statementsPublishFailed => 'Could not add the lines.';

  @override
  String get statementsChooseFile => 'Choose statement file';

  @override
  String get statementsUploading => 'Uploading…';

  @override
  String get statementsFileHint => 'PDF or CSV · up to 6 months in one file';

  @override
  String get statementsAccountFallback => 'Account';

  @override
  String statementsCoverageTitle(String name) {
    return '$name · last 6 months';
  }

  @override
  String get statementsCheckingMonths => 'Checking months…';

  @override
  String get statementsLegendAllLabelled => 'All labelled';

  @override
  String get statementsLegendNeedsLabels => 'Needs labels';

  @override
  String get statementsLegendNoStatement => 'No statement';

  @override
  String statementsMonthLeft(int count) {
    return '$count left';
  }

  @override
  String get statementsPdfStatement => 'PDF statement';

  @override
  String get statementsCsvStatement => 'CSV statement';

  @override
  String get statementsReadFailed =>
      'Hisaab could not read this statement. Try another file.';

  @override
  String get statementsAddingLines => 'Adding the lines to your books…';

  @override
  String get statementsReading =>
      'Hisaab is reading every line. This can take a minute.';

  @override
  String get statementsLinesFound => 'lines found';

  @override
  String get statementsNeedsColumnMapping =>
      'This file needs its columns matched on the Hisaab website before the lines can be added.';

  @override
  String statementsAddLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add these $count lines',
      one: 'Add this 1 line',
    );
    return '$_temp0';
  }

  @override
  String get statementsAutoLabelled => 'auto-labelled';

  @override
  String get statementsNeedYou => 'need you';

  @override
  String statementsLabelItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Label the $count items',
      one: 'Label the 1 item',
    );
    return '$_temp0';
  }

  @override
  String get statementsAllLabelled => 'Everything is labelled.';

  @override
  String get statementsStatusFailed => 'Failed';

  @override
  String get statementsStatusAdded => 'Added';

  @override
  String get statementsStatusAdding => 'Adding…';

  @override
  String get statementsStatusReading => 'Reading…';

  @override
  String get statementsStatusRead => 'Read';

  @override
  String get statementsStatusWaiting => 'Waiting…';

  @override
  String get statementsRecent => 'Recent statements';

  @override
  String get statementsStatementFallback => 'Statement';

  @override
  String statementsAddedOn(String date) {
    return 'Added $date';
  }

  @override
  String statementsLinesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '1 line',
    );
    return '$_temp0';
  }

  @override
  String get statementReviewLoadFailed => 'Could not load the statement lines.';

  @override
  String statementReviewKeywordFailed(String error) {
    return 'Labelled this one. The keyword was not saved: $error';
  }

  @override
  String get statementReviewUnknownError => 'unknown error';

  @override
  String get statementReviewNothingToLabel =>
      'Nothing to label. Every line has a label.';

  @override
  String get statementReviewAllDone => 'All done. Every line has a label.';

  @override
  String get statementReviewDoneForNow => 'Done for now';

  @override
  String statementReviewPosition(int position, int total) {
    return '$position of $total';
  }

  @override
  String get statementReviewWhereFrom => 'Where did this come from?';

  @override
  String get statementReviewWhatWasThis => 'What was this?';

  @override
  String get statementReviewNotExpense => 'Not an expense';

  @override
  String get statementReviewNewLabel => '+ Make a new label';

  @override
  String statementReviewLabelAllSimilar(int count) {
    return 'Label all $count like this';
  }

  @override
  String get statementReviewAutoLabelFuture =>
      'Auto-label future lines like this';

  @override
  String get statementReviewLinesContaining => 'Lines containing';

  @override
  String get statementReviewSkip => 'Skip';

  @override
  String get statementReviewSaveNext => 'Save & next';

  @override
  String get budgetsScreenTitle => 'Budget';

  @override
  String budgetsOverByNote(String amount) {
    return 'Over by $amount.';
  }

  @override
  String budgetsLeftForDays(String amount, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$amount left for the last $_temp0. Blue line is today.';
  }

  @override
  String budgetsLeftNote(String amount) {
    return '$amount left.';
  }

  @override
  String budgetsSpentOfPlanned(String amount) {
    return 'Spent of $amount planned';
  }

  @override
  String get budgetsSpent => 'Spent';

  @override
  String budgetsDayOf(int day, int days) {
    return 'day $day of $days';
  }

  @override
  String get budgetsNoLimitSet => 'No limit set';

  @override
  String budgetsOverByLine(String amount) {
    return 'Over by $amount';
  }

  @override
  String get noAccountsTitle => 'Add your first account';

  @override
  String get noAccountsBody =>
      'Accounts are where money is paid from and into. Start with \"Cash in hand\", then add your bank account.';

  @override
  String get upgradeTitle => 'Update available';

  @override
  String upgradeBody(
      String appName, String storeVersion, String installedVersion) {
    return '$appName $storeVersion is now available — you have $installedVersion.\n\nWhat\'s new? Check the store for release notes.';
  }

  @override
  String get upgradeNow => 'Update now';

  @override
  String get upgradeLater => 'Later';

  @override
  String get swatchInk => 'Ink';

  @override
  String get swatchCobalt => 'Cobalt';

  @override
  String get swatchAmber => 'Amber';

  @override
  String get swatchOlive => 'Olive';

  @override
  String get swatchPlum => 'Plum';

  @override
  String get swatchSteel => 'Steel';

  @override
  String get swatchStone => 'Stone';

  @override
  String get transactionFormAddFirstAccount => '+ Add an account';

  @override
  String get transactionFormNewAccountOption => '+ New account';
}
