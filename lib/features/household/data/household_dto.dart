import 'package:hive/hive.dart';

import '../domain/household.dart';

class HouseholdDto {
  HouseholdDto({
    required this.id,
    required this.name,
    required this.adminIds,
    required this.memberIds,
  });

  final String id;
  final String name;
  final List<String> adminIds;
  final List<String> memberIds;

  Household toDomain() {
    return Household(
      id: id,
      name: name,
      adminIds: List<String>.from(adminIds),
      memberIds: List<String>.from(memberIds),
    );
  }

  static HouseholdDto fromDomain(Household household) {
    return HouseholdDto(
      id: household.id,
      name: household.name,
      adminIds: List<String>.from(household.adminIds),
      memberIds: List<String>.from(household.memberIds),
    );
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
    );
  }

  @override
  void write(BinaryWriter writer, HouseholdDto obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.adminIds)
      ..writeByte(3)
      ..write(obj.memberIds);
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
}
