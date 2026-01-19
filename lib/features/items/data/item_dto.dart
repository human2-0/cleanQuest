import 'package:hive/hive.dart';

import '../domain/area_category.dart';
import '../domain/item.dart';

class ItemDto {
  ItemDto({
    required this.id,
    required this.householdId,
    required this.name,
    required this.categoryIndex,
    required this.icon,
    required this.intervalSeconds,
    required this.points,
    required this.isPaused,
    this.roomOrZone,
    this.snoozedUntil,
  });

  final String id;
  final String householdId;
  final String name;
  final int categoryIndex;
  final String icon;
  final int intervalSeconds;
  final int points;
  final String? roomOrZone;
  final bool isPaused;
  final DateTime? snoozedUntil;

  Item toDomain() {
    return Item(
      id: id,
      householdId: householdId,
      name: name,
      category: AreaCategory.values[categoryIndex],
      icon: icon,
      intervalSeconds: intervalSeconds,
      points: points,
      roomOrZone: roomOrZone,
      isPaused: isPaused,
      snoozedUntil: snoozedUntil,
    );
  }

  static ItemDto fromDomain(Item item) {
    return ItemDto(
      id: item.id,
      householdId: item.householdId,
      name: item.name,
      categoryIndex: item.category.index,
      icon: item.icon,
      intervalSeconds: item.intervalSeconds,
      points: item.points,
      roomOrZone: item.roomOrZone,
      isPaused: item.isPaused,
      snoozedUntil: item.snoozedUntil,
    );
  }
}

class ItemDtoAdapter extends TypeAdapter<ItemDto> {
  @override
  final int typeId = 1;

  @override
  ItemDto read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return ItemDto(
      id: fields[0] as String,
      householdId: fields[1] as String,
      name: fields[2] as String,
      categoryIndex: fields[3] as int,
      icon: fields[4] as String,
      intervalSeconds: fields[5] as int,
      points: fields[9] as int? ?? 10,
      roomOrZone: fields[6] as String?,
      isPaused: fields[7] as bool,
      snoozedUntil: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ItemDto obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.householdId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.categoryIndex)
      ..writeByte(4)
      ..write(obj.icon)
      ..writeByte(5)
      ..write(obj.intervalSeconds)
      ..writeByte(9)
      ..write(obj.points)
      ..writeByte(6)
      ..write(obj.roomOrZone)
      ..writeByte(7)
      ..write(obj.isPaused)
      ..writeByte(8)
      ..write(obj.snoozedUntil);
  }
}
