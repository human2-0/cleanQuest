import '../providers/user_providers.dart';

class LocalProfile {
  const LocalProfile({
    required this.id,
    required this.displayName,
    required this.role,
    required this.householdId,
    required this.joinCode,
  });

  final String id;
  final String displayName;
  final UserRole role;
  final String householdId;
  final String joinCode;

  LocalProfile copyWith({
    String? id,
    String? displayName,
    UserRole? role,
    String? householdId,
    String? joinCode,
  }) {
    return LocalProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      householdId: householdId ?? this.householdId,
      joinCode: joinCode ?? this.joinCode,
    );
  }
}
