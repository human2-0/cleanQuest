import 'package:flutter/foundation.dart';

import '../../points/domain/ledger_entry.dart';
import '../../points/domain/ledger_reason.dart';
import '../../points/data/ledger_repository.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../l10n/app_localizations.dart';
import '../data/box_rules_repository.dart';
import '../data/redemptions_repository.dart';
import '../data/rewards_repository.dart';
import '../domain/box_rule.dart';
import '../domain/redemption.dart';
import '../domain/reward.dart';
import '../domain/weighted_picker.dart';

class RedeemController {
  RedeemController({
    required RewardsRepository rewardsRepository,
    required BoxRulesRepository boxRulesRepository,
    required RedemptionsRepository redemptionsRepository,
    required LedgerRepository ledgerRepository,
    required NotificationService notifications,
    required bool notificationsEnabled,
    required AppLocalizations localizations,
    WeightedPicker? picker,
  })  : _rewardsRepository = rewardsRepository,
        _boxRulesRepository = boxRulesRepository,
        _redemptionsRepository = redemptionsRepository,
        _ledgerRepository = ledgerRepository,
        _notifications = notifications,
        _notificationsEnabled = notificationsEnabled,
        _localizations = localizations,
        _picker = picker ?? WeightedPicker();

  final RewardsRepository _rewardsRepository;
  final BoxRulesRepository _boxRulesRepository;
  final RedemptionsRepository _redemptionsRepository;
  final LedgerRepository _ledgerRepository;
  final NotificationService _notifications;
  final bool _notificationsEnabled;
  final AppLocalizations _localizations;
  final WeightedPicker _picker;

  Future<Redemption> redeem({
    required String householdId,
    required String userId,
    required BoxRule boxRule,
    required int pointsBalance,
    required List<Redemption> existingRedemptions,
    String? userLabel,
  }) async {
    if (pointsBalance < boxRule.costPoints) {
      throw StateError(_localizations.rewardsNotEnoughPoints);
    }
    _assertCooldown(boxRule, existingRedemptions);
    _assertDailyLimit(boxRule, existingRedemptions);

    final rewards = await _loadRewards(householdId, boxRule);
    final reward = _picker.pick(rewards);
    final now = DateTime.now();
    final redemption = Redemption(
      id: _newId(),
      householdId: householdId,
      userId: userId,
      boxRuleId: boxRule.id,
      costPoints: boxRule.costPoints,
      rolledAt: now,
      outcomeRewardId: reward.id,
      rngVersion: 'v1',
    );
    await _redemptionsRepository.addRedemption(redemption);
    await _ledgerRepository.addEntry(
      LedgerEntry(
        id: _newId(),
        householdId: householdId,
        userId: userId,
        delta: -boxRule.costPoints,
        createdAt: now,
        reason: LedgerReason.redemptionCost,
        relatedRedemptionId: redemption.id,
      ),
    );
    if (_notificationsEnabled) {
      final label = userLabel ?? userId;
      await _notifications.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: _localizations.notificationRewardTitle,
        body: _localizations.notificationRewardBody(label, reward.title),
      );
    }
    return redemption;
  }

  Future<List<Reward>> _loadRewards(String householdId, BoxRule rule) async {
    final rewards = await _rewardsRepository
        .watchRewards(householdId)
        .first;
    final ids = rule.rewardIds.toSet();
    return rewards.where((reward) => ids.contains(reward.id)).toList();
  }

  void _assertCooldown(BoxRule rule, List<Redemption> redemptions) {
    if (kDebugMode) {
      return;
    }
    if (rule.cooldownSeconds <= 0) {
      return;
    }
    final now = DateTime.now();
    final latest = redemptions
        .where((redemption) => redemption.boxRuleId == rule.id)
        .map((redemption) => redemption.rolledAt)
        .fold<DateTime?>(null, (latest, current) {
      if (latest == null || current.isAfter(latest)) {
        return current;
      }
      return latest;
    });
    if (latest == null) {
      return;
    }
    final nextAllowed =
        latest.add(Duration(seconds: rule.cooldownSeconds));
    if (now.isBefore(nextAllowed)) {
      throw StateError(_localizations.rewardsCooldownActive);
    }
  }

  void _assertDailyLimit(BoxRule rule, List<Redemption> redemptions) {
    if (kDebugMode) {
      return;
    }
    if (rule.maxPerDay <= 0) {
      return;
    }
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final count = redemptions.where((redemption) {
      return redemption.boxRuleId == rule.id &&
          redemption.rolledAt.isAfter(dayStart);
    }).length;
    if (count >= rule.maxPerDay) {
      throw StateError(_localizations.rewardsDailyLimitReached);
    }
  }

  String _newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
