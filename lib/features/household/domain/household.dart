class Household {
  const Household({
    required this.id,
    required this.name,
    required this.adminIds,
    required this.memberIds,
    required this.primaryAdminId,
    required this.secondaryAdminId,
    required this.adminEpoch,
  });

  final String id;
  final String name;
  final List<String> adminIds;
  final List<String> memberIds;
  final String primaryAdminId;
  final String? secondaryAdminId;
  final int adminEpoch;

  Household copyWith({
    String? id,
    String? name,
    List<String>? adminIds,
    List<String>? memberIds,
    String? primaryAdminId,
    String? secondaryAdminId,
    int? adminEpoch,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      adminIds: adminIds ?? this.adminIds,
      memberIds: memberIds ?? this.memberIds,
      primaryAdminId: primaryAdminId ?? this.primaryAdminId,
      secondaryAdminId: secondaryAdminId ?? this.secondaryAdminId,
      adminEpoch: adminEpoch ?? this.adminEpoch,
    );
  }
}
