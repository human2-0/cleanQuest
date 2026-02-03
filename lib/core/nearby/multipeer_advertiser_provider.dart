import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_config/app_config.dart';
import '../app_config/app_config_providers.dart';
import '../providers/user_providers.dart';
import '../../features/household/application/household_providers.dart';
import 'multipeer_bridge.dart';

class MultipeerAdvertiserController {
  bool _started = false;
  String _householdId = '';
  String _hostUserId = '';

  void update(AppConfig config, {required bool isPrimaryAdmin}) {
    final shouldStart = config.onboardingComplete &&
        config.role == UserRole.admin &&
        isPrimaryAdmin &&
        (config.householdId ?? '').isNotEmpty &&
        (config.userId ?? '').isNotEmpty;
    if (shouldStart) {
      final householdId = config.householdId!;
      final hostUserId = config.userId!;
      final displayName = config.activeDisplayName ?? '';
      final householdName = config.householdName ?? '';
      if (_started &&
          householdId == _householdId &&
          hostUserId == _hostUserId) {
        return;
      }
      debugPrint(
        '[multipeer][advertiser] start householdId=$householdId '
        'hostUserId=$hostUserId displayName="$displayName" '
        'householdName="$householdName"',
      );
      _started = true;
      _householdId = householdId;
      _hostUserId = hostUserId;
      MultipeerBridge.startAdvertiser(
        householdId: householdId,
        hostUserId: hostUserId,
        displayName: displayName,
        householdName: householdName,
      );
    } else if (_started) {
      debugPrint(
        '[multipeer][advertiser] stop householdId=$_householdId '
        'hostUserId=$_hostUserId',
      );
      _started = false;
      _householdId = '';
      _hostUserId = '';
      MultipeerBridge.stopAdvertiser();
    }
  }

  void dispose() {
    if (_started) {
      MultipeerBridge.stopAdvertiser();
      _started = false;
    }
  }
}

final multipeerAdvertiserProvider =
    Provider<MultipeerAdvertiserController>((ref) {
  final controller = MultipeerAdvertiserController();
  controller.update(
    ref.read(appConfigProvider),
    isPrimaryAdmin: ref.read(currentUserIsPrimaryAdminProvider),
  );
  final configSub = ref.listen<AppConfig>(appConfigProvider, (_, next) {
    controller.update(
      next,
      isPrimaryAdmin: ref.read(currentUserIsPrimaryAdminProvider),
    );
  });
  final primarySub =
      ref.listen<bool>(currentUserIsPrimaryAdminProvider, (_, __) {
    controller.update(
      ref.read(appConfigProvider),
      isPrimaryAdmin: ref.read(currentUserIsPrimaryAdminProvider),
    );
  });
  ref.onDispose(() {
    configSub.close();
    primarySub.close();
    controller.dispose();
  });
  return controller;
});
