import '../../features/approvals/domain/request_status.dart';
import '../../features/items/domain/area_category.dart';
import '../../features/items/domain/item_status.dart';
import '../../l10n/app_localizations.dart';

String localizedAreaCategory(AppLocalizations l10n, AreaCategory category) {
  switch (category) {
    case AreaCategory.home:
      return l10n.areaCategoryHome;
    case AreaCategory.car:
      return l10n.areaCategoryCar;
    case AreaCategory.other:
      return l10n.areaCategoryOther;
  }
}

String localizedItemStatus(AppLocalizations l10n, ItemStatus status) {
  switch (status) {
    case ItemStatus.fresh:
      return l10n.itemStatusFresh;
    case ItemStatus.soon:
      return l10n.itemStatusSoon;
    case ItemStatus.due:
      return l10n.itemStatusDue;
    case ItemStatus.overdue:
      return l10n.itemStatusOverdue;
    case ItemStatus.snoozed:
      return l10n.itemStatusSnoozed;
    case ItemStatus.paused:
      return l10n.itemStatusPaused;
  }
}

String localizedRequestStatus(AppLocalizations l10n, RequestStatus status) {
  switch (status) {
    case RequestStatus.pending:
      return l10n.statusPending;
    case RequestStatus.approved:
      return l10n.statusApproved;
    case RequestStatus.rejected:
      return l10n.statusRejected;
  }
}
