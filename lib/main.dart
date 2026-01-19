import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/hive/hive_boxes.dart';
import 'core/app_config/app_config_repository.dart';
import 'features/items/data/item_dto.dart';
import 'features/items/data/items_seeder.dart';
import 'features/items/data/completion_event_dto.dart';
import 'features/approvals/data/completion_request_dto.dart';
import 'features/points/data/ledger_entry_dto.dart';
import 'features/rewards/data/reward_dto.dart';
import 'features/rewards/data/box_rule_dto.dart';
import 'features/rewards/data/redemption_dto.dart';
import 'features/rewards/data/rewards_seeder.dart';
import 'features/notifications/data/notification_log_dto.dart';
import 'features/notifications/data/notification_log_repository.dart';
import 'features/household/data/household_dto.dart';
import 'features/household/data/user_profile_dto.dart';
import 'core/localization/localization_providers.dart';
import 'l10n/app_localizations.dart';
import 'core/app_config/app_config_providers.dart';
import 'core/notifications/notification_service.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ItemDtoAdapter());
  Hive.registerAdapter(CompletionEventDtoAdapter());
  Hive.registerAdapter(CompletionRequestDtoAdapter());
  Hive.registerAdapter(LedgerEntryDtoAdapter());
  Hive.registerAdapter(RewardDtoAdapter());
  Hive.registerAdapter(BoxRuleDtoAdapter());
  Hive.registerAdapter(RedemptionDtoAdapter());
  Hive.registerAdapter(NotificationLogDtoAdapter());
  Hive.registerAdapter(HouseholdDtoAdapter());
  Hive.registerAdapter(UserProfileDtoAdapter());
  await Hive.openBox<dynamic>(appConfigBoxName);
  final itemsBox = await Hive.openBox<ItemDto>(itemsBoxName);
  final eventsBox =
      await Hive.openBox<CompletionEventDto>(completionEventsBoxName);
  await Hive.openBox<CompletionRequestDto>(completionRequestsBoxName);
  await Hive.openBox<LedgerEntryDto>(ledgerBoxName);
  final rewardsBox = await Hive.openBox<RewardDto>(rewardsBoxName);
  final boxRulesBox = await Hive.openBox<BoxRuleDto>(boxRulesBoxName);
  await Hive.openBox<RedemptionDto>(redemptionsBoxName);
  await Hive.openBox<HouseholdDto>(householdsBoxName);
  await Hive.openBox<UserProfileDto>(userProfilesBoxName);
  final notificationsBox =
      await Hive.openBox<NotificationLogDto>(notificationsBoxName);
  await NotificationService.instance.init();
  NotificationService.instance
      .attachLogRepository(NotificationLogRepository(notificationsBox));
  final config = AppConfigRepository(Hive.box<dynamic>(appConfigBoxName)).load();
  if (config.householdId != null && config.householdId!.isNotEmpty) {
    await seedItemsIfEmpty(itemsBox, config.householdId!);
    await seedCompletionEventsIfEmpty(eventsBox, config.householdId!);
    await seedRewardsIfEmpty(rewardsBox, boxRulesBox, config.householdId!);
  }
  runApp(const ProviderScope(child: CleanQuestApp()));
}

class CleanQuestApp extends ConsumerWidget {
  const CleanQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D7A59)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _RootScreen(),
    );
  }
}

class _RootScreen extends ConsumerWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    if (!config.onboardingComplete) {
      return const OnboardingScreen();
    }
    return const DashboardScreen();
  }
}
