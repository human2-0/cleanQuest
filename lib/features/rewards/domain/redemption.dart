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
  });

  final String id;
  final String householdId;
  final String userId;
  final String boxRuleId;
  final int costPoints;
  final DateTime rolledAt;
  final String outcomeRewardId;
  final String rngVersion;
}
