import '../../features/items/data/item_dto.dart';
import '../../features/items/data/completion_event_dto.dart';
import '../../features/items/domain/item_type.dart';
import '../../features/approvals/data/completion_request_dto.dart';
import '../../features/points/data/ledger_entry_dto.dart';
import '../../features/rewards/data/reward_dto.dart';
import '../../features/rewards/data/box_rule_dto.dart';
import '../../features/rewards/data/redemption_dto.dart';
import '../../features/rewards/data/inventory_item_dto.dart';
import '../../features/rewards/domain/redemption_status.dart';
import '../../features/household/data/household_dto.dart';
import '../../features/household/data/user_profile_dto.dart';
import '../../features/behaviors/data/behavior_rule_dto.dart';

class SyncPayloadCodec {
  static Map<String, dynamic> itemToMap(ItemDto dto) {
    return <String, dynamic>{
      'id': dto.id,
      'householdId': dto.householdId,
      'name': dto.name,
      'categoryIndex': dto.categoryIndex,
      'icon': dto.icon,
      'intervalSeconds': dto.intervalSeconds,
      'points': dto.points,
      'overdueWeight': dto.overdueWeight,
      'protectionUntil': _encodeDate(dto.protectionUntil),
      'protectionUsed': dto.protectionUsed,
      'typeIndex': dto.typeIndex,
      'roomOrZone': dto.roomOrZone,
      'isPaused': dto.isPaused,
      'snoozedUntil': _encodeDate(dto.snoozedUntil),
    };
  }

  static ItemDto itemFromMap(Map<String, dynamic> map) {
    return ItemDto(
      id: map['id'] as String,
      householdId: map['householdId'] as String,
      name: map['name'] as String,
      categoryIndex: map['categoryIndex'] as int,
      icon: map['icon'] as String,
      intervalSeconds: map['intervalSeconds'] as int,
      points: map['points'] as int? ?? 10,
      overdueWeight: map['overdueWeight'] as int? ?? 0,
      protectionUntil: _decodeDate(map['protectionUntil']),
      protectionUsed: map['protectionUsed'] as bool? ?? false,
      typeIndex: map['typeIndex'] as int? ?? ItemType.recurring.index,
      roomOrZone: map['roomOrZone'] as String?,
      isPaused: map['isPaused'] as bool? ?? false,
      snoozedUntil: _decodeDate(map['snoozedUntil']),
    );
  }

  static Map<String, dynamic> completionEventToMap(CompletionEventDto dto) {
    return <String, dynamic>{
      'id': dto.id,
      'householdId': dto.householdId,
      'itemId': dto.itemId,
      'approvedAt': _encodeDate(dto.approvedAt),
    };
  }

