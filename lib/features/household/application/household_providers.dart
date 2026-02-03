import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_config/app_config_providers.dart';
import '../../../core/app_config/app_config.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/profiles/local_profiles_providers.dart';
import '../../../core/profiles/local_profile.dart';
import '../../../core/sync/sync_providers.dart';
import '../data/households_repository.dart';
import '../data/user_profiles_repository.dart';
import '../domain/household.dart';
import '../domain/user_profile.dart';

final householdsRepositoryProvider = Provider<HouseholdsRepository>((ref) {
  return HouseholdsRepository.open(sync: ref.read(syncCoordinatorProvider));
});

final userProfilesRepositoryProvider = Provider<UserProfilesRepository>((ref) {
  return UserProfilesRepository.open(sync: ref.read(syncCoordinatorProvider));
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
  final localProfile = ref.watch(currentLocalProfileProvider);
  return profiles.firstWhere(
    (profile) => profile.id == userId,
    orElse: () => UserProfile(
      id: userId,
      householdId: ref.watch(appConfigProvider).householdId ?? '',
      displayName: localProfile?.displayName ?? userId,
      role: ref.watch(currentUserRoleProvider),
    ),
  );
});

final currentUserIsPrimaryAdminProvider = Provider<bool>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final household = ref.watch(activeHouseholdProvider).value;
  if (userId.isEmpty || household == null) {
    return false;
  }
  return household.primaryAdminId == userId;
});

