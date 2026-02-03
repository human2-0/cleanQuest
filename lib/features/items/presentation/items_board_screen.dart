import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localized_labels.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../approvals/application/approvals_providers.dart';
import '../../approvals/presentation/approvals_screen.dart';
import '../../approvals/domain/request_status.dart';
import '../../rewards/application/rewards_providers.dart';
import '../../rewards/data/inventory_repository.dart';
import '../../rewards/domain/inventory_item.dart';
import '../../rewards/domain/inventory_item_type.dart';
import '../application/item_board_entry.dart';
import '../application/items_providers.dart';
import '../domain/item.dart';
import '../domain/item_status.dart';
import 'item_detail_screen.dart';
import '../../points/application/points_providers.dart';

class ItemsBoardScreen extends ConsumerStatefulWidget {
  const ItemsBoardScreen({super.key});

  @override
  ConsumerState<ItemsBoardScreen> createState() => _ItemsBoardScreenState();
}

class _ItemsBoardScreenState extends ConsumerState<ItemsBoardScreen> {
  String? _selectedRoom;
  final Set<String> _submittingRequests = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = ref.watch(itemsBoardProvider);
    final roomOptions = _roomOptions(entries);
    final effectiveRoom =
        _selectedRoom != null && roomOptions.contains(_selectedRoom)
            ? _selectedRoom
            : null;
    final filteredEntries = effectiveRoom == null
        ? entries
        : entries
            .where((entry) =>
                _normalizeRoom(entry.item.roomOrZone) == effectiveRoom)
            .toList();
    final householdId = ref.read(activeHouseholdIdProvider);
    final role = ref.watch(currentUserRoleProvider);
    final userId = ref.read(currentUserIdProvider);
    final requestsController = ref.read(completionRequestsControllerProvider);
    final itemsController = ref.read(itemsControllerProvider);
    final isAdmin = role == UserRole.admin;
    final balance = ref.watch(pointsBalanceProvider);
    final pendingCount = ref.watch(pendingRequestsProvider).length;
    final myRequests = ref.watch(myRequestsProvider);
    final inventory = ref.watch(inventoryProvider).value ?? <InventoryItem>[];
    final pendingByItemId = {
      for (final request in myRequests)
        if (request.status == RequestStatus.pending) request.itemId,
    };
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                l10n.choresTitleWithRole(
                  role == UserRole.admin ? l10n.commonAdmin : l10n.commonMember,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _PointsBadge(points: balance),
            if (isAdmin) ...[
              const SizedBox(width: 8),
              _PendingBadge(count: pendingCount),
            ],
          ],
        ),
        actions: [
          if (role == UserRole.admin)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ItemDetailScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              tooltip: l10n.choresAddTooltip,
            ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ApprovalsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: role == UserRole.admin
                ? l10n.choresApprovalsTooltip
                : l10n.choresMyRequestsTooltip,
          ),
        ],
      ),
      body: Column(
        children: [
          if (roomOptions.isNotEmpty)
            _FilterBar(
              options: roomOptions,
              selected: effectiveRoom,
              onSelected: (value) {
                setState(() => _selectedRoom = value);
              },
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredEntries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = filteredEntries[index];
                final isSubmitting =
                    _submittingRequests.contains(entry.item.id);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(
                          itemId: entry.item.id,
                          readOnly: role == UserRole.member,
                        ),
                      ),
                    );
                  },
                  child: _ItemBoardCard(
                    entry: entry,
                    showAction: role == UserRole.member,
                    showAdminHint: isAdmin,
                    showAdminActions: isAdmin,
                    menu: role == UserRole.member
                        ? PopupMenuButton<_ChoreAction>(
                            icon: const Icon(Icons.more_horiz),
                            onSelected: (action) {
                              if (action == _ChoreAction.useAmulet) {
                                _showAmuletPicker(
                                  context: context,
                                  ref: ref,
                                  item: entry.item,
                                  inventory: inventory,
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: _ChoreAction.useAmulet,
                                child: Text(l10n.choresUseAmulet),
                              ),
                            ],
                          )
                        : null,
                    underReview: pendingByItemId.contains(entry.item.id),
                    actionLabel: pendingByItemId.contains(entry.item.id)
                        ? l10n.statusPending
                        : l10n.choresRequestCompletion,
                    actionIcon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    onAction: pendingByItemId.contains(entry.item.id) ||
                            isSubmitting
                        ? null
                        : () {
                            _promptForNote(context).then((note) async {
                              if (note == null) {
                                return;
                              }
                              setState(() {
                                _submittingRequests.add(entry.item.id);
                              });
                              try {
                                final coordinator =
                                    ref.read(syncCoordinatorProvider);
                                await coordinator.ensureConnected();
                                await coordinator.waitForConnection(
                                  const Duration(seconds: 3),
                                );
                                final request =
                                    await requestsController.submitRequest(
                                  householdId: householdId,
                                  itemId: entry.item.id,
                                  submittedByUserId: userId,
                                  isAdmin: role == UserRole.admin,
                                  itemName: entry.item.name,
                                  note: note.isEmpty ? null : note,
                                );
                                final queued = coordinator.isQueued(
                                  SyncEntityType.completionRequests,
                                  request.id,
                                );
                                final message = queued
                                    ? 'Admin offline. Request queued and will send when nearby.'
                                    : l10n.choresRequestSubmitted;
                                if (!mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              } catch (error) {
                                if (!mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.toString())),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _submittingRequests.remove(entry.item.id);
                                  });
                                }
                              }
                            });
                          },
                    onCleanNow: isAdmin
                        ? () async {
                            try {
                              await itemsController.markCleanedNow(
                                item: entry.item,
                                userId: userId,
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.choresMarkedCleaned),
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          }
                        : null,
                    onSnooze: isAdmin
                        ? () async {
                            final until = await _pickSnoozeUntil(context);
                            if (until == null) {
                              return;
                            }
                            try {
                              await itemsController.snoozeItem(entry.item, until);
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.choresSnoozedUntilToast(
                                      formatShortDate(until),
                                    ),
                                  ),
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          }
                        : null,
                    onClearSnooze: isAdmin
                        ? () async {
                            try {
                              await itemsController.clearSnooze(entry.item);
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.choresSnoozeCleared),
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          }
                        : null,
                    onTogglePause: isAdmin
                        ? () async {
                            try {
                              await itemsController.setPaused(
                                entry.item,
                                !entry.item.isPaused,
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    entry.item.isPaused
                                        ? l10n.choresResumedToast
                                        : l10n.choresPausedToast,
                                  ),
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          }
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(option),
                selected: selected == option,
                onSelected: (_) => onSelected(option),
              ),
            ),
        ],
      ),
    );
  }
}

