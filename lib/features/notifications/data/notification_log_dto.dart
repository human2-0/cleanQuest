import 'package:hive/hive.dart';

import '../domain/notification_log_entry.dart';

class NotificationLogDto {
  NotificationLogDto({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  NotificationLogEntry toDomain() {
    return NotificationLogEntry(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
    );
  }

  static NotificationLogDto fromDomain(NotificationLogEntry entry) {
    return NotificationLogDto(
      id: entry.id,
      title: entry.title,
      body: entry.body,
      createdAt: entry.createdAt,
    );
  }
}

class NotificationLogDtoAdapter extends TypeAdapter<NotificationLogDto> {
  @override
  final int typeId = 8;

  @override
  NotificationLogDto read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return NotificationLogDto(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationLogDto obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.createdAt);
  }
}
