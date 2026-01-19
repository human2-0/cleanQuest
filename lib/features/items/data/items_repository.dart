import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../domain/item.dart';
import 'item_dto.dart';

class ItemsRepository {
  ItemsRepository(this._box);

  final Box<ItemDto> _box;

  static ItemsRepository open() {
    return ItemsRepository(Hive.box<ItemDto>(itemsBoxName));
  }

  Stream<List<Item>> watchItems(String householdId) async* {
    yield _itemsForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _itemsForHousehold(householdId);
    }
  }

  Future<void> upsertItem(Item item) {
    return _box.put(item.id, ItemDto.fromDomain(item));
  }

  Future<void> deleteItem(String id) {
    return _box.delete(id);
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
