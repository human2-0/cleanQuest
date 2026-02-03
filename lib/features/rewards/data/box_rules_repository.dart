import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_payloads.dart';
import '../domain/box_rule.dart';
import 'box_rule_dto.dart';

class BoxRulesRepository {
  BoxRulesRepository(this._box, {SyncCoordinator? sync}) : _sync = sync;

  final Box<BoxRuleDto> _box;
  final SyncCoordinator? _sync;

  static BoxRulesRepository open({SyncCoordinator? sync}) {
    return BoxRulesRepository(Hive.box<BoxRuleDto>(boxRulesBoxName), sync: sync);
  }

  Stream<List<BoxRule>> watchRules(String householdId) async* {
    yield _rulesForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _rulesForHousehold(householdId);
    }
  }

  Future<void> upsertRule(BoxRule rule) async {
    final dto = BoxRuleDto.fromDomain(rule);
    await _box.put(rule.id, dto);
    await _sync?.publishUpsert(
      SyncEntityType.boxRules,
      SyncPayloadCodec.boxRuleToMap(dto),
      entityId: rule.id,
    );
  }

  Future<void> deleteRule(String id) async {
    await _box.delete(id);
    await _sync?.publishDelete(SyncEntityType.boxRules, id);
  }

  Future<void> removeRewardFromRules(String rewardId) async {
    final rules = _box.values.toList();
    for (final rule in rules) {
      if (!rule.rewardIds.contains(rewardId)) {
        continue;
      }
      final updated = rule.toDomain().copyWith(
            rewardIds:
                rule.rewardIds.where((id) => id != rewardId).toList(),
          );
      final dto = BoxRuleDto.fromDomain(updated);
      await _box.put(rule.id, dto);
      await _sync?.publishUpsert(
        SyncEntityType.boxRules,
        SyncPayloadCodec.boxRuleToMap(dto),
        entityId: rule.id,
      );
    }
  }

  List<BoxRule> _rulesForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