final localProfileSyncProvider = Provider<void>((ref) {
  final config = ref.watch(appConfigProvider);
  final profiles =
      ref.watch(householdProfilesProvider).value ?? <UserProfile>[];
  final userId = config.userId;
  final householdId = config.householdId;
  final localRepo = ref.read(localProfilesRepositoryProvider);
  final appConfigNotifier = ref.read(appConfigProvider.notifier);
  final profilesRepo = ref.read(userProfilesRepositoryProvider);
  final householdsRepo = ref.read(householdsRepositoryProvider);
  debugPrint(
    '[local-sync] config onboarding=${config.onboardingComplete} '
    'role=${config.role} userId=$userId householdId=$householdId '
    'localCount=${localRepo.listProfiles().length} '
    'remoteCount=${profiles.length}',
  );
  if (userId == null ||
      userId.isEmpty ||
      householdId == null ||
      householdId.isEmpty) {
    final localProfiles = localRepo.listProfiles().where((profile) {
      return profile.householdId.isNotEmpty;
    }).toList();
    if (localProfiles.isNotEmpty) {
      final profile = localProfiles.first;
      debugPrint(
        '[local-sync] restoring from local profile '
        'userId=${profile.id} householdId=${profile.householdId} '
        'role=${profile.role} displayName="${profile.displayName}"',
      );
      Future.microtask(() {
        appConfigNotifier.setActiveProfile(
          role: profile.role,
          userId: profile.id,
          householdId: profile.householdId,
          joinCode: profile.joinCode,
          displayName: profile.displayName,
        );
      });
    }
    return;
  }
  if (!config.onboardingComplete ||
      householdId == null ||
      householdId.isEmpty ||
      userId == null ||
      userId.isEmpty) {
    return;
  }
  _ensureHouseholdName(
    householdsRepo: householdsRepo,
    config: config,
    userId: userId,
  );
  final localProfile = localRepo.getProfile(userId);
  UserProfile? remoteProfile;
  for (final profile in profiles) {
    if (profile.id == userId) {
      remoteProfile = profile;
      break;
    }
  }
  if (localProfile == null) {
    debugPrint('[local-sync] missing local profile userId=$userId');
    final existing = remoteProfile ?? profilesRepo.getProfile(userId);
    if (existing != null && existing.householdId == householdId) {
      final recovered = LocalProfile(
        id: existing.id,
        displayName: existing.displayName,
        role: existing.role,
        householdId: householdId,
        joinCode: config.joinCode ?? householdId,
      );
      Future.microtask(() => localRepo.upsertProfile(recovered));
      if (config.role == null || config.role != existing.role) {
        Future.microtask(() {
          appConfigNotifier.setActiveDisplayName(existing.displayName);
          appConfigNotifier.setActiveUser(
            role: existing.role,
            userId: existing.id,
          );
        });
      }
    }
    return;
  }
  var effectiveLocalProfile = localProfile;
  if (_shouldRepairLocalProfile(localProfile, config, userId)) {
    final repaired = localProfile.copyWith(
      role: config.role ?? localProfile.role,
      displayName: _resolvedDisplayName(
        localProfile,
        config.activeDisplayName,
        config.activeDisplayNameUserId,
        userId,
      ),
    );
    debugPrint(
      '[local-sync] repairing local profile '
      'role=${localProfile.role}->${repaired.role} '
      'displayName="${localProfile.displayName}"->"${repaired.displayName}"',
    );
    Future.microtask(() => localRepo.upsertProfile(repaired));
    effectiveLocalProfile = repaired;
  }
  debugPrint(
    '[local-sync] local profile userId=${effectiveLocalProfile.id} '
    'role=${effectiveLocalProfile.role} '
    'displayName="${effectiveLocalProfile.displayName}"',
  );
  if ((config.activeDisplayNameUserId == null ||
          config.activeDisplayNameUserId != userId) &&
      !_isPlaceholderName(effectiveLocalProfile.displayName, userId)) {
    Future.microtask(() {
      appConfigNotifier
          .setActiveDisplayName(effectiveLocalProfile.displayName);
    });
  }
  if (remoteProfile != null &&
      remoteProfile.householdId == householdId &&
      remoteProfile.displayName.trim().isNotEmpty &&
      _isPlaceholderName(effectiveLocalProfile.displayName, userId) &&
      remoteProfile.displayName != effectiveLocalProfile.displayName) {
    final refreshed =
        effectiveLocalProfile.copyWith(displayName: remoteProfile.displayName);
    Future.microtask(() => localRepo.upsertProfile(refreshed));
  }
  if (config.role == null || config.role != effectiveLocalProfile.role) {
    if (!_shouldPreferLocalProfile(effectiveLocalProfile, config, userId)) {
      debugPrint(
        '[local-sync] skip config update from placeholder local profile',
      );
    } else {
      Future.microtask(() {
        appConfigNotifier
            .setActiveDisplayName(effectiveLocalProfile.displayName);
        appConfigNotifier.setActiveUser(
          role: effectiveLocalProfile.role,
          userId: effectiveLocalProfile.id,
        );
      });
    }
  }
  final normalized = effectiveLocalProfile.householdId == config.householdId
      ? effectiveLocalProfile
      : effectiveLocalProfile.copyWith(
          householdId: config.householdId!,
          joinCode: config.joinCode ?? config.householdId!,
        );
  if (normalized != localProfile) {
    Future.microtask(() => localRepo.upsertProfile(normalized));
  }
  final existing = profilesRepo.getProfile(normalized.id);
  if (_shouldUpsertProfile(
    localProfile: normalized,
    householdId: householdId,
    existing: existing,
  )) {
    Future.microtask(() {
      profilesRepo.upsertProfile(
        UserProfile(
          id: normalized.id,
          householdId: config.householdId!,
          displayName: normalized.displayName,
          role: normalized.role,
        ),
      );
    });
  }
});

bool _isPlaceholderName(String value, String userId) {
  final name = value.trim();
  return name.isEmpty ||
      name == userId ||
      name == 'Unknown' ||
      name == 'unknown-user';
}

bool _shouldPreferLocalProfile(
  LocalProfile localProfile,
  AppConfig config,
  String userId,
) {
  if (_isPlaceholderName(localProfile.displayName, userId)) {
    return false;
  }
  if (config.role == UserRole.admin && localProfile.role != UserRole.admin) {
    return false;
  }
  return true;
}