String? _normalizeRoom(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

List<String> _roomOptions(List<ItemBoardEntry> entries) {
  final rooms = <String>{};
  for (final entry in entries) {
    final normalized = _normalizeRoom(entry.item.roomOrZone);
    if (normalized != null) {
      rooms.add(normalized);
    }
  }
  final sorted = rooms.toList()..sort();
  return sorted;
}

class _ItemBoardCard extends StatelessWidget {
  const _ItemBoardCard({
    required this.entry,
    required this.onAction,
    required this.actionLabel,
    required this.actionIcon,
    required this.showAction,
    required this.underReview,
    required this.showAdminHint,
    required this.showAdminActions,
    this.menu,
    this.onCleanNow,
    this.onSnooze,
    this.onClearSnooze,
    this.onTogglePause,
  });

  final ItemBoardEntry entry;
  final VoidCallback? onAction;
  final String actionLabel;
  final Widget actionIcon;
  final bool showAction;
  final bool underReview;
  final bool showAdminHint;
  final bool showAdminActions;
  final Widget? menu;
  final VoidCallback? onCleanNow;
  final VoidCallback? onSnooze;
  final VoidCallback? onClearSnooze;
  final VoidCallback? onTogglePause;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dueLabel = _buildDueLabel(l10n, entry, now);
    final lastCleaned = entry.lastApprovedAt == null
        ? l10n.choresLastCleanedNever
        : l10n.choresLastCleaned(formatShortDate(entry.lastApprovedAt!));
    final room = entry.item.roomOrZone;

    return Card(
      elevation: 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.status.emoji,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.item.icon,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.item.name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (menu != null) ...[
                        const SizedBox(width: 8),
                        menu!,
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${localizedAreaCategory(l10n, entry.item.category)}${room == null ? '' : ' • $room'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.commonPointsLabel(entry.item.points),
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dueLabel,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastCleaned,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (entry.item.protectionUntil != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.choresProtectionUntil(
                        formatShortDateTime(entry.item.protectionUntil!),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (showAdminHint) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.choresAdminReviewHint,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                  if (underReview) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.statusPending,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                  if (showAction) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: onAction,
                        icon: actionIcon,
                        label: Text(actionLabel),
                      ),
                    ),
                  ],
                  if (showAdminActions) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: onCleanNow,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(l10n.choresCleanedNow),
                        ),
                        OutlinedButton.icon(
                          onPressed: entry.item.snoozedUntil == null
                              ? onSnooze
                              : onClearSnooze,
                          icon: Icon(
                            entry.item.snoozedUntil == null
                                ? Icons.snooze_outlined
                                : Icons.snooze,
                          ),
                          label: Text(
                            entry.item.snoozedUntil == null
                                ? l10n.choresSnooze
                                : l10n.choresClearSnooze,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onTogglePause,
                          icon: Icon(
                            entry.item.isPaused
                                ? Icons.play_arrow
                                : Icons.pause,
                          ),
                          label: Text(
                            entry.item.isPaused
                                ? l10n.choresResume
                                : l10n.choresPause,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusChip(status: entry.status),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          localizedItemStatus(l10n, status),
          style: theme.textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '⭐ $points',
          style: theme.textTheme.labelMedium,
        ),
      ),
    );
  }
}

enum _ChoreAction { useAmulet }

Future<void> _showAmuletPicker({
  required BuildContext context,
  required WidgetRef ref,
  required Item item,
  required List<InventoryItem> inventory,
}) async {
  final l10n = AppLocalizations.of(context)!;
  if (item.protectionUsed) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.choresAmuletAlreadyUsed)),
    );
    return;
  }
  if (item.protectionUntil != null &&
      item.protectionUntil!.isAfter(DateTime.now())) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.choresAmuletAlreadyActive)),
    );
    return;
  }
  final available = inventory
      .where(
        (entry) =>
            entry.isAvailable && entry.type == InventoryItemType.lossProtection,
      )
      .toList();
  if (available.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.choresAmuletNone)),
    );
    return;
  }
  final selected = await showModalBottomSheet<InventoryItem>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(l10n.choresAmuletSelectTitle),
          ),
          for (final entry in available)
            ListTile(
              title: Text(
                l10n.amuletLossProtection(entry.durationHours),
              ),
              subtitle: Text(l10n.amuletDurationLabel(entry.durationHours)),
              onTap: () => Navigator.pop(context, entry),
            ),
        ],
      ),
    ),
  );
  if (selected == null) {
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.choresAmuletConfirmTitle),
      content: Text(l10n.choresAmuletConfirmBody(item.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.choresUseAmulet),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return;
  }
  final now = DateTime.now();
  final itemsRepository = ref.read(itemsRepositoryProvider);
  final inventoryRepository = ref.read(inventoryRepositoryProvider);
  await itemsRepository.upsertItem(
    item.copyWith(
      protectionUntil: now.add(Duration(hours: selected.durationHours)),
      protectionUsed: true,
    ),
  );
  await inventoryRepository.upsertItem(
    selected.copyWith(
      usedAt: now,
      appliedItemId: item.id,
    ),
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.choresAmuletApplied)),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '⏳ $count',
          style: theme.textTheme.labelMedium,
        ),
      ),
    );
  }
}

