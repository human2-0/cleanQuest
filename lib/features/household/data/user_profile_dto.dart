import 'package:hive/hive.dart';

import '../../../core/providers/user_providers.dart';
import '../domain/user_profile.dart';

class UserProfileDto {
  UserProfileDto({
    required this.id,
    required this.householdId,
    required this.displayName,
    required this.roleName,
  });

  final String id;
  final String householdId;
  final String displayName;
  final String roleName;

  UserProfile toDomain() {
    return UserProfile(
      id: id,
      householdId: householdId,
      displayName: displayName,
      role: _decodeRole(roleName),
    );
  }

  static UserProfileDto fromDomain(UserProfile profile) {
    return UserProfileDto(
      id: profile.id,
      householdId: profile.householdId,
      displayName: profile.displayName,
      roleName: profile.role.name,
    );
  }

  UserRole _decodeRole(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.member,
    );
  }
}

class UserProfileDtoAdapter extends TypeAdapter<UserProfileDto> {
  @override
  final int typeId = 10;

  @override
  UserProfileDto read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (int i = 0; i < reader.readByte(); i++) reader.readByte(): reader.read(),
    };
    return UserProfileDto(
      id: _readString(fields[0], fallback: ''),
      householdId: _readString(fields[1], fallback: ''),
      displayName: _readString(fields[2], fallback: 'User'),
      roleName: _readString(fields[3], fallback: UserRole.member.name),
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileDto obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.householdId)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.roleName);
  }

  String _readString(dynamic value, {required String fallback}) {
    if (value is String) {
      return value;
    }
    return fallback;
  }
}
