import 'ledger_reason.dart';

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.delta,
    required this.createdAt,
    required this.reason,
    this.relatedRequestId,
    this.relatedRedemptionId,
  });

  final String id;
  final String householdId;
  final String userId;
  final int delta;
  final DateTime createdAt;
  final LedgerReason reason;
  final String? relatedRequestId;
  final String? relatedRedemptionId;
}
