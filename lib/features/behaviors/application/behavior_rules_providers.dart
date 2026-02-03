import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_config/app_config_providers.dart';
import '../../../core/sync/sync_providers.dart';
import '../data/behavior_rules_repository.dart';
import '../domain/behavior_rule.dart';

class BehaviorRulesController {
  BehaviorRulesController(this._repository);

  final BehaviorRulesRepository _repository;

  Future<void> addRule({
    required String householdId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final rule = BehaviorRule(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      householdId: householdId,
      name: trimmed,
      likes: 0,
      dislikes: 0,
    );
    await _repository.upsertRule(rule);
  }

  Future<void> addFeedback(BehaviorRule rule, int delta) async {
    final likes = rule.likes + (delta > 0 ? 1 : 0);
    final dislikes = rule.dislikes + (delta < 0 ? 1 : 0);
    await _repository.upsertRule(
      rule.copyWith(likes: likes, dislikes: dislikes),
    );
  }

  Future<void> renameRule(BehaviorRule rule, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == rule.name) {
      return;
    }
    await _repository.upsertRule(rule.copyWith(name: trimmed));
  }

  Future<void> deleteRule(BehaviorRule rule) async {
    await _repository.deleteRule(rule.id);
  }
}

final behaviorRulesRepositoryProvider = Provider<BehaviorRulesRepository>((ref) {
  return BehaviorRulesRepository.open(sync: ref.read(syncCoordinatorProvider));
});

final behaviorRulesControllerProvider = Provider<BehaviorRulesController>((ref) {
  return BehaviorRulesController(ref.read(behaviorRulesRepositoryProvider));
});

final behaviorRulesProvider = StreamProvider<List<BehaviorRule>>((ref) {
  final householdId = ref.watch(appConfigProvider).householdId;
  if (householdId == null || householdId.isEmpty) {
    return Stream<List<BehaviorRule>>.value(<BehaviorRule>[]);
  }
  return ref.read(behaviorRulesRepositoryProvider).watchRules(householdId);
});
