import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../domain/household.dart';
import 'household_dto.dart';

class HouseholdsRepository {
  HouseholdsRepository(this._box);

  final Box<HouseholdDto> _box;

  static HouseholdsRepository open() {
    return HouseholdsRepository(Hive.box<HouseholdDto>(householdsBoxName));
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

  Future<void> upsertHousehold(Household household) {
    return _box.put(household.id, HouseholdDto.fromDomain(household));
  }

  Household? _getHousehold(String householdId) {
    final dto = _box.get(householdId);
    return dto?.toDomain();
  }
}
