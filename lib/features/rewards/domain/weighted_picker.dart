import 'dart:math';

import 'reward.dart';

class WeightedPicker {
  WeightedPicker({Random? random}) : _random = random ?? Random();

  final Random _random;

  Reward? pick(List<Reward> rewards) {
    final enabled =
        rewards.where((reward) => reward.enabled && reward.weight > 0).toList();
    if (enabled.isEmpty) {
      return null;
    }
    final totalWeight =
        enabled.fold<int>(0, (sum, reward) => sum + reward.weight);
    if (totalWeight <= 0) {
      return null;
    }
    final roll = _random.nextInt(100) + 1;
    var cumulative = 0;
    for (final reward in enabled) {
      cumulative += reward.weight;
      if (roll <= cumulative) {
        return reward;
      }
    }
    return null;
  }
}
