import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_payloads.dart';
import '../domain/inventory_item.dart';
import 'inventory_item_dto.dart';

class InventoryRepository {
  InventoryRepository(this._box, {SyncCoordinator? sync}) : _sync = sync;

  final Box<InventoryItemDto> _box;
  final SyncCoordinator? _sync;

  static InventoryRepository open({SyncCoordinator? sync}) {
    return InventoryRepository(
      Hive.box<InventoryItemDto>(inventoryBoxName),
      sync: sync,
    );
  }

  Stream<List<InventoryItem>> watchInventory(
    String householdId,
    String userId,
  ) async* {
    yield _inventoryFor(householdId, userId);
    await for (final _ in _box.watch()) {
      yield _inventoryFor(householdId, userId);
    }
  }

  Future<void> upsertItem(InventoryItem item) async {
    final dto = InventoryItemDto.fromDomain(item);
    await _box.put(item.id, dto);
    await _sync?.publishUpsert(
      SyncEntityType.inventoryItems,
      SyncPayloadCodec.inventoryItemToMap(dto),
      entityId: item.id,
    );
  }

  List<InventoryItem> _inventoryFor(String householdId, String userId) {
    return _box.values
        .where((dto) => dto.householdId == householdId && dto.userId == userId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
