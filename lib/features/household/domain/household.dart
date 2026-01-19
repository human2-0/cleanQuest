class Household {
  const Household({
    required this.id,
    required this.name,
    required this.adminIds,
    required this.memberIds,
  });

  final String id;
  final String name;
  final List<String> adminIds;
  final List<String> memberIds;

  Household copyWith({
    String? id,
    String? name,
    List<String>? adminIds,
    List<String>? memberIds,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      adminIds: adminIds ?? this.adminIds,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}
