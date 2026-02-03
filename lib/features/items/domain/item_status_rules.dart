import '../../../core/constants/status_thresholds.dart';
import 'item.dart';
import 'item_status.dart';
import 'item_type.dart';

class ItemStatusRules {
  const ItemStatusRules._();

  static ItemStatus resolve({
    required Item item,
    required DateTime now,
    required DateTime? lastApprovedAt,
  }) {
    if (item.isPaused) {
      return ItemStatus.paused;
    }
    if (item.protectionUntil != null &&
        now.isBefore(item.protectionUntil!)) {
      return ItemStatus.paused;
    }
    if (item.snoozedUntil != null && now.isBefore(item.snoozedUntil!)) {
      return ItemStatus.snoozed;
    }

    if (item.type == ItemType.singular) {
      return lastApprovedAt == null ? ItemStatus.due : ItemStatus.fresh;
    }

    if (item.intervalSeconds <= 0) {
      return ItemStatus.due;
    }

    if (lastApprovedAt == null) {
      return ItemStatus.due;
    }

    final elapsedSeconds = now.difference(lastApprovedAt).inSeconds;
    final elapsedRatio = elapsedSeconds / item.intervalSeconds;

    if (elapsedRatio < StatusThresholds.freshMax) {
      return ItemStatus.fresh;
    }
    if (elapsedRatio < StatusThresholds.soonMax) {
      return ItemStatus.soon;
    }
    if (elapsedRatio < StatusThresholds.dueMax) {
      return ItemStatus.due;
    }
    return ItemStatus.overdue;
  }
}
