import 'package:hive/hive.dart';

import '../domain/inventory_item.dart';
import '../domain/inventory_item_type.dart';

class InventoryItemDto {
  InventoryItemDto({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.typeIndex,
    required this.durationHours,
    required this.purchasedAt,
    this.usedAt,
    this.appliedItemId,
  });

  final String id;
  final String householdId;
  final String userId;
  final int typeIndex;
  final int durationHours;
  final DateTime purchasedAt;
  final DateTime? usedAt;
  final String? appliedItemId;

  InventoryItem toDomain() {
    return InventoryItem(
      id: id,
      householdId: householdId,
      userId: userId,
      type: InventoryItemType.values[typeIndex],
      durationHours: durationHours,
      purchasedAt: purchasedAt,
      usedAt: usedAt,
      appliedItemId: appliedItemId,
    );
  }

  static InventoryItemDto fromDomain(InventoryItem item) {
    return InventoryItemDto(
      id: item.id,
      householdId: item.householdId,
      userId: item.userId,
      typeIndex: item.type.index,
      durationHours: item.durationHours,
      purchasedAt: item.purchasedAt,
      usedAt: item.usedAt,
      appliedItemId: item.appliedItemId,
    );
  }
}

class InventoryItemDtoAdapter extends TypeAdapter<InventoryItemDto> {
  @override
  final int typeId = 12;

  @override
  InventoryItemDto read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return InventoryItemDto(
      id: fields[0] as String,
      householdId: fields[1] as String,
      userId: fields[2] as String,
      typeIndex: fields[3] as int? ?? InventoryItemType.lossProtection.index,
      durationHours: fields[4] as int? ?? 24,
      purchasedAt: fields[5] as DateTime,
      usedAt: fields[6] as DateTime?,
      appliedItemId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItemDto obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.householdId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.typeIndex)
      ..writeByte(4)
      ..write(obj.durationHours)
      ..writeByte(5)
      ..write(obj.purchasedAt)
      ..writeByte(6)
      ..write(obj.usedAt)
      ..writeByte(7)
      ..write(obj.appliedItemId);
  }
}
