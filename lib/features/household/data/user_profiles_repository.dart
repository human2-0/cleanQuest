import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../domain/user_profile.dart';
import 'user_profile_dto.dart';

class UserProfilesRepository {
  UserProfilesRepository(this._box);

  final Box<UserProfileDto> _box;

  static UserProfilesRepository open() {
    return UserProfilesRepository(Hive.box<UserProfileDto>(userProfilesBoxName));
  }

  Stream<List<UserProfile>> watchProfiles(String householdId) async* {
    yield _profilesForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _profilesForHousehold(householdId);
    }
  }

  UserProfile? getProfile(String profileId) {
    return _box.get(profileId)?.toDomain();
  }

  List<UserProfile> listProfiles(String householdId) {
    return _profilesForHousehold(householdId);
  }

  Future<void> upsertProfile(UserProfile profile) {
    return _box.put(profile.id, UserProfileDto.fromDomain(profile));
  }

  List<UserProfile> _profilesForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
