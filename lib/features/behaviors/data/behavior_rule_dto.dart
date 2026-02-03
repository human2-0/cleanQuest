import 'package:hive/hive.dart';

import '../domain/behavior_rule.dart';

class BehaviorRuleDto {
  BehaviorRuleDto({
    required this.id,
    required this.householdId,
    required this.name,
    required this.likes,
    required this.dislikes,
  });

  final String id;
  final String householdId;
  final String name;
  final int likes;
  final int dislikes;

  BehaviorRule toDomain() {
    return BehaviorRule(
      id: id,
      householdId: householdId,
      name: name,
      likes: likes,
      dislikes: dislikes,
    );
  }

  static BehaviorRuleDto fromDomain(BehaviorRule rule) {
    return BehaviorRuleDto(
      id: rule.id,
      householdId: rule.householdId,
      name: rule.name,
      likes: rule.likes,
      dislikes: rule.dislikes,
    );
  }
}

class BehaviorRuleDtoAdapter extends TypeAdapter<BehaviorRuleDto> {
  @override
  final int typeId = 13;

  @override
  BehaviorRuleDto read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (int i = 0; i < reader.readByte(); i++)
        reader.readByte(): reader.read(),
    };
    return BehaviorRuleDto(
      id: fields[0] as String? ?? '',
      householdId: fields[1] as String? ?? '',
      name: fields[2] as String? ?? '',
      likes: fields[3] as int? ?? 0,
      dislikes: fields[4] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, BehaviorRuleDto obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.householdId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.likes)
      ..writeByte(4)
      ..write(obj.dislikes);
  }
}
