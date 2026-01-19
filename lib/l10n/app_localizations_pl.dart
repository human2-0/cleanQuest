// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'CleanQuest';

  @override
  String get commonAdmin => 'Admin';

  @override
  String get commonMember => 'Użytkownik';

  @override
  String get commonCancel => 'Anuluj';

  @override
  String get commonSave => 'Zapisz';

  @override
  String get commonDelete => 'Usuń';

  @override
  String get commonClose => 'Zamknij';

  @override
  String get commonDone => 'Gotowe';

  @override
  String get commonApprove => 'Zatwierdź';

  @override
  String get commonReject => 'Odrzuć';

  @override
  String get commonSubmit => 'Wyślij';

  @override
  String get commonCopy => 'Kopiuj';

  @override
  String get commonCopied => 'Skopiowano';

  @override
  String commonPointsLabel(Object points) {
    return 'Punkty: $points';
  }

  @override
  String commonPointsShort(Object points) {
    return '$points pkt';
  }

  @override
  String get commonUnknownChore => 'Nieznane zadanie';

  @override
  String get commonUnknownReward => 'Nieznana nagroda';

  @override
  String get commonUnknownHousehold => 'Gospodarstwo';

  @override
  String get onboardingTitle => 'Witaj w CleanQuest';

  @override
  String get onboardingChooseRole => 'Wybierz rolę';

  @override
  String get onboardingRoleSubtitle =>
      'Admini weryfikują pracę. Użytkownicy zgłaszają wykonanie.';

  @override
  String get onboardingYourName => 'Twoje imię';

  @override
  String get onboardingHouseholdName => 'Nazwa gospodarstwa';

  @override
  String get onboardingShareCode => 'Udostępnij ten kod użytkownikom';

  @override
  String get onboardingFinishSetup => 'Zakończ konfigurację';

  @override
  String get onboardingGenerateCode => 'Wygeneruj nowy kod';

  @override
  String get onboardingCodeInstructions =>
      'Użytkownicy wpiszą ten kod, aby dołączyć do gospodarstwa.';

  @override
  String get onboardingAdminCodeLabel => 'Wpisz kod admina';

  @override
  String get onboardingJoinHousehold => 'Dołącz do gospodarstwa';

  @override
  String get onboardingCodeRequired => 'Kod jest wymagany.';

  @override
  String get onboardingCodeLength => 'Wpisz 6-cyfrowy kod.';

  @override
  String get onboardingHouseholdNotFound => 'Nie znaleziono gospodarstwa.';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsAdminJoinCode => 'Kod admina';

  @override
  String get settingsHouseholdCode => 'Kod gospodarstwa';

  @override
  String get settingsJoinCodeNotSet => 'Nie ustawiono';

  @override
  String get settingsCodeCopiedToast => 'Kod skopiowany';

  @override
  String get settingsEnableNotifications => 'Włącz powiadomienia';

  @override
  String get settingsNotificationsSubtitle =>
      'Powiadomienia o zatwierdzeniach i nagrodach';

  @override
  String get settingsDailyDigest => 'Dzienny podsumowanie';

  @override
  String get settingsDailyDigestSubtitle => 'Podsumowanie zadań i zatwierdzeń';

  @override
  String get settingsLanguage => 'Język';

  @override
  String get settingsLanguageSubtitle => 'Język aplikacji';

  @override
  String get languageEnglish => 'Angielski';

  @override
  String get languagePolish => 'Polski';

  @override
  String get settingsViewNotifications => 'Zobacz powiadomienia';

  @override
  String get settingsRegenerateJoinCode => 'Wygeneruj nowy kod';

  @override
  String get settingsRestoreTemplates => 'Przywróć domyślne szablony';

  @override
  String get settingsLogOut => 'Wyloguj (reset onboardingu)';

  @override
  String get settingsLogOutDialogTitle => 'Wylogować?';

  @override
  String get settingsLogOutDialogBody =>
      'To czyści rolę i wybór gospodarstwa na tym urządzeniu.';

  @override
  String get settingsReset => 'Resetuj';

  @override
  String get settingsRegenerateDialogTitle => 'Wygenerować nowy kod?';

  @override
  String get settingsRegenerateDialogBody =>
      'Użytkownicy ze starym kodem nie będą mogli dołączyć.';

  @override
  String get settingsRegenerate => 'Wygeneruj';

  @override
  String get settingsNewJoinCode => 'Nowy kod';

  @override
  String get settingsNewCodeGenerated => 'Nowy kod wygenerowany i skopiowany';

  @override
  String get settingsRestoreDialogTitle => 'Przywrócić domyślne szablony?';

  @override
  String get settingsRestoreDialogBody =>
      'To zastąpi obecne zadania i historię ukończeń dla tego gospodarstwa.';

  @override
  String get settingsRestore => 'Przywróć';

  @override
  String get settingsTemplatesRestored => 'Szablony przywrócone';

  @override
  String get settingsSwitchToAdmin => 'Przełącz na admina';

  @override
  String get settingsSwitchToMember => 'Przełącz na użytkownika';

  @override
  String get settingsSwitchedToAdmin => 'Przełączono na admina';

  @override
  String get settingsSwitchedToMember => 'Przełączono na użytkownika';

  @override
  String get settingsTesting => 'Testy';

  @override
  String get settingsNoHouseholdToSwitch =>
      'Brak gospodarstwa do przełączenia.';

  @override
  String get settingsDailyDigestScheduled => 'Dzienny podsumowanie ustawione';

  @override
  String get settingsNotificationsDenied => 'Brak zgody na powiadomienia';

  @override
  String choresTitleWithRole(Object role) {
    return 'Zadania ($role)';
  }

  @override
  String get choresAddTooltip => 'Dodaj zadanie';

  @override
  String get choresApprovalsTooltip => 'Zatwierdzenia';

  @override
  String get choresMyRequestsTooltip => 'Moje zgłoszenia';

  @override
  String get choresRequestCompletion => 'Zgłoś wykonanie';

  @override
  String get choresAdminReviewHint => 'Admin: sprawdź w Zatwierdzeniach';

  @override
  String get choresLastCleanedNever => 'Ostatnio wykonane: nigdy';

  @override
  String choresLastCleaned(Object date) {
    return 'Ostatnio wykonane: $date';
  }

  @override
  String choresDueIn(Object duration) {
    return 'Do terminu: $duration';
  }

  @override
  String choresOverdueBy(Object duration) {
    return 'Po terminie: $duration';
  }

  @override
  String choresSnoozedUntil(Object date) {
    return 'Uśpione do $date';
  }

  @override
  String get choresPaused => 'Wstrzymane';

  @override
  String get choresNoHistory => 'Brak historii';

  @override
  String get choresNoteDialogTitle => 'Dodać notatkę?';

  @override
  String get choresNoteDialogHint => 'Opcjonalna notatka dla admina';

  @override
  String get choresSnoozeDialogTitle => 'Uśpij zadanie';

  @override
  String get choresSnooze1Day => '1 dzień';

  @override
  String get choresSnooze3Days => '3 dni';

  @override
  String get choresSnooze1Week => '1 tydzień';

  @override
  String get choresSnoozePickDate => 'Wybierz datę';

  @override
  String get choresRequestSubmitted => 'Zgłoszenie wysłane';

  @override
  String get choresMarkedCleaned => 'Oznaczono jako wykonane';

  @override
  String choresSnoozedUntilToast(Object date) {
    return 'Uśpione do $date';
  }

  @override
  String get choresSnoozeCleared => 'Uśpienie usunięte';

  @override
  String get choresPausedToast => 'Wstrzymane';

  @override
  String get choresResumedToast => 'Wznowione';

  @override
  String get choresCleanedNow => 'Wykonane teraz';

  @override
  String get choresSnooze => 'Uśpij';

  @override
  String get choresClearSnooze => 'Usuń uśpienie';

  @override
  String get choresPause => 'Wstrzymaj';

  @override
  String get choresResume => 'Wznów';

  @override
  String get choreDetailsTitle => 'Szczegóły zadania';

  @override
  String get choreEditTitle => 'Edytuj zadanie';

  @override
  String get choreNewTitle => 'Nowe zadanie';

  @override
  String get choreLastCleanedTitle => 'Ostatnio wykonane';

  @override
  String get choreNoApprovedCompletions => 'Brak zatwierdzonych ukończeń';

  @override
  String get choreNameLabel => 'Nazwa zadania';

  @override
  String get choreIconLabel => 'Ikona (emoji)';

  @override
  String get choreCategoryLabel => 'Kategoria';

  @override
  String get choreRoomLabel => 'Pomieszczenie lub strefa (opcjonalnie)';

  @override
  String get choreIntervalLabel => 'Interwał (dni)';

  @override
  String get chorePointsLabel => 'Punkty';

  @override
  String get chorePausedLabel => 'Wstrzymane';

  @override
  String get choreSave => 'Zapisz zadanie';

  @override
  String get choreDeleteTooltip => 'Usuń zadanie';

  @override
  String get choreDeleteTitle => 'Usunąć zadanie?';

  @override
  String get choreDeleteBody => 'Tego nie można cofnąć.';

  @override
  String get choreNameRequired => 'Nazwa jest wymagana.';

  @override
  String get choreIntervalPositive => 'Interwał musi być dodatni.';

  @override
  String get chorePointsPositive => 'Punkty muszą być dodatnie.';

  @override
  String get approvalsTitle => 'Zatwierdzenia';

  @override
  String get myRequestsTitle => 'Moje zgłoszenia';

  @override
  String get approvalsHistoryTitle => 'Historia zatwierdzeń';

  @override
  String get approvalsNoPending => 'Brak oczekujących zgłoszeń.';

  @override
  String get approvalsNoRequestsYet => 'Brak zgłoszeń.';

  @override
  String approvalsRequestedBy(Object user) {
    return 'Zgłoszone przez $user';
  }

  @override
  String approvalsSubmittedAt(Object date) {
    return 'Zgłoszono $date';
  }

  @override
  String approvalsReviewedAt(Object date) {
    return 'Sprawdzone $date';
  }

  @override
  String approvalsReviewedBy(Object user) {
    return 'Sprawdzone przez $user';
  }

  @override
  String get approvalsApprovedToast => 'Zatwierdzono';

  @override
  String get approvalsRejectedToast => 'Odrzucono';

  @override
  String get statusPending => 'Oczekujące';

  @override
  String get statusApproved => 'Zatwierdzone';

  @override
  String get statusRejected => 'Odrzucone';

  @override
  String get dashboardToday => 'Dzisiaj';

  @override
  String get dashboardTopPriorities => 'Najważniejsze';

  @override
  String get dashboardQuickActions => 'Szybkie akcje';

  @override
  String get dashboardRecentActivity => 'Ostatnia aktywność';

  @override
  String get dashboardNoActivity => 'Brak aktywności.';

  @override
  String get activityFilterAll => 'Wszystkie';

  @override
  String get activityFilterApproved => 'Zatwierdzone';

  @override
  String get activityFilterRejected => 'Odrzucone';

  @override
  String get activityFilterPending => 'Oczekujące';

  @override
  String get dashboardAllCaughtUp => 'Na razie wszystko zrobione.';

  @override
  String get dashboardDueToday => 'Na dziś';

  @override
  String get dashboardOverdue => 'Po terminie';

  @override
  String get dashboardPendingApprovals => 'Oczekujące';

  @override
  String get dashboardPoints => 'Punkty';

  @override
  String get dashboardChoresBoard => 'Lista zadań';

  @override
  String get dashboardRewards => 'Nagrody';

  @override
  String get dashboardApprovals => 'Zatwierdzenia';

  @override
  String get dashboardMyRequests => 'Moje zgłoszenia';

  @override
  String get dashboardActivityCompletionRequest => 'Zgłoszenie wykonania';

  @override
  String dashboardActivityPending(Object name) {
    return 'Oczekujące • $name';
  }

  @override
  String dashboardActivityStatus(Object status, Object name) {
    return '$status • $name';
  }

  @override
  String get dashboardActivityRedemption => 'Otworzono mystery box';

  @override
  String get rewardsTitle => 'Nagrody';

  @override
  String get rewardsPointsBalance => 'Saldo punktów';

  @override
  String get rewardsMysteryBoxes => 'Mystery boxy';

  @override
  String get rewardsNoBoxes => 'Brak dostępnych boxów.';

  @override
  String get rewardsViewOdds => 'Zobacz szanse';

  @override
  String get rewardsOpenBox => 'Otwórz box';

  @override
  String get rewardsYouGot => 'Wylosowano';

  @override
  String get rewardsNice => 'Super';

  @override
  String get rewardsManageRewards => 'Zarządzaj nagrodami';

  @override
  String rewardsWeightStatus(Object weight, Object status) {
    return 'Waga $weight • $status';
  }

  @override
  String get rewardsEnabled => 'Aktywne';

  @override
  String get rewardsDisabled => 'Wyłączone';

  @override
  String get rewardsAddReward => 'Dodaj nagrodę';

  @override
  String get rewardsManageBoxRules => 'Zarządzaj zasadami boxów';

  @override
  String rewardsCostRewardsCount(Object cost, Object count) {
    return 'Koszt $cost • $count nagród';
  }

  @override
  String get rewardsAddBoxRule => 'Dodaj zasadę boxa';

  @override
  String get rewardsMyRewards => 'Moje nagrody';

  @override
  String get rewardsAdminRewards => 'Nagrody admina';

  @override
  String get rewardsMemberRewards => 'Nagrody użytkowników';

  @override
  String get rewardsNoRedemptions => 'Brak nagród.';

  @override
  String get rewardsNoAdminRewards => 'Brak nagród admina.';

  @override
  String get rewardsNoMemberRewards => 'Brak nagród użytkowników.';

  @override
  String get rewardsViewAll => 'Zobacz wszystko';

  @override
  String rewardsCostPoints(Object cost) {
    return 'Koszt: $cost punktów';
  }

  @override
  String rewardsRewardsCount(Object count) {
    return 'Nagrody: $count';
  }

  @override
  String get rewardsAddRewardTitle => 'Dodaj nagrodę';

  @override
  String get rewardsEditRewardTitle => 'Edytuj nagrodę';

  @override
  String get rewardsAddBoxRuleTitle => 'Dodaj zasadę boxa';

  @override
  String get rewardsEditBoxRuleTitle => 'Edytuj zasadę boxa';

  @override
  String get rewardsTitleLabel => 'Tytuł';

  @override
  String get rewardsDescriptionLabel => 'Opis';

  @override
  String get rewardsWeightLabel => 'Waga';

  @override
  String get rewardsEnabledLabel => 'Aktywne';

  @override
  String get rewardsCostPointsLabel => 'Koszt punktów';

  @override
  String get rewardsCooldownSecondsLabel => 'Cooldown (sekundy)';

  @override
  String get rewardsMaxPerDayLabel => 'Maks. na dzień';

  @override
  String get rewardsOddsTitle => 'Szanse';

  @override
  String get rewardsDeleteRewardTitle => 'Usunąć nagrodę?';

  @override
  String get rewardsDeleteRewardBody => 'Ta nagroda zostanie usunięta z puli.';

  @override
  String get rewardsDeleteBoxRuleTitle => 'Usunąć zasadę boxa?';

  @override
  String get rewardsDeleteBoxRuleBody => 'Ten box nie będzie już dostępny.';

  @override
  String get rewardsNotEnoughPoints => 'Za mało punktów na wykupienie.';

  @override
  String get rewardsCooldownActive => 'Box jest w cooldownie. Spróbuj później.';

  @override
  String get rewardsDailyLimitReached =>
      'Osiągnięto dzienny limit dla tego boxa.';

  @override
  String rewardsCooldownRemaining(Object remaining) {
    return 'Czas odnowienia: $remaining';
  }

  @override
  String rewardsDailyLimitStatus(Object count, Object max) {
    return 'Limit dzienny: $count/$max';
  }

  @override
  String get rewardsCooldownDisabledDebug => 'Debug: cooldown wyłączony';

  @override
  String get rewardsDailyLimitDisabledDebug => 'Debug: limit dzienny wyłączony';

  @override
  String get notificationsTitle => 'Powiadomienia';

  @override
  String get notificationsEmpty => 'Brak powiadomień.';

  @override
  String get areaCategoryHome => 'Dom';

  @override
  String get areaCategoryCar => 'Auto';

  @override
  String get areaCategoryOther => 'Inne';

  @override
  String get itemStatusFresh => 'Świeże';

  @override
  String get itemStatusSoon => 'Wkrótce';

  @override
  String get itemStatusDue => 'Na czas';

  @override
  String get itemStatusOverdue => 'Po terminie';

  @override
  String get itemStatusSnoozed => 'Uśpione';

  @override
  String get itemStatusPaused => 'Wstrzymane';

  @override
  String get dailyDigestTitle => 'Dzienne podsumowanie CleanQuest';

  @override
  String dailyDigestBody(Object due, Object overdue, Object pendingSegment) {
    return 'Na dziś: $due • Po terminie: $overdue$pendingSegment';
  }

  @override
  String dailyDigestPendingSegment(Object pending) {
    return ' • Oczekujące: $pending';
  }

  @override
  String get notificationNewApprovalTitle => 'Nowe zgłoszenie';

  @override
  String get notificationNewApprovalBody => 'Użytkownik wysłał zgłoszenie.';

  @override
  String get notificationRequestApprovedTitle => 'Zgłoszenie zatwierdzone';

  @override
  String get notificationRequestApprovedBody =>
      'Zgłoszenie zostało zatwierdzone.';

  @override
  String get notificationRequestRejectedTitle => 'Zgłoszenie odrzucone';

  @override
  String get notificationRequestRejectedBody => 'Zgłoszenie zostało odrzucone.';

  @override
  String get notificationRewardTitle => 'Nagroda odebrana';

  @override
  String notificationRewardBody(Object user, Object reward) {
    return '$user wygrał(a) $reward';
  }

  @override
  String get errorAdminsCannotSubmit => 'Admini nie mogą zgłaszać wykonania.';

  @override
  String get errorOnlyAdminsApprove =>
      'Tylko admin może zatwierdzać zgłoszenia.';

  @override
  String get errorOnlyAdminsReject => 'Tylko admin może odrzucać zgłoszenia.';
}
