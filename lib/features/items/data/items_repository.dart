import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_payloads.dart';
import '../domain/item.dart';
import 'item_dto.dart';

class ItemsRepository {
  ItemsRepository(this._box, {SyncCoordinator? sync}) : _sync = sync;

  final Box<ItemDto> _box;
  final SyncCoordinator? _sync;

  static ItemsRepository open({SyncCoordinator? sync}) {
    return ItemsRepository(Hive.box<ItemDto>(itemsBoxName), sync: sync);
  }

  Stream<List<Item>> watchItems(String householdId) async* {
    yield _itemsForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _itemsForHousehold(householdId);
    }
  }

  Future<void> upsertItem(Item item) async {
    final dto = ItemDto.fromDomain(item);
    await _box.put(item.id, dto);
    await _sync?.publishUpsert(
      SyncEntityType.items,
      SyncPayloadCodec.itemToMap(dto),
      entityId: item.id,
    );
  }

  Future<void> deleteItem(String id) async {
    await _box.delete(id);
    await _sync?.publishDelete(SyncEntityType.items, id);
  }

  Item? getItem(String id) {
    return _box.get(id)?.toDomain();
  }

  List<Item> _itemsForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
