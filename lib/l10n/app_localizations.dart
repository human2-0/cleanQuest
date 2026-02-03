import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CleanQuest'**
  String get appTitle;

  /// No description provided for @commonAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get commonAdmin;

  /// No description provided for @commonMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get commonMember;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get commonApprove;

  /// No description provided for @commonReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get commonReject;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get commonCopied;

  /// No description provided for @commonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// No description provided for @commonPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points: {points}'**
  String commonPointsLabel(Object points);

  /// No description provided for @commonPointsShort.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String commonPointsShort(Object points);

  /// No description provided for @commonUnknownChore.
  ///
  /// In en, this message translates to:
  /// **'Unknown chore'**
  String get commonUnknownChore;

  /// No description provided for @commonUnknownReward.
  ///
  /// In en, this message translates to:
  /// **'Unknown reward'**
  String get commonUnknownReward;

  /// No description provided for @commonUnknownHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get commonUnknownHousehold;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to CleanQuest'**
  String get onboardingTitle;

  /// No description provided for @onboardingChooseRole.
  ///
  /// In en, this message translates to:
  /// **'Create or join a household'**
  String get onboardingChooseRole;

  /// No description provided for @onboardingRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The creator becomes admin. Everyone else joins as a member.'**
  String get onboardingRoleSubtitle;

  /// No description provided for @onboardingCreateHouseholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Create household'**
  String get onboardingCreateHouseholdLabel;

  /// No description provided for @onboardingJoinHouseholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Join household'**
  String get onboardingJoinHouseholdLabel;

  /// No description provided for @onboardingYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get onboardingYourName;

  /// No description provided for @onboardingHouseholdName.
  ///
  /// In en, this message translates to:
  /// **'Household name'**
  String get onboardingHouseholdName;

  /// No description provided for @onboardingShareCode.
  ///
  /// In en, this message translates to:
  /// **'Share this code with members'**
  String get onboardingShareCode;

  /// No description provided for @onboardingQrTitle.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get onboardingQrTitle;

  /// No description provided for @onboardingQrHint.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code to join the household.'**
  String get onboardingQrHint;

  /// No description provided for @onboardingFinishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get onboardingFinishSetup;

  /// No description provided for @onboardingGenerateCode.
  ///
  /// In en, this message translates to:
  /// **'Generate new code'**
  String get onboardingGenerateCode;

  /// No description provided for @onboardingCodeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Members will enter this to join your household.'**
  String get onboardingCodeInstructions;

  /// No description provided for @onboardingAdminCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter join code'**
  String get onboardingAdminCodeLabel;

  /// No description provided for @onboardingJoinHousehold.
  ///
  /// In en, this message translates to:
  /// **'Join household'**
  String get onboardingJoinHousehold;

  /// No description provided for @onboardingCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Code is required.'**
  String get onboardingCodeRequired;

  /// No description provided for @onboardingCodeLength.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get onboardingCodeLength;

  /// No description provided for @onboardingHouseholdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Household not found.'**
  String get onboardingHouseholdNotFound;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAdminJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Admin join code'**
  String get settingsAdminJoinCode;

  /// No description provided for @settingsHouseholdCode.
  ///
  /// In en, this message translates to:
  /// **'Household code'**
  String get settingsHouseholdCode;

  /// No description provided for @settingsJoinCodeNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsJoinCodeNotSet;

  /// No description provided for @settingsCodeCopiedToast.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get settingsCodeCopiedToast;

  /// No description provided for @settingsEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get settingsEnableNotifications;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Approvals and reward alerts'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsDailyDigest.
  ///
  /// In en, this message translates to:
  /// **'Daily digest'**
  String get settingsDailyDigest;

  /// No description provided for @settingsDailyDigestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Due items and approvals summary'**
  String get settingsDailyDigestSubtitle;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDarkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get settingsDarkModeSubtitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePolish.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get languagePolish;

  /// No description provided for @settingsViewNotifications.
  ///
  /// In en, this message translates to:
  /// **'View notifications'**
  String get settingsViewNotifications;

  /// No description provided for @settingsRegenerateJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Regenerate join code'**
  String get settingsRegenerateJoinCode;

  /// No description provided for @settingsRestoreTemplates.
  ///
  /// In en, this message translates to:
  /// **'Restore default templates'**
  String get settingsRestoreTemplates;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out (reset onboarding)'**
  String get settingsLogOut;

  /// No description provided for @settingsLogOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get settingsLogOutDialogTitle;

  /// No description provided for @settingsLogOutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This clears your role and household selection on this device.'**
  String get settingsLogOutDialogBody;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsReset;

  /// No description provided for @settingsRegenerateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Regenerate join code?'**
  String get settingsRegenerateDialogTitle;

  /// No description provided for @settingsRegenerateDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Members with the old code will not be able to join.'**
  String get settingsRegenerateDialogBody;

  /// No description provided for @settingsRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get settingsRegenerate;

  /// No description provided for @settingsNewJoinCode.
  ///
  /// In en, this message translates to:
  /// **'New join code'**
  String get settingsNewJoinCode;

  /// No description provided for @settingsNewCodeGenerated.
  ///
  /// In en, this message translates to:
  /// **'New code generated and copied'**
  String get settingsNewCodeGenerated;

  /// No description provided for @settingsRestoreDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore default templates?'**
  String get settingsRestoreDialogTitle;

  /// No description provided for @settingsRestoreDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This replaces current chores and completion history for this household.'**
  String get settingsRestoreDialogBody;

  /// No description provided for @settingsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settingsRestore;

  /// No description provided for @settingsTemplatesRestored.
  ///
  /// In en, this message translates to:
  /// **'Templates restored'**
  String get settingsTemplatesRestored;

  /// No description provided for @settingsSwitchToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Switch to admin'**
  String get settingsSwitchToAdmin;

  /// No description provided for @settingsSwitchToMember.
  ///
  /// In en, this message translates to:
  /// **'Switch to member'**
  String get settingsSwitchToMember;

  /// No description provided for @settingsSwitchedToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Switched to admin'**
  String get settingsSwitchedToAdmin;

  /// No description provided for @settingsSwitchedToMember.
  ///
  /// In en, this message translates to:
  /// **'Switched to member'**
  String get settingsSwitchedToMember;

  /// No description provided for @settingsTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get settingsTesting;

  /// No description provided for @settingsNoHouseholdToSwitch.
  ///
  /// In en, this message translates to:
  /// **'No household to switch.'**
  String get settingsNoHouseholdToSwitch;

  /// No description provided for @settingsProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get settingsProfilesTitle;

  /// No description provided for @settingsProfilesNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active profile'**
  String get settingsProfilesNoActive;

  /// No description provided for @settingsProfilesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add profile'**
  String get settingsProfilesAdd;

  /// No description provided for @settingsProfilesSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch profile'**
  String get settingsProfilesSwitchTitle;

  /// No description provided for @settingsProfilesCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get settingsProfilesCreateTitle;

  /// No description provided for @settingsProfilesCreateAdmin.
  ///
  /// In en, this message translates to:
  /// **'Create admin profile'**
  String get settingsProfilesCreateAdmin;

  /// No description provided for @settingsProfilesJoinHousehold.
  ///
  /// In en, this message translates to:
  /// **'Join household'**
  String get settingsProfilesJoinHousehold;

  /// No description provided for @settingsProfilesDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get settingsProfilesDisplayName;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get profileNameRequired;

  /// No description provided for @settingsProfilesHouseholdName.
  ///
  /// In en, this message translates to:
  /// **'Household name'**
  String get settingsProfilesHouseholdName;

  /// No description provided for @settingsProfilesJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Household code'**
  String get settingsProfilesJoinCode;

  /// No description provided for @settingsProfilesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get settingsProfilesCreate;

  /// No description provided for @settingsProfilesCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Join code'**
  String get settingsProfilesCodeLabel;

  /// No description provided for @settingsProfilesRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename profile'**
  String get settingsProfilesRenameTitle;

  /// No description provided for @settingsProfilesFindNearby.
  ///
  /// In en, this message translates to:
  /// **'Find nearby'**
  String get settingsProfilesFindNearby;

  /// No description provided for @settingsProfilesDiscoveryStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Discovery status'**
  String get settingsProfilesDiscoveryStatusTitle;

  /// No description provided for @settingsProfilesDiscoveryLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Discovery log'**
  String get settingsProfilesDiscoveryLogTitle;

  /// No description provided for @settingsProfilesDiscoveryIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get settingsProfilesDiscoveryIdle;

  /// No description provided for @settingsProfilesDiscoveryStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting discovery...'**
  String get settingsProfilesDiscoveryStarting;

  /// No description provided for @settingsProfilesDiscoveryScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning for nearby households...'**
  String get settingsProfilesDiscoveryScanning;

  /// No description provided for @settingsProfilesDiscoveryFinished.
  ///
  /// In en, this message translates to:
  /// **'Discovery finished.'**
  String get settingsProfilesDiscoveryFinished;

  /// No description provided for @settingsProfilesDiscoveryNone.
  ///
  /// In en, this message translates to:
  /// **'No nearby households found.'**
  String get settingsProfilesDiscoveryNone;

  /// No description provided for @settingsProfilesDiscoveryFound.
  ///
  /// In en, this message translates to:
  /// **'Found {count} nearby households.'**
  String settingsProfilesDiscoveryFound(int count);

  /// No description provided for @settingsProfilesNoNearby.
  ///
  /// In en, this message translates to:
  /// **'No nearby households found'**
  String get settingsProfilesNoNearby;

  /// No description provided for @settingsProfilesNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby households'**
  String get settingsProfilesNearbyTitle;

  /// No description provided for @settingsDailyDigestScheduled.
  ///
  /// In en, this message translates to:
  /// **'Daily digest scheduled'**
  String get settingsDailyDigestScheduled;

  /// No description provided for @settingsNotificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications permission denied'**
  String get settingsNotificationsDenied;

  /// No description provided for @choresTitleWithRole.
  ///
  /// In en, this message translates to:
  /// **'Chores ({role})'**
  String choresTitleWithRole(Object role);

  /// No description provided for @choresAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add chore'**
  String get choresAddTooltip;

  /// No description provided for @choresApprovalsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get choresApprovalsTooltip;

  /// No description provided for @choresMyRequestsTooltip.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get choresMyRequestsTooltip;

  /// No description provided for @choresRequestCompletion.
  ///
  /// In en, this message translates to:
  /// **'Request completion'**
  String get choresRequestCompletion;

  /// No description provided for @choresAdminReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Admin: review in Approvals'**
  String get choresAdminReviewHint;

  /// No description provided for @choresLastCleanedNever.
  ///
  /// In en, this message translates to:
  /// **'Last cleaned: never'**
  String get choresLastCleanedNever;

  /// No description provided for @choresLastCleaned.
  ///
  /// In en, this message translates to:
  /// **'Last cleaned: {date}'**
  String choresLastCleaned(Object date);

  /// No description provided for @choresDueIn.
  ///
  /// In en, this message translates to:
  /// **'Due in {duration}'**
  String choresDueIn(Object duration);

  /// No description provided for @choresOverdueBy.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {duration}'**
  String choresOverdueBy(Object duration);

  /// No description provided for @choresSnoozedUntil.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {date}'**
  String choresSnoozedUntil(Object date);

  /// No description provided for @choresPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get choresPaused;

  /// No description provided for @choresNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get choresNoHistory;

  /// No description provided for @choresUseAmulet.
  ///
  /// In en, this message translates to:
  /// **'Use amulet'**
  String get choresUseAmulet;

  /// No description provided for @choresProtectionUntil.
  ///
  /// In en, this message translates to:
  /// **'Protected until {date}'**
  String choresProtectionUntil(Object date);

  /// No description provided for @choresAmuletAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'Amulet already used for this chore.'**
  String get choresAmuletAlreadyUsed;

  /// No description provided for @choresAmuletAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'Chore already protected.'**
  String get choresAmuletAlreadyActive;

  /// No description provided for @choresAmuletNone.
  ///
  /// In en, this message translates to:
  /// **'No amulets available.'**
  String get choresAmuletNone;

  /// No description provided for @choresAmuletSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select an amulet'**
  String get choresAmuletSelectTitle;

  /// No description provided for @choresAmuletConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Use amulet?'**
  String get choresAmuletConfirmTitle;

  /// No description provided for @choresAmuletConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Use amulet on {chore}?'**
  String choresAmuletConfirmBody(Object chore);

  /// No description provided for @choresAmuletApplied.
  ///
  /// In en, this message translates to:
  /// **'Amulet applied'**
  String get choresAmuletApplied;

  /// No description provided for @choresNoteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a note?'**
  String get choresNoteDialogTitle;

  /// No description provided for @choresNoteDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note for admin'**
  String get choresNoteDialogHint;

  /// No description provided for @choresSnoozeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Snooze chore'**
  String get choresSnoozeDialogTitle;

  /// No description provided for @choresSnooze1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get choresSnooze1Day;

  /// No description provided for @choresSnooze3Days.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get choresSnooze3Days;

  /// No description provided for @choresSnooze1Week.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get choresSnooze1Week;

  /// No description provided for @choresSnoozePickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get choresSnoozePickDate;

  /// No description provided for @choresRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted for review'**
  String get choresRequestSubmitted;

  /// No description provided for @choresMarkedCleaned.
  ///
  /// In en, this message translates to:
  /// **'Marked as cleaned'**
  String get choresMarkedCleaned;

  /// No description provided for @choresSnoozedUntilToast.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {date}'**
  String choresSnoozedUntilToast(Object date);

  /// No description provided for @choresSnoozeCleared.
  ///
  /// In en, this message translates to:
  /// **'Snooze cleared'**
  String get choresSnoozeCleared;

  /// No description provided for @choresPausedToast.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get choresPausedToast;

  /// No description provided for @choresResumedToast.
  ///
  /// In en, this message translates to:
  /// **'Resumed'**
  String get choresResumedToast;

  /// No description provided for @choresCleanedNow.
  ///
  /// In en, this message translates to:
  /// **'Cleaned now'**
  String get choresCleanedNow;

  /// No description provided for @choresSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get choresSnooze;

  /// No description provided for @choresClearSnooze.
  ///
  /// In en, this message translates to:
  /// **'Clear snooze'**
  String get choresClearSnooze;

  /// No description provided for @choresPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get choresPause;

  /// No description provided for @choresResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get choresResume;

  /// No description provided for @choreDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chore details'**
  String get choreDetailsTitle;

  /// No description provided for @choreEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit chore'**
  String get choreEditTitle;

  /// No description provided for @choreNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New chore'**
  String get choreNewTitle;

  /// No description provided for @choreLastCleanedTitle.
  ///
  /// In en, this message translates to:
  /// **'Last cleaned'**
  String get choreLastCleanedTitle;

  /// No description provided for @choreNoApprovedCompletions.
  ///
  /// In en, this message translates to:
  /// **'No approved completions yet'**
  String get choreNoApprovedCompletions;

  /// No description provided for @choreNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Chore name'**
  String get choreNameLabel;

  /// No description provided for @choreIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon (emoji)'**
  String get choreIconLabel;

  /// No description provided for @choreCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get choreCategoryLabel;

  /// No description provided for @choreRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room or zone (optional)'**
  String get choreRoomLabel;

  /// No description provided for @choreTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Chore type'**
  String get choreTypeLabel;

  /// No description provided for @choreTypeSingular.
  ///
  /// In en, this message translates to:
  /// **'Singular'**
  String get choreTypeSingular;

  /// No description provided for @choreTypeRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get choreTypeRecurring;

  /// No description provided for @choreIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Interval (days)'**
  String get choreIntervalLabel;

  /// No description provided for @choreOverdueWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Overdue weight (points/day)'**
  String get choreOverdueWeightLabel;

  /// No description provided for @chorePointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get chorePointsLabel;

  /// No description provided for @chorePausedLabel.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get chorePausedLabel;

  /// No description provided for @choreSave.
  ///
  /// In en, this message translates to:
  /// **'Save chore'**
  String get choreSave;

  /// No description provided for @choreDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete chore'**
  String get choreDeleteTooltip;

  /// No description provided for @choreDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete chore?'**
  String get choreDeleteTitle;

  /// No description provided for @choreDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get choreDeleteBody;

  /// No description provided for @choreNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get choreNameRequired;

  /// No description provided for @choreIntervalPositive.
  ///
  /// In en, this message translates to:
  /// **'Interval must be a positive number.'**
  String get choreIntervalPositive;

  /// No description provided for @chorePointsPositive.
  ///
  /// In en, this message translates to:
  /// **'Points must be a positive number.'**
  String get chorePointsPositive;

  /// No description provided for @choreOverdueWeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Overdue weight must be 0 or more.'**
  String get choreOverdueWeightInvalid;

  /// No description provided for @approvalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvalsTitle;

  /// No description provided for @myRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get myRequestsTitle;

  /// No description provided for @approvalsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Approval history'**
  String get approvalsHistoryTitle;

  /// No description provided for @approvalsNoPending.
  ///
  /// In en, this message translates to:
  /// **'No pending requests.'**
  String get approvalsNoPending;

  /// No description provided for @approvalsNoRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No requests yet.'**
  String get approvalsNoRequestsYet;

  /// No description provided for @approvalsRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by {user}'**
  String approvalsRequestedBy(Object user);

  /// No description provided for @approvalsSubmittedAt.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String approvalsSubmittedAt(Object date);

  /// No description provided for @approvalsReviewedAt.
  ///
  /// In en, this message translates to:
  /// **'Reviewed {date}'**
  String approvalsReviewedAt(Object date);

  /// No description provided for @approvalsReviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by {user}'**
  String approvalsReviewedBy(Object user);

  /// No description provided for @approvalsApprovedToast.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvalsApprovedToast;

  /// No description provided for @approvalsRejectedToast.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get approvalsRejectedToast;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @dashboardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardToday;

  /// No description provided for @dashboardTopPriorities.
  ///
  /// In en, this message translates to:
  /// **'Top priorities'**
  String get dashboardTopPriorities;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get dashboardNoActivity;

  /// No description provided for @activityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get activityFilterAll;

  /// No description provided for @activityFilterApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get activityFilterApproved;

  /// No description provided for @activityFilterRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get activityFilterRejected;

  /// No description provided for @activityFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get activityFilterPending;

  /// No description provided for @dashboardAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up for now.'**
  String get dashboardAllCaughtUp;

  /// No description provided for @dashboardDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dashboardDueToday;

  /// No description provided for @dashboardOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dashboardOverdue;

  /// No description provided for @dashboardPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending approvals'**
  String get dashboardPendingApprovals;

  /// No description provided for @dashboardPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get dashboardPoints;

  /// No description provided for @dashboardChoresBoard.
  ///
  /// In en, this message translates to:
  /// **'Chores board'**
  String get dashboardChoresBoard;

  /// No description provided for @dashboardRewards.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get dashboardRewards;

  /// No description provided for @dashboardApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get dashboardApprovals;

  /// No description provided for @dashboardMyRequests.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get dashboardMyRequests;

  /// No description provided for @dashboardActivityCompletionRequest.
  ///
  /// In en, this message translates to:
  /// **'Completion request'**
  String get dashboardActivityCompletionRequest;

  /// No description provided for @dashboardActivityPending.
  ///
  /// In en, this message translates to:
  /// **'Pending • {name}'**
  String dashboardActivityPending(Object name);

  /// No description provided for @dashboardActivityStatus.
  ///
  /// In en, this message translates to:
  /// **'{status} • {name}'**
  String dashboardActivityStatus(Object status, Object name);

  /// No description provided for @dashboardActivityRedemption.
  ///
  /// In en, this message translates to:
  /// **'Mystery box opened'**
  String get dashboardActivityRedemption;

  /// No description provided for @rewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get rewardsTitle;

  /// No description provided for @rewardsPointsBalance.
  ///
  /// In en, this message translates to:
  /// **'Points balance'**
  String get rewardsPointsBalance;

  /// No description provided for @rewardsMysteryBoxes.
  ///
  /// In en, this message translates to:
  /// **'Mystery boxes'**
  String get rewardsMysteryBoxes;

  /// No description provided for @rewardsNoBoxes.
  ///
  /// In en, this message translates to:
  /// **'No boxes available yet.'**
  String get rewardsNoBoxes;

  /// No description provided for @rewardsViewOdds.
  ///
  /// In en, this message translates to:
  /// **'View odds'**
  String get rewardsViewOdds;

  /// No description provided for @rewardsOpenBox.
  ///
  /// In en, this message translates to:
  /// **'Open box'**
  String get rewardsOpenBox;

  /// No description provided for @rewardsYouGot.
  ///
  /// In en, this message translates to:
  /// **'You got'**
  String get rewardsYouGot;

  /// No description provided for @rewardsNice.
  ///
  /// In en, this message translates to:
  /// **'Nice'**
  String get rewardsNice;

  /// No description provided for @rewardsManageRewards.
  ///
  /// In en, this message translates to:
  /// **'Manage rewards'**
  String get rewardsManageRewards;

  /// No description provided for @rewardsWeightStatus.
  ///
  /// In en, this message translates to:
  /// **'Chance {weight}% • {status}'**
  String rewardsWeightStatus(Object weight, Object status);

  /// No description provided for @rewardsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get rewardsEnabled;

  /// No description provided for @rewardsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get rewardsDisabled;

  /// No description provided for @rewardsAddReward.
  ///
  /// In en, this message translates to:
  /// **'Add reward'**
  String get rewardsAddReward;

  /// No description provided for @rewardsManageBoxRules.
  ///
  /// In en, this message translates to:
  /// **'Manage box rules'**
  String get rewardsManageBoxRules;

  /// No description provided for @rewardsCostRewardsCount.
  ///
  /// In en, this message translates to:
  /// **'Cost {cost} • {count} rewards'**
  String rewardsCostRewardsCount(Object cost, Object count);

  /// No description provided for @rewardsAddBoxRule.
  ///
  /// In en, this message translates to:
  /// **'Add box rule'**
  String get rewardsAddBoxRule;

  /// No description provided for @rewardsMyRewards.
  ///
  /// In en, this message translates to:
  /// **'My rewards'**
  String get rewardsMyRewards;

  /// No description provided for @shopItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop items'**
  String get shopItemsTitle;

  /// No description provided for @shopBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get shopBuy;

  /// No description provided for @shopPurchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Added to inventory'**
  String get shopPurchaseSuccess;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// No description provided for @inventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items yet.'**
  String get inventoryEmpty;

  /// No description provided for @inventoryUseFromChore.
  ///
  /// In en, this message translates to:
  /// **'Use from a chore menu'**
  String get inventoryUseFromChore;

  /// No description provided for @amuletLossProtection.
  ///
  /// In en, this message translates to:
  /// **'Amulet of loss protection ({hours}h)'**
  String amuletLossProtection(Object hours);

  /// No description provided for @amuletDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Pauses overdue for {hours} hours'**
  String amuletDurationLabel(Object hours);

  /// No description provided for @rewardsNoRedemptions.
  ///
  /// In en, this message translates to:
  /// **'No redemptions yet.'**
  String get rewardsNoRedemptions;

  /// No description provided for @rewardsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get rewardsViewAll;

  /// No description provided for @rewardsFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get rewardsFilterLabel;

  /// No description provided for @rewardsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rewardsFilterAll;

  /// No description provided for @rewardsRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get rewardsRedeem;

  /// No description provided for @rewardsRedeemRequested.
  ///
  /// In en, this message translates to:
  /// **'Redemption requested'**
  String get rewardsRedeemRequested;

  /// No description provided for @rewardsRedeemRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Redemption requests'**
  String get rewardsRedeemRequestsTitle;

  /// No description provided for @rewardsNoRedeemRequests.
  ///
  /// In en, this message translates to:
  /// **'No redemption requests.'**
  String get rewardsNoRedeemRequests;

  /// No description provided for @rewardsStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get rewardsStatusActive;

  /// No description provided for @rewardsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get rewardsStatusPending;

  /// No description provided for @rewardsStatusUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get rewardsStatusUsed;

  /// No description provided for @rewardsStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rewardsStatusRejected;

  /// No description provided for @rewardsNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get rewardsNothingFound;

  /// No description provided for @rewardsChanceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Chance must be between 0 and 100%.'**
  String get rewardsChanceInvalid;

  /// No description provided for @rewardsChanceOverLimit.
  ///
  /// In en, this message translates to:
  /// **'Total chance cannot exceed 100%.'**
  String get rewardsChanceOverLimit;

  /// No description provided for @rewardsCostPoints.
  ///
  /// In en, this message translates to:
  /// **'Cost: {cost} points'**
  String rewardsCostPoints(Object cost);

  /// No description provided for @rewardsRewardsCount.
  ///
  /// In en, this message translates to:
  /// **'Rewards: {count}'**
  String rewardsRewardsCount(Object count);

  /// No description provided for @rewardsAddRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Add reward'**
  String get rewardsAddRewardTitle;

  /// No description provided for @rewardsEditRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reward'**
  String get rewardsEditRewardTitle;

  /// No description provided for @rewardsAddBoxRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add box rule'**
  String get rewardsAddBoxRuleTitle;

  /// No description provided for @rewardsEditBoxRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit box rule'**
  String get rewardsEditBoxRuleTitle;

  /// No description provided for @rewardsTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get rewardsTitleLabel;

  /// No description provided for @rewardsDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get rewardsDescriptionLabel;

  /// No description provided for @rewardsWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Chance (%)'**
  String get rewardsWeightLabel;

  /// No description provided for @rewardsEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get rewardsEnabledLabel;

  /// No description provided for @rewardsCostPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost points'**
  String get rewardsCostPointsLabel;

  /// No description provided for @rewardsCooldownSecondsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cooldown (days)'**
  String get rewardsCooldownSecondsLabel;

  /// No description provided for @rewardsMaxPerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Max per day'**
  String get rewardsMaxPerDayLabel;

  /// No description provided for @rewardsOddsTitle.
  ///
  /// In en, this message translates to:
  /// **'Odds'**
  String get rewardsOddsTitle;

  /// No description provided for @rewardsDeleteRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete reward?'**
  String get rewardsDeleteRewardTitle;

  /// No description provided for @rewardsDeleteRewardBody.
  ///
  /// In en, this message translates to:
  /// **'This reward will be removed from the pool.'**
  String get rewardsDeleteRewardBody;

  /// No description provided for @rewardsDeleteBoxRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete box rule?'**
  String get rewardsDeleteBoxRuleTitle;

  /// No description provided for @rewardsDeleteBoxRuleBody.
  ///
  /// In en, this message translates to:
  /// **'This box will no longer be redeemable.'**
  String get rewardsDeleteBoxRuleBody;

  /// No description provided for @rewardsNotEnoughPoints.
  ///
  /// In en, this message translates to:
  /// **'Not enough points to redeem.'**
  String get rewardsNotEnoughPoints;

  /// No description provided for @rewardsCooldownActive.
  ///
  /// In en, this message translates to:
  /// **'Box is cooling down. Try later.'**
  String get rewardsCooldownActive;

  /// No description provided for @rewardsDailyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached for this box.'**
  String get rewardsDailyLimitReached;

  /// No description provided for @rewardsCooldownRemaining.
  ///
  /// In en, this message translates to:
  /// **'Cooldown: {remaining}'**
  String rewardsCooldownRemaining(Object remaining);

  /// No description provided for @rewardsDailyLimitStatus.
  ///
  /// In en, this message translates to:
  /// **'Daily limit: {count}/{max}'**
  String rewardsDailyLimitStatus(Object count, Object max);

  /// No description provided for @rewardsCooldownDisabledDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug: cooldown off'**
  String get rewardsCooldownDisabledDebug;

  /// No description provided for @rewardsDailyLimitDisabledDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug: daily limit off'**
  String get rewardsDailyLimitDisabledDebug;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @areaCategoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get areaCategoryHome;

  /// No description provided for @areaCategoryCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get areaCategoryCar;

  /// No description provided for @areaCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get areaCategoryOther;

  /// No description provided for @itemStatusFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get itemStatusFresh;

  /// No description provided for @itemStatusSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get itemStatusSoon;

  /// No description provided for @itemStatusDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get itemStatusDue;

  /// No description provided for @itemStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get itemStatusOverdue;

  /// No description provided for @itemStatusSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get itemStatusSnoozed;

  /// No description provided for @itemStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get itemStatusPaused;

  /// No description provided for @dailyDigestTitle.
  ///
  /// In en, this message translates to:
  /// **'CleanQuest daily digest'**
  String get dailyDigestTitle;

  /// No description provided for @dailyDigestBody.
  ///
  /// In en, this message translates to:
  /// **'Due today: {due} • Overdue: {overdue}{pendingSegment}'**
  String dailyDigestBody(Object due, Object overdue, Object pendingSegment);

  /// No description provided for @dailyDigestPendingSegment.
  ///
  /// In en, this message translates to:
  /// **' • Pending approvals: {pending}'**
  String dailyDigestPendingSegment(Object pending);

  /// No description provided for @notificationNewApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'New approval request'**
  String get notificationNewApprovalTitle;

  /// No description provided for @notificationNewApprovalBody.
  ///
  /// In en, this message translates to:
  /// **'A member submitted a request.'**
  String get notificationNewApprovalBody;

  /// No description provided for @notificationRequestApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get notificationRequestApprovedTitle;

  /// No description provided for @notificationRequestApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'A request was approved.'**
  String get notificationRequestApprovedBody;

  /// No description provided for @notificationRequestRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get notificationRequestRejectedTitle;

  /// No description provided for @notificationRequestRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'A request was rejected.'**
  String get notificationRequestRejectedBody;

  /// No description provided for @notificationRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Reward redeemed'**
  String get notificationRewardTitle;

  /// No description provided for @notificationRewardBody.
  ///
  /// In en, this message translates to:
  /// **'{user} won {reward}'**
  String notificationRewardBody(Object user, Object reward);

  /// No description provided for @errorAdminsCannotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Admins cannot submit completion requests.'**
  String get errorAdminsCannotSubmit;

  /// No description provided for @errorOnlyAdminsApprove.
  ///
  /// In en, this message translates to:
  /// **'Only admins can approve requests.'**
  String get errorOnlyAdminsApprove;

  /// No description provided for @errorOnlyAdminsReject.
  ///
  /// In en, this message translates to:
  /// **'Only admins can reject requests.'**
  String get errorOnlyAdminsReject;
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
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
