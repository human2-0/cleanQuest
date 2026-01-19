import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../domain/ledger_entry.dart';
import 'ledger_entry_dto.dart';

class LedgerRepository {
  LedgerRepository(this._box);

  final Box<LedgerEntryDto> _box;

  static LedgerRepository open() {
    return LedgerRepository(Hive.box<LedgerEntryDto>(ledgerBoxName));
  }

  Stream<List<LedgerEntry>> watchEntries(String householdId, String userId) async* {
    yield _entriesFor(householdId, userId);
    await for (final _ in _box.watch()) {
      yield _entriesFor(householdId, userId);
    }
  }

  Future<void> addEntry(LedgerEntry entry) {
    return _box.put(entry.id, LedgerEntryDto.fromDomain(entry));
  }

  List<LedgerEntry> _entriesFor(String householdId, String userId) {
    return _box.values
        .where((dto) => dto.householdId == householdId && dto.userId == userId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
