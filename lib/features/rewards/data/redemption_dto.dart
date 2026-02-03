import 'package:hive/hive.dart';

import '../domain/redemption.dart';
import '../domain/redemption_status.dart';

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
    required this.statusIndex,
    this.requestedAt,
    this.reviewedAt,
    this.reviewedByUserId,
  });

  final String id;
  final String householdId;
  final String userId;
  final String boxRuleId;
  final int costPoints;
  final DateTime rolledAt;
  final String outcomeRewardId;
  final String rngVersion;
  final int statusIndex;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedByUserId;

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
      status: RedemptionStatus.values[statusIndex],
      requestedAt: requestedAt,
      reviewedAt: reviewedAt,
      reviewedByUserId: reviewedByUserId,
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
      statusIndex: redemption.status.index,
      requestedAt: redemption.requestedAt,
      reviewedAt: redemption.reviewedAt,
      reviewedByUserId: redemption.reviewedByUserId,
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
      statusIndex:
          fields[8] as int? ?? RedemptionStatus.active.index,
      requestedAt: fields[9] as DateTime?,
      reviewedAt: fields[10] as DateTime?,
      reviewedByUserId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RedemptionDto obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.rngVersion)
      ..writeByte(8)
      ..write(obj.statusIndex)
      ..writeByte(9)
      ..write(obj.requestedAt)
      ..writeByte(10)
      ..write(obj.reviewedAt)
      ..writeByte(11)
      ..write(obj.reviewedByUserId);
  }
}
