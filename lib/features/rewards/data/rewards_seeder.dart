import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../domain/box_rule.dart';
import '../domain/reward.dart';
import 'box_rule_dto.dart';
import 'reward_dto.dart';

Future<void> seedRewardsIfEmpty(
  Box<RewardDto> rewardsBox,
  Box<BoxRuleDto> rulesBox,
  String householdId,
) async {
  if (rewardsBox.isNotEmpty || rulesBox.isNotEmpty) {
    return;
  }

  final rewards = [
    Reward(
      id: 'reward-coffee',
      householdId: householdId,
      title: 'Coffee treat',
      description: 'Grab a fancy coffee on the house.',
      weight: 45,
      enabled: true,
    ),
    Reward(
      id: 'reward-movie',
      householdId: householdId,
      title: 'Movie night',
      description: 'Pick a movie, pick the snacks.',
      weight: 30,
      enabled: true,
    ),
    Reward(
      id: 'reward-skip',
      householdId: householdId,
      title: 'Skip a chore',
      description: 'Skip one chore this week.',
      weight: 15,
      enabled: true,
    ),
    Reward(
      id: 'reward-surprise',
      householdId: householdId,
      title: 'Mystery surprise',
      description: 'Admin decides a small surprise.',
      weight: 10,
      enabled: true,
    ),
  ];

  for (final reward in rewards) {
    await rewardsBox.put(reward.id, RewardDto.fromDomain(reward));
  }

  final rule = BoxRule(
    id: 'box-standard',
    householdId: householdId,
    title: 'Mystery Box',
    costPoints: 20,
    cooldownSeconds: 60 * 60,
    maxPerDay: 5,
    rewardIds: rewards.map((reward) => reward.id).toList(),
  );
  await rulesBox.put(rule.id, BoxRuleDto.fromDomain(rule));
}
