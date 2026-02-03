import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_payloads.dart';
import '../domain/behavior_rule.dart';
import 'behavior_rule_dto.dart';

class BehaviorRulesRepository {
  BehaviorRulesRepository(this._box, {SyncCoordinator? sync}) : _sync = sync;

  final Box<BehaviorRuleDto> _box;
  final SyncCoordinator? _sync;

  static BehaviorRulesRepository open({SyncCoordinator? sync}) {
    return BehaviorRulesRepository(
      Hive.box<BehaviorRuleDto>(behaviorRulesBoxName),
      sync: sync,
    );
  }

  Stream<List<BehaviorRule>> watchRules(String householdId) async* {
    await _migrateMissingHouseholdIds(householdId);
    yield _rulesForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _rulesForHousehold(householdId);
    }
  }

  Future<void> upsertRule(BehaviorRule rule) async {
    final normalized = _normalizeRule(rule);
    final dto = BehaviorRuleDto.fromDomain(normalized);
    await _box.put(normalized.id, dto);
    await _sync?.publishUpsert(
      SyncEntityType.behaviorRules,
      SyncPayloadCodec.behaviorRuleToMap(dto),
      entityId: normalized.id,
    );
  }

  Future<void> deleteRule(String ruleId) async {
    await _box.delete(ruleId);
    await _sync?.publishDelete(
      SyncEntityType.behaviorRules,
      ruleId,
    );
  }

  List<BehaviorRule> _rulesForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }

  Future<void> _migrateMissingHouseholdIds(String householdId) async {
    if (householdId.isEmpty) {
      return;
    }
    final missing = _box.values
        .where((dto) => dto.householdId.trim().isEmpty)
        .toList();
    if (missing.isEmpty) {
      return;
    }
    for (final dto in missing) {
      final updated = BehaviorRuleDto(
        id: dto.id,
        householdId: householdId,
        name: dto.name,
        likes: dto.likes,
        dislikes: dto.dislikes,
      );
      await _box.put(dto.id, updated);
      await _sync?.publishUpsert(
        SyncEntityType.behaviorRules,
        SyncPayloadCodec.behaviorRuleToMap(updated),
        entityId: dto.id,
      );
    }
  }

  BehaviorRule _normalizeRule(BehaviorRule rule) {
    final existing = _box.get(rule.id);
    final trimmedName = rule.name.trim();
    final householdId = rule.householdId.trim();
    final likes = rule.likes < 0 ? null : rule.likes;
    final dislikes = rule.dislikes < 0 ? null : rule.dislikes;
    return rule.copyWith(
      householdId: householdId.isNotEmpty
          ? householdId
          : (existing?.householdId ?? ''),
      name: trimmedName.isNotEmpty ? trimmedName : (existing?.name ?? ''),
      likes: likes ?? existing?.likes ?? 0,
      dislikes: dislikes ?? existing?.dislikes ?? 0,
    );
  }
}
