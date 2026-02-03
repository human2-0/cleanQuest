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
  bool _didRepairBlankNames = false;
  bool _didRepairFromBackup = false;

  static BehaviorRulesRepository open({SyncCoordinator? sync}) {
    return BehaviorRulesRepository(
      Hive.box<BehaviorRuleDto>(behaviorRulesBoxName),
      sync: sync,
    );
  }

  Stream<List<BehaviorRule>> watchRules(String householdId) async* {
    await _migrateMissingHouseholdIds(householdId);
    await _repairBlankNamesFromSyncEvents();
    await _repairFromBackup();
    yield _rulesForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _rulesForHousehold(householdId);
    }
  }

  Future<void> upsertRule(BehaviorRule rule) async {
    final normalized = _normalizeRule(rule);
    if (normalized.name.trim().isEmpty) {
      return;
    }
    final dto = BehaviorRuleDto.fromDomain(normalized);
    await _box.put(normalized.id, dto);
    await _storeBackup(dto);
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

  Future<void> _repairBlankNamesFromSyncEvents() async {
    if (_didRepairBlankNames) {
      return;
    }
    _didRepairBlankNames = true;
    final blank = _box.values
        .where((dto) => dto.name.trim().isEmpty)
        .toList();
    final eventsBox = Hive.box<dynamic>(syncEventsBoxName);
    if (eventsBox.isEmpty) {
      return;
    }
    final latestById = <String, Map<String, dynamic>>{};
    final latestTsById = <String, int>{};
    for (final raw in eventsBox.values) {
      if (raw is! Map) {
        continue;
      }
      final event = raw.cast<String, dynamic>();
      if (event['entityType'] != SyncEntityType.behaviorRules.wire) {
        continue;
      }
      if (event['action'] != 'upsert') {
        continue;
      }
      final entityId = event['entityId'];
      if (entityId is! String || entityId.isEmpty) {
        continue;
      }
      final payload = event['payload'];
      if (payload is! Map) {
        continue;
      }
      final nameValue = payload['name'] ?? payload['title'] ?? payload['label'];
      final name = nameValue is String ? nameValue.trim() : '';
      final tsMs = event['tsMs'] is int ? event['tsMs'] as int : 0;
      final previous = latestTsById[entityId] ?? -1;
      if (tsMs >= previous) {
        latestTsById[entityId] = tsMs;
        latestById[entityId] = payload.cast<String, dynamic>();
      }
    }
    if (latestById.isEmpty) {
      return;
    }
    for (final dto in _box.values) {
      final payload = latestById[dto.id];
      if (payload == null) {
        continue;
      }
      final repaired = SyncPayloadCodec.behaviorRuleFromMap(payload);
      final repairedName = repaired.name.trim();
      final updated = BehaviorRuleDto(
        id: dto.id,
        householdId: dto.householdId.trim().isEmpty
            ? repaired.householdId
            : dto.householdId,
        name: repairedName.isNotEmpty ? repairedName : dto.name,
        likes: repaired.likes > dto.likes ? repaired.likes : dto.likes,
        dislikes:
            repaired.dislikes > dto.dislikes ? repaired.dislikes : dto.dislikes,
      );
      if (updated.name.trim().isEmpty) {
        continue;
      }
      if (updated == dto) {
        continue;
      }
      await _box.put(dto.id, updated);
      await _sync?.publishUpsert(
        SyncEntityType.behaviorRules,
        SyncPayloadCodec.behaviorRuleToMap(updated),
        entityId: dto.id,
      );
    }
  }

  Future<void> _repairFromBackup() async {
    if (_didRepairFromBackup) {
      return;
    }
    _didRepairFromBackup = true;
    final metaBox = Hive.box<dynamic>(syncMetaBoxName);
    if (metaBox.isEmpty) {
      return;
    }
    for (final dto in _box.values) {
      final raw = metaBox.get(_backupKey(dto.id));
      if (raw is! Map) {
        continue;
      }
      final payload = raw.cast<String, dynamic>();
      final backup = SyncPayloadCodec.behaviorRuleFromMap(payload);
      final backupName = backup.name.trim();
      final updated = BehaviorRuleDto(
        id: dto.id,
        householdId: dto.householdId.trim().isEmpty
            ? backup.householdId
            : dto.householdId,
        name: dto.name.trim().isEmpty && backupName.isNotEmpty
            ? backupName
            : dto.name,
        likes: backup.likes > dto.likes ? backup.likes : dto.likes,
        dislikes: backup.dislikes > dto.dislikes
            ? backup.dislikes
            : dto.dislikes,
      );
      if (updated.name.trim().isEmpty) {
        continue;
      }
      await _box.put(dto.id, updated);
      await _sync?.publishUpsert(
        SyncEntityType.behaviorRules,
        SyncPayloadCodec.behaviorRuleToMap(updated),
        entityId: dto.id,
      );
    }
  }

  Future<void> _storeBackup(BehaviorRuleDto dto) async {
    final metaBox = Hive.box<dynamic>(syncMetaBoxName);
    final payload = SyncPayloadCodec.behaviorRuleToMap(dto);
    payload['tsMs'] = DateTime.now().millisecondsSinceEpoch;
    await metaBox.put(_backupKey(dto.id), payload);
  }

  String _backupKey(String id) => 'behaviorRuleBackup:$id';

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
