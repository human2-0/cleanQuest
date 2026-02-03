import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_payloads.dart';
import '../domain/redemption.dart';
import 'redemption_dto.dart';

class RedemptionsRepository {
  RedemptionsRepository(this._box, {SyncCoordinator? sync}) : _sync = sync;

  final Box<RedemptionDto> _box;
  final SyncCoordinator? _sync;

  static RedemptionsRepository open({SyncCoordinator? sync}) {
    return RedemptionsRepository(
      Hive.box<RedemptionDto>(redemptionsBoxName),
      sync: sync,
    );
  }

  Stream<List<Redemption>> watchRedemptions(String householdId, String userId) async* {
    yield _redemptionsFor(householdId, userId);
    await for (final _ in _box.watch()) {
      yield _redemptionsFor(householdId, userId);
    }
  }

  Stream<List<Redemption>> watchHouseholdRedemptions(String householdId) async* {
    yield _redemptionsForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _redemptionsForHousehold(householdId);
    }
  }

  Future<void> addRedemption(Redemption redemption) async {
    await upsertRedemption(redemption);
  }

  Future<void> upsertRedemption(Redemption redemption) async {
    final dto = RedemptionDto.fromDomain(redemption);
    await _box.put(redemption.id, dto);
    await _sync?.publishUpsert(
      SyncEntityType.redemptions,
      SyncPayloadCodec.redemptionToMap(dto),
      entityId: redemption.id,
    );
  }

  List<Redemption> _redemptionsFor(String householdId, String userId) {
    return _box.values
        .where((dto) => dto.householdId == householdId && dto.userId == userId)
        .map((dto) => dto.toDomain())
        .toList();
  }

  List<Redemption> _redemptionsForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
