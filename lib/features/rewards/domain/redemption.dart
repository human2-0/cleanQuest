import 'redemption_status.dart';

const String noRewardId = 'reward-none';

class Redemption {
  const Redemption({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.boxRuleId,
    required this.costPoints,
    required this.rolledAt,
    required this.outcomeRewardId,
    required this.rngVersion,
    required this.status,
    this.requestedAt,
    this.reviewedAt,
    this.reviewedByUserId,
  });

  final String id;
  final String householdId;
  final String userId;
  final String boxRuleId;
  final int costPoints;
  final DateTime rolledAt;
  final String outcomeRewardId;
  final String rngVersion;
  final RedemptionStatus status;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedByUserId;

  Redemption copyWith({
    RedemptionStatus? status,
    DateTime? requestedAt,
    DateTime? reviewedAt,
    String? reviewedByUserId,
  }) {
    return Redemption(
      id: id,
      householdId: householdId,
      userId: userId,
      boxRuleId: boxRuleId,
      costPoints: costPoints,
      rolledAt: rolledAt,
      outcomeRewardId: outcomeRewardId,
      rngVersion: rngVersion,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedByUserId: reviewedByUserId ?? this.reviewedByUserId,
    );
  }
}
