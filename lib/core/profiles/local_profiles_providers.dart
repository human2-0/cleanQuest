import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_config/app_config_providers.dart';
import 'local_profile.dart';
import '../providers/user_providers.dart';
import 'local_profiles_repository.dart';

final localProfilesRepositoryProvider = Provider<LocalProfilesRepository>((ref) {
  return LocalProfilesRepository.open();
});

final localProfilesProvider = StreamProvider<List<LocalProfile>>((ref) {
  return ref.read(localProfilesRepositoryProvider).watchProfiles();
});

final currentLocalProfileProvider = Provider<LocalProfile?>((ref) {
  final config = ref.watch(appConfigProvider);
  final userId = config.userId;
  final householdId = config.householdId;
  if (userId == null || householdId == null) {
    return null;
  }
  final profiles = ref.watch(localProfilesProvider).value ?? <LocalProfile>[];
  final repo = ref.read(localProfilesRepositoryProvider);
  return profiles.firstWhere(
    (profile) =>
        profile.id == userId && profile.householdId == householdId,
    orElse: () => LocalProfile(
      id: userId,
      displayName: repo.getProfile(userId)?.displayName ?? userId,
      role: config.role ?? UserRole.member,
      householdId: householdId,
      joinCode: config.joinCode ?? householdId,
    ),
  );
});
