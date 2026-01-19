import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../providers/user_providers.dart';
import 'app_config.dart';
import 'app_config_repository.dart';

class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier(this._repository) : super(_repository.load());

  final AppConfigRepository _repository;

  Future<void> completeOnboardingAsAdmin({String? joinCode}) async {
    final code = joinCode ?? _generateJoinCode();
    final config = state.copyWith(
      onboardingComplete: true,
      role: UserRole.admin,
      userId: _newId(),
      householdId: code,
      joinCode: code,
      notificationsEnabled: state.notificationsEnabled,
      dailyDigestEnabled: state.dailyDigestEnabled,
      localeCode: state.localeCode,
    );
    state = config;
    await _repository.save(config);
  }

  Future<void> completeOnboardingAsMember(String joinCode) async {
    final config = state.copyWith(
      onboardingComplete: true,
      role: UserRole.member,
      userId: _newId(),
      householdId: joinCode,
      joinCode: joinCode,
      notificationsEnabled: state.notificationsEnabled,
      dailyDigestEnabled: state.dailyDigestEnabled,
      localeCode: state.localeCode,
    );
    state = config;
    await _repository.save(config);
  }

  Future<void> reset() async {
    final config = AppConfig(
      onboardingComplete: false,
      role: null,
      userId: null,
      householdId: null,
      joinCode: null,
      notificationsEnabled: false,
      dailyDigestEnabled: false,
      localeCode: state.localeCode,
    );
    state = config;
    await _repository.save(config);
  }

  Future<String> regenerateJoinCode() async {
    final code = _generateJoinCode();
    final config = state.copyWith(
      joinCode: code,
      householdId: code,
    );
    state = config;
    await _repository.save(config);
    return code;
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

  Future<void> setActiveUser({
    required UserRole role,
    required String userId,
  }) async {
    final config = state.copyWith(
      role: role,
      userId: userId,
      dailyDigestEnabled: state.dailyDigestEnabled,
      localeCode: state.localeCode,
    );
    state = config;
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
