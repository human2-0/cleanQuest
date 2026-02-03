import 'package:hive/hive.dart';

import '../providers/user_providers.dart';
import 'local_profile.dart';

class LocalProfileDto {
  LocalProfileDto({
    required this.id,
    required this.displayName,
    required this.roleName,
    required this.householdId,
    required this.joinCode,
  });

  final String id;
  final String displayName;
  final String roleName;
  final String householdId;
  final String joinCode;

  LocalProfile toDomain() {
    return LocalProfile(
      id: id,
      displayName: displayName,
      role: _decodeRole(roleName),
      householdId: householdId,
      joinCode: joinCode,
    );
  }

  static LocalProfileDto fromDomain(LocalProfile profile) {
    return LocalProfileDto(
      id: profile.id,
      displayName: profile.displayName,
      roleName: profile.role.name,
      householdId: profile.householdId,
      joinCode: profile.joinCode,
    );
  }

  UserRole _decodeRole(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.member,
    );
  }
}

class LocalProfileDtoAdapter extends TypeAdapter<LocalProfileDto> {
  @override
  final int typeId = 11;

  @override
  LocalProfileDto read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (int i = 0; i < reader.readByte(); i++) reader.readByte(): reader.read(),
    };
    final householdId = fields[3] as String? ?? '';
    return LocalProfileDto(
      id: fields[0] as String? ?? '',
      displayName: fields[1] as String? ?? 'Unknown',
      roleName: fields[2] as String? ?? UserRole.member.name,
      householdId: householdId,
      joinCode: fields[4] as String? ?? householdId,
    );
  }

  @override
  void write(BinaryWriter writer, LocalProfileDto obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.roleName)
      ..writeByte(3)
      ..write(obj.householdId)
      ..writeByte(4)
      ..write(obj.joinCode);
  }
}
