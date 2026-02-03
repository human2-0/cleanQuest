import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_payloads.dart';
import '../domain/household.dart';
import 'household_dto.dart';

class HouseholdsRepository {
  HouseholdsRepository(this._box, {SyncCoordinator? sync}) : _sync = sync;

  final Box<HouseholdDto> _box;
  final SyncCoordinator? _sync;

  static HouseholdsRepository open({SyncCoordinator? sync}) {
    return HouseholdsRepository(
      Hive.box<HouseholdDto>(householdsBoxName),
      sync: sync,
    );
  }

  Stream<Household?> watchHousehold(String householdId) async* {
    yield _getHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _getHousehold(householdId);
    }
  }

  Household? getHousehold(String householdId) {
    return _getHousehold(householdId);
  }

  Future<void> upsertHousehold(Household household) async {
    debugPrint(
      '[household] upsert id=${household.id} name="${household.name}"',
    );
    final dto = HouseholdDto.fromDomain(household);
    await _box.put(household.id, dto);
    await _sync?.publishUpsert(
      SyncEntityType.households,
      SyncPayloadCodec.householdToMap(dto),
      entityId: household.id,
    );
  }

  Household? _getHousehold(String householdId) {
    final dto = _box.get(householdId);
    return dto?.toDomain();
  }
}
