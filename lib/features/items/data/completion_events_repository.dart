import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_payloads.dart';
import '../domain/completion_event.dart';
import 'completion_event_dto.dart';

class CompletionEventsRepository {
  CompletionEventsRepository(this._box, {SyncCoordinator? sync})
      : _sync = sync;

  final Box<CompletionEventDto> _box;
  final SyncCoordinator? _sync;

  static CompletionEventsRepository open({SyncCoordinator? sync}) {
    return CompletionEventsRepository(
      Hive.box<CompletionEventDto>(completionEventsBoxName),
      sync: sync,
    );
  }

  Stream<List<CompletionEvent>> watchEvents(String householdId) async* {
    yield _eventsForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _eventsForHousehold(householdId);
    }
  }

  Future<void> addEvent(CompletionEvent event) async {
    final dto = CompletionEventDto.fromDomain(event);
    await _box.put(event.id, dto);
    await _sync?.publishUpsert(
      SyncEntityType.completionEvents,
      SyncPayloadCodec.completionEventToMap(dto),
      entityId: event.id,
    );
  }

  List<CompletionEvent> _eventsForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }

  DateTime? latestApprovedAt(String householdId, String itemId) {
    DateTime? latest;
    for (final dto in _box.values) {
      if (dto.householdId != householdId || dto.itemId != itemId) {
        continue;
      }
      final approvedAt = dto.approvedAt;
      if (latest == null || approvedAt.isAfter(latest)) {
        latest = approvedAt;
      }
    }
    return latest;
  }
}
