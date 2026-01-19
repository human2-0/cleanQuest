import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_log_repository.dart';
import '../domain/notification_log_entry.dart';

final notificationLogRepositoryProvider =
    Provider<NotificationLogRepository>((ref) {
  return NotificationLogRepository.open();
});

final notificationLogProvider = StreamProvider<List<NotificationLogEntry>>((ref) {
  return ref.read(notificationLogRepositoryProvider).watchLogs().map((logs) {
    final sorted = [...logs];
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  });
});
