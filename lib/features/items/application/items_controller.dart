import '../data/completion_events_repository.dart';
import '../data/items_repository.dart';
import '../../points/data/ledger_repository.dart';
import '../../points/domain/ledger_entry.dart';
import '../../points/domain/ledger_reason.dart';
import '../domain/completion_event.dart';
import '../domain/item.dart';

class ItemsController {
  ItemsController(
    this._repository,
    this._eventsRepository,
    this._ledgerRepository,
  );

  final ItemsRepository _repository;
  final CompletionEventsRepository _eventsRepository;
  final LedgerRepository _ledgerRepository;

  Future<void> addItem(Item item) => _repository.upsertItem(item);

  Future<void> updateItem(Item item) => _repository.upsertItem(item);

  Future<void> deleteItem(String id) => _repository.deleteItem(id);

  Future<void> recordCompletion({
    required String householdId,
    required String itemId,
    DateTime? approvedAt,
  }) {
    final event = CompletionEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      householdId: householdId,
      itemId: itemId,
      approvedAt: approvedAt ?? DateTime.now(),
    );
    return _eventsRepository.addEvent(event);
  }

  Future<void> markCleanedNow({
    required Item item,
    required String userId,
  }) async {
    await recordCompletion(
      householdId: item.householdId,
      itemId: item.id,
      approvedAt: DateTime.now(),
    );
    await _ledgerRepository.addEntry(
      LedgerEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        householdId: item.householdId,
        userId: userId,
        delta: item.points,
        createdAt: DateTime.now(),
        reason: LedgerReason.choreApproved,
      ),
    );
    if (item.isPaused || item.snoozedUntil != null) {
      await _repository.upsertItem(
        item.copyWith(isPaused: false, snoozedUntil: null),
      );
    }
  }

  Future<void> setPaused(Item item, bool paused) {
    return _repository.upsertItem(
      item.copyWith(isPaused: paused, snoozedUntil: paused ? null : item.snoozedUntil),
    );
  }

  Future<void> snoozeItem(Item item, DateTime until) {
    return _repository.upsertItem(
      item.copyWith(isPaused: false, snoozedUntil: until),
    );
  }

  Future<void> clearSnooze(Item item) {
    return _repository.upsertItem(item.copyWith(snoozedUntil: null));
  }
}
