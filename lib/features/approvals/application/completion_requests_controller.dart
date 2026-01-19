import '../../items/data/completion_events_repository.dart';
import '../../items/data/items_repository.dart';
import '../../items/domain/completion_event.dart';
import '../../points/data/ledger_repository.dart';
import '../../points/domain/ledger_entry.dart';
import '../../points/domain/ledger_reason.dart';
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

  Future<void> submitRequest({
    required String householdId,
    required String itemId,
    required String submittedByUserId,
    required bool isAdmin,
    String? itemName,
    String? note,
  }) {
    if (isAdmin) {
      throw StateError(_localizations.errorAdminsCannotSubmit);
    }
    final request = CompletionRequest(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      householdId: householdId,
      itemId: itemId,
      submittedByUserId: submittedByUserId,
      submittedAt: DateTime.now(),
      status: RequestStatus.pending,
      note: note,
    );
    return _requestsRepository.upsertRequest(request).then((_) async {
      if (_notificationsEnabled) {
        await _notifications.show(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          title: _localizations.notificationNewApprovalTitle,
          body: itemName ?? _localizations.notificationNewApprovalBody,
        );
      }
    });
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
    final points = _itemsRepository.getItem(request.itemId)?.points ?? 10;
    await _ledgerRepository.addEntry(
      LedgerEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        householdId: request.householdId,
        userId: request.submittedByUserId,
        delta: points,
        createdAt: DateTime.now(),
        reason: LedgerReason.choreApproved,
        relatedRequestId: request.id,
      ),
    );
    await _ledgerRepository.addEntry(
      LedgerEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        householdId: request.householdId,
        userId: reviewedByUserId,
        delta: points,
        createdAt: DateTime.now(),
        reason: LedgerReason.adminApprovalReward,
        relatedRequestId: request.id,
      ),
    );
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
}