  static CompletionEventDto completionEventFromMap(Map<String, dynamic> map) {
    return CompletionEventDto(
      id: map['id'] as String,
      householdId: map['householdId'] as String,
      itemId: map['itemId'] as String,
      approvedAt: _decodeDate(map['approvedAt']) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> completionRequestToMap(
    CompletionRequestDto dto,
  ) {
    return <String, dynamic>{
      'id': dto.id,
      'householdId': dto.householdId,
      'itemId': dto.itemId,
      'submittedByUserId': dto.submittedByUserId,
      'submittedAt': _encodeDate(dto.submittedAt),
      'statusIndex': dto.statusIndex,
      'note': dto.note,
      'reviewedByUserId': dto.reviewedByUserId,
      'reviewedAt': _encodeDate(dto.reviewedAt),
    };
  }

  static CompletionRequestDto completionRequestFromMap(
    Map<String, dynamic> map,
  ) {
    return CompletionRequestDto(
      id: map['id'] as String,
      householdId: map['householdId'] as String,
      itemId: map['itemId'] as String,
      submittedByUserId: map['submittedByUserId'] as String,
      submittedAt: _decodeDate(map['submittedAt']) ?? DateTime.now(),
      statusIndex: map['statusIndex'] as int,
      note: map['note'] as String?,
      reviewedByUserId: map['reviewedByUserId'] as String?,
      reviewedAt: _decodeDate(map['reviewedAt']),
    );
  }

  static Map<String, dynamic> ledgerEntryToMap(LedgerEntryDto dto) {
    return <String, dynamic>{
      'id': dto.id,
      'householdId': dto.householdId,
      'userId': dto.userId,
      'delta': dto.delta,
      'createdAt': _encodeDate(dto.createdAt),
      'reasonIndex': dto.reasonIndex,
      'relatedRequestId': dto.relatedRequestId,
      'relatedRedemptionId': dto.relatedRedemptionId,
    };
  }

  static LedgerEntryDto ledgerEntryFromMap(Map<String, dynamic> map) {
    return LedgerEntryDto(
      id: map['id'] as String,
      householdId: map['householdId'] as String,
      userId: map['userId'] as String,
      delta: map['delta'] as int,
      createdAt: _decodeDate(map['createdAt']) ?? DateTime.now(),
      reasonIndex: map['reasonIndex'] as int,
      relatedRequestId: map['relatedRequestId'] as String?,
      relatedRedemptionId: map['relatedRedemptionId'] as String?,
    );
  }

  static Map<String, dynamic> rewardToMap(RewardDto dto) {
    return <String, dynamic>{
      'id': dto.id,
      'householdId': dto.householdId,
      'title': dto.title,
      'description': dto.description,
      'weight': dto.weight,
      'enabled': dto.enabled,
    };
  }

  static RewardDto rewardFromMap(Map<String, dynamic> map) {
    return RewardDto(
      id: map['id'] as String,
      householdId: map['householdId'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      weight: map['weight'] as int,
      enabled: map['enabled'] as bool,
    );
  }

  static Map<String, dynamic> boxRuleToMap(BoxRuleDto dto) {
    return <String, dynamic>{
      'id': dto.id,
      'householdId': dto.householdId,
      'title': dto.title,
      'costPoints': dto.costPoints,
      'cooldownSeconds': dto.cooldownSeconds,
      'maxPerDay': dto.maxPerDay,
      'rewardIds': dto.rewardIds,
    };
  }

  static BoxRuleDto boxRuleFromMap(Map<String, dynamic> map) {
    return BoxRuleDto(
      id: map['id'] as String,
      householdId: map['householdId'] as String,
      title: map['title'] as String,
      costPoints: map['costPoints'] as int,
      cooldownSeconds: map['cooldownSeconds'] as int,
      maxPerDay: map['maxPerDay'] as int,
      rewardIds: (map['rewardIds'] as List).cast<String>(),
    );
  }

  static Map<String, dynamic> redemptionToMap(RedemptionDto dto) {
    return <String, dynamic>{
      'id': dto.id,
      'householdId': dto.householdId,
      'userId': dto.userId,
      'boxRuleId': dto.boxRuleId,
      'costPoints': dto.costPoints,
      'rolledAt': _encodeDate(dto.rolledAt),
      'outcomeRewardId': dto.outcomeRewardId,
      'rngVersion': dto.rngVersion,
      'statusIndex': dto.statusIndex,
      'requestedAt': _encodeDate(dto.requestedAt),
      'reviewedAt': _encodeDate(dto.reviewedAt),
      'reviewedByUserId': dto.reviewedByUserId,
    };
  }

  static RedemptionDto redemptionFromMap(Map<String, dynamic> map) {
    return RedemptionDto(
      id: map['id'] as String,
      householdId: map['householdId'] as String,
      userId: map['userId'] as String,
      boxRuleId: map['boxRuleId'] as String,
      costPoints: map['costPoints'] as int,
      rolledAt: _decodeDate(map['rolledAt']) ?? DateTime.now(),
      outcomeRewardId: map['outcomeRewardId'] as String,
      rngVersion: map['rngVersion'] as String,
      statusIndex:
          map['statusIndex'] as int? ?? RedemptionStatus.active.index,
      requestedAt: _decodeDate(map['requestedAt']),
      reviewedAt: _decodeDate(map['reviewedAt']),
      reviewedByUserId: map['reviewedByUserId'] as String?,
    );
  }

  static Map<String, dynamic> inventoryItemToMap(InventoryItemDto dto) {
    return <String, dynamic>{
      'id': dto.id,
      'householdId': dto.householdId,
      'userId': dto.userId,
      'typeIndex': dto.typeIndex,
      'durationHours': dto.durationHours,
      'purchasedAt': _encodeDate(dto.purchasedAt),
      'usedAt': _encodeDate(dto.usedAt),
      'appliedItemId': dto.appliedItemId,
    };
  }

  static InventoryItemDto inventoryItemFromMap(Map<String, dynamic> map) {
    return InventoryItemDto(
      id: map['id'] as String,
      householdId: map['householdId'] as String,
      userId: map['userId'] as String,
      typeIndex: map['typeIndex'] as int? ?? 0,
      durationHours: map['durationHours'] as int? ?? 24,
      purchasedAt: _decodeDate(map['purchasedAt']) ?? DateTime.now(),
      usedAt: _decodeDate(map['usedAt']),
      appliedItemId: map['appliedItemId'] as String?,
    );
  }

  static Map<String, dynamic> householdToMap(HouseholdDto dto) {
    return <String, dynamic>{
      'id': dto.id,
      'name': dto.name,
      'adminIds': dto.adminIds,
      'memberIds': dto.memberIds,
      'primaryAdminId': dto.primaryAdminId,
      'secondaryAdminId': dto.secondaryAdminId,
      'adminEpoch': dto.adminEpoch,
    };
  }

  static HouseholdDto householdFromMap(Map<String, dynamic> map) {
    return HouseholdDto(
      id: map['id'] as String,
      name: map['name'] as String,
      adminIds: (map['adminIds'] as List).cast<String>(),
      memberIds: (map['memberIds'] as List).cast<String>(),
      primaryAdminId: map['primaryAdminId'] as String? ?? '',
      secondaryAdminId: map['secondaryAdminId'] as String?,
      adminEpoch: map['adminEpoch'] as int? ?? 0,
    );
  }

  static Map<String, dynamic> userProfileToMap(UserProfileDto dto) {
    return <String, dynamic>{
      'id': dto.id,
      'householdId': dto.householdId,
      'displayName': dto.displayName,
      'roleName': dto.roleName,
    };
  }

  static UserProfileDto userProfileFromMap(Map<String, dynamic> map) {
    return UserProfileDto(
      id: map['id'] as String,
      householdId: map['householdId'] as String,
      displayName: map['displayName'] as String,
      roleName: map['roleName'] as String,
    );
  }

  static Map<String, dynamic> behaviorRuleToMap(BehaviorRuleDto dto) {
    final name = dto.name.trim();
    final likes = dto.likes < 0 ? 0 : dto.likes;
    final dislikes = dto.dislikes < 0 ? 0 : dto.dislikes;
    return <String, dynamic>{
      'id': dto.id,
      'householdId': dto.householdId,
      'name': name,
      'likes': likes,
      'dislikes': dislikes,
    };
  }

  static BehaviorRuleDto behaviorRuleFromMap(Map<String, dynamic> map) {
    final nameValue = map['name'] ?? map['title'] ?? map['label'];
    final likesValue = map['likes'] ?? map['likeCount'] ?? map['thumbsUp'];
    final dislikesValue =
        map['dislikes'] ?? map['dislikeCount'] ?? map['thumbsDown'];
    return BehaviorRuleDto(
      id: _readString(map['id']),
      householdId: _readString(map['householdId']),
      name: _readString(nameValue),
      likes: _readInt(likesValue),
      dislikes: _readInt(dislikesValue),
    );
  }

  static String? _encodeDate(DateTime? value) {
    return value?.toIso8601String();
  }

  static DateTime? _decodeDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  static String _readString(dynamic value) {
    if (value is String) {
      return value;
    }
    return '';
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return 0;
  }
}
