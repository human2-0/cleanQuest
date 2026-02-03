enum SyncEntityType {
  items,
  completionEvents,
  completionRequests,
  ledgerEntries,
  rewards,
  boxRules,
  redemptions,
  inventoryItems,
  behaviorRules,
  households,
  userProfiles,
}

extension SyncEntityTypeWire on SyncEntityType {
  String get wire {
    switch (this) {
      case SyncEntityType.items:
        return 'items';
      case SyncEntityType.completionEvents:
        return 'completion_events';
      case SyncEntityType.completionRequests:
        return 'completion_requests';
      case SyncEntityType.ledgerEntries:
        return 'ledger_entries';
      case SyncEntityType.rewards:
        return 'rewards';
      case SyncEntityType.boxRules:
        return 'box_rules';
      case SyncEntityType.redemptions:
        return 'redemptions';
      case SyncEntityType.inventoryItems:
        return 'inventory_items';
      case SyncEntityType.behaviorRules:
        return 'behavior_rules';
      case SyncEntityType.households:
        return 'households';
      case SyncEntityType.userProfiles:
        return 'user_profiles';
    }
  }
}

SyncEntityType? syncEntityTypeFromWire(String? value) {
  switch (value) {
    case 'items':
      return SyncEntityType.items;
    case 'completion_events':
      return SyncEntityType.completionEvents;
    case 'completion_requests':
      return SyncEntityType.completionRequests;
    case 'ledger_entries':
      return SyncEntityType.ledgerEntries;
    case 'rewards':
      return SyncEntityType.rewards;
    case 'box_rules':
      return SyncEntityType.boxRules;
    case 'redemptions':
      return SyncEntityType.redemptions;
    case 'inventory_items':
      return SyncEntityType.inventoryItems;
    case 'behavior_rules':
      return SyncEntityType.behaviorRules;
    case 'households':
      return SyncEntityType.households;
    case 'user_profiles':
      return SyncEntityType.userProfiles;
  }
  return null;
}

String syncOutboxKey(SyncEntityType type, String entityId) {
  return 'outbox:${type.wire}:$entityId';
}
