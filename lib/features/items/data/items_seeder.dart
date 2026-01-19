import 'package:hive/hive.dart';

import '../domain/area_category.dart';
import '../domain/completion_event.dart';
import '../domain/item.dart';
import 'completion_event_dto.dart';
import 'item_dto.dart';

Future<void> seedItemsIfEmpty(Box<ItemDto> itemsBox, String householdId) async {
  if (itemsBox.isNotEmpty) {
    return;
  }
  final seedItems = _defaultItems(householdId);

  for (final item in seedItems) {
    await itemsBox.put(item.id, ItemDto.fromDomain(item));
  }
}

Future<void> seedCompletionEventsIfEmpty(
  Box<CompletionEventDto> eventsBox,
  String householdId,
) async {
  if (eventsBox.isNotEmpty) {
    return;
  }
  final seedEvents = _defaultEvents(householdId);

  for (final event in seedEvents) {
    await eventsBox.put(event.id, CompletionEventDto.fromDomain(event));
  }
}

Future<void> restoreDefaultTemplates(
  Box<ItemDto> itemsBox,
  Box<CompletionEventDto> eventsBox,
  String householdId,
) async {
  await _deleteItemsForHousehold(itemsBox, householdId);
  await _deleteEventsForHousehold(eventsBox, householdId);
  final seedItems = _defaultItems(householdId);
  final seedEvents = _defaultEvents(householdId);

  for (final item in seedItems) {
    await itemsBox.put(item.id, ItemDto.fromDomain(item));
  }
  for (final event in seedEvents) {
    await eventsBox.put(event.id, CompletionEventDto.fromDomain(event));
  }
}

List<Item> _defaultItems(String householdId) {
  return [
    Item(
      id: 'item-kitchen-sink',
      householdId: householdId,
      name: 'Kitchen sink scrub',
      category: AreaCategory.home,
      roomOrZone: 'Kitchen',
      icon: '🧽',
      intervalSeconds: 60 * 60 * 24 * 3,
      points: 10,
    ),
    Item(
      id: 'item-living-vacuum',
      householdId: householdId,
      name: 'Vacuum living room',
      category: AreaCategory.home,
      roomOrZone: 'Living',
      icon: '🧹',
      intervalSeconds: 60 * 60 * 24 * 7,
      points: 12,
    ),
    Item(
      id: 'item-bath-mirror',
      householdId: householdId,
      name: 'Bathroom mirror wipe',
      category: AreaCategory.home,
      roomOrZone: 'Bath',
      icon: '🪞',
      intervalSeconds: 60 * 60 * 24 * 5,
      points: 8,
    ),
    Item(
      id: 'item-car-exterior',
      householdId: householdId,
      name: 'Exterior wash',
      category: AreaCategory.car,
      roomOrZone: 'Body',
      icon: '🚗',
      intervalSeconds: 60 * 60 * 24 * 14,
      points: 20,
    ),
    Item(
      id: 'item-car-interior',
      householdId: householdId,
      name: 'Interior tidy',
      category: AreaCategory.car,
      roomOrZone: 'Cabin',
      icon: '🧼',
      intervalSeconds: 60 * 60 * 24 * 10,
      points: 14,
    ),
    Item(
      id: 'item-garage-floor',
      householdId: householdId,
      name: 'Garage sweep',
      category: AreaCategory.other,
      roomOrZone: 'Garage',
      icon: '🧽',
      intervalSeconds: 60 * 60 * 24 * 30,
      points: 15,
      isPaused: true,
    ),
    Item(
      id: 'item-windows',
      householdId: householdId,
      name: 'Window polish',
      category: AreaCategory.home,
      roomOrZone: 'Whole home',
      icon: '🪟',
      intervalSeconds: 60 * 60 * 24 * 21,
      points: 18,
      snoozedUntil: DateTime.now().add(const Duration(days: 2)),
    ),
  ];
}

List<CompletionEvent> _defaultEvents(String householdId) {
  final now = DateTime.now();
  return [
    CompletionEvent(
      id: 'evt-1',
      householdId: householdId,
      itemId: 'item-kitchen-sink',
      approvedAt: now.subtract(const Duration(days: 1)),
    ),
    CompletionEvent(
      id: 'evt-2',
      householdId: householdId,
      itemId: 'item-living-vacuum',
      approvedAt: now.subtract(const Duration(days: 9)),
    ),
    CompletionEvent(
      id: 'evt-3',
      householdId: householdId,
      itemId: 'item-car-exterior',
      approvedAt: now.subtract(const Duration(days: 16)),
    ),
    CompletionEvent(
      id: 'evt-4',
      householdId: householdId,
      itemId: 'item-car-interior',
      approvedAt: now.subtract(const Duration(days: 3)),
    ),
  ];
}

Future<void> _deleteItemsForHousehold(
  Box<ItemDto> itemsBox,
  String householdId,
) async {
  final keysToRemove = <dynamic>[];
  for (final key in itemsBox.keys) {
    final item = itemsBox.get(key);
    if (item != null && item.householdId == householdId) {
      keysToRemove.add(key);
    }
  }
  for (final key in keysToRemove) {
    await itemsBox.delete(key);
  }
}

Future<void> _deleteEventsForHousehold(
  Box<CompletionEventDto> eventsBox,
  String householdId,
) async {
  final keysToRemove = <dynamic>[];
  for (final key in eventsBox.keys) {
    final event = eventsBox.get(key);
    if (event != null && event.householdId == householdId) {
      keysToRemove.add(key);
    }
  }
  for (final key in keysToRemove) {
    await eventsBox.delete(key);
  }
}
