import '../../items/data/completion_events_repository.dart';
import '../../items/data/items_repository.dart';
import '../../items/domain/completion_event.dart';
import '../../points/data/ledger_repository.dart';
import '../../points/domain/ledger_entry.dart';
import '../../points/domain/ledger_reason.dart';
import '../../items/domain/item.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../l10n/app_localizations.dart';
import '../data/completion_requests_repository.dart';
import '../domain/completion_request.dart';
import '../domain/request_status.dart';

class CompletionRequestsController {
  CompletionRequestsController(
    this._requestsRepository,
    this._eventsRepository,
    this._itemsRepository,
    this._ledgerRepository,
    this._notifications,
    this._notificationsEnabled,
    this._localizations,
  );

  final CompletionRequestsRepository _requestsRepository;
  final CompletionEventsRepository _eventsRepository;
  final ItemsRepository _itemsRepository;
  final LedgerRepository _ledgerRepository;
  final NotificationService _notifications;
  final bool _notificationsEnabled;
  final AppLocalizations _localizations;

  Future<CompletionRequest> submitRequest({
    required String householdId,
    required String itemId,
    required String submittedByUserId,
    required bool isAdmin,
    String? itemName,
    String? note,
  }) async {
    if (isAdmin) {
      throw StateError(_localizations.errorAdminsCannotSubmit);
    }
    await _requestsRepository.ensureConnected();
    final request = CompletionRequest(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      householdId: householdId,
      itemId: itemId,
      submittedByUserId: submittedByUserId,
      submittedAt: DateTime.now(),
      status: RequestStatus.pending,
      note: note,
    );
    await _requestsRepository.upsertRequest(request);
    if (_notificationsEnabled) {
      await _notifications.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: _localizations.notificationNewApprovalTitle,
        body: itemName ?? _localizations.notificationNewApprovalBody,
      );
    }
    return request;
  }

  Future<void> approveRequest({
    required CompletionRequest request,
    required String reviewedByUserId,
    required bool isAdmin,
    String? itemName,
  }) async {
    if (!isAdmin) {
      throw StateError(_localizations.errorOnlyAdminsApprove);
    }
    final approved = request.copyWith(
      status: RequestStatus.approved,
      reviewedByUserId: reviewedByUserId,
      reviewedAt: DateTime.now(),
    );
    await _requestsRepository.upsertRequest(approved);
    await _eventsRepository.addEvent(
      CompletionEvent(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        householdId: request.householdId,
        itemId: request.itemId,
        approvedAt: DateTime.now(),
      ),
    );
    final item = _itemsRepository.getItem(request.itemId);
    final points = item?.points ?? 10;
    final penalty = _overduePenaltyPoints(
      item: item,
      request: request,
    );
    final memberPoints = (points - penalty).clamp(0, points);
    await _ledgerRepository.addEntry(
      LedgerEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        householdId: request.householdId,
        userId: request.submittedByUserId,
        delta: memberPoints,
        createdAt: DateTime.now(),
        reason: LedgerReason.choreApproved,
        relatedRequestId: request.id,
      ),
    );
    if (penalty > 0) {
      await _ledgerRepository.addEntry(
        LedgerEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          householdId: request.householdId,
          userId: reviewedByUserId,
          delta: penalty,
          createdAt: DateTime.now(),
          reason: LedgerReason.overduePenalty,
          relatedRequestId: request.id,
        ),
      );
    }
    if (item != null &&
        (item.protectionUntil != null || item.protectionUsed)) {
      await _itemsRepository.upsertItem(
        item.copyWith(
          protectionUntil: null,
          protectionUsed: false,
        ),
      );
    }
    if (_notificationsEnabled) {
      await _notifications.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: _localizations.notificationRequestApprovedTitle,
        body: itemName ?? _localizations.notificationRequestApprovedBody,
      );
    }
  }

  Future<void> rejectRequest({
    required CompletionRequest request,
    required String reviewedByUserId,
    required bool isAdmin,
    String? itemName,
  }) {
    if (!isAdmin) {
      throw StateError(_localizations.errorOnlyAdminsReject);
    }
    final rejected = request.copyWith(
      status: RequestStatus.rejected,
      reviewedByUserId: reviewedByUserId,
      reviewedAt: DateTime.now(),
    );
    return _requestsRepository.upsertRequest(rejected).then((_) async {
      if (_notificationsEnabled) {
        await _notifications.show(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          title: _localizations.notificationRequestRejectedTitle,
          body: itemName ?? _localizations.notificationRequestRejectedBody,
        );
      }
    });
  }

  int _overduePenaltyPoints({
    required Item? item,
    required CompletionRequest request,
  }) {
    if (item == null || item.overdueWeight <= 0) {
      return 0;
    }
    if (item.intervalSeconds <= 0) {
      return 0;
    }
    final lastApprovedAt =
        _eventsRepository.latestApprovedAt(request.householdId, request.itemId);
    if (lastApprovedAt == null) {
      return 0;
    }
    final dueAt =
        lastApprovedAt.add(Duration(seconds: item.intervalSeconds));
    var penaltyStartAt = dueAt;
    if (item.protectionUntil != null) {
      final graceStart =
          item.protectionUntil!.add(const Duration(hours: 1));
      if (graceStart.isAfter(penaltyStartAt)) {
        penaltyStartAt = graceStart;
      }
    }
    final overdueDays =
        request.submittedAt.difference(penaltyStartAt).inDays;
    if (overdueDays <= 0) {
      return 0;
    }
    final penalty = item.overdueWeight * overdueDays;
    return penalty > item.points ? item.points : penalty;
  }
}
