import 'package:hive/hive.dart';

import '../domain/reward.dart';

class RewardDto {
  RewardDto({
    required this.id,
    required this.householdId,
    required this.title,
    required this.weight,
    required this.enabled,
    this.description,
  });

  final String id;
  final String householdId;
  final String title;
  final String? description;
  final int weight;
  final bool enabled;

  Reward toDomain() {
    return Reward(
      id: id,
      householdId: householdId,
      title: title,
      description: description,
      weight: weight,
      enabled: enabled,
    );
  }

  static RewardDto fromDomain(Reward reward) {
    return RewardDto(
      id: reward.id,
      householdId: reward.householdId,
      title: reward.title,
      description: reward.description,
      weight: reward.weight,
      enabled: reward.enabled,
    );
  }
}

class RewardDtoAdapter extends TypeAdapter<RewardDto> {
  @override
  final int typeId = 5;

  @override
  RewardDto read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return RewardDto(
      id: fields[0] as String,
      householdId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String?,
      weight: fields[4] as int,
      enabled: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RewardDto obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.householdId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.weight)
      ..writeByte(5)
      ..write(obj.enabled);
  }
}
