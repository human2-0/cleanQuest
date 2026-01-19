import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../domain/notification_log_entry.dart';
import 'notification_log_dto.dart';

class NotificationLogRepository {
  NotificationLogRepository(this._box);

  final Box<NotificationLogDto> _box;

  static NotificationLogRepository open() {
    return NotificationLogRepository(
      Hive.box<NotificationLogDto>(notificationsBoxName),
    );
  }

  Stream<List<NotificationLogEntry>> watchLogs() async* {
    yield _logs();
    await for (final _ in _box.watch()) {
      yield _logs();
    }
  }

  Future<void> addLog(NotificationLogEntry entry) {
    return _box.put(entry.id, NotificationLogDto.fromDomain(entry));
  }

  List<NotificationLogEntry> _logs() {
    return _box.values.map((dto) => dto.toDomain()).toList();
  }
}