bool _shouldRepairLocalProfile(
  LocalProfile localProfile,
  AppConfig config,
  String userId,
) {
  final activeName = config.activeDisplayName;
  final activeNameForUser = config.activeDisplayNameUserId == null ||
      config.activeDisplayNameUserId == userId;
  final needsName = activeName != null &&
      activeName.trim().isNotEmpty &&
      activeNameForUser &&
      _isPlaceholderName(localProfile.displayName, userId) &&
      localProfile.displayName != activeName;
  final needsRole =
      config.role != null && localProfile.role != config.role;
  return needsName || needsRole;
}

String _resolvedDisplayName(
  LocalProfile localProfile,
  String? activeDisplayName,
  String? activeDisplayNameUserId,
  String userId,
) {
  final next = activeDisplayName?.trim();
  if (next == null || next.isEmpty) {
    return localProfile.displayName;
  }
  if (activeDisplayNameUserId != null && activeDisplayNameUserId != userId) {
    return localProfile.displayName;
  }
  return next;
}

void _ensureHouseholdName({
  required HouseholdsRepository householdsRepo,
  required AppConfig config,
  required String userId,
}) {
  final householdId = config.householdId;
  final householdName = config.householdName?.trim();
  final isAdmin = config.role == UserRole.admin;
  if (householdId == null || householdId.isEmpty) {
    return;
  }
  if (householdName == null || householdName.isEmpty) {
    return;
  }
  final existing = householdsRepo.getHousehold(householdId);
  if (existing == null) {
    final admins = isAdmin ? [userId] : <String>[];
    final members = isAdmin ? <String>[] : [userId];
    debugPrint(
      '[local-sync] seeding household name="$householdName" '
      'householdId=$householdId',
    );
    Future.microtask(() {
      householdsRepo.upsertHousehold(
        Household(
          id: householdId,
          name: householdName,
          adminIds: admins,
          memberIds: members,
          primaryAdminId: isAdmin ? userId : '',
          secondaryAdminId: null,
          adminEpoch: 0,
        ),
      );
    });
    return;
  }
  var updated = existing;
  var changed = false;
  if (_shouldRepairHouseholdName(existing.name, householdName)) {
    debugPrint(
      '[local-sync] repairing household name '
      '"${existing.name}"->"$householdName"',
    );
    updated = updated.copyWith(name: householdName);
    changed = true;
  }
  if (isAdmin) {
    final nextAdmins = existing.adminIds.contains(userId)
        ? existing.adminIds
        : [...existing.adminIds, userId];
    if (!_listEquals(nextAdmins, existing.adminIds)) {
      debugPrint(
        '[local-sync] repairing household admins '
        'adminIds=${existing.adminIds}->${nextAdmins} '
        'primaryAdminId="${existing.primaryAdminId}"',
      );
      updated = updated.copyWith(adminIds: nextAdmins);
      changed = true;
    }
    if (existing.primaryAdminId.isEmpty) {
      debugPrint(
        '[local-sync] repairing household primary admin '
        '"${existing.primaryAdminId}"->"$userId"',
      );
      updated = updated.copyWith(primaryAdminId: userId);
      changed = true;
    }
  }
  if (!changed) {
    return;
  }
  Future.microtask(() {
    householdsRepo.upsertHousehold(updated);
  });
}

bool _shouldRepairHouseholdName(String current, String desired) {
  if (current == desired) {
    return false;
  }
  final trimmed = current.trim();
  if (trimmed.isEmpty) {
    return true;
  }
  return _isPlaceholderHouseholdName(trimmed);
}

bool _isPlaceholderHouseholdName(String value) {
  return value == 'Household' || value == 'Gospodarstwo';
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i += 1) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

bool _shouldUpsertProfile({
  required LocalProfile localProfile,
  required String householdId,
  required UserProfile? existing,
}) {
  if (localProfile.householdId != householdId) {
    return true;
  }
  if (existing == null) {
    return true;
  }
  return existing.displayName != localProfile.displayName ||
      existing.role != localProfile.role ||
      existing.householdId != householdId;
}
