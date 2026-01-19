class BoxRule {
  const BoxRule({
    required this.id,
    required this.householdId,
    required this.title,
    required this.costPoints,
    required this.cooldownSeconds,
    required this.maxPerDay,
    required this.rewardIds,
  });

  final String id;
  final String householdId;
  final String title;
  final int costPoints;
  final int cooldownSeconds;
  final int maxPerDay;
  final List<String> rewardIds;

  BoxRule copyWith({
    String? id,
    String? householdId,
    String? title,
    int? costPoints,
    int? cooldownSeconds,
    int? maxPerDay,
    List<String>? rewardIds,
  }) {
    return BoxRule(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      title: title ?? this.title,
      costPoints: costPoints ?? this.costPoints,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      maxPerDay: maxPerDay ?? this.maxPerDay,
      rewardIds: rewardIds ?? this.rewardIds,
    );
  }
}
