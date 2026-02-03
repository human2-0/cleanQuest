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
import 'features/rewards/data/inventory_item_dto.dart';
import 'features/rewards/data/rewards_seeder.dart';
import 'features/notifications/data/notification_log_dto.dart';
import 'features/notifications/data/notification_log_repository.dart';
import 'features/household/data/household_dto.dart';
import 'features/household/data/user_profile_dto.dart';
import 'core/profiles/local_profile_dto.dart';
import 'features/behaviors/data/behavior_rule_dto.dart';
import 'core/localization/localization_providers.dart';
import 'l10n/app_localizations.dart';
import 'core/app_config/app_config_providers.dart';
import 'core/app_config/app_config.dart';
import 'core/notifications/notification_service.dart';
import 'core/sync/sync_providers.dart';
import 'core/nearby/multipeer_advertiser_provider.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/household/application/household_providers.dart';

bool _didRestoreFromLocalProfile = false;

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
  Hive.registerAdapter(InventoryItemDtoAdapter());
  Hive.registerAdapter(NotificationLogDtoAdapter());
  Hive.registerAdapter(HouseholdDtoAdapter());
  Hive.registerAdapter(UserProfileDtoAdapter());
  Hive.registerAdapter(LocalProfileDtoAdapter());
  Hive.registerAdapter(BehaviorRuleDtoAdapter());
  await Hive.openBox<dynamic>(appConfigBoxName);
  final itemsBox = await Hive.openBox<ItemDto>(itemsBoxName);
  final eventsBox =
      await Hive.openBox<CompletionEventDto>(completionEventsBoxName);
  await Hive.openBox<CompletionRequestDto>(completionRequestsBoxName);
  await Hive.openBox<LedgerEntryDto>(ledgerBoxName);
  final rewardsBox = await Hive.openBox<RewardDto>(rewardsBoxName);
  final boxRulesBox = await Hive.openBox<BoxRuleDto>(boxRulesBoxName);
  await Hive.openBox<RedemptionDto>(redemptionsBoxName);
  await Hive.openBox<InventoryItemDto>(inventoryBoxName);
  await Hive.openBox<BehaviorRuleDto>(behaviorRulesBoxName);
  await Hive.openBox<HouseholdDto>(householdsBoxName);
  await Hive.openBox<UserProfileDto>(userProfilesBoxName);
  await Hive.openBox<LocalProfileDto>(localProfilesBoxName);
  await Hive.openBox<dynamic>(syncEventsBoxName);
  await Hive.openBox<dynamic>(syncMetaBoxName);
  await Hive.openBox<dynamic>(syncOutboxBoxName);
  final notificationsBox =
      await Hive.openBox<NotificationLogDto>(notificationsBoxName);
  await NotificationService.instance.init();
  NotificationService.instance
      .attachLogRepository(NotificationLogRepository(notificationsBox));
  final configRepo = AppConfigRepository(Hive.box<dynamic>(appConfigBoxName));
  var config = configRepo.load();
  config = await _restoreConfigFromLocalProfile(configRepo, config);
  if (config.householdId != null && config.householdId!.isNotEmpty) {
    await seedItemsIfEmpty(itemsBox, config.householdId!);
    await seedCompletionEventsIfEmpty(eventsBox, config.householdId!);
    await seedRewardsIfEmpty(rewardsBox, boxRulesBox, config.householdId!);
  }
  runApp(
    ProviderScope(
      child: CleanQuestApp(showRestoreSplash: _didRestoreFromLocalProfile),
    ),
  );
}

Future<AppConfig> _restoreConfigFromLocalProfile(
  AppConfigRepository repository,
  AppConfig config,
) async {
  final needsRestore = !config.onboardingComplete ||
      config.userId == null ||
      config.userId!.isEmpty ||
      config.householdId == null ||
      config.householdId!.isEmpty;
  if (!needsRestore) {
    return config;
  }
  final localProfilesBox =
      Hive.box<LocalProfileDto>(localProfilesBoxName);
  if (localProfilesBox.isEmpty) {
    return config;
  }
  final profiles = localProfilesBox.values
      .map((dto) => dto.toDomain())
      .where((profile) => profile.householdId.trim().isNotEmpty)
      .toList();
  if (profiles.isEmpty) {
    return config;
  }
  final preferred = config.userId == null || config.userId!.isEmpty
      ? profiles.first
      : profiles.firstWhere(
          (profile) => profile.id == config.userId,
          orElse: () => profiles.first,
        );
  final restored = config.copyWith(
    onboardingComplete: true,
    role: preferred.role,
    userId: preferred.id,
    householdId: preferred.householdId,
    joinCode: preferred.joinCode.isNotEmpty
        ? preferred.joinCode
        : preferred.householdId,
    activeDisplayName: preferred.displayName,
    activeDisplayNameUserId: preferred.id,
  );
  await repository.save(restored);
  _didRestoreFromLocalProfile = true;
  return restored;
}

class CleanQuestApp extends ConsumerWidget {
  const CleanQuestApp({
    super.key,
    required this.showRestoreSplash,
  });

  final bool showRestoreSplash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final config = ref.watch(appConfigProvider);
    final seedColor = const Color(0xFF3D7A59);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: config.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _StartupSplashGate(
        showSplash: showRestoreSplash,
        child: const _SyncLifecycleGate(child: _RootScreen()),
      ),
    );
  }
}

class _StartupSplashGate extends StatefulWidget {
  const _StartupSplashGate({
    required this.showSplash,
    required this.child,
  });

  final bool showSplash;
  final Widget child;

  @override
  State<_StartupSplashGate> createState() => _StartupSplashGateState();
}

class _StartupSplashGateState extends State<_StartupSplashGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (!widget.showSplash) {
      _ready = true;
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) {
        return;
      }
      setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return widget.child;
    }
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Restoring profile...'),
          ],
        ),
      ),
    );
  }
}

class _SyncLifecycleGate extends ConsumerStatefulWidget {
  const _SyncLifecycleGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_SyncLifecycleGate> createState() =>
      _SyncLifecycleGateState();
}

class _SyncLifecycleGateState extends ConsumerState<_SyncLifecycleGate>
    with WidgetsBindingObserver {
  ProviderSubscription<AppConfig>? _configSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _kickSync();
    });
    _configSub = ref.listenManual<AppConfig>(appConfigProvider, (prev, next) {
      if (!mounted) {
        return;
      }
      final prevReady = prev?.onboardingComplete ?? false;
      if (!prevReady && next.onboardingComplete) {
        _kickSync();
        return;
      }
      if (prev?.userId != next.userId ||
          prev?.householdId != next.householdId) {
        _kickSync();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _configSub?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _kickSync();
    }
  }

  void _kickSync() {
    if (!mounted) {
      return;
    }
    final config = ref.read(appConfigProvider);
    final coordinator = ref.read(syncCoordinatorProvider);
    coordinator.startIfReady(config);
    coordinator.requestFullSync();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _RootScreen extends ConsumerWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncCoordinatorProvider);
    ref.watch(multipeerAdvertiserProvider);
    ref.watch(localProfileSyncProvider);
    final config = ref.watch(appConfigProvider);
    if (!config.onboardingComplete) {
      return const OnboardingScreen();
    }
    return const DashboardScreen();
  }
}
