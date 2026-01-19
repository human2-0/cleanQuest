import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../domain/completion_event.dart';
import 'completion_event_dto.dart';

class CompletionEventsRepository {
  CompletionEventsRepository(this._box);

  final Box<CompletionEventDto> _box;

  static CompletionEventsRepository open() {
    return CompletionEventsRepository(
      Hive.box<CompletionEventDto>(completionEventsBoxName),
    );
  }

  Stream<List<CompletionEvent>> watchEvents(String householdId) async* {
    yield _eventsForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _eventsForHousehold(householdId);
    }
  }

  Future<void> addEvent(CompletionEvent event) {
    return _box.put(event.id, CompletionEventDto.fromDomain(event));
  }

  List<CompletionEvent> _eventsForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
