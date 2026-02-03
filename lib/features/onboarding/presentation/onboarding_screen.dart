import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/app_config/app_config_providers.dart';
import '../../../core/nearby/multipeer_bridge.dart';
import '../../../core/profiles/local_profile.dart';
import '../../../core/profiles/local_profiles_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../data/hive/hive_boxes.dart';
import '../../../l10n/app_localizations.dart';
import '../../household/application/household_providers.dart';
import '../../household/domain/household.dart';
import '../../household/domain/user_profile.dart';
import '../../items/data/completion_event_dto.dart';
import '../../items/data/item_dto.dart';
import '../../items/data/items_seeder.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _OnboardingMode _mode = _OnboardingMode.create;
  final _joinCodeController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _householdNameController = TextEditingController();
  final Map<String, _DiscoveredHousehold> _discoveredHouseholds = {};
  String? _adminJoinCode;
  String? _errorText;
  bool _isDiscovering = false;
  String? _discoveryStatus;
  final List<String> _discoveryLog = [];
  String _savedName = '';
  bool _profileReady = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(appConfigProvider);
    final draft = config.draftDisplayName;
    if (draft != null && draft.isNotEmpty) {
      _displayNameController.text = draft;
      _savedName = draft;
      _profileReady =
          config.draftUserId != null && config.draftUserId!.isNotEmpty;
    }
    _displayNameController.addListener(_handleNameEdited);
  }

  @override
  void dispose() {
    _displayNameController.removeListener(_handleNameEdited);
    _joinCodeController.dispose();
    _displayNameController.dispose();
    _householdNameController.dispose();
    super.dispose();
  }

  void _handleNameEdited() {
    final next = _displayNameController.text.trim();
    if (next == _savedName || !_profileReady) {
      return;
    }
    setState(() => _profileReady = false);
  }

  Future<void> _saveProfile(UserRole role) async {
    final name = _displayNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileNameRequired)),
      );
      return;
    }
    final notifier = ref.read(appConfigProvider.notifier);
    final repo = ref.read(localProfilesRepositoryProvider);
    final userId = await notifier.ensureDraftUserId();
    await notifier.setDraftDisplayName(name);
    await repo.upsertProfile(
      LocalProfile(
        id: userId,
        displayName: name,
        role: role,
        householdId: '',
        joinCode: '',
      ),
    );
    debugPrint(
      '[onboarding] saved draft profile '
      'userId=$userId role=$role displayName="$name"',
    );
    if (mounted) {
      setState(() {
        _savedName = name;
        _profileReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.onboardingChooseRole,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(l10n.onboardingRoleSubtitle),
          const SizedBox(height: 16),
          SegmentedButton<_OnboardingMode>(
            segments: [
              ButtonSegment(
                value: _OnboardingMode.create,
                label: Text(l10n.onboardingCreateHouseholdLabel),
              ),
              ButtonSegment(
                value: _OnboardingMode.join,
                label: Text(l10n.onboardingJoinHouseholdLabel),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (value) {
              setState(() {
                _mode = value.first;
                if (_mode == _OnboardingMode.create &&
                    _adminJoinCode == null) {
                  _adminJoinCode = _generateJoinCode();
                }
                _errorText = null;
                _profileReady = false;
              });
            },
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _displayNameController,
            decoration: InputDecoration(labelText: l10n.onboardingYourName),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _saveProfile(
              _mode == _OnboardingMode.create
                  ? UserRole.admin
                  : UserRole.member,
            ),
            child: Text(l10n.commonSave),
          ),
          const SizedBox(height: 24),
          if (_mode == _OnboardingMode.create && _profileReady) ...[
            TextField(
              controller: _householdNameController,
              decoration:
                  InputDecoration(labelText: l10n.onboardingHouseholdName),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.onboardingShareCode,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _AdminCodeCard(
              code: _adminJoinCode ?? _generateJoinCode(),
              onGenerate: (code) => setState(() => _adminJoinCode = code),
            ),
            const SizedBox(height: 16),
            _QrJoinCodeCard(
              code: _adminJoinCode ?? _generateJoinCode(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final code = _adminJoinCode ?? _generateJoinCode();
                if (!_profileReady) {
                  return;
                }
                final displayName = _savedName;
                final name = _householdNameController.text.trim().isEmpty
                    ? l10n.commonUnknownHousehold
                    : _householdNameController.text.trim();
                final localProfilesRepo =
                    ref.read(localProfilesRepositoryProvider);
                final householdsRepository =
                    ref.read(householdsRepositoryProvider);
                final profilesRepository =
                    ref.read(userProfilesRepositoryProvider);
                final configNotifier = ref.read(appConfigProvider.notifier);
                final draftUserId = ref.read(appConfigProvider).draftUserId;
                final userId =
                    draftUserId ?? await configNotifier.ensureDraftUserId();
                final existing = householdsRepository.getHousehold(code);
                final admins = {
                  ...?existing?.adminIds,
                  userId,
                }.toList();
                final members = existing?.memberIds ?? <String>[];
                await householdsRepository.upsertHousehold(
                  Household(
                    id: code,
                    name: name,
                    adminIds: admins,
                    memberIds: members,
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
                await localProfilesRepo.upsertProfile(
                  LocalProfile(
                    id: userId,
                    displayName: displayName,
                    role: UserRole.admin,
                    householdId: code,
                    joinCode: code,
                  ),
                );
                await _seedForHousehold(code, isAdmin: true);
                await configNotifier.completeOnboardingAsAdmin(
                  joinCode: code,
                  userId: userId,
                  displayName: displayName,
                  householdName: name,
                );
                debugPrint(
                  '[onboarding] completed admin onboarding '
                  'userId=$userId householdId=$code displayName="$displayName"',
                );
              },
              child: Text(l10n.onboardingFinishSetup),
            ),
          ],
          if (_mode == _OnboardingMode.join && _profileReady) ...[
            TextField(
              controller: _joinCodeController,
              decoration: InputDecoration(
                labelText: l10n.onboardingAdminCodeLabel,
                errorText: _errorText,
              ),
              keyboardType: TextInputType.number,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _isDiscovering
                    ? null
                    : () async {
                        setState(() => _isDiscovering = true);
                        final code = await _pickNearbyHousehold(context);
                        if (code != null) {
                          setState(() => _joinCodeController.text = code);
                        }
                        if (mounted) {
                          setState(() => _isDiscovering = false);
                        }
                      },
                icon: const Icon(Icons.wifi_tethering_outlined),
                label: Text(l10n.settingsProfilesFindNearby),
              ),
            ),
            const SizedBox(height: 8),
            _DiscoveryStatusCard(
              status: _discoveryStatus ?? l10n.settingsProfilesDiscoveryIdle,
              entries: _discoveryLog,
              isActive: _isDiscovering,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final code = _joinCodeController.text.trim();
                if (!_profileReady) {
                  return;
                }
                if (code.isEmpty) {
                  setState(() => _errorText = l10n.onboardingCodeRequired);
                  return;
                }
                if (code.length != 6) {
                  setState(() => _errorText = l10n.onboardingCodeLength);
                  return;
                }
                final displayName = _savedName;
                final discovered = _discoveredHouseholds[code];
                final discoveredHouseholdName =
                    discovered?.householdName?.trim();
                final localProfilesRepo =
                    ref.read(localProfilesRepositoryProvider);
                final householdsRepository =
                    ref.read(householdsRepositoryProvider);
                final profilesRepository =
                    ref.read(userProfilesRepositoryProvider);
                final configNotifier = ref.read(appConfigProvider.notifier);
                final draftUserId = ref.read(appConfigProvider).draftUserId;
                final userId =
                    draftUserId ?? await configNotifier.ensureDraftUserId();
                final household = householdsRepository.getHousehold(code);
                if (household == null) {
                  await householdsRepository.upsertHousehold(
                    Household(
                      id: code,
                      name: (discoveredHouseholdName == null ||
                              discoveredHouseholdName.isEmpty)
                          ? l10n.commonUnknownHousehold
                          : discoveredHouseholdName,
                      adminIds: const [],
                      memberIds: [userId],
                      primaryAdminId: '',
                      secondaryAdminId: null,
                      adminEpoch: 0,
                    ),
                  );
                } else {
                  final members = {...household.memberIds, userId}.toList();
                  var updated = household.copyWith(memberIds: members);
                  if ((updated.name == l10n.commonUnknownHousehold ||
                          updated.name.trim().isEmpty) &&
                      discoveredHouseholdName != null &&
                      discoveredHouseholdName.isNotEmpty) {
                    updated =
                        updated.copyWith(name: discoveredHouseholdName);
                  }
                  await householdsRepository.upsertHousehold(updated);
                }
                await profilesRepository.upsertProfile(
                  UserProfile(
                    id: userId,
                    householdId: code,
                    displayName: displayName,
                    role: UserRole.member,
                  ),
                );
                final hostUserId = discovered?.hostUserId;
                if (hostUserId != null && hostUserId.isNotEmpty) {
                  final hostDisplayName =
                      discovered?.hostDisplayName?.trim();
                  final hostName = (hostDisplayName == null ||
                          hostDisplayName.isEmpty)
                      ? hostUserId
                      : hostDisplayName;
                  if (profilesRepository.getProfile(hostUserId) == null) {
                    await profilesRepository.upsertProfile(
                      UserProfile(
                        id: hostUserId,
                        householdId: code,
                        displayName: hostName,
                        role: UserRole.admin,
                      ),
                    );
                  }
                }
                await localProfilesRepo.upsertProfile(
                  LocalProfile(
                    id: userId,
                    displayName: displayName,
                    role: UserRole.member,
                    householdId: code,
                    joinCode: code,
                  ),
                );
                await _seedForHousehold(code, isAdmin: false);
                await configNotifier.completeOnboardingAsMember(
                  code,
                  userId: userId,
                  displayName: displayName,
                  householdName: discoveredHouseholdName,
                );
                debugPrint(
                  '[onboarding] completed member onboarding '
                  'userId=$userId householdId=$code displayName="$displayName"',
                );
              },
              child: Text(l10n.onboardingJoinHousehold),
            ),
          ],
        ],
      ),
    );
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

  Future<String?> _pickNearbyHousehold(BuildContext context) async {
    if (mounted) {
      setState(() => _discoveryLog.clear());
      _setDiscoveryStatus(AppLocalizations.of(context)!.settingsProfilesDiscoveryStarting);
    }
    final households = await _discoverHouseholds();
    _discoveredHouseholds
      ..clear()
      ..addEntries(
        households.map((item) => MapEntry(item.householdId, item)),
      );
    if (households.isEmpty) {
      if (!context.mounted) {
        return null;
      }
      _setDiscoveryStatus(
        AppLocalizations.of(context)!.settingsProfilesDiscoveryNone,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.settingsProfilesNoNearby),
        ),
      );
      return null;
    }
    if (!context.mounted) {
      return null;
    }
    _setDiscoveryStatus(
      AppLocalizations.of(context)!.settingsProfilesDiscoveryFound(
        households.length,
      ),
    );
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.settingsProfilesNearbyTitle,
              ),
            ),
            for (final item in households)
              ListTile(
                title: Text(item.householdId),
                subtitle: Text(item.hostLabel),
                onTap: () => Navigator.of(context).pop(item.householdId),
              ),
          ],
        ),
      ),
    );
  }

  Future<List<_DiscoveredHousehold>> _discoverHouseholds() async {
    if (!mounted) {
      return [];
    }
    final l10n = AppLocalizations.of(context)!;
    final results = <String, _DiscoveredHousehold>{};
    _setDiscoveryStatus(l10n.settingsProfilesDiscoveryScanning);
    if (Platform.isIOS) {
      _logDiscovery('multipeer: browse start');
      final peers = await MultipeerBridge.browseNearby(
        timeout: const Duration(seconds: 4),
      );
      _logDiscovery('multipeer: found ${peers.length}');
      for (final peer in peers) {
        final householdId = peer['householdId'];
        final hostDisplayName = peer['displayName'];
        final hostUserId =
            peer['hostUserId'] ?? peer['peerName'] ?? 'Host';
        final householdName = peer['householdName'];
        _logDiscovery(
          'multipeer peer householdId=$householdId hostUserId=$hostUserId '
          'displayName="$hostDisplayName" householdName="$householdName"',
        );
        if (householdId == null || householdId.isEmpty) {
          _logDiscovery('multipeer resolved missing householdId');
          continue;
        }
        _logDiscovery('multipeer resolved household $householdId');
        results[householdId] = _DiscoveredHousehold(
          householdId: householdId,
          hostUserId: hostUserId,
          hostDisplayName: hostDisplayName,
          householdName: householdName,
        );
      }
      await _discoverBonjour(results);
      _setDiscoveryStatus(l10n.settingsProfilesDiscoveryFinished);
      return results.values.toList();
    }
    await _discoverBonjour(results);
    _setDiscoveryStatus(l10n.settingsProfilesDiscoveryFinished);
    return results.values.toList();
  }

  Future<void> _discoverBonjour(
    Map<String, _DiscoveredHousehold> results,
  ) async {
    _logDiscovery('bonjour: browse start');
    final discovery = BonsoirDiscovery(type: '_cleanquest._tcp');
    await discovery.ready;
    final sub = discovery.eventStream?.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        event.service?.resolve(discovery.serviceResolver);
        _logDiscovery(
          'bonjour service found: ${event.service?.name ?? "unknown"}',
        );
        return;
      }
      if (event.type != BonsoirDiscoveryEventType.discoveryServiceResolved) {
        _logDiscovery('bonjour event: ${event.type}');
        return;
      }
      final service = event.service;
      if (service is! ResolvedBonsoirService) {
        _logDiscovery('bonjour resolved event without host');
        return;
      }
      final attributes = service.attributes;
      final householdId = attributes['householdId'];
      final hostDisplayName = attributes['hostDisplayName'];
      final hostUserId = attributes['hostUserId'] ?? 'Host';
      final householdName = attributes['householdName'];
      _logDiscovery(
        'bonjour peer householdId=$householdId hostUserId=$hostUserId '
        'displayName="$hostDisplayName" householdName="$householdName"',
      );
      if (householdId == null || householdId.isEmpty) {
        _logDiscovery('bonjour resolved missing householdId');
        return;
      }
      _logDiscovery('bonjour resolved household $householdId');
      results[householdId] = _DiscoveredHousehold(
        householdId: householdId,
        hostUserId: hostUserId,
        hostDisplayName: hostDisplayName,
        householdName: householdName,
      );
    });
    await discovery.start();
    await Future<void>.delayed(const Duration(seconds: 4));
    await discovery.stop();
    await sub?.cancel();
    _logDiscovery('bonjour: browse finished (${results.length} total)');
  }

  void _setDiscoveryStatus(String status) {
    if (!mounted) {
      return;
    }
    setState(() => _discoveryStatus = status);
  }

  void _logDiscovery(String message) {
    if (!mounted) {
      return;
    }
    final stamp =
        TimeOfDay.fromDateTime(DateTime.now()).format(context);
    debugPrint('[discovery][$stamp] $message');
    setState(() {
      _discoveryLog.add('[$stamp] $message');
      if (_discoveryLog.length > 6) {
        _discoveryLog.removeRange(0, _discoveryLog.length - 6);
      }
    });
  }
}

