// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CleanQuest';

  @override
  String get commonAdmin => 'Admin';

  @override
  String get commonMember => 'Member';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDone => 'Done';

  @override
  String get commonApprove => 'Approve';

  @override
  String get commonReject => 'Reject';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String commonPointsLabel(Object points) {
    return 'Points: $points';
  }

  @override
  String commonPointsShort(Object points) {
    return '$points pts';
  }

  @override
  String get commonUnknownChore => 'Unknown chore';

  @override
  String get commonUnknownReward => 'Unknown reward';

  @override
  String get commonUnknownHousehold => 'Household';

  @override
  String get onboardingTitle => 'Welcome to CleanQuest';

  @override
  String get onboardingChooseRole => 'Create or join a household';

  @override
  String get onboardingRoleSubtitle =>
      'The creator becomes admin. Everyone else joins as a member.';

  @override
  String get onboardingCreateHouseholdLabel => 'Create household';

  @override
  String get onboardingJoinHouseholdLabel => 'Join household';

  @override
  String get onboardingYourName => 'Your name';

  @override
  String get onboardingHouseholdName => 'Household name';

  @override
  String get onboardingShareCode => 'Share this code with members';

  @override
  String get onboardingQrTitle => 'QR code';

  @override
  String get onboardingQrHint => 'Scan this QR code to join the household.';

  @override
  String get onboardingFinishSetup => 'Finish setup';

  @override
  String get onboardingGenerateCode => 'Generate new code';

  @override
  String get onboardingCodeInstructions =>
      'Members will enter this to join your household.';

  @override
  String get onboardingAdminCodeLabel => 'Enter join code';

  @override
  String get onboardingJoinHousehold => 'Join household';

  @override
  String get onboardingCodeRequired => 'Code is required.';

  @override
  String get onboardingCodeLength => 'Enter the 6-digit code.';

  @override
  String get onboardingHouseholdNotFound => 'Household not found.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAdminJoinCode => 'Admin join code';

  @override
  String get settingsHouseholdCode => 'Household code';

  @override
  String get settingsJoinCodeNotSet => 'Not set';

  @override
  String get settingsCodeCopiedToast => 'Code copied';

  @override
  String get settingsEnableNotifications => 'Enable notifications';

  @override
  String get settingsNotificationsSubtitle => 'Approvals and reward alerts';

  @override
  String get settingsDailyDigest => 'Daily digest';

  @override
  String get settingsDailyDigestSubtitle => 'Due items and approvals summary';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsDarkModeSubtitle => 'Use dark theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'App language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePolish => 'Polish';

  @override
  String get settingsViewNotifications => 'View notifications';

  @override
  String get settingsRegenerateJoinCode => 'Regenerate join code';

  @override
  String get settingsRestoreTemplates => 'Restore default templates';

  @override
  String get settingsLogOut => 'Log out (reset onboarding)';

  @override
  String get settingsLogOutDialogTitle => 'Log out?';

  @override
  String get settingsLogOutDialogBody =>
      'This clears your role and household selection on this device.';

  @override
  String get settingsReset => 'Reset';

  @override
  String get settingsRegenerateDialogTitle => 'Regenerate join code?';

  @override
  String get settingsRegenerateDialogBody =>
      'Members with the old code will not be able to join.';

  @override
  String get settingsRegenerate => 'Regenerate';

  @override
  String get settingsNewJoinCode => 'New join code';

  @override
  String get settingsNewCodeGenerated => 'New code generated and copied';

  @override
  String get settingsRestoreDialogTitle => 'Restore default templates?';

  @override
  String get settingsRestoreDialogBody =>
      'This replaces current chores and completion history for this household.';

  @override
  String get settingsRestore => 'Restore';

  @override
  String get settingsTemplatesRestored => 'Templates restored';

  @override
  String get settingsSwitchToAdmin => 'Switch to admin';

  @override
  String get settingsSwitchToMember => 'Switch to member';

  @override
  String get settingsSwitchedToAdmin => 'Switched to admin';

  @override
  String get settingsSwitchedToMember => 'Switched to member';

  @override
  String get settingsTesting => 'Testing';

  @override
  String get settingsNoHouseholdToSwitch => 'No household to switch.';

  @override
  String get settingsProfilesTitle => 'Profiles';

  @override
  String get settingsProfilesNoActive => 'No active profile';

  @override
  String get settingsProfilesAdd => 'Add profile';

  @override
  String get settingsProfilesSwitchTitle => 'Switch profile';

  @override
  String get settingsProfilesCreateTitle => 'Create profile';

  @override
  String get settingsProfilesCreateAdmin => 'Create admin profile';

  @override
  String get settingsProfilesJoinHousehold => 'Join household';

  @override
  String get settingsProfilesDisplayName => 'Display name';

  @override
  String get profileNameRequired => 'Name is required.';

  @override
  String get settingsProfilesHouseholdName => 'Household name';

  @override
  String get settingsProfilesJoinCode => 'Household code';

  @override
  String get settingsProfilesCreate => 'Create';

  @override
  String get settingsProfilesCodeLabel => 'Join code';

  @override
  String get settingsProfilesRenameTitle => 'Rename profile';

  @override
  String get settingsProfilesFindNearby => 'Find nearby';

  @override
  String get settingsProfilesDiscoveryStatusTitle => 'Discovery status';

  @override
  String get settingsProfilesDiscoveryLogTitle => 'Discovery log';

  @override
  String get settingsProfilesDiscoveryIdle => 'Idle';

  @override
  String get settingsProfilesDiscoveryStarting => 'Starting discovery...';

  @override
  String get settingsProfilesDiscoveryScanning =>
      'Scanning for nearby households...';

  @override
  String get settingsProfilesDiscoveryFinished => 'Discovery finished.';

  @override
  String get settingsProfilesDiscoveryNone => 'No nearby households found.';

  @override
  String settingsProfilesDiscoveryFound(int count) {
    return 'Found $count nearby households.';
  }

  @override
  String get settingsProfilesNoNearby => 'No nearby households found';

  @override
  String get settingsProfilesNearbyTitle => 'Nearby households';

  @override
  String get settingsDailyDigestScheduled => 'Daily digest scheduled';

  @override
  String get settingsNotificationsDenied => 'Notifications permission denied';

  @override
  String choresTitleWithRole(Object role) {
    return 'Chores ($role)';
  }

  @override
  String get choresAddTooltip => 'Add chore';

  @override
  String get choresApprovalsTooltip => 'Approvals';

  @override
  String get choresMyRequestsTooltip => 'My requests';

  @override
  String get choresRequestCompletion => 'Request completion';

  @override
  String get choresAdminReviewHint => 'Admin: review in Approvals';

  @override
  String get choresLastCleanedNever => 'Last cleaned: never';

  @override
  String choresLastCleaned(Object date) {
    return 'Last cleaned: $date';
  }

  @override
  String choresDueIn(Object duration) {
    return 'Due in $duration';
  }

  @override
  String choresOverdueBy(Object duration) {
    return 'Overdue by $duration';
  }

  @override
  String choresSnoozedUntil(Object date) {
    return 'Snoozed until $date';
  }

  @override
  String get choresPaused => 'Paused';

  @override
  String get choresNoHistory => 'No history yet';

  @override
  String get choresUseAmulet => 'Use amulet';

  @override
  String choresProtectionUntil(Object date) {
    return 'Protected until $date';
  }

  @override
  String get choresAmuletAlreadyUsed => 'Amulet already used for this chore.';

  @override
  String get choresAmuletAlreadyActive => 'Chore already protected.';

  @override
  String get choresAmuletNone => 'No amulets available.';

  @override
  String get choresAmuletSelectTitle => 'Select an amulet';

  @override
  String get choresAmuletConfirmTitle => 'Use amulet?';

  @override
  String choresAmuletConfirmBody(Object chore) {
    return 'Use amulet on $chore?';
  }

  @override
  String get choresAmuletApplied => 'Amulet applied';

  @override
  String get choresNoteDialogTitle => 'Add a note?';

  @override
  String get choresNoteDialogHint => 'Optional note for admin';

  @override
  String get choresSnoozeDialogTitle => 'Snooze chore';

  @override
  String get choresSnooze1Day => '1 day';

  @override
  String get choresSnooze3Days => '3 days';

  @override
  String get choresSnooze1Week => '1 week';

  @override
  String get choresSnoozePickDate => 'Pick a date';

  @override
  String get choresRequestSubmitted => 'Submitted for review';

  @override
  String get choresMarkedCleaned => 'Marked as cleaned';

  @override
  String choresSnoozedUntilToast(Object date) {
    return 'Snoozed until $date';
  }

  @override
  String get choresSnoozeCleared => 'Snooze cleared';

  @override
  String get choresPausedToast => 'Paused';

  @override
  String get choresResumedToast => 'Resumed';

  @override
  String get choresCleanedNow => 'Cleaned now';

  @override
  String get choresSnooze => 'Snooze';

  @override
  String get choresClearSnooze => 'Clear snooze';

  @override
  String get choresPause => 'Pause';

  @override
  String get choresResume => 'Resume';

  @override
  String get choreDetailsTitle => 'Chore details';

  @override
  String get choreEditTitle => 'Edit chore';

  @override
  String get choreNewTitle => 'New chore';

  @override
  String get choreLastCleanedTitle => 'Last cleaned';

  @override
  String get choreNoApprovedCompletions => 'No approved completions yet';

  @override
  String get choreNameLabel => 'Chore name';

  @override
  String get choreIconLabel => 'Icon (emoji)';

  @override
  String get choreCategoryLabel => 'Category';

  @override
  String get choreRoomLabel => 'Room or zone (optional)';

  @override
  String get choreTypeLabel => 'Chore type';

  @override
  String get choreTypeSingular => 'Singular';

  @override
  String get choreTypeRecurring => 'Recurring';

  @override
  String get choreIntervalLabel => 'Interval (days)';

  @override
  String get choreOverdueWeightLabel => 'Overdue weight (points/day)';

  @override
  String get chorePointsLabel => 'Points';

  @override
  String get chorePausedLabel => 'Paused';

  @override
  String get choreSave => 'Save chore';

  @override
  String get choreDeleteTooltip => 'Delete chore';

  @override
  String get choreDeleteTitle => 'Delete chore?';

  @override
  String get choreDeleteBody => 'This cannot be undone.';

  @override
  String get choreNameRequired => 'Name is required.';

  @override
  String get choreIntervalPositive => 'Interval must be a positive number.';

  @override
  String get chorePointsPositive => 'Points must be a positive number.';

  @override
  String get choreOverdueWeightInvalid => 'Overdue weight must be 0 or more.';

  @override
  String get approvalsTitle => 'Approvals';

  @override
  String get myRequestsTitle => 'My requests';

  @override
  String get approvalsHistoryTitle => 'Approval history';

  @override
  String get approvalsNoPending => 'No pending requests.';

  @override
  String get approvalsNoRequestsYet => 'No requests yet.';

  @override
  String approvalsRequestedBy(Object user) {
    return 'Requested by $user';
  }

  @override
  String approvalsSubmittedAt(Object date) {
    return 'Submitted $date';
  }

  @override
  String approvalsReviewedAt(Object date) {
    return 'Reviewed $date';
  }

  @override
  String approvalsReviewedBy(Object user) {
    return 'Reviewed by $user';
  }

  @override
  String get approvalsApprovedToast => 'Approved';

  @override
  String get approvalsRejectedToast => 'Rejected';

  @override
  String get statusPending => 'Under review';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get dashboardToday => 'Today';

  @override
  String get dashboardTopPriorities => 'Top priorities';

  @override
  String get dashboardQuickActions => 'Quick actions';

  @override
  String get dashboardRecentActivity => 'Recent activity';

  @override
  String get dashboardNoActivity => 'No activity yet.';

  @override
  String get activityFilterAll => 'All';

  @override
  String get activityFilterApproved => 'Approved';

  @override
  String get activityFilterRejected => 'Rejected';

  @override
  String get activityFilterPending => 'Pending';

  @override
  String get dashboardAllCaughtUp => 'All caught up for now.';

  @override
  String get dashboardDueToday => 'Due today';

  @override
  String get dashboardOverdue => 'Overdue';

  @override
  String get dashboardPendingApprovals => 'Pending approvals';

  @override
  String get dashboardPoints => 'Points';

  @override
  String get dashboardChoresBoard => 'Chores board';

  @override
  String get dashboardRewards => 'Shop';

  @override
  String get dashboardApprovals => 'Approvals';

  @override
  String get dashboardMyRequests => 'My requests';

  @override
  String get dashboardActivityCompletionRequest => 'Completion request';

  @override
  String dashboardActivityPending(Object name) {
    return 'Pending • $name';
  }

  @override
  String dashboardActivityStatus(Object status, Object name) {
    return '$status • $name';
  }

  @override
  String get dashboardActivityRedemption => 'Mystery box opened';

  @override
  String get rewardsTitle => 'Shop';

  @override
  String get rewardsPointsBalance => 'Points balance';

  @override
  String get rewardsMysteryBoxes => 'Mystery boxes';

  @override
  String get rewardsNoBoxes => 'No boxes available yet.';

  @override
  String get rewardsViewOdds => 'View odds';

  @override
  String get rewardsOpenBox => 'Open box';

  @override
  String get rewardsYouGot => 'You got';

  @override
  String get rewardsNice => 'Nice';

  @override
  String get rewardsManageRewards => 'Manage rewards';

  @override
  String rewardsWeightStatus(Object weight, Object status) {
    return 'Chance $weight% • $status';
  }

  @override
  String get rewardsEnabled => 'Enabled';

  @override
  String get rewardsDisabled => 'Disabled';

  @override
  String get rewardsAddReward => 'Add reward';

  @override
  String get rewardsManageBoxRules => 'Manage box rules';

  @override
  String rewardsCostRewardsCount(Object cost, Object count) {
    return 'Cost $cost • $count rewards';
  }

  @override
  String get rewardsAddBoxRule => 'Add box rule';

  @override
  String get rewardsMyRewards => 'My rewards';

  @override
  String get shopItemsTitle => 'Shop items';

  @override
  String get shopBuy => 'Buy';

  @override
  String get shopPurchaseSuccess => 'Added to inventory';

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String get inventoryEmpty => 'No items yet.';

  @override
  String get inventoryUseFromChore => 'Use from a chore menu';

  @override
  String amuletLossProtection(Object hours) {
    return 'Amulet of loss protection (${hours}h)';
  }

  @override
  String amuletDurationLabel(Object hours) {
    return 'Pauses overdue for $hours hours';
  }

  @override
  String get rewardsNoRedemptions => 'No redemptions yet.';

  @override
  String get rewardsViewAll => 'View all';

  @override
  String get rewardsFilterLabel => 'Filter';

  @override
  String get rewardsFilterAll => 'All';

  @override
  String get rewardsRedeem => 'Redeem';

  @override
  String get rewardsRedeemRequested => 'Redemption requested';

  @override
  String get rewardsRedeemRequestsTitle => 'Redemption requests';

  @override
  String get rewardsNoRedeemRequests => 'No redemption requests.';

  @override
  String get rewardsStatusActive => 'Active';

  @override
  String get rewardsStatusPending => 'Under review';

  @override
  String get rewardsStatusUsed => 'Used';

  @override
  String get rewardsStatusRejected => 'Rejected';

  @override
  String get rewardsNothingFound => 'Nothing found';

  @override
  String get rewardsChanceInvalid => 'Chance must be between 0 and 100%.';

  @override
  String get rewardsChanceOverLimit => 'Total chance cannot exceed 100%.';

  @override
  String rewardsCostPoints(Object cost) {
    return 'Cost: $cost points';
  }

  @override
  String rewardsRewardsCount(Object count) {
    return 'Rewards: $count';
  }

  @override
  String get rewardsAddRewardTitle => 'Add reward';

  @override
  String get rewardsEditRewardTitle => 'Edit reward';

  @override
  String get rewardsAddBoxRuleTitle => 'Add box rule';

  @override
  String get rewardsEditBoxRuleTitle => 'Edit box rule';

  @override
  String get rewardsTitleLabel => 'Title';

  @override
  String get rewardsDescriptionLabel => 'Description';

  @override
  String get rewardsWeightLabel => 'Chance (%)';

  @override
  String get rewardsEnabledLabel => 'Enabled';

  @override
  String get rewardsCostPointsLabel => 'Cost points';

  @override
  String get rewardsCooldownSecondsLabel => 'Cooldown (days)';

  @override
  String get rewardsMaxPerDayLabel => 'Max per day';

  @override
  String get rewardsOddsTitle => 'Odds';

  @override
  String get rewardsDeleteRewardTitle => 'Delete reward?';

  @override
  String get rewardsDeleteRewardBody =>
      'This reward will be removed from the pool.';

  @override
  String get rewardsDeleteBoxRuleTitle => 'Delete box rule?';

  @override
  String get rewardsDeleteBoxRuleBody =>
      'This box will no longer be redeemable.';

  @override
  String get rewardsNotEnoughPoints => 'Not enough points to redeem.';

  @override
  String get rewardsCooldownActive => 'Box is cooling down. Try later.';

  @override
  String get rewardsDailyLimitReached => 'Daily limit reached for this box.';

  @override
  String rewardsCooldownRemaining(Object remaining) {
    return 'Cooldown: $remaining';
  }

  @override
  String rewardsDailyLimitStatus(Object count, Object max) {
    return 'Daily limit: $count/$max';
  }

  @override
  String get rewardsCooldownDisabledDebug => 'Debug: cooldown off';

  @override
  String get rewardsDailyLimitDisabledDebug => 'Debug: daily limit off';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get areaCategoryHome => 'Home';

  @override
  String get areaCategoryCar => 'Car';

  @override
  String get areaCategoryOther => 'Other';

  @override
  String get itemStatusFresh => 'Fresh';

  @override
  String get itemStatusSoon => 'Soon';

  @override
  String get itemStatusDue => 'Due';

  @override
  String get itemStatusOverdue => 'Overdue';

  @override
  String get itemStatusSnoozed => 'Snoozed';

  @override
  String get itemStatusPaused => 'Paused';

  @override
  String get dailyDigestTitle => 'CleanQuest daily digest';

  @override
  String dailyDigestBody(Object due, Object overdue, Object pendingSegment) {
    return 'Due today: $due • Overdue: $overdue$pendingSegment';
  }

  @override
  String dailyDigestPendingSegment(Object pending) {
    return ' • Pending approvals: $pending';
  }

  @override
  String get notificationNewApprovalTitle => 'New approval request';

  @override
  String get notificationNewApprovalBody => 'A member submitted a request.';

  @override
  String get notificationRequestApprovedTitle => 'Request approved';

  @override
  String get notificationRequestApprovedBody => 'A request was approved.';

  @override
  String get notificationRequestRejectedTitle => 'Request rejected';

  @override
  String get notificationRequestRejectedBody => 'A request was rejected.';

  @override
  String get notificationRewardTitle => 'Reward redeemed';

  @override
  String notificationRewardBody(Object user, Object reward) {
    return '$user won $reward';
  }

  @override
  String get errorAdminsCannotSubmit =>
      'Admins cannot submit completion requests.';

  @override
  String get errorOnlyAdminsApprove => 'Only admins can approve requests.';

  @override
  String get errorOnlyAdminsReject => 'Only admins can reject requests.';
}
