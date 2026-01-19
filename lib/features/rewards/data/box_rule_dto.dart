import 'package:hive/hive.dart';

import '../domain/box_rule.dart';

class BoxRuleDto {
  BoxRuleDto({
    required this.id,
    required this.householdId,
    required this.title,
    required this.costPoints,
    required this.cooldownSeconds,
    required this.maxPerDay,
    required this.rewardIds,
  });

  final String id;
  final String householdId;
  final String title;
  final int costPoints;
  final int cooldownSeconds;
  final int maxPerDay;
  final List<String> rewardIds;

  BoxRule toDomain() {
    return BoxRule(
      id: id,
      householdId: householdId,
      title: title,
      costPoints: costPoints,
      cooldownSeconds: cooldownSeconds,
      maxPerDay: maxPerDay,
      rewardIds: List<String>.from(rewardIds),
    );
  }

  static BoxRuleDto fromDomain(BoxRule rule) {
    return BoxRuleDto(
      id: rule.id,
      householdId: rule.householdId,
      title: rule.title,
      costPoints: rule.costPoints,
      cooldownSeconds: rule.cooldownSeconds,
      maxPerDay: rule.maxPerDay,
      rewardIds: List<String>.from(rule.rewardIds),
    );
  }
}

class BoxRuleDtoAdapter extends TypeAdapter<BoxRuleDto> {
  @override
  final int typeId = 6;

  @override
  BoxRuleDto read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return BoxRuleDto(
      id: fields[0] as String,
      householdId: fields[1] as String,
      title: fields[2] as String,
      costPoints: fields[3] as int,
      cooldownSeconds: fields[4] as int,
      maxPerDay: fields[5] as int,
      rewardIds: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, BoxRuleDto obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.householdId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.costPoints)
      ..writeByte(4)
      ..write(obj.cooldownSeconds)
      ..writeByte(5)
      ..write(obj.maxPerDay)
      ..writeByte(6)
      ..write(obj.rewardIds);
  }
}
