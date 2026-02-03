import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../items/application/items_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/app_config/app_config_providers.dart';
import '../../../core/localization/localization_providers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../points/application/points_providers.dart';
import '../../../core/sync/sync_providers.dart';
import '../data/completion_requests_repository.dart';
import '../domain/completion_request.dart';
import '../domain/request_status.dart';
import 'completion_requests_controller.dart';

final completionRequestsRepositoryProvider =
    Provider<CompletionRequestsRepository>((ref) {
  return CompletionRequestsRepository.open(
    sync: ref.read(syncCoordinatorProvider),
  );
});

final completionRequestsControllerProvider =
    Provider<CompletionRequestsController>((ref) {
  final notificationsEnabled =
      ref.watch(appConfigProvider).notificationsEnabled;
  return CompletionRequestsController(
    ref.read(completionRequestsRepositoryProvider),
    ref.read(completionEventsRepositoryProvider),
    ref.read(itemsRepositoryProvider),
    ref.read(ledgerRepositoryProvider),
    NotificationService.instance,
    notificationsEnabled,
    ref.watch(appLocalizationsProvider),
  );
});

final completionRequestsProvider =
    StreamProvider<List<CompletionRequest>>((ref) {
  final householdId = ref.watch(activeHouseholdIdProvider);
  return ref
      .read(completionRequestsRepositoryProvider)
      .watchRequests(householdId);
});

final pendingRequestsProvider = Provider<List<CompletionRequest>>((ref) {
  final requests = ref.watch(completionRequestsProvider).value ?? <CompletionRequest>[];
  return requests
      .where((request) => request.status == RequestStatus.pending)
      .toList();
});

final myRequestsProvider = Provider<List<CompletionRequest>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final requests = ref.watch(completionRequestsProvider).value ?? <CompletionRequest>[];
  final mine = requests.where((request) => request.submittedByUserId == userId).toList();
  mine.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  return mine;
});
