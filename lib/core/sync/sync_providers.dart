import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../app_config/app_config_providers.dart';
import '../app_config/app_config.dart';
import '../../data/hive/hive_boxes.dart';
import '../../features/items/data/item_dto.dart';
import '../../features/items/data/completion_event_dto.dart';
import '../../features/approvals/data/completion_request_dto.dart';
import '../../features/points/data/ledger_entry_dto.dart';
import '../../features/rewards/data/reward_dto.dart';
import '../../features/rewards/data/box_rule_dto.dart';
import '../../features/rewards/data/redemption_dto.dart';
import '../../features/rewards/data/inventory_item_dto.dart';
import '../../features/behaviors/data/behavior_rule_dto.dart';
import '../../features/household/data/household_dto.dart';
import '../../features/household/data/user_profile_dto.dart';
import 'p2p_sync_engine.dart';
import 'sync_coordinator.dart';

class _SyncConfigKey {
  const _SyncConfigKey({
    required this.onboardingComplete,
    required this.householdId,
    required this.userId,
    required this.displayName,
    required this.householdName,
  });

  final bool onboardingComplete;
  final String? householdId;
  final String? userId;
  final String? displayName;
  final String? householdName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _SyncConfigKey &&
        other.onboardingComplete == onboardingComplete &&
        other.householdId == householdId &&
        other.userId == userId &&
        other.displayName == displayName &&
        other.householdName == householdName;
  }

  @override
  int get hashCode =>
      Object.hash(
        onboardingComplete,
        householdId,
        userId,
        displayName,
        householdName,
      );
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  ref.watch(
    appConfigProvider.select(
      (config) => _SyncConfigKey(
        onboardingComplete: config.onboardingComplete,
        householdId: config.householdId,
        userId: config.userId,
        displayName: config.activeDisplayName,
        householdName: config.householdName,
      ),
    ),
  );
  final config = ref.read(appConfigProvider);
  final engine = P2pSyncEngine(
    householdId: config.householdId ?? '',
    userId: config.userId ?? '',
    householdName: config.householdName ?? '',
    displayName: config.activeDisplayName ?? '',
  );
  final coordinator = SyncCoordinator(
    engine: engine,
    itemsBox: Hive.box<ItemDto>(itemsBoxName),
    completionEventsBox: Hive.box<CompletionEventDto>(completionEventsBoxName),
    completionRequestsBox:
        Hive.box<CompletionRequestDto>(completionRequestsBoxName),
    ledgerBox: Hive.box<LedgerEntryDto>(ledgerBoxName),
    rewardsBox: Hive.box<RewardDto>(rewardsBoxName),
    boxRulesBox: Hive.box<BoxRuleDto>(boxRulesBoxName),
    redemptionsBox: Hive.box<RedemptionDto>(redemptionsBoxName),
    inventoryBox: Hive.box<InventoryItemDto>(inventoryBoxName),
    behaviorRulesBox: Hive.box<BehaviorRuleDto>(behaviorRulesBoxName),
    householdsBox: Hive.box<HouseholdDto>(householdsBoxName),
    userProfilesBox: Hive.box<UserProfileDto>(userProfilesBoxName),
    syncEventsBox: Hive.box<dynamic>(syncEventsBoxName),
    syncMetaBox: Hive.box<dynamic>(syncMetaBoxName),
    syncOutboxBox: Hive.box<dynamic>(syncOutboxBoxName),
  );
  coordinator.startIfReady(config);
  ref.listen<AppConfig>(appConfigProvider, (_, next) {
    coordinator.startIfReady(next);
  });
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

final syncPresenceProvider = StreamProvider<List<SyncPresenceEntry>>((ref) {
  return ref.read(syncCoordinatorProvider).presence;
});

final syncOutboxKeysProvider = StreamProvider<Set<String>>((ref) async* {
  final box = Hive.box<dynamic>(syncOutboxBoxName);
  yield box.keys.whereType<String>().toSet();
  await for (final _ in box.watch()) {
    yield box.keys.whereType<String>().toSet();
  }
});
