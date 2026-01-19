import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_config/app_config_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../data/households_repository.dart';
import '../data/user_profiles_repository.dart';
import '../domain/household.dart';
import '../domain/user_profile.dart';

final householdsRepositoryProvider = Provider<HouseholdsRepository>((ref) {
  return HouseholdsRepository.open();
});

final userProfilesRepositoryProvider = Provider<UserProfilesRepository>((ref) {
  return UserProfilesRepository.open();
});

final activeHouseholdProvider = StreamProvider<Household?>((ref) {
  final householdId = ref.watch(appConfigProvider).householdId;
  if (householdId == null || householdId.isEmpty) {
    return Stream<Household?>.value(null);
  }
  return ref.read(householdsRepositoryProvider).watchHousehold(householdId);
});

final householdProfilesProvider = StreamProvider<List<UserProfile>>((ref) {
  final householdId = ref.watch(appConfigProvider).householdId;
  if (householdId == null || householdId.isEmpty) {
    return Stream<List<UserProfile>>.value(<UserProfile>[]);
  }
  return ref.read(userProfilesRepositoryProvider).watchProfiles(householdId);
});

final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final profiles = ref.watch(householdProfilesProvider).value ?? <UserProfile>[];
  return profiles.firstWhere(
    (profile) => profile.id == userId,
    orElse: () => UserProfile(
      id: userId,
      householdId: ref.watch(appConfigProvider).householdId ?? '',
      displayName: userId,
      role: ref.watch(currentUserRoleProvider),
    ),
  );
});
