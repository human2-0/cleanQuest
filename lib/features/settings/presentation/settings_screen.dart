import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:bonsoir/bonsoir.dart';

import '../../../core/app_config/app_config_providers.dart';
import '../../../core/app_config/app_config.dart';
import '../../../core/localization/localization_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/profiles/local_profiles_providers.dart';
import '../../../core/profiles/local_profile.dart';
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

class _DiscoveredHousehold {
  const _DiscoveredHousehold({
    required this.householdId,
    required this.hostUserId,
  });

  final String householdId;
  final String hostUserId;
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _copied = false;
  Timer? _copiedTimer;
  bool _profileSeeded = false;

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
    final localProfiles = ref.watch(localProfilesProvider).value ?? <LocalProfile>[];
    final currentLocalProfile = ref.watch(currentLocalProfileProvider);
    final notificationsEnabled = config.notificationsEnabled;
    final dailyDigestEnabled = config.dailyDigestEnabled;
    final darkModeEnabled = config.darkModeEnabled;
    final localeCode = ref.watch(appLocaleProvider).languageCode;
    if (!_profileSeeded) {
      _profileSeeded = true;
      _ensureLocalProfileSeed(ref, config);
    }

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
          const SizedBox(height: 16),
          Text(
            l10n.settingsProfilesTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0.6,
            child: ListTile(
              title: Text(
                currentLocalProfile?.displayName ?? l10n.commonUnknown,
              ),
              subtitle: Text(
                currentLocalProfile == null
                    ? l10n.settingsProfilesNoActive
                    : '${_roleLabel(l10n, currentLocalProfile.role)} • ${currentLocalProfile.householdId}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: currentLocalProfile == null
                        ? null
                        : () => _renameProfile(context, ref, currentLocalProfile),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_outlined),
                    onPressed: localProfiles.isEmpty
                        ? null
                        : () => _showProfileSwitcher(context, ref, localProfiles),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddProfile(context, ref),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(l10n.settingsProfilesAdd),
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
          SwitchListTile(
            value: darkModeEnabled,
            onChanged: (value) =>
                ref.read(appConfigProvider.notifier).setDarkModeEnabled(value),
            title: Text(l10n.settingsDarkMode),
            subtitle: Text(l10n.settingsDarkModeSubtitle),
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
      await ref.read(localProfilesRepositoryProvider).clear();
      await ref.read(appConfigProvider.notifier).reset();
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _roleLabel(AppLocalizations l10n, UserRole role) {
    return role == UserRole.admin ? l10n.commonAdmin : l10n.commonMember;
  }

  Future<void> _showProfileSwitcher(
    BuildContext context,
    WidgetRef ref,
    List<LocalProfile> profiles,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(currentLocalProfileProvider);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l10n.settingsProfilesSwitchTitle),
            ),
            for (final profile in profiles)
              ListTile(
                title: Text(profile.displayName),
                subtitle: Text(
                  '${_roleLabel(l10n, profile.role)} • ${profile.householdId}',
                ),
                trailing: profile.id == current?.id &&
                        profile.householdId == current?.householdId
                    ? const Icon(Icons.check_circle_outline)
                    : null,
                onTap: () async {
                  Navigator.of(context).pop();
                  await _switchToProfile(ref, profile);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddProfile(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l10n.settingsProfilesCreateTitle),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: Text(l10n.settingsProfilesCreateAdmin),
              onTap: () async {
                Navigator.of(context).pop();
                await _createAdminProfile(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: Text(l10n.settingsProfilesJoinHousehold),
              onTap: () async {
                Navigator.of(context).pop();
                await _createMemberProfile(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameProfile(
    BuildContext context,
    WidgetRef ref,
    LocalProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: profile.displayName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsProfilesRenameTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.settingsProfilesDisplayName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final name = controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    final updated = profile.copyWith(displayName: name);
    await ref.read(localProfilesRepositoryProvider).upsertProfile(updated);
    await ref.read(userProfilesRepositoryProvider).upsertProfile(
          UserProfile(
            id: profile.id,
            householdId: profile.householdId,
            displayName: name,
            role: profile.role,
          ),
        );
  }

  Future<void> _createAdminProfile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final householdController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsProfilesCreateAdmin),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.settingsProfilesDisplayName,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: householdController,
              decoration: InputDecoration(
                labelText: l10n.settingsProfilesHouseholdName,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsProfilesCreate),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final displayName = nameController.text.trim().isEmpty
        ? l10n.commonAdmin
        : nameController.text.trim();
    final householdName = householdController.text.trim().isEmpty
        ? l10n.commonUnknownHousehold
        : householdController.text.trim();
    final code = _generateJoinCode();
    final userId = DateTime.now().microsecondsSinceEpoch.toString();
    final profile = LocalProfile(
      id: userId,
      displayName: displayName,
      role: UserRole.admin,
      householdId: code,
      joinCode: code,
    );
    final householdsRepository = ref.read(householdsRepositoryProvider);
    final profilesRepository = ref.read(userProfilesRepositoryProvider);
    await householdsRepository.upsertHousehold(
      Household(
        id: code,
        name: householdName,
        adminIds: [userId],
        memberIds: const [],
        primaryAdminId: userId,
        secondaryAdminId: null,
        adminEpoch: 0,
      ),
    );
    await profilesRepository.upsertProfile(
      UserProfile(
        id: userId,
        householdId: code,
        displayName: displayName,
        role: UserRole.admin,
      ),
    );
    await ref.read(localProfilesRepositoryProvider).upsertProfile(profile);
    await ref.read(appConfigProvider.notifier).setActiveProfile(
          role: UserRole.admin,
          userId: userId,
          householdId: code,
          joinCode: code,
          displayName: displayName,
          householdName: householdName,
        );
    await _seedForHousehold(code, isAdmin: true);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.settingsProfilesCodeLabel}: $code')),
    );
  }

  Future<void> _createMemberProfile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    var isDiscovering = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.settingsProfilesJoinHousehold),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.settingsProfilesDisplayName,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: l10n.settingsProfilesJoinCode,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: isDiscovering
                      ? null
                      : () async {
                          setState(() => isDiscovering = true);
                          final code =
                              await _pickNearbyHousehold(context);
                          setState(() => isDiscovering = false);
                          if (code != null) {
                            codeController.text = code;
                          }
                        },
                  icon: const Icon(Icons.wifi_tethering_outlined),
                  label: Text(l10n.settingsProfilesFindNearby),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.settingsProfilesCreate),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      return;
    }
    final code = codeController.text.trim();
    final displayName = nameController.text.trim();
    if (displayName.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileNameRequired)),
        );
      }
      return;
    }
    if (code.length != 6) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.onboardingCodeLength)),
        );
      }
      return;
    }
    final userId = DateTime.now().microsecondsSinceEpoch.toString();
    final profile = LocalProfile(
      id: userId,
      displayName: displayName,
      role: UserRole.member,
      householdId: code,
      joinCode: code,
    );
    final householdsRepository = ref.read(householdsRepositoryProvider);
    final profilesRepository = ref.read(userProfilesRepositoryProvider);
    final household = householdsRepository.getHousehold(code);
    if (household == null) {
      await householdsRepository.upsertHousehold(
        Household(
          id: code,
          name: l10n.commonUnknownHousehold,
          adminIds: const [],
          memberIds: [userId],
          primaryAdminId: '',
          secondaryAdminId: null,
          adminEpoch: 0,
        ),
      );
    } else {
      final members = {...household.memberIds, userId}.toList();
      await householdsRepository.upsertHousehold(
        household.copyWith(memberIds: members),
      );
    }
    await profilesRepository.upsertProfile(
      UserProfile(
        id: userId,
        householdId: code,
        displayName: displayName,
        role: UserRole.member,
      ),
    );
    await ref.read(localProfilesRepositoryProvider).upsertProfile(profile);
    await ref.read(appConfigProvider.notifier).setActiveProfile(
          role: UserRole.member,
          userId: userId,
          householdId: code,
          joinCode: code,
          displayName: displayName,
        );
  }

  Future<void> _switchToProfile(WidgetRef ref, LocalProfile profile) async {
    await ref.read(appConfigProvider.notifier).setActiveProfile(
          role: profile.role,
          userId: profile.id,
          householdId: profile.householdId,
          joinCode: profile.joinCode,
          displayName: profile.displayName,
        );
    await _ensureUserProfile(ref, profile);
  }

  Future<void> _ensureUserProfile(
    WidgetRef ref,
    LocalProfile profile,
  ) async {
    final profilesRepository = ref.read(userProfilesRepositoryProvider);
    final existing = profilesRepository.getProfile(profile.id);
    if (existing != null) {
      return;
    }
    final householdsRepository = ref.read(householdsRepositoryProvider);
    final household = householdsRepository.getHousehold(profile.householdId);
    if (household == null) {
      final l10n = ref.read(appLocalizationsProvider);
      await householdsRepository.upsertHousehold(
        Household(
          id: profile.householdId,
          name: l10n.commonUnknownHousehold,
          adminIds: const [],
          memberIds: [profile.id],
          primaryAdminId: '',
          secondaryAdminId: null,
          adminEpoch: 0,
        ),
      );
    }
    await profilesRepository.upsertProfile(
      UserProfile(
        id: profile.id,
        householdId: profile.householdId,
        displayName: profile.displayName,
        role: profile.role,
      ),
    );
  }

  Future<String?> _pickNearbyHousehold(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final households = await _discoverHouseholds();
    if (households.isEmpty) {
      if (!context.mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsProfilesNoNearby)),
      );
      return null;
    }
    if (!context.mounted) {
      return null;
    }
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l10n.settingsProfilesNearbyTitle),
            ),
            for (final item in households)
              ListTile(
                title: Text(item.householdId),
                subtitle: Text(item.hostUserId),
                onTap: () => Navigator.of(context).pop(item.householdId),
              ),
          ],
        ),
      ),
    );
  }

  Future<List<_DiscoveredHousehold>> _discoverHouseholds() async {
    final discovery = BonsoirDiscovery(type: '_cleanquest._tcp');
    await discovery.ready;
    final results = <String, _DiscoveredHousehold>{};
    final sub = discovery.eventStream?.listen((event) {
      if (event.type != BonsoirDiscoveryEventType.discoveryServiceResolved) {
        return;
      }
      final service = event.service;
      if (service is! ResolvedBonsoirService) {
        return;
      }
      final attributes = service.attributes;
      final householdId = attributes['householdId'];
      final hostUserId = attributes['hostUserId'] ?? 'Host';
      _logDiscovery(
        'bonjour peer householdId=$householdId hostUserId=$hostUserId '
        'service=${service.name}',
      );
      if (householdId == null || householdId.isEmpty) {
        _logDiscovery('bonjour resolved missing householdId');
        return;
      }
      results[householdId] = _DiscoveredHousehold(
        householdId: householdId,
        hostUserId: hostUserId,
      );
    });
    await discovery.start();
    await Future<void>.delayed(const Duration(seconds: 2));
    await discovery.stop();
    await sub?.cancel();
    return results.values.toList();
  }

  void _logDiscovery(String message) {
    if (kDebugMode) {
      debugPrint('[settings][discovery] $message');
    }
  }

  Future<void> _seedForHousehold(
    String householdId, {
    required bool isAdmin,
  }) async {
    if (!isAdmin) {
      return;
    }
    final itemsBox = Hive.box<ItemDto>(itemsBoxName);
    final eventsBox = Hive.box<CompletionEventDto>(completionEventsBoxName);
    await seedItemsIfEmpty(itemsBox, householdId);
    await seedCompletionEventsIfEmpty(eventsBox, householdId);
  }

  String _generateJoinCode() {
    final raw = DateTime.now().microsecondsSinceEpoch % 1000000;
    return raw.toString().padLeft(6, '0');
  }

  void _ensureLocalProfileSeed(WidgetRef ref, AppConfig config) {
    final userId = config.userId;
    final householdId = config.householdId;
    final role = config.role;
    if (!config.onboardingComplete ||
        userId == null ||
        householdId == null ||
        role == null) {
      return;
    }
    final repo = ref.read(localProfilesRepositoryProvider);
    final existing = repo.getProfile(userId);
    if (existing != null) {
      return;
    }
    final profile = LocalProfile(
      id: userId,
      displayName: userId,
      role: role,
      householdId: householdId,
      joinCode: config.joinCode ?? householdId,
    );
    Future.microtask(() => repo.upsertProfile(profile));
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
            primaryAdminId: '',
            secondaryAdminId: null,
            adminEpoch: 0,
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
          primaryAdminId: _resolvePrimaryAdmin(
            household: household,
            role: role,
            userId: profile.id,
          ),
          secondaryAdminId: _resolveSecondaryAdmin(
            household: household,
            role: role,
            userId: profile.id,
          ),
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

  String _resolvePrimaryAdmin({
    required Household household,
    required UserRole role,
    required String userId,
  }) {
    if (role != UserRole.admin) {
      return household.primaryAdminId;
    }
    if (household.primaryAdminId.isNotEmpty) {
      return household.primaryAdminId;
    }
    return userId;
  }

  String? _resolveSecondaryAdmin({
    required Household household,
    required UserRole role,
    required String userId,
  }) {
    if (role != UserRole.admin) {
      return household.secondaryAdminId;
    }
    if (household.primaryAdminId.isEmpty) {
      return household.secondaryAdminId;
    }
    if (household.secondaryAdminId != null &&
        household.secondaryAdminId!.isNotEmpty) {
      return household.secondaryAdminId;
    }
    if (household.primaryAdminId != userId) {
      return userId;
    }
    return household.secondaryAdminId;
  }
}
