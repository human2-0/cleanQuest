import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/completion_event.dart';
import '../domain/item.dart';
import '../domain/item_status.dart';
import '../domain/item_status_rules.dart';
import '../domain/item_type.dart';
import '../data/items_repository.dart';
import '../data/completion_events_repository.dart';
import '../../points/application/points_providers.dart';
import 'item_board_entry.dart';
import 'items_controller.dart';
import '../../../core/app_config/app_config_providers.dart';
import '../../../core/sync/sync_providers.dart';

const demoHouseholdId = 'household-demo';

final activeHouseholdIdProvider = Provider<String>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.householdId ?? demoHouseholdId;
});

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  return ItemsRepository.open(sync: ref.read(syncCoordinatorProvider));
});

final completionEventsRepositoryProvider =
    Provider<CompletionEventsRepository>((ref) {
  return CompletionEventsRepository.open(sync: ref.read(syncCoordinatorProvider));
});

final itemsControllerProvider = Provider<ItemsController>((ref) {
  return ItemsController(
    ref.read(itemsRepositoryProvider),
    ref.read(completionEventsRepositoryProvider),
    ref.read(ledgerRepositoryProvider),
  );
});

final itemsListProvider = StreamProvider<List<Item>>((ref) {
  final householdId = ref.watch(activeHouseholdIdProvider);
  return ref.read(itemsRepositoryProvider).watchItems(householdId);
});

final completionEventsProvider = StreamProvider<List<CompletionEvent>>((ref) {
  final householdId = ref.watch(activeHouseholdIdProvider);
  return ref
      .read(completionEventsRepositoryProvider)
      .watchEvents(householdId);
});

final itemsBoardProvider = Provider<List<ItemBoardEntry>>((ref) {
  final items = ref.watch(itemsListProvider).value ?? <Item>[];
  final events = ref.watch(completionEventsProvider).value ?? <CompletionEvent>[];
  final lastApprovedByItem = _latestApprovalByItem(events);
  final now = DateTime.now();

  final entries = items.map((item) {
    final lastApprovedAt = lastApprovedByItem[item.id];
    final status = ItemStatusRules.resolve(
      item: item,
      now: now,
      lastApprovedAt: lastApprovedAt,
    );
    final nextDueAt =
        item.type == ItemType.recurring && lastApprovedAt != null
            ? lastApprovedAt.add(Duration(seconds: item.intervalSeconds))
            : null;

    return ItemBoardEntry(
      item: item,
      status: status,
      lastApprovedAt: lastApprovedAt,
      nextDueAt: nextDueAt,
    );
  }).toList();

  entries.sort((a, b) {
    final rank = _statusRank(a.status).compareTo(_statusRank(b.status));
    if (rank != 0) {
      return rank;
    }
    final aDue = a.nextDueAt ?? now;
    final bDue = b.nextDueAt ?? now;
    return aDue.compareTo(bDue);
  });

  return entries;
});

Map<String, DateTime> _latestApprovalByItem(List<CompletionEvent> events) {
  final map = <String, DateTime>{};
  for (final event in events) {
    final existing = map[event.itemId];
    if (existing == null || event.approvedAt.isAfter(existing)) {
      map[event.itemId] = event.approvedAt;
    }
  }
  return map;
}

int _statusRank(ItemStatus status) {
  switch (status) {
    case ItemStatus.overdue:
      return 0;
    case ItemStatus.due:
      return 1;
    case ItemStatus.soon:
      return 2;
    case ItemStatus.fresh:
      return 3;
    case ItemStatus.snoozed:
      return 4;
    case ItemStatus.paused:
      return 5;
  }
}
