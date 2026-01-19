import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/app_config/app_config_providers.dart';
import '../../../core/localization/localization_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/providers/user_providers.dart';
import '../../approvals/application/approvals_providers.dart';
import '../../household/application/household_providers.dart';
import '../../household/domain/household.dart';
import '../../household/domain/user_profile.dart';
import '../../items/application/items_providers.dart';
import '../../items/data/completion_event_dto.dart';
import '../../items/data/item_dto.dart';
import '../../items/data/items_seeder.dart';
import '../../items/domain/item_status.dart';
import '../../notifications/presentation/notifications_log_screen.dart';
import '../../../data/hive/hive_boxes.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _copied = false;
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(appConfigProvider);
    final role = ref.watch(currentUserRoleProvider);
    final joinCode = config.joinCode ?? l10n.settingsJoinCodeNotSet;
    final notificationsEnabled = config.notificationsEnabled;
    final dailyDigestEnabled = config.dailyDigestEnabled;
    final localeCode = ref.watch(appLocaleProvider).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0.6,
            child: ListTile(
              title: Text(
                role == UserRole.admin
                    ? l10n.settingsAdminJoinCode
                    : l10n.settingsHouseholdCode,
              ),
              subtitle: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(joinCode),
                  if (_copied) ...[
                    const SizedBox(width: 8),
                    Text(
                      l10n.commonCopied,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
              trailing: IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: joinCode));
                  _setCopied();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.settingsCodeCopiedToast)),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                tooltip: l10n.commonCopy,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: notificationsEnabled,
            onChanged: (value) => _toggleNotifications(context, ref, value),
            title: Text(l10n.settingsEnableNotifications),
            subtitle: Text(l10n.settingsNotificationsSubtitle),
          ),
          SwitchListTile(
            value: dailyDigestEnabled,
            onChanged: notificationsEnabled
                ? (value) => _toggleDailyDigest(context, ref, value)
                : null,
            title: Text(l10n.settingsDailyDigest),
            subtitle: Text(l10n.settingsDailyDigestSubtitle),
          ),
          ListTile(
            title: Text(l10n.settingsLanguage),
            subtitle: Text(l10n.settingsLanguageSubtitle),
            trailing: DropdownButton<String>(
              value: localeCode,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                ref.read(appConfigProvider.notifier).setLocaleCode(value);
              },
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.languageEnglish),
                ),
                DropdownMenuItem(
                  value: 'pl',
                  child: Text(l10n.languagePolish),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsLogScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
            label: Text(l10n.settingsViewNotifications),
          ),
          if (role == UserRole.admin) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _confirmRegenerate(context, ref),
              icon: const Icon(Icons.autorenew_outlined),
              label: Text(l10n.settingsRegenerateJoinCode),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _confirmRestoreTemplates(context, ref),
              icon: const Icon(Icons.restore_outlined),
              label: Text(l10n.settingsRestoreTemplates),
            ),
          ],
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Text(
              l10n.settingsTesting,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _switchRole(context, ref, UserRole.admin),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: Text(l10n.settingsSwitchToAdmin),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _switchRole(context, ref, UserRole.member),
              icon: const Icon(Icons.person_outline),
              label: Text(l10n.settingsSwitchToMember),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, ref),
            icon: const Icon(Icons.restart_alt),
            label: Text(l10n.settingsLogOut),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsLogOutDialogTitle),
        content: Text(l10n.settingsLogOutDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsReset),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(appConfigProvider.notifier).reset();
    }
  }

  Future<void> _switchRole(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.read(appConfigProvider);
    final householdId = config.householdId;
    if (householdId == null || householdId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsNoHouseholdToSwitch)),
      );
      return;
    }
    final profilesRepository = ref.read(userProfilesRepositoryProvider);
    final householdsRepository = ref.read(householdsRepositoryProvider);
    final profiles = profilesRepository.listProfiles(householdId);
    UserProfile? profile;
    for (final entry in profiles) {
      if (entry.role == role) {
        profile = entry;
        break;
      }
    }
    if (profile == null) {
      final newId = DateTime.now().microsecondsSinceEpoch.toString();
      profile = UserProfile(
        id: newId,
        householdId: householdId,
        displayName:
            role == UserRole.admin ? l10n.commonAdmin : l10n.commonMember,
        role: role,
      );
      await profilesRepository.upsertProfile(profile);
      final household = householdsRepository.getHousehold(householdId) ??
          Household(
            id: householdId,
            name: l10n.commonUnknownHousehold,
            adminIds: const [],
            memberIds: const [],
          );
      final admins = {...household.adminIds};
      final members = {...household.memberIds};
      if (role == UserRole.admin) {
        admins.add(profile.id);
      } else {
        members.add(profile.id);
      }
      await householdsRepository.upsertHousehold(
        household.copyWith(
          adminIds: admins.toList(),
          memberIds: members.toList(),
        ),
      );
    }
    await ref
        .read(appConfigProvider.notifier)
        .setActiveUser(role: role, userId: profile.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          role == UserRole.admin
              ? l10n.settingsSwitchedToAdmin
              : l10n.settingsSwitchedToMember,
        ),
      ),
    );
  }

  Future<void> _toggleNotifications(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!value) {
      await ref.read(appConfigProvider.notifier).setNotificationsEnabled(false);
      await NotificationService.instance.cancelDailyDigest();
      return;
    }
    final granted = await NotificationService.instance.requestPermissions();
    if (!context.mounted) {
      return;
    }
    if (granted) {
      await ref.read(appConfigProvider.notifier).setNotificationsEnabled(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsNotificationsDenied)),
      );
    }
  }

  Future<void> _toggleDailyDigest(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!value) {
      await NotificationService.instance.cancelDailyDigest();
      await ref.read(appConfigProvider.notifier).setDailyDigestEnabled(false);
      return;
    }
    final granted = await NotificationService.instance.requestPermissions();
    if (!context.mounted) {
      return;
    }
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsNotificationsDenied)),
      );
      return;
    }
    final entries = ref.read(itemsBoardProvider);
    final pendingApprovals = ref.read(pendingRequestsProvider).length;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final dueToday = entries.where((entry) {
      final dueAt = entry.nextDueAt;
      return entry.status == ItemStatus.due &&
          dueAt != null &&
          dueAt.isAfter(todayStart) &&
          dueAt.isBefore(todayEnd);
    }).length;
    final overdueCount =
        entries.where((entry) => entry.status == ItemStatus.overdue).length;
    final pendingSegment =
        ref.read(currentUserRoleProvider) == UserRole.admin
            ? l10n.dailyDigestPendingSegment(pendingApprovals)
            : '';
    await NotificationService.instance.scheduleDailyDigest(
      title: l10n.dailyDigestTitle,
      body: l10n.dailyDigestBody(
        dueToday,
        overdueCount,
        pendingSegment,
      ),
    );
    await ref.read(appConfigProvider.notifier).setDailyDigestEnabled(true);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsDailyDigestScheduled)),
    );
  }

  Future<void> _confirmRegenerate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsRegenerateDialogTitle),
        content: Text(l10n.settingsRegenerateDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsRegenerate),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final code =
          await ref.read(appConfigProvider.notifier).regenerateJoinCode();
      Clipboard.setData(ClipboardData(text: code));
      _setCopied();
      if (!context.mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.settingsNewJoinCode),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(code),
              if (_copied) ...[
                const SizedBox(width: 8),
                Text(
                  l10n.commonCopied,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonDone),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsNewCodeGenerated)),
      );
    }
  }

  Future<void> _confirmRestoreTemplates(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsRestoreDialogTitle),
        content: Text(l10n.settingsRestoreDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsRestore),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final householdId = ref.read(activeHouseholdIdProvider);
      final itemsBox = Hive.box<ItemDto>(itemsBoxName);
      final eventsBox = Hive.box<CompletionEventDto>(completionEventsBoxName);
      await restoreDefaultTemplates(itemsBox, eventsBox, householdId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsTemplatesRestored)),
      );
    }
  }

  void _setCopied() {
    _copiedTimer?.cancel();
    setState(() => _copied = true);
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }
}
