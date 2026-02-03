import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/user_providers.dart';
import '../../items/application/items_providers.dart';
import '../../../core/sync/sync_providers.dart';
import '../data/ledger_repository.dart';
import '../domain/ledger_entry.dart';

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository.open(sync: ref.read(syncCoordinatorProvider));
});

final ledgerEntriesProvider = StreamProvider<List<LedgerEntry>>((ref) {
  final householdId = ref.watch(activeHouseholdIdProvider);
  final userId = ref.watch(currentUserIdProvider);
  return ref.read(ledgerRepositoryProvider).watchEntries(householdId, userId);
});

final pointsBalanceProvider = Provider<int>((ref) {
  final entries = ref.watch(ledgerEntriesProvider).value ?? <LedgerEntry>[];
  return entries.fold(0, (sum, entry) => sum + entry.delta);
});
