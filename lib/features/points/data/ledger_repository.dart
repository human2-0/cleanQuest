import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_payloads.dart';
import '../domain/ledger_entry.dart';
import 'ledger_entry_dto.dart';

class LedgerRepository {
  LedgerRepository(this._box, {SyncCoordinator? sync}) : _sync = sync;

  final Box<LedgerEntryDto> _box;
  final SyncCoordinator? _sync;

  static LedgerRepository open({SyncCoordinator? sync}) {
    return LedgerRepository(
      Hive.box<LedgerEntryDto>(ledgerBoxName),
      sync: sync,
    );
  }

  Stream<List<LedgerEntry>> watchEntries(String householdId, String userId) async* {
    yield _entriesFor(householdId, userId);
    await for (final _ in _box.watch()) {
      yield _entriesFor(householdId, userId);
    }
  }

  Future<void> addEntry(LedgerEntry entry) async {
    final dto = LedgerEntryDto.fromDomain(entry);
    await _box.put(entry.id, dto);
    await _sync?.publishUpsert(
      SyncEntityType.ledgerEntries,
      SyncPayloadCodec.ledgerEntryToMap(dto),
      entityId: entry.id,
    );
  }

  List<LedgerEntry> _entriesFor(String householdId, String userId) {
    return _box.values
        .where((dto) => dto.householdId == householdId && dto.userId == userId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
