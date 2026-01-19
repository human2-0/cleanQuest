import '../domain/item.dart';
import '../domain/item_status.dart';

class ItemBoardEntry {
  const ItemBoardEntry({
    required this.item,
    required this.status,
    required this.lastApprovedAt,
    required this.nextDueAt,
  });

  final Item item;
  final ItemStatus status;
  final DateTime? lastApprovedAt;
  final DateTime? nextDueAt;
}
