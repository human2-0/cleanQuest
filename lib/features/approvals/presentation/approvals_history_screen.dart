import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localized_labels.dart';
import '../../../core/utils/date_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../household/application/household_providers.dart';
import '../../household/domain/user_profile.dart';
import '../../items/application/items_providers.dart';
import '../../items/domain/area_category.dart';
import '../../items/domain/item.dart';
import '../application/approvals_providers.dart';
import '../domain/completion_request.dart';
import '../domain/request_status.dart';

class ApprovalsHistoryScreen extends ConsumerWidget {
  const ApprovalsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final requests =
        ref.watch(completionRequestsProvider).value ?? <CompletionRequest>[];
    final items = ref.watch(itemsListProvider).value ?? <Item>[];
    final profiles = ref.watch(householdProfilesProvider).value ?? <UserProfile>[];
    final sorted = [...requests]
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.approvalsHistoryTitle),
      ),
      body: sorted.isEmpty
          ? Center(child: Text(l10n.approvalsNoRequestsYet))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = sorted[index];
                final item = _findItem(items, request, l10n);
                return Card(
                  elevation: 0.6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            _StatusPill(status: request.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.commonPointsLabel(item.points),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.approvalsRequestedBy(
                            _displayNameFor(request.submittedByUserId, profiles),
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.approvalsSubmittedAt(
                            formatShortDateTime(request.submittedAt),
                          ),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (request.reviewedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.approvalsReviewedAt(
                              formatShortDateTime(request.reviewedAt!),
                            ),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                        if (request.reviewedByUserId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.approvalsReviewedBy(
                              _displayNameFor(request.reviewedByUserId!, profiles),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (request.note != null &&
                            request.note!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            request.note!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
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