String _buildDueLabel(AppLocalizations l10n, ItemBoardEntry entry, DateTime now) {
  if (entry.status == ItemStatus.paused) {
    return l10n.choresPaused;
  }
  if (entry.status == ItemStatus.snoozed && entry.item.snoozedUntil != null) {
    return l10n.choresSnoozedUntil(formatShortDate(entry.item.snoozedUntil!));
  }
  if (entry.nextDueAt == null) {
    return l10n.choresNoHistory;
  }
  final delta = entry.nextDueAt!.difference(now);
  if (delta.isNegative) {
    return l10n.choresOverdueBy(formatDurationShort(delta));
  }
  return l10n.choresDueIn(formatDurationShort(delta));
}

Future<String?> _promptForNote(BuildContext context) {
  return showDialog<String?>(
    context: context,
    builder: (context) => const _NoteDialog(),
  );
}

enum _SnoozeChoice { oneDay, threeDays, oneWeek, custom }

Future<DateTime?> _pickSnoozeUntil(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final choice = await showDialog<_SnoozeChoice>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.choresSnoozeDialogTitle),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, _SnoozeChoice.oneDay),
          child: Text(l10n.choresSnooze1Day),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, _SnoozeChoice.threeDays),
          child: Text(l10n.choresSnooze3Days),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, _SnoozeChoice.oneWeek),
          child: Text(l10n.choresSnooze1Week),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, _SnoozeChoice.custom),
          child: Text(l10n.choresSnoozePickDate),
        ),
      ],
    ),
  );

  if (choice == null) {
    return null;
  }

  final now = DateTime.now();
  switch (choice) {
    case _SnoozeChoice.oneDay:
      return now.add(const Duration(days: 1));
    case _SnoozeChoice.threeDays:
      return now.add(const Duration(days: 3));
    case _SnoozeChoice.oneWeek:
      return now.add(const Duration(days: 7));
    case _SnoozeChoice.custom:
      final picked = await showDatePicker(
        context: context,
        initialDate: now.add(const Duration(days: 1)),
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
      );
      if (picked == null) {
        return null;
      }
      return DateTime(
        picked.year,
        picked.month,
        picked.day,
        now.hour,
        now.minute,
      );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog();

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.choresNoteDialogTitle),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: l10n.choresNoteDialogHint),
        maxLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n.commonSubmit),
        ),
      ],
    );
  }
}
