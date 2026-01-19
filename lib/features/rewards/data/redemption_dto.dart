import 'package:hive/hive.dart';

import '../domain/redemption.dart';

class RedemptionDto {
  RedemptionDto({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.boxRuleId,
    required this.costPoints,
    required this.rolledAt,
    required this.outcomeRewardId,
    required this.rngVersion,
  });

  final String id;
  final String householdId;
  final String userId;
  final String boxRuleId;
  final int costPoints;
  final DateTime rolledAt;
  final String outcomeRewardId;
  final String rngVersion;

  Redemption toDomain() {
    return Redemption(
      id: id,
      householdId: householdId,
      userId: userId,
      boxRuleId: boxRuleId,
      costPoints: costPoints,
      rolledAt: rolledAt,
      outcomeRewardId: outcomeRewardId,
      rngVersion: rngVersion,
    );
  }

  static RedemptionDto fromDomain(Redemption redemption) {
    return RedemptionDto(
      id: redemption.id,
      householdId: redemption.householdId,
      userId: redemption.userId,
      boxRuleId: redemption.boxRuleId,
      costPoints: redemption.costPoints,
      rolledAt: redemption.rolledAt,
      outcomeRewardId: redemption.outcomeRewardId,
      rngVersion: redemption.rngVersion,
    );
  }
}

class RedemptionDtoAdapter extends TypeAdapter<RedemptionDto> {
  @override
  final int typeId = 7;

  @override
  RedemptionDto read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return RedemptionDto(
      id: fields[0] as String,
      householdId: fields[1] as String,
      userId: fields[2] as String,
      boxRuleId: fields[3] as String,
      costPoints: fields[4] as int,
      rolledAt: fields[5] as DateTime,
      outcomeRewardId: fields[6] as String,
      rngVersion: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RedemptionDto obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.householdId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.boxRuleId)
      ..writeByte(4)
      ..write(obj.costPoints)
      ..writeByte(5)
      ..write(obj.rolledAt)
      ..writeByte(6)
      ..write(obj.outcomeRewardId)
      ..writeByte(7)
      ..write(obj.rngVersion);
  }
}
