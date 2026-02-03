import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localized_labels.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../core/utils/date_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../household/application/household_providers.dart';
import '../../household/domain/user_profile.dart';
import '../../items/application/items_providers.dart';
import '../../items/domain/area_category.dart';
import '../../items/domain/item.dart';
import '../application/approvals_providers.dart';
import '../application/completion_requests_controller.dart';
import '../domain/completion_request.dart';
import '../domain/request_status.dart';
import 'approvals_history_screen.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pending = ref.watch(pendingRequestsProvider);
    final myRequests = ref.watch(myRequestsProvider);
    final items = ref.watch(itemsListProvider).value ?? <Item>[];
    final profiles = ref.watch(householdProfilesProvider).value ?? <UserProfile>[];
    final controller = ref.read(completionRequestsControllerProvider);
    final reviewerId = ref.read(currentUserIdProvider);
    final role = ref.watch(currentUserRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          role == UserRole.admin ? l10n.approvalsTitle : l10n.myRequestsTitle,
        ),
        actions: [
          if (role == UserRole.admin)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ApprovalsHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              tooltip: l10n.approvalsHistoryTitle,
            ),
        ],
      ),
      body: role == UserRole.admin
          ? _AdminApprovalsList(
              pending: pending,
              items: items,
              profiles: profiles,
              controller: controller,
              reviewerId: reviewerId,
            )
          : _MemberRequestsList(
              requests: myRequests,
              items: items,
            ),
    );
  }
}

class _AdminApprovalsList extends StatelessWidget {
  const _AdminApprovalsList({
    required this.pending,
    required this.items,
    required this.profiles,
    required this.controller,
    required this.reviewerId,
  });

  final List<CompletionRequest> pending;
  final List<Item> items;
  final List<UserProfile> profiles;
  final CompletionRequestsController controller;
  final String reviewerId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (pending.isEmpty) {
      return Center(child: Text(l10n.approvalsNoPending));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = pending[index];
        final item = _findItem(items, request, l10n);
        return Card(
          elevation: 0.6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.commonPointsLabel(item.points),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.approvalsRequestedBy(
                    _displayNameFor(request.submittedByUserId, profiles),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  formatShortDateTime(request.submittedAt),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (request.note != null && request.note!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    request.note!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () async {
                        try {
                          await controller.approveRequest(
                            request: request,
                            reviewedByUserId: reviewerId,
                            isAdmin: true,
                            itemName: item.name,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          messenger?.showSnackBar(
                            SnackBar(content: Text(l10n.approvalsApprovedToast)),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          messenger?.showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                      child: Text(l10n.commonApprove),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          await controller.rejectRequest(
                            request: request,
                            reviewedByUserId: reviewerId,
                            isAdmin: true,
                            itemName: item.name,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          messenger?.showSnackBar(
                            SnackBar(content: Text(l10n.approvalsRejectedToast)),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          messenger?.showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                      child: Text(l10n.commonReject),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MemberRequestsList extends ConsumerWidget {
  const _MemberRequestsList({
    required this.requests,
    required this.items,
  });

  final List<CompletionRequest> requests;
  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final outboxKeys =
        ref.watch(syncOutboxKeysProvider).value ?? <String>{};
    if (requests.isEmpty) {
      return Center(child: Text(l10n.approvalsNoRequestsYet));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = requests[index];
        final item = _findItem(items, request, l10n);
        final isQueued = outboxKeys.contains(
          syncOutboxKey(SyncEntityType.completionRequests, request.id),
        );
        return Card(
          elevation: 0.6,
          child: ListTile(
            title: Text(item.name),
            subtitle: Text(formatShortDateTime(request.submittedAt)),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusPill(status: request.status),
                if (isQueued) ...[
                  const SizedBox(height: 4),
                  const _QueuedPill(),
                ],
                const SizedBox(height: 4),
                Text(
                  l10n.commonPointsShort(item.points),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final RequestStatus status;

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
          localizedRequestStatus(l10n, status),
          style: theme.textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _QueuedPill extends StatelessWidget {
  const _QueuedPill();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          'Queued',
          style: theme.textTheme.labelSmall,
        ),
      ),
    );
  }
}

Item _findItem(
  List<Item> items,
  CompletionRequest request,
  AppLocalizations l10n,
) {
  return items.firstWhere(
    (item) => item.id == request.itemId,
    orElse: () => Item(
      id: request.itemId,
      householdId: request.householdId,
      name: l10n.commonUnknownChore,
      category: AreaCategory.other,
      icon: '🧽',
      intervalSeconds: 0,
      points: 10,
    ),
  );
}

String _displayNameFor(String userId, List<UserProfile> profiles) {
  for (final profile in profiles) {
    if (profile.id == userId) {
      return profile.displayName;
    }
  }
  return userId;
}
