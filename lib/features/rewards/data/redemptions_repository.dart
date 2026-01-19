import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../domain/redemption.dart';
import 'redemption_dto.dart';

class RedemptionsRepository {
  RedemptionsRepository(this._box);

  final Box<RedemptionDto> _box;

  static RedemptionsRepository open() {
    return RedemptionsRepository(Hive.box<RedemptionDto>(redemptionsBoxName));
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

  Future<void> addRedemption(Redemption redemption) {
    return _box.put(redemption.id, RedemptionDto.fromDomain(redemption));
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
