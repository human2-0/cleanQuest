import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_payloads.dart';
import '../domain/reward.dart';
import 'reward_dto.dart';

class RewardsRepository {
  RewardsRepository(this._box, {SyncCoordinator? sync}) : _sync = sync;

  final Box<RewardDto> _box;
  final SyncCoordinator? _sync;

  static RewardsRepository open({SyncCoordinator? sync}) {
    return RewardsRepository(Hive.box<RewardDto>(rewardsBoxName), sync: sync);
  }

  Stream<List<Reward>> watchRewards(String householdId) async* {
    yield _rewardsForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _rewardsForHousehold(householdId);
    }
  }

  Future<void> upsertReward(Reward reward) async {
    final dto = RewardDto.fromDomain(reward);
    await _box.put(reward.id, dto);
    await _sync?.publishUpsert(
      SyncEntityType.rewards,
      SyncPayloadCodec.rewardToMap(dto),
      entityId: reward.id,
    );
  }

  Future<void> deleteReward(String id) async {
    await _box.delete(id);
    await _sync?.publishDelete(SyncEntityType.rewards, id);
  }

  List<Reward> _rewardsForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
