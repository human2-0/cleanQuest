import 'package:hive/hive.dart';

import '../domain/completion_event.dart';

class CompletionEventDto {
  CompletionEventDto({
    required this.id,
    required this.householdId,
    required this.itemId,
    required this.approvedAt,
  });

  final String id;
  final String householdId;
  final String itemId;
  final DateTime approvedAt;

  CompletionEvent toDomain() {
    return CompletionEvent(
      id: id,
      householdId: householdId,
      itemId: itemId,
      approvedAt: approvedAt,
    );
  }

  static CompletionEventDto fromDomain(CompletionEvent event) {
    return CompletionEventDto(
      id: event.id,
      householdId: event.householdId,
      itemId: event.itemId,
      approvedAt: event.approvedAt,
    );
  }
}

class CompletionEventDtoAdapter extends TypeAdapter<CompletionEventDto> {
  @override
  final int typeId = 2;

  @override
  CompletionEventDto read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return CompletionEventDto(
      id: fields[0] as String,
      householdId: fields[1] as String,
      itemId: fields[2] as String,
      approvedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CompletionEventDto obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.householdId)
      ..writeByte(2)
      ..write(obj.itemId)
      ..writeByte(3)
      ..write(obj.approvedAt);
  }
}
