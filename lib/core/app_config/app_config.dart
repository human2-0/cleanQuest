import '../providers/user_providers.dart';

class AppConfig {
  const AppConfig({
    required this.onboardingComplete,
    required this.role,
    required this.userId,
    required this.householdId,
    required this.joinCode,
    required this.notificationsEnabled,
    required this.dailyDigestEnabled,
    required this.localeCode,
  });

  final bool onboardingComplete;
  final UserRole? role;
  final String? userId;
  final String? householdId;
  final String? joinCode;
  final bool notificationsEnabled;
  final bool dailyDigestEnabled;
  final String? localeCode;

  AppConfig copyWith({
    bool? onboardingComplete,
    UserRole? role,
    String? userId,
    String? householdId,
    String? joinCode,
    bool? notificationsEnabled,
    bool? dailyDigestEnabled,
    String? localeCode,
  }) {
    return AppConfig(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      joinCode: joinCode ?? this.joinCode,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      dailyDigestEnabled: dailyDigestEnabled ?? this.dailyDigestEnabled,
      localeCode: localeCode ?? this.localeCode,
    );
  }
}
