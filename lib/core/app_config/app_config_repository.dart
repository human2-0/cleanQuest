import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../providers/user_providers.dart';
import 'app_config.dart';

const appConfigBoxName = 'appConfigBox';

class AppConfigRepository {
  AppConfigRepository(this._box);

  final Box<dynamic> _box;

  static const _keyOnboardingComplete = 'onboardingComplete';
  static const _keyRole = 'role';
  static const _keyUserId = 'userId';
  static const _keyHouseholdId = 'householdId';
  static const _keyHouseholdName = 'householdName';
  static const _keyJoinCode = 'joinCode';
  static const _keyDraftUserId = 'draftUserId';
  static const _keyDraftDisplayName = 'draftDisplayName';
  static const _keyActiveDisplayName = 'activeDisplayName';
  static const _keyActiveDisplayNameUserId = 'activeDisplayNameUserId';
  static const _keyNotificationsEnabled = 'notificationsEnabled';
  static const _keyDailyDigestEnabled = 'dailyDigestEnabled';
  static const _keyLocaleCode = 'localeCode';
  static const _keyDarkModeEnabled = 'darkModeEnabled';

  AppConfig load() {
    final config = AppConfig(
      onboardingComplete: _box.get(_keyOnboardingComplete, defaultValue: false)
          as bool,
      role: _decodeRole(_box.get(_keyRole) as String?),
      userId: _box.get(_keyUserId) as String?,
      householdId: _box.get(_keyHouseholdId) as String?,
      householdName: _box.get(_keyHouseholdName) as String?,
      joinCode: _box.get(_keyJoinCode) as String?,
      draftUserId: _box.get(_keyDraftUserId) as String?,
      draftDisplayName: _box.get(_keyDraftDisplayName) as String?,
      activeDisplayName: _box.get(_keyActiveDisplayName) as String?,
      activeDisplayNameUserId:
          _box.get(_keyActiveDisplayNameUserId) as String?,
      notificationsEnabled:
          _box.get(_keyNotificationsEnabled, defaultValue: false) as bool,
      dailyDigestEnabled:
          _box.get(_keyDailyDigestEnabled, defaultValue: false) as bool,
      localeCode: _box.get(_keyLocaleCode) as String?,
      darkModeEnabled:
          _box.get(_keyDarkModeEnabled, defaultValue: false) as bool,
    );
    _logConfig('load', config);
    return config;
  }

  Future<void> save(AppConfig config) async {
    _logConfig('save', config);
    await _box.put(_keyOnboardingComplete, config.onboardingComplete);
    await _box.put(_keyRole, _encodeRole(config.role));
    await _box.put(_keyUserId, config.userId);
    await _box.put(_keyHouseholdId, config.householdId);
    await _box.put(_keyHouseholdName, config.householdName);
    await _box.put(_keyJoinCode, config.joinCode);
    await _box.put(_keyDraftUserId, config.draftUserId);
    await _box.put(_keyDraftDisplayName, config.draftDisplayName);
    await _box.put(_keyActiveDisplayName, config.activeDisplayName);
    await _box.put(
      _keyActiveDisplayNameUserId,
      config.activeDisplayNameUserId,
    );
    await _box.put(_keyNotificationsEnabled, config.notificationsEnabled);
    await _box.put(_keyDailyDigestEnabled, config.dailyDigestEnabled);
    await _box.put(_keyLocaleCode, config.localeCode);
    await _box.put(_keyDarkModeEnabled, config.darkModeEnabled);
  }

  String? _encodeRole(UserRole? role) {
    return role?.name;
  }

  UserRole? _decodeRole(String? value) {
    if (value == null) {
      return null;
    }
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.member,
    );
  }

  void _logConfig(String label, AppConfig config) {
    debugPrint(
      '[app-config][$label] onboarding=${config.onboardingComplete} '
      'role=${config.role} userId=${config.userId} '
      'householdId=${config.householdId} '
      'householdName=${config.householdName} joinCode=${config.joinCode} '
      'draftUserId=${config.draftUserId} draftName=${config.draftDisplayName} '
      'activeName=${config.activeDisplayName} '
      'activeNameUserId=${config.activeDisplayNameUserId}',
    );
  }
}
