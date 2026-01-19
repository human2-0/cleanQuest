import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../domain/box_rule.dart';
import 'box_rule_dto.dart';

class BoxRulesRepository {
  BoxRulesRepository(this._box);

  final Box<BoxRuleDto> _box;

  static BoxRulesRepository open() {
    return BoxRulesRepository(Hive.box<BoxRuleDto>(boxRulesBoxName));
  }

  Stream<List<BoxRule>> watchRules(String householdId) async* {
    yield _rulesForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _rulesForHousehold(householdId);
    }
  }

  Future<void> upsertRule(BoxRule rule) {
    return _box.put(rule.id, BoxRuleDto.fromDomain(rule));
  }

  Future<void> deleteRule(String id) {
    return _box.delete(id);
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
      await _box.put(rule.id, BoxRuleDto.fromDomain(updated));
    }
  }

  List<BoxRule> _rulesForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
