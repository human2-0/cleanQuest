import '../../../core/providers/user_providers.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.householdId,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String householdId;
  final String displayName;
  final UserRole role;

  UserProfile copyWith({
    String? id,
    String? householdId,
    String? displayName,
    UserRole? role,
  }) {
    return UserProfile(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
    );
  }
}
