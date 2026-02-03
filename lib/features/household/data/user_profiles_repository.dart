import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_payloads.dart';
import '../domain/user_profile.dart';
import 'user_profile_dto.dart';

class UserProfilesRepository {
  UserProfilesRepository(this._box, {SyncCoordinator? sync}) : _sync = sync;

  final Box<UserProfileDto> _box;
  final SyncCoordinator? _sync;

  static UserProfilesRepository open({SyncCoordinator? sync}) {
    return UserProfilesRepository(
      Hive.box<UserProfileDto>(userProfilesBoxName),
      sync: sync,
    );
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

  Future<void> upsertProfile(UserProfile profile) async {
    final dto = UserProfileDto.fromDomain(profile);
    await _box.put(profile.id, dto);
    await _sync?.publishUpsert(
      SyncEntityType.userProfiles,
      SyncPayloadCodec.userProfileToMap(dto),
      entityId: profile.id,
    );
  }

  List<UserProfile> _profilesForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
