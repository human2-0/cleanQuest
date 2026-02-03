import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../providers/user_providers.dart';
import 'app_config.dart';
import 'app_config_repository.dart';

class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier(this._repository) : super(_repository.load()) {
    Future.microtask(_migrateActiveDisplayNameUserId);
  }

  final AppConfigRepository _repository;

  Future<String> completeOnboardingAsAdmin({
    String? joinCode,
    String? userId,
    String? displayName,
    String? householdName,
  }) async {
    final code = joinCode ?? _generateJoinCode();
    final resolvedUserId = userId ?? _newId();
    final config = state.copyWith(
      onboardingComplete: true,
      role: UserRole.admin,
      userId: resolvedUserId,
      householdId: code,
      householdName: householdName ?? state.householdName,
      joinCode: code,
      draftUserId: null,
      draftDisplayName: null,
      activeDisplayName: displayName ?? state.activeDisplayName,
      activeDisplayNameUserId:
          displayName != null ? resolvedUserId : state.activeDisplayNameUserId,
      notificationsEnabled: state.notificationsEnabled,
      dailyDigestEnabled: state.dailyDigestEnabled,
      localeCode: state.localeCode,
      darkModeEnabled: state.darkModeEnabled,
    );
    state = config;
    debugPrint(
      '[app-config][complete-admin] userId=$resolvedUserId '
      'householdId=$code displayName="$displayName"',
    );
    await _repository.save(config);
    return resolvedUserId;
  }

  Future<String> completeOnboardingAsMember(
    String joinCode, {
    String? userId,
    String? displayName,
    String? householdName,
  }) async {
    final resolvedUserId = userId ?? _newId();
    final config = state.copyWith(
      onboardingComplete: true,
      role: UserRole.member,
      userId: resolvedUserId,
      householdId: joinCode,
      householdName: householdName ?? state.householdName,
      joinCode: joinCode,
      draftUserId: null,
      draftDisplayName: null,
      activeDisplayName: displayName ?? state.activeDisplayName,
      activeDisplayNameUserId:
          displayName != null ? resolvedUserId : state.activeDisplayNameUserId,
      notificationsEnabled: state.notificationsEnabled,
      dailyDigestEnabled: state.dailyDigestEnabled,
      localeCode: state.localeCode,
      darkModeEnabled: state.darkModeEnabled,
    );
    state = config;
    debugPrint(
      '[app-config][complete-member] userId=$resolvedUserId '
      'householdId=$joinCode displayName="$displayName"',
    );
    await _repository.save(config);
    return resolvedUserId;
  }

  Future<void> reset() async {
    debugPrint('[app-config][reset] requested\n${StackTrace.current}');
    final config = AppConfig(
      onboardingComplete: false,
      role: null,
      userId: null,
      householdId: null,
      householdName: null,
      joinCode: null,
      draftUserId: null,
      draftDisplayName: null,
      activeDisplayName: null,
      activeDisplayNameUserId: null,
      notificationsEnabled: false,
      dailyDigestEnabled: false,
      localeCode: state.localeCode,
      darkModeEnabled: state.darkModeEnabled,
    );
    state = config;
    await _repository.save(config);
  }

  Future<String> regenerateJoinCode() async {
    final code = _generateJoinCode();
    final config = state.copyWith(
      joinCode: code,
      householdId: code,
      activeDisplayName: state.activeDisplayName,
      activeDisplayNameUserId: state.activeDisplayNameUserId,
    );
    state = config;
    await _repository.save(config);
    return code;
  }

  Future<String> ensureDraftUserId() async {
    final existing = state.draftUserId;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final draftUserId = _newId();
    final config = state.copyWith(draftUserId: draftUserId);
    state = config;
    await _repository.save(config);
    return draftUserId;
  }

  Future<void> clearDraftProfile() async {
    if (state.draftUserId == null && state.draftDisplayName == null) {
      return;
    }
    final config = state.copyWith(
      draftUserId: null,
      draftDisplayName: null,
    );
    state = config;
    await _repository.save(config);
  }

  Future<void> setDraftDisplayName(String name) async {
    final trimmed = name.trim();
    final next = trimmed.isEmpty ? null : trimmed;
    if (next == state.draftDisplayName) {
      return;
    }
    final config = state.copyWith(draftDisplayName: next);
    state = config;
    await _repository.save(config);
  }

  Future<void> setActiveDisplayName(String? name) async {
    final trimmed = name?.trim();
    final next = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (next == state.activeDisplayName) {
      return;
    }
    final config = state.copyWith(
      activeDisplayName: next,
      activeDisplayNameUserId: state.userId,
    );
    state = config;
    debugPrint('[app-config][active-name] "$next"');
    await _repository.save(config);
  }

  void _migrateActiveDisplayNameUserId() {
    final name = state.activeDisplayName?.trim();
    final userId = state.userId;
    if (state.activeDisplayNameUserId != null ||
        name == null ||
        name.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      return;
    }
    final config = state.copyWith(activeDisplayNameUserId: userId);
    state = config;
    _repository.save(config);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final config = state.copyWith(
      notificationsEnabled: enabled,
      dailyDigestEnabled: enabled ? state.dailyDigestEnabled : false,
    );
    state = config;
    await _repository.save(config);
  }

  Future<void> setDailyDigestEnabled(bool enabled) async {
    final config = state.copyWith(dailyDigestEnabled: enabled);
    state = config;
    await _repository.save(config);
  }

  Future<void> setLocaleCode(String? code) async {
    final config = state.copyWith(localeCode: code);
    state = config;
    await _repository.save(config);
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    final config = state.copyWith(darkModeEnabled: enabled);
    state = config;
    await _repository.save(config);
  }

  Future<void> setActiveUser({
    required UserRole role,
    required String userId,
  }) async {
    final config = state.copyWith(
      role: role,
      userId: userId,
      activeDisplayName: state.activeDisplayName,
      activeDisplayNameUserId: state.activeDisplayNameUserId,
      dailyDigestEnabled: state.dailyDigestEnabled,
      localeCode: state.localeCode,
    );
    state = config;
    debugPrint('[app-config][active-user] role=$role userId=$userId');
    await _repository.save(config);
  }

  Future<void> setActiveProfile({
    required UserRole role,
    required String userId,
    required String householdId,
    required String joinCode,
    String? displayName,
    String? householdName,
  }) async {
    final config = state.copyWith(
      onboardingComplete: true,
      role: role,
      userId: userId,
      householdId: householdId,
      householdName: householdName ?? state.householdName,
      joinCode: joinCode,
      activeDisplayName: displayName ?? state.activeDisplayName,
      activeDisplayNameUserId:
          displayName != null ? userId : state.activeDisplayNameUserId,
      dailyDigestEnabled: state.dailyDigestEnabled,
      localeCode: state.localeCode,
    );
    state = config;
    debugPrint(
      '[app-config][active-profile] role=$role userId=$userId '
      'householdId=$householdId displayName="$displayName"',
    );
    await _repository.save(config);
  }

  String _newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  String _generateJoinCode() {
    final raw = DateTime.now().microsecondsSinceEpoch % 1000000;
    return raw.toString().padLeft(6, '0');
  }
}

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepository(Hive.box<dynamic>(appConfigBoxName));
});

final appConfigProvider =
    StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier(ref.read(appConfigRepositoryProvider));
});
