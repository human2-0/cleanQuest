import 'inventory_item_type.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.type,
    required this.durationHours,
    required this.purchasedAt,
    this.usedAt,
    this.appliedItemId,
  });

  final String id;
  final String householdId;
  final String userId;
  final InventoryItemType type;
  final int durationHours;
  final DateTime purchasedAt;
  final DateTime? usedAt;
  final String? appliedItemId;

  bool get isAvailable => usedAt == null;

  InventoryItem copyWith({
    DateTime? usedAt,
    String? appliedItemId,
  }) {
    return InventoryItem(
      id: id,
      householdId: householdId,
      userId: userId,
      type: type,
      durationHours: durationHours,
      purchasedAt: purchasedAt,
      usedAt: usedAt ?? this.usedAt,
      appliedItemId: appliedItemId ?? this.appliedItemId,
    );
  }
}
