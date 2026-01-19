import 'request_status.dart';

class CompletionRequest {
  const CompletionRequest({
    required this.id,
    required this.householdId,
    required this.itemId,
    required this.submittedByUserId,
    required this.submittedAt,
    required this.status,
    this.note,
    this.reviewedByUserId,
    this.reviewedAt,
  });

  final String id;
  final String householdId;
  final String itemId;
  final String submittedByUserId;
  final DateTime submittedAt;
  final String? note;
  final RequestStatus status;
  final String? reviewedByUserId;
  final DateTime? reviewedAt;

  CompletionRequest copyWith({
    String? id,
    String? householdId,
    String? itemId,
    String? submittedByUserId,
    DateTime? submittedAt,
    String? note,
    RequestStatus? status,
    String? reviewedByUserId,
    DateTime? reviewedAt,
  }) {
    return CompletionRequest(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      itemId: itemId ?? this.itemId,
      submittedByUserId: submittedByUserId ?? this.submittedByUserId,
      submittedAt: submittedAt ?? this.submittedAt,
      note: note ?? this.note,
      status: status ?? this.status,
      reviewedByUserId: reviewedByUserId ?? this.reviewedByUserId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
