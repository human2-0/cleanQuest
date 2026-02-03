import 'package:hive/hive.dart';

import '../domain/household.dart';

class HouseholdDto {
  HouseholdDto({
    required this.id,
    required this.name,
    required this.adminIds,
    required this.memberIds,
    required this.primaryAdminId,
    required this.secondaryAdminId,
    required this.adminEpoch,
  });

  final String id;
  final String name;
  final List<String> adminIds;
  final List<String> memberIds;
  final String primaryAdminId;
  final String? secondaryAdminId;
  final int adminEpoch;

  Household toDomain() {
    final resolvedPrimary =
        primaryAdminId.isNotEmpty ? primaryAdminId : _fallbackPrimary();
    final resolvedSecondary =
        secondaryAdminId ?? _fallbackSecondary(resolvedPrimary);
    return Household(
      id: id,
      name: name,
      adminIds: List<String>.from(adminIds),
      memberIds: List<String>.from(memberIds),
      primaryAdminId: resolvedPrimary,
      secondaryAdminId: resolvedSecondary,
      adminEpoch: adminEpoch,
    );
  }

  static HouseholdDto fromDomain(Household household) {
    return HouseholdDto(
      id: household.id,
      name: household.name,
      adminIds: List<String>.from(household.adminIds),
      memberIds: List<String>.from(household.memberIds),
      primaryAdminId: household.primaryAdminId,
      secondaryAdminId: household.secondaryAdminId,
      adminEpoch: household.adminEpoch,
    );
  }

  String _fallbackPrimary() {
    if (adminIds.isNotEmpty) {
      return adminIds.first;
    }
    return '';
  }

  String? _fallbackSecondary(String resolvedPrimary) {
    if (adminIds.length < 2) {
      return null;
    }
    for (final adminId in adminIds) {
      if (adminId != resolvedPrimary) {
        return adminId;
      }
    }
    return null;
  }
}

class HouseholdDtoAdapter extends TypeAdapter<HouseholdDto> {
  @override
  final int typeId = 9;

  @override
  HouseholdDto read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (int i = 0; i < reader.readByte(); i++) reader.readByte(): reader.read(),
    };
    return HouseholdDto(
      id: _readString(fields[0], fallback: ''),
      name: _readString(fields[1], fallback: 'Household'),
      adminIds: _readStringList(fields[2]),
      memberIds: _readStringList(fields[3]),
      primaryAdminId: _readString(fields[4], fallback: ''),
      secondaryAdminId: _readNullableString(fields[5]),
      adminEpoch: _readInt(fields[6], fallback: 0),
    );
  }

  @override
  void write(BinaryWriter writer, HouseholdDto obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.adminIds)
      ..writeByte(3)
      ..write(obj.memberIds)
      ..writeByte(4)
      ..write(obj.primaryAdminId)
      ..writeByte(5)
      ..write(obj.secondaryAdminId)
      ..writeByte(6)
      ..write(obj.adminEpoch);
  }

  String _readString(dynamic value, {required String fallback}) {
    if (value is String) {
      return value;
    }
    return fallback;
  }

  List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.cast<String>();
    }
    return <String>[];
  }

  String? _readNullableString(dynamic value) {
    if (value is String) {
      return value;
    }
    return null;
  }

  int _readInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    return fallback;
  }
}
