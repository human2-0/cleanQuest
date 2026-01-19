import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/app_config/app_config_providers.dart';
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
  UserRole? _selectedRole;
  final _joinCodeController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _householdNameController = TextEditingController();
  String? _adminJoinCode;
  String? _errorText;

  @override
  void dispose() {
    _joinCodeController.dispose();
    _displayNameController.dispose();
    _householdNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(appConfigProvider.notifier);
    final householdsRepository = ref.read(householdsRepositoryProvider);
    final profilesRepository = ref.read(userProfilesRepositoryProvider);
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
          SegmentedButton<UserRole>(
            segments: [
              ButtonSegment(
                value: UserRole.admin,
                label: Text(l10n.commonAdmin),
              ),
              ButtonSegment(
                value: UserRole.member,
                label: Text(l10n.commonMember),
              ),
            ],
            emptySelectionAllowed: true,
            selected: _selectedRole == null ? {} : {_selectedRole!},
            onSelectionChanged: (value) {
              setState(() {
                _selectedRole = value.first;
                if (_selectedRole == UserRole.admin && _adminJoinCode == null) {
                  _adminJoinCode = _generateJoinCode();
                }
                _errorText = null;
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
          if (_selectedRole == UserRole.admin) ...[
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
            FilledButton(
              onPressed: () async {
                final code = _adminJoinCode ?? _generateJoinCode();
                await notifier.completeOnboardingAsAdmin(joinCode: code);
                final userId = ref.read(appConfigProvider).userId!;
                final displayName =
                    _displayNameController.text.trim().isEmpty
                        ? l10n.commonAdmin
                        : _displayNameController.text.trim();
                final name = _householdNameController.text.trim().isEmpty
                    ? l10n.commonUnknownHousehold
                    : _householdNameController.text.trim();
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
                await _seedForHousehold(code);
              },
              child: Text(l10n.onboardingFinishSetup),
            ),
          ],
          if (_selectedRole == UserRole.member) ...[
            TextField(
              controller: _joinCodeController,
              decoration: InputDecoration(
                labelText: l10n.onboardingAdminCodeLabel,
                errorText: _errorText,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final code = _joinCodeController.text.trim();
                if (code.isEmpty) {
                  setState(() => _errorText = l10n.onboardingCodeRequired);
                  return;
                }
                if (code.length != 6) {
                  setState(() => _errorText = l10n.onboardingCodeLength);
                  return;
                }
                final household = householdsRepository.getHousehold(code);
                if (household == null) {
                  setState(() => _errorText = l10n.onboardingHouseholdNotFound);
                  return;
                }
                await notifier.completeOnboardingAsMember(code);
                final userId = ref.read(appConfigProvider).userId!;
                final displayName =
                    _displayNameController.text.trim().isEmpty
                        ? l10n.commonMember
                        : _displayNameController.text.trim();
                final members = {...household.memberIds, userId}.toList();
                await householdsRepository.upsertHousehold(
                  household.copyWith(memberIds: members),
                );
                await profilesRepository.upsertProfile(
                  UserProfile(
                    id: userId,
                    householdId: code,
                    displayName: displayName,
                    role: UserRole.member,
                  ),
                );
                await _seedForHousehold(code);
              },
              child: Text(l10n.onboardingJoinHousehold),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _seedForHousehold(String householdId) async {
    final itemsBox = Hive.box<ItemDto>(itemsBoxName);
    final eventsBox = Hive.box<CompletionEventDto>(completionEventsBoxName);
    await seedItemsIfEmpty(itemsBox, householdId);
    await seedCompletionEventsIfEmpty(eventsBox, householdId);
  }
}

class _AdminCodeCard extends StatefulWidget {
  const _AdminCodeCard({required this.code, required this.onGenerate});

  final String code;
  final ValueChanged<String> onGenerate;

  @override
  State<_AdminCodeCard> createState() => _AdminCodeCardState();
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