class _DiscoveredHousehold {
  const _DiscoveredHousehold({
    required this.householdId,
    required this.hostUserId,
    this.hostDisplayName,
    this.householdName,
  });

  final String householdId;
  final String hostUserId;
  final String? hostDisplayName;
  final String? householdName;

  String get hostLabel {
    final display = hostDisplayName?.trim();
    if (display != null && display.isNotEmpty) {
      return display;
    }
    return hostUserId;
  }
}

enum _OnboardingMode {
  create,
  join,
}

class _AdminCodeCard extends StatefulWidget {
  const _AdminCodeCard({required this.code, required this.onGenerate});

  final String code;
  final ValueChanged<String> onGenerate;

  @override
  State<_AdminCodeCard> createState() => _AdminCodeCardState();
}

class _QrJoinCodeCard extends StatelessWidget {
  const _QrJoinCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      elevation: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.onboardingQrTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Center(
              child: QrImageView(
                data: code,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.onboardingQrHint,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryStatusCard extends StatelessWidget {
  const _DiscoveryStatusCard({
    required this.status,
    required this.entries,
    required this.isActive,
  });

  final String status;
  final List<String> entries;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      elevation: 0.4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsProfilesDiscoveryStatusTitle,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isActive)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(
                  child: Text(
                    status,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.settingsProfilesDiscoveryLogTitle,
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              for (final entry in entries)
                Text(
                  entry,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminCodeCardState extends State<_AdminCodeCard> {
  late String _code;

  @override
  void initState() {
    super.initState();
    _code = widget.code;
  }

  @override
  void didUpdateWidget(covariant _AdminCodeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) {
      _code = widget.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _code,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.onboardingCodeInstructions,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                final code = _generateJoinCode();
                widget.onGenerate(code);
                setState(() => _code = code);
              },
              child: Text(AppLocalizations.of(context)!.onboardingGenerateCode),
            ),
          ],
        ),
      ),
    );
  }
}

String _generateJoinCode() {
  final raw = DateTime.now().microsecondsSinceEpoch % 1000000;
  return raw.toString().padLeft(6, '0');
}
