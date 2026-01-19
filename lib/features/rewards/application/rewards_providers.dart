import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/user_providers.dart';
import '../../../core/app_config/app_config_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/localization/localization_providers.dart';
import '../../items/application/items_providers.dart';
import '../../points/application/points_providers.dart';
import '../data/box_rules_repository.dart';
import '../data/redemptions_repository.dart';
import '../data/rewards_repository.dart';
import '../domain/box_rule.dart';
import '../domain/redemption.dart';
import '../domain/reward.dart';
import 'redeem_controller.dart';

final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  return RewardsRepository.open();
});

final boxRulesRepositoryProvider = Provider<BoxRulesRepository>((ref) {
  return BoxRulesRepository.open();
});

final redemptionsRepositoryProvider = Provider<RedemptionsRepository>((ref) {
  return RedemptionsRepository.open();
});

final rewardsProvider = StreamProvider<List<Reward>>((ref) {
  final householdId = ref.watch(activeHouseholdIdProvider);
  return ref.read(rewardsRepositoryProvider).watchRewards(householdId);
});

final boxRulesProvider = StreamProvider<List<BoxRule>>((ref) {
  final householdId = ref.watch(activeHouseholdIdProvider);
  return ref.read(boxRulesRepositoryProvider).watchRules(householdId);
});

final redemptionsProvider = StreamProvider<List<Redemption>>((ref) {
  final householdId = ref.watch(activeHouseholdIdProvider);
  final userId = ref.watch(currentUserIdProvider);
  return ref.read(redemptionsRepositoryProvider).watchRedemptions(
        householdId,
        userId,
      ).map((redemptions) {
    final sorted = [...redemptions];
    sorted.sort((a, b) => b.rolledAt.compareTo(a.rolledAt));
    return sorted;
  });
});

final householdRedemptionsProvider = StreamProvider<List<Redemption>>((ref) {
  final householdId = ref.watch(activeHouseholdIdProvider);
  return ref
      .read(redemptionsRepositoryProvider)
      .watchHouseholdRedemptions(householdId)
      .map((redemptions) {
    final sorted = [...redemptions];
    sorted.sort((a, b) => b.rolledAt.compareTo(a.rolledAt));
    return sorted;
  });
});

final redeemControllerProvider = Provider<RedeemController>((ref) {
  final notificationsEnabled =
      ref.watch(appConfigProvider).notificationsEnabled;
  return RedeemController(
    rewardsRepository: ref.read(rewardsRepositoryProvider),
    boxRulesRepository: ref.read(boxRulesRepositoryProvider),
    redemptionsRepository: ref.read(redemptionsRepositoryProvider),
    ledgerRepository: ref.read(ledgerRepositoryProvider),
    notifications: NotificationService.instance,
    notificationsEnabled: notificationsEnabled,
    localizations: ref.watch(appLocalizationsProvider),
  );
});
