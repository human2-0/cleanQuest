import '../providers/user_providers.dart';

class AppConfig {
  const AppConfig({
    required this.onboardingComplete,
    required this.role,
    required this.userId,
    required this.householdId,
    required this.householdName,
    required this.joinCode,
    required this.draftUserId,
    required this.draftDisplayName,
    required this.activeDisplayName,
    required this.activeDisplayNameUserId,
    required this.notificationsEnabled,
    required this.dailyDigestEnabled,
    required this.localeCode,
    required this.darkModeEnabled,
  });

  final bool onboardingComplete;
  final UserRole? role;
  final String? userId;
  final String? householdId;
  final String? householdName;
  final String? joinCode;
  final String? draftUserId;
  final String? draftDisplayName;
  final String? activeDisplayName;
  final String? activeDisplayNameUserId;
  final bool notificationsEnabled;
  final bool dailyDigestEnabled;
  final String? localeCode;
  final bool darkModeEnabled;

  AppConfig copyWith({
    bool? onboardingComplete,
    UserRole? role,
    String? userId,
    String? householdId,
    String? householdName,
    String? joinCode,
    String? draftUserId,
    String? draftDisplayName,
    String? activeDisplayName,
    String? activeDisplayNameUserId,
    bool? notificationsEnabled,
    bool? dailyDigestEnabled,
    String? localeCode,
    bool? darkModeEnabled,
  }) {
    return AppConfig(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
      householdName: householdName ?? this.householdName,
      joinCode: joinCode ?? this.joinCode,
      draftUserId: draftUserId ?? this.draftUserId,
      draftDisplayName: draftDisplayName ?? this.draftDisplayName,
      activeDisplayName: activeDisplayName ?? this.activeDisplayName,
      activeDisplayNameUserId:
          activeDisplayNameUserId ?? this.activeDisplayNameUserId,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      dailyDigestEnabled: dailyDigestEnabled ?? this.dailyDigestEnabled,
      localeCode: localeCode ?? this.localeCode,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
    );
  }
}
