import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/user_providers.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/localization/localized_labels.dart';
import '../../../l10n/app_localizations.dart';
import '../../approvals/application/approvals_providers.dart';
import '../../approvals/domain/completion_request.dart';
import '../../approvals/domain/request_status.dart';
import '../../approvals/presentation/approvals_screen.dart';
import '../../household/application/household_providers.dart';
import '../../items/presentation/items_board_screen.dart';
import '../../items/application/items_providers.dart';
import '../../items/application/item_board_entry.dart';
import '../../items/domain/item.dart';
import '../../items/domain/item_status.dart';
import '../../items/presentation/item_detail_screen.dart';
import '../../points/application/points_providers.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../rewards/application/rewards_providers.dart';
import '../../rewards/domain/reward.dart';
import '../../rewards/domain/redemption.dart';
import '../../settings/presentation/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

enum _ActivityFilter {
  all,
  approved,
  rejected,
  pending,
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  _ActivityFilter _filter = _ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final balance = ref.watch(pointsBalanceProvider);
    final role = ref.watch(currentUserRoleProvider);
    final household = ref.watch(activeHouseholdProvider).value;
    final profile = ref.watch(currentUserProfileProvider);
    final requests =
        ref.watch(completionRequestsProvider).value ?? <CompletionRequest>[];
    final redemptions =
        ref.watch(redemptionsProvider).value ?? <Redemption>[];
    final items = ref.watch(itemsListProvider).value ?? <Item>[];
    final rewards = ref.watch(rewardsProvider).value ?? <Reward>[];
    final entries = ref.watch(itemsBoardProvider);
    final pendingApprovals = ref.watch(pendingRequestsProvider).length;
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
    final priorityItems = entries
        .where((entry) =>
            entry.status == ItemStatus.overdue ||
            entry.status == ItemStatus.due ||
            entry.status == ItemStatus.soon)
        .take(8)
        .toList();
    final activity = _buildActivity(
      l10n: l10n,
      requests: requests,
      redemptions: redemptions,
      items: items,
      rewards: rewards,
      filter: _filter,
    );
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(household?.name ?? l10n.appTitle),
            if (profile != null)
              Text(
                profile.displayName,
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.dashboardToday,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _KpiCard(
                label: l10n.dashboardDueToday,
                value: dueToday.toString(),
                icon: Icons.event_available_outlined,
              ),
              _KpiCard(
                label: l10n.dashboardOverdue,
                value: overdueCount.toString(),
                icon: Icons.warning_amber_outlined,
              ),
              if (role == UserRole.admin)
                _KpiCard(
                  label: l10n.dashboardPendingApprovals,
                  value: pendingApprovals.toString(),
                  icon: Icons.fact_check_outlined,
                ),
              _KpiCard(
                label: l10n.dashboardPoints,
                value: balance.toString(),
                icon: Icons.star_outline,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.dashboardTopPriorities,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (priorityItems.isEmpty)
            Text(l10n.dashboardAllCaughtUp)
          else
            ...priorityItems.map(
              (entry) => Card(
                elevation: 0.6,
                child: ListTile(
                  leading: Text(
                    entry.status.emoji,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  title: Text(entry.item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_buildDueLabel(l10n, entry, now)),
                      Text(
                        l10n.commonPointsShort(entry.item.points),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
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
              ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            l10n.dashboardQuickActions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              final actions = [
                _QuickActionCard(
                  label: l10n.dashboardChoresBoard,
                  icon: Icons.checklist_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ItemsBoardScreen(),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  label: role == UserRole.admin
                      ? l10n.dashboardApprovals
                      : l10n.dashboardMyRequests,
                  icon: Icons.fact_check_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ApprovalsScreen(),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  label: l10n.dashboardRewards,
                  icon: Icons.card_giftcard_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RewardsScreen(),
                      ),
                    );
                  },
                  highlighted: true,
                ),
              ];
              if (isNarrow) {
                return Column(
                  children: [
                    for (final action in actions) ...[
                      action,
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: actions[0]),
                  const SizedBox(width: 12),
                  Expanded(child: actions[1]),
                  const SizedBox(width: 12),
                  Expanded(child: actions[2]),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            l10n.dashboardRecentActivity,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_ActivityFilter>(
              segments: [
                ButtonSegment(
                  value: _ActivityFilter.all,
                  label: Text(l10n.activityFilterAll),
                ),
                ButtonSegment(
                  value: _ActivityFilter.pending,
                  label: Text(l10n.activityFilterPending),
                ),
                ButtonSegment(
                  value: _ActivityFilter.approved,
                  label: Text(l10n.activityFilterApproved),
                ),
                ButtonSegment(
                  value: _ActivityFilter.rejected,
                  label: Text(l10n.activityFilterRejected),
                ),
              ],
              selected: {_filter},
              showSelectedIcon: false,
              onSelectionChanged: (value) {
                setState(() => _filter = value.first);
              },
            ),
          ),
          const SizedBox(height: 8),
          if (activity.isEmpty)
            Text(l10n.dashboardNoActivity)
          else
            ...activity.map(
              (entry) => ListTile(
                title: Text(entry.title),
                subtitle: Text(entry.subtitle),
                trailing: _ActivityBadge(entry: entry),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityEntry {
  const _ActivityEntry({
    required this.at,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.requestStatus,
    required this.kind,
  });

  final DateTime at;
  final String title;
  final String subtitle;
  final String trailing;
  final RequestStatus? requestStatus;
  final _ActivityKind kind;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = highlighted
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.secondaryContainer,
              scheme.tertiaryContainer,
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer,
              scheme.secondaryContainer.withOpacity(0.6),
            ],
          );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withOpacity(0.3),
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: scheme.tertiary.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: scheme.shadow.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surface.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        color: scheme.onSurface,
                        size: 24,
                      ),
                    ),
                    if (highlighted)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ActivityKind {
  request,
  redemption,
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<_ActivityEntry> _buildActivity({
  required AppLocalizations l10n,
  required List<CompletionRequest> requests,
  required List<Redemption> redemptions,
  required List<Item> items,
  required List<Reward> rewards,
  required _ActivityFilter filter,
}) {
  final entries = <_ActivityEntry>[];
  final itemById = {for (final item in items) item.id: item.name};

  for (final request in requests) {
    if (filter == _ActivityFilter.approved &&
        request.status != RequestStatus.approved) {
      continue;
    }
    if (filter == _ActivityFilter.rejected &&
        request.status != RequestStatus.rejected) {
      continue;
    }
    if (filter == _ActivityFilter.pending &&
        request.status != RequestStatus.pending) {
      continue;
    }
    final name = itemById[request.itemId] ?? l10n.commonUnknownChore;
    final status = localizedRequestStatus(l10n, request.status);
    final at = request.reviewedAt ?? request.submittedAt;
    final subtitle = request.status == RequestStatus.pending
        ? l10n.dashboardActivityPending(name)
        : l10n.dashboardActivityStatus(status, name);
    entries.add(
      _ActivityEntry(
        at: at,
        title: l10n.dashboardActivityCompletionRequest,
        subtitle: subtitle,
        trailing: formatShortDateTime(at),
        requestStatus: request.status,
        kind: _ActivityKind.request,
      ),
    );
  }

  if (filter == _ActivityFilter.all) {
    for (final redemption in redemptions) {
      entries.add(
        _ActivityEntry(
          at: redemption.rolledAt,
          title: l10n.dashboardActivityRedemption,
          subtitle: _rewardTitleFor(l10n, rewards, redemption),
          trailing: formatShortDateTime(redemption.rolledAt),
          kind: _ActivityKind.redemption,
        ),
      );
    }
  }

  entries.sort((a, b) => b.at.compareTo(a.at));
  return entries.take(10).toList();
}

String _rewardTitleFor(
  AppLocalizations l10n,
  List<Reward> rewards,
  Redemption redemption,
) {
  return rewards
      .firstWhere(
        (reward) => reward.id == redemption.outcomeRewardId,
        orElse: () => Reward(
          id: redemption.outcomeRewardId,
          householdId: redemption.householdId,
          title: l10n.commonUnknownReward,
          weight: 0,
          enabled: false,
        ),
      )
      .title;
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

class _ActivityBadge extends StatelessWidget {
  const _ActivityBadge({required this.entry});

  final _ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (entry.kind == _ActivityKind.redemption) {
      return Text(entry.trailing);
    }
    final status = entry.requestStatus ?? RequestStatus.pending;
    Color background;
    Color foreground;
    switch (status) {
      case RequestStatus.approved:
        background = theme.colorScheme.tertiaryContainer;
        foreground = theme.colorScheme.onTertiaryContainer;
      case RequestStatus.rejected:
        background = theme.colorScheme.errorContainer;
        foreground = theme.colorScheme.onErrorContainer;
      case RequestStatus.pending:
        background = theme.colorScheme.secondaryContainer;
        foreground = theme.colorScheme.onSecondaryContainer;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              localizedRequestStatus(l10n, status),
              style: theme.textTheme.labelSmall?.copyWith(color: foreground),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(entry.trailing),
      ],
    );
  }
}
