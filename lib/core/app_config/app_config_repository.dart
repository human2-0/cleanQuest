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
  static const _keyJoinCode = 'joinCode';
  static const _keyNotificationsEnabled = 'notificationsEnabled';
  static const _keyDailyDigestEnabled = 'dailyDigestEnabled';
  static const _keyLocaleCode = 'localeCode';

  AppConfig load() {
    return AppConfig(
      onboardingComplete: _box.get(_keyOnboardingComplete, defaultValue: false)
          as bool,
      role: _decodeRole(_box.get(_keyRole) as String?),
      userId: _box.get(_keyUserId) as String?,
      householdId: _box.get(_keyHouseholdId) as String?,
      joinCode: _box.get(_keyJoinCode) as String?,
      notificationsEnabled:
          _box.get(_keyNotificationsEnabled, defaultValue: false) as bool,
      dailyDigestEnabled:
          _box.get(_keyDailyDigestEnabled, defaultValue: false) as bool,
      localeCode: _box.get(_keyLocaleCode) as String?,
    );
  }

  Future<void> save(AppConfig config) async {
    await _box.put(_keyOnboardingComplete, config.onboardingComplete);
    await _box.put(_keyRole, _encodeRole(config.role));
    await _box.put(_keyUserId, config.userId);
    await _box.put(_keyHouseholdId, config.householdId);
    await _box.put(_keyJoinCode, config.joinCode);
    await _box.put(_keyNotificationsEnabled, config.notificationsEnabled);
    await _box.put(_keyDailyDigestEnabled, config.dailyDigestEnabled);
    await _box.put(_keyLocaleCode, config.localeCode);
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
}
