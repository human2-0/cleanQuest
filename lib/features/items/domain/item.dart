import 'area_category.dart';

class Item {
  const Item({
    required this.id,
    required this.householdId,
    required this.name,
    required this.category,
    required this.icon,
    required this.intervalSeconds,
    required this.points,
    this.roomOrZone,
    this.isPaused = false,
    this.snoozedUntil,
  });

  final String id;
  final String householdId;
  final String name;
  final AreaCategory category;
  final String icon;
  final int intervalSeconds;
  final int points;
  final String? roomOrZone;
  final bool isPaused;
  final DateTime? snoozedUntil;

  Item copyWith({
    String? id,
    String? householdId,
    String? name,
    AreaCategory? category,
    String? icon,
    int? intervalSeconds,
    int? points,
    String? roomOrZone,
    bool? isPaused,
    DateTime? snoozedUntil,
  }) {
    return Item(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      points: points ?? this.points,
      roomOrZone: roomOrZone ?? this.roomOrZone,
      isPaused: isPaused ?? this.isPaused,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    );
  }
}
