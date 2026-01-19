import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../domain/reward.dart';
import 'reward_dto.dart';

class RewardsRepository {
  RewardsRepository(this._box);

  final Box<RewardDto> _box;

  static RewardsRepository open() {
    return RewardsRepository(Hive.box<RewardDto>(rewardsBoxName));
  }

  Stream<List<Reward>> watchRewards(String householdId) async* {
    yield _rewardsForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _rewardsForHousehold(householdId);
    }
  }

  Future<void> upsertReward(Reward reward) {
    return _box.put(reward.id, RewardDto.fromDomain(reward));
  }

  Future<void> deleteReward(String id) {
    return _box.delete(id);
  }

  List<Reward> _rewardsForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
