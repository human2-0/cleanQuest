enum ItemStatus {
  fresh,
  soon,
  due,
  overdue,
  snoozed,
  paused,
}

extension ItemStatusPresentation on ItemStatus {
  String get label {
    switch (this) {
      case ItemStatus.fresh:
        return 'Fresh';
      case ItemStatus.soon:
        return 'Soon';
      case ItemStatus.due:
        return 'Due';
      case ItemStatus.overdue:
        return 'Overdue';
      case ItemStatus.snoozed:
        return 'Snoozed';
      case ItemStatus.paused:
        return 'Paused';
    }
  }

  String get emoji {
    switch (this) {
      case ItemStatus.fresh:
        return '🟢';
      case ItemStatus.soon:
        return '🟡';
      case ItemStatus.due:
        return '🟠';
      case ItemStatus.overdue:
        return '🔴';
      case ItemStatus.snoozed:
        return '😴';
      case ItemStatus.paused:
        return '⏸️';
    }
  }
}
