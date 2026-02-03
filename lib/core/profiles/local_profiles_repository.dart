import 'dart:async';

import 'package:hive/hive.dart';

import '../../data/hive/hive_boxes.dart';
import 'local_profile.dart';
import 'local_profile_dto.dart';

class LocalProfilesRepository {
  LocalProfilesRepository(this._box);

  final Box<LocalProfileDto> _box;

  static LocalProfilesRepository open() {
    return LocalProfilesRepository(
      Hive.box<LocalProfileDto>(localProfilesBoxName),
    );
  }

  Stream<List<LocalProfile>> watchProfiles() async* {
    yield _profiles();
    await for (final _ in _box.watch()) {
      yield _profiles();
    }
  }

  List<LocalProfile> listProfiles() {
    return _profiles();
  }

  LocalProfile? getProfile(String id) {
    return _box.get(id)?.toDomain();
  }

  Future<void> upsertProfile(LocalProfile profile) {
    return _box.put(profile.id, LocalProfileDto.fromDomain(profile));
  }

  Future<void> deleteProfile(String id) {
    return _box.delete(id);
  }

  Future<void> clear() {
    return _box.clear();
  }

  List<LocalProfile> _profiles() {
    return _box.values.map((dto) => dto.toDomain()).toList();
  }
}
