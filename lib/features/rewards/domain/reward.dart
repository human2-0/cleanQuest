class Reward {
  const Reward({
    required this.id,
    required this.householdId,
    required this.title,
    this.description,
    required this.weight,
    required this.enabled,
  });

  final String id;
  final String householdId;
  final String title;
  final String? description;
  final int weight;
  final bool enabled;
}
