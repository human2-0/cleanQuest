import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_config/app_config_providers.dart';

enum UserRole {
  admin,
  member,
}

final currentUserRoleProvider = Provider<UserRole>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.role ?? UserRole.member;
});

final currentUserIdProvider = Provider<String>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.userId ?? 'unknown-user';
});
