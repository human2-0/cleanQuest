import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../app_config/app_config.dart';
import '../providers/user_providers.dart';
import '../../features/items/data/item_dto.dart';
import '../../features/items/data/completion_event_dto.dart';
import '../../features/approvals/data/completion_request_dto.dart';
import '../../features/points/data/ledger_entry_dto.dart';
import '../../features/rewards/data/reward_dto.dart';
import '../../features/rewards/data/box_rule_dto.dart';
import '../../features/rewards/data/redemption_dto.dart';
import '../../features/rewards/data/inventory_item_dto.dart';
import '../../features/rewards/domain/redemption_status.dart';
import '../../features/behaviors/data/behavior_rule_dto.dart';
import '../../features/household/data/household_dto.dart';
import '../../features/household/domain/household.dart';
import '../../features/household/data/user_profile_dto.dart';
import '../../features/points/domain/ledger_reason.dart';
import 'p2p_sync_engine.dart';
import 'sync_models.dart';
import 'sync_payloads.dart';

class SyncCoordinator {
  SyncCoordinator({
    required P2pSyncEngine engine,
    required Box<ItemDto> itemsBox,
    required Box<CompletionEventDto> completionEventsBox,
    required Box<CompletionRequestDto> completionRequestsBox,
    required Box<LedgerEntryDto> ledgerBox,
    required Box<RewardDto> rewardsBox,
    required Box<BoxRuleDto> boxRulesBox,
    required Box<RedemptionDto> redemptionsBox,
    required Box<InventoryItemDto> inventoryBox,
    required Box<BehaviorRuleDto> behaviorRulesBox,
    required Box<HouseholdDto> householdsBox,
    required Box<UserProfileDto> userProfilesBox,
    required Box<dynamic> syncEventsBox,
    required Box<dynamic> syncMetaBox,
    required Box<dynamic> syncOutboxBox,
  })  : _engine = engine,
        _itemsBox = itemsBox,
        _completionEventsBox = completionEventsBox,
        _completionRequestsBox = completionRequestsBox,
        _ledgerBox = ledgerBox,
        _rewardsBox = rewardsBox,
        _boxRulesBox = boxRulesBox,
        _redemptionsBox = redemptionsBox,
        _inventoryBox = inventoryBox,
        _behaviorRulesBox = behaviorRulesBox,
        _householdsBox = householdsBox,
        _userProfilesBox = userProfilesBox,
        _syncEventsBox = syncEventsBox,
        _syncMetaBox = syncMetaBox,
        _syncOutboxBox = syncOutboxBox;

  final P2pSyncEngine _engine;
  final Box<ItemDto> _itemsBox;
  final Box<CompletionEventDto> _completionEventsBox;
  final Box<CompletionRequestDto> _completionRequestsBox;
  final Box<LedgerEntryDto> _ledgerBox;
  final Box<RewardDto> _rewardsBox;
  final Box<BoxRuleDto> _boxRulesBox;
  final Box<RedemptionDto> _redemptionsBox;
  final Box<InventoryItemDto> _inventoryBox;
  final Box<BehaviorRuleDto> _behaviorRulesBox;
  final Box<HouseholdDto> _householdsBox;
  final Box<UserProfileDto> _userProfilesBox;
  final Box<dynamic> _syncEventsBox;
  final Box<dynamic> _syncMetaBox;
  final Box<dynamic> _syncOutboxBox;

  StreamSubscription<Map<String, dynamic>>? _subscription;
  StreamSubscription<SyncConnectionState>? _stateSubscription;
  StreamSubscription<BoxEvent>? _householdSub;
  final StreamController<List<SyncPresenceEntry>> _presenceController =
      StreamController.broadcast();
  Future<void> _engineTask = Future.value();
  String _householdId = '';
  String _userId = '';
  bool _started = false;
  int _localEventCounter = 0;
  final Map<String, int> _presenceByUser = {};
  final Map<String, int> _autoAdmitByUser = {};
  Timer? _presenceTimer;
  Timer? _syncPulseTimer;
  UserRole? _role;
  String _primaryAdminId = '';
  int _adminEpoch = 0;
  int _lastPrimaryHeartbeatMs = 0;
  bool _promotionInFlight = false;
  int _syncStartedAtMs = 0;
  int _lastSyncRequestMs = 0;
  int _lastInboundMs = 0;

  Stream<List<SyncPresenceEntry>> get presence =>
      _presenceController.stream;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[sync] $message');
    }
  }

  void startIfReady(AppConfig config) {
    final householdId = config.householdId;
    final userId = config.userId;
    final role = config.role;
    _log(
      'startIfReady onboarding=${config.onboardingComplete} '
      'role=$role userId=$userId householdId=$householdId '
      'householdName=${config.householdName}',
    );
    if (!config.onboardingComplete ||
        householdId == null ||
        householdId.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      _log('stop: missing onboarding or ids');
      _stop();
      return;
    }
    if (_started &&
        householdId == _householdId &&
        userId == _userId) {
      if (_role != role) {
        _role = role;
        _refreshAdminState();
      }
      return;
    }
    _householdId = householdId;
    _userId = userId;
    _role = role;
    _start();
  }

  Future<void> publishUpsert(
    SyncEntityType type,
    Map<String, dynamic> payload, {
    required String entityId,
  }) async {
    if (_householdId.isEmpty || _userId.isEmpty) {
      return;
    }
    final tsMs = DateTime.now().millisecondsSinceEpoch;
    _markEntityTimestamp(type, entityId, tsMs);
    final eventId = _newEventId(tsMs);
    final outboundType = _engine.isHost ? 'event' : 'mutation';
    final message = <String, dynamic>{
      'type': outboundType,
      'householdId': _householdId,
      'senderId': _userId,
      'entityType': type.wire,
      'action': 'upsert',
      'entityId': entityId,
      'payload': payload,
      'ts': DateTime.now().toIso8601String(),
      'tsMs': tsMs,
      'eventId': eventId,
    };
    final eventRecord = Map<String, dynamic>.from(message);
    eventRecord['type'] = 'event';
    _recordEvent(eventRecord);
    if (!_isConnectedOrHosting()) {
      if (!_engine.isHost) {
        _queueOutbox(message, type, entityId);
      }
      await ensureConnected();
      return;
    }
    if (!_engine.isHost &&
        !_isMemberConfirmed() &&
        !_canSendWhileUnconfirmed(type, 'upsert', payload)) {
      _queueOutbox(message, type, entityId);
      return;
    }
    await _sendMessage(message);
  }

  Future<void> publishDelete(
    SyncEntityType type,
    String entityId,
  ) async {
    if (_householdId.isEmpty || _userId.isEmpty) {
      return;
    }
    final tsMs = DateTime.now().millisecondsSinceEpoch;
    _markEntityTimestamp(type, entityId, tsMs);
    final eventId = _newEventId(tsMs);
    final outboundType = _engine.isHost ? 'event' : 'mutation';
    final message = <String, dynamic>{
      'type': outboundType,
      'householdId': _householdId,
      'senderId': _userId,
      'entityType': type.wire,
      'action': 'delete',
      'entityId': entityId,
      'payload': null,
      'ts': DateTime.now().toIso8601String(),
      'tsMs': tsMs,
      'eventId': eventId,
    };
    final eventRecord = Map<String, dynamic>.from(message);
    eventRecord['type'] = 'event';
    _recordEvent(eventRecord);
    if (!_isConnectedOrHosting()) {
      if (!_engine.isHost) {
        _queueOutbox(message, type, entityId);
      }
      await ensureConnected();
      return;
    }
    if (!_engine.isHost && !_isMemberConfirmed()) {
      _queueOutbox(message, type, entityId);
      return;
    }
    await _sendMessage(message);
  }

  Future<void> _sendMessage(Map<String, dynamic> message) async {
    try {
      if (_engine.isHost) {
        await _engine.broadcast(message);
      } else {
        await _engine.send(message);
      }
    } on SocketException catch (error) {
      _log('send socket exception: $error');
      await ensureConnected();
    } catch (error) {
      _log('send exception: $error');
      await ensureConnected();
    }
  }

  Future<void> requestSync() async {
    if (!_started || _householdId.isEmpty || _userId.isEmpty) {
      return;
    }
    await _sendSyncRequest();
  }

  Future<void> ensureConnected() async {
    if (!_started || _householdId.isEmpty || _userId.isEmpty) {
      return;
    }
    final state = _engine.currentState;
    if (state == SyncConnectionState.connected ||
        state == SyncConnectionState.hosting ||
        state == SyncConnectionState.discovering) {
      return;
    }
    await restartConnection();
  }

  Future<bool> waitForConnection(Duration timeout) async {
    if (!_started) {
      return false;
    }
    if (_isConnectedOrHosting()) {
      return true;
    }
    final completer = Completer<bool>();
    late final StreamSubscription<SyncConnectionState> sub;
    sub = _engine.state.listen((state) {
      if (state == SyncConnectionState.connected ||
          state == SyncConnectionState.hosting) {
        sub.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });
    Timer(timeout, () {
      sub.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });
    return completer.future;
  }

  Future<void> requestFullSync() async {
    if (!_started || _householdId.isEmpty || _userId.isEmpty) {
      return;
    }
    await _sendSyncRequest(full: true);
  }

  Future<void> restartConnection() async {
    if (_householdId.isEmpty || _userId.isEmpty) {
      return;
    }
    await _engine.stop();
    await _engine.start();
    await _sendSyncRequest(full: true);
  }

  Future<void> dispose() async {
    _stop();
    await _presenceController.close();
  }

  void _start() {
    _subscription?.cancel();
    _stateSubscription?.cancel();
    _householdSub?.cancel();
    _subscription = _engine.messages.listen(_handleMessage);
    _stateSubscription = _engine.state.listen((state) {
      _log('engine state=$state');
      if (state == SyncConnectionState.connected) {
        _sendSyncRequest();
        _announceLocalProfile();
        _flushOutbox();
      } else if (state == SyncConnectionState.hosting) {
        _flushOutbox();
      }
    });
    _householdSub = _householdsBox.watch(key: _householdId).listen((_) {
      _refreshAdminState();
    });
    _startPresenceTimer();
    _startSyncPulseTimer();
    _syncStartedAtMs = DateTime.now().millisecondsSinceEpoch;
    _refreshAdminState();
    _started = true;
    _queueEngine(() async {
      await _engine.stop();
      await _engine.start();
    });
  }

  void _stop() {
    _subscription?.cancel();
    _subscription = null;
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _householdSub?.cancel();
    _householdSub = null;
    _presenceTimer?.cancel();
    _presenceTimer = null;
    _syncPulseTimer?.cancel();
    _syncPulseTimer = null;
    _presenceByUser.clear();
    _emitPresence();
    _started = false;
    _queueEngine(_engine.stop);
  }

  Future<void> _handleMessage(Map<String, dynamic> message) async {
    final householdId = message['householdId'] as String?;
    if (householdId != _householdId) {
      return;
    }
    _lastInboundMs = DateTime.now().millisecondsSinceEpoch;
    final type = message['type'] as String?;
    if (type == 'heartbeat') {
      final senderId = message['senderId'] as String?;
      if (senderId != null && senderId.isNotEmpty) {
        _trackPresence(senderId);
        final displayName = message['displayName'] as String?;
        final isAdmin = message['isAdmin'] == true;
        _seedProfileFromHeartbeat(senderId, displayName, isAdmin);
        if (_engine.isHost) {
          await _maybeAdmitMember(senderId);
        }
        if (senderId == _primaryAdminId && senderId != _userId) {
          _lastPrimaryHeartbeatMs =
              DateTime.now().millisecondsSinceEpoch;
        }
      }
      return;
    }
    if (type == 'sync_request') {
      final senderId = message['senderId'] as String?;
      if (senderId != null && senderId.isNotEmpty) {
        _trackPresence(senderId);
      }
      if (_engine.isHost) {
        await _handleSyncRequest(message);
      }
      return;
    }
    if (type == 'sync_response') {
      final senderId = message['senderId'] as String?;
      if (senderId != null && senderId.isNotEmpty) {
        _trackPresence(senderId);
      }
      await _handleSyncResponse(message);
      return;
    }
    if (type == 'sync_snapshot') {
      final senderId = message['senderId'] as String?;
      if (senderId != null && senderId.isNotEmpty) {
        _trackPresence(senderId);
      }
      await _handleSyncSnapshot(message);
      return;
    }
    final senderId = message['senderId'] as String?;
    if (senderId != null && senderId.isNotEmpty) {
      _trackPresence(senderId);
      if (senderId == _primaryAdminId && senderId != _userId) {
        _lastPrimaryHeartbeatMs = DateTime.now().millisecondsSinceEpoch;
      }
    }
    if (senderId == _userId) {
      return;
    }

    if (type == 'mutation') {
      if (_engine.isHost) {
        await _applyEvent(message);
        final eventMessage = Map<String, dynamic>.from(message);
        eventMessage['type'] = 'event';
        eventMessage['eventId'] = message['eventId'] ?? _newEventId(
          _readTimestampMs(message),
        );
        eventMessage['tsMs'] = _readTimestampMs(message);
        _recordEvent(eventMessage);
        await _engine.broadcast(eventMessage);
      }
      return;
    }

    if (type == 'event') {
      await _applyEvent(message);
    }
  }

  Future<void> _applyEvent(Map<String, dynamic> message) async {
    final entityType =
        syncEntityTypeFromWire(message['entityType'] as String?);
    if (entityType == null) {
      return;
    }
    final senderId = message['senderId'] as String? ?? '';
    final tsMs = _readTimestampMs(message);
    final action = message['action'] as String?;
    final entityId = message['entityId'] as String?;
    if (action == null || entityId == null || entityId.isEmpty) {
      return;
    }
    if (!_isAuthorizedMutation(
      entityType: entityType,
      action: action,
      entityId: entityId,
      senderId: senderId,
      payload: message['payload'],
    )) {
      _log(
        'auth reject senderId=$senderId entityType=${entityType.wire} '
        'action=$action entityId=$entityId',
      );
      return;
    }
    if (!_shouldApply(entityType, entityId, tsMs)) {
      return;
    }

    if (action == 'delete') {
      await _deleteEntity(entityType, entityId);
      if (message['type'] == 'event') {
        _recordEvent(message);
      }
      if (entityType == SyncEntityType.households &&
          entityId == _householdId) {
        _refreshAdminState();
      }
      return;
    }

    final payload = message['payload'];
    if (payload is! Map) {
      return;
    }
    if (entityType == SyncEntityType.households &&
        !_passesHouseholdCas(
          payload: payload.cast<String, dynamic>(),
          entityId: entityId,
        )) {
      _log(
        'cas reject entityType=${entityType.wire} entityId=$entityId '
        'senderId=$senderId',
      );
      return;
    }
    await _upsertEntity(entityType, payload.cast<String, dynamic>(), entityId);
    if (message['type'] == 'event') {
      _recordEvent(message);
    }
    if (entityType == SyncEntityType.households &&
        entityId == _householdId) {
      _refreshAdminState();
    }
  }

  bool _isAuthorizedMutation({
    required SyncEntityType entityType,
    required String action,
    required String entityId,
    required String senderId,
    required dynamic payload,
  }) {
    if (senderId.isEmpty) {
      return false;
    }
    if (senderId == _userId) {
      return true;
    }
    final householdDto = _householdsBox.get(_householdId);
    if (householdDto == null) {
      if (entityType == SyncEntityType.households &&
          action == 'upsert' &&
          payload is Map) {
        return _allowHouseholdBootstrap(senderId, payload.cast<String, dynamic>());
      }
      return false;
    }
    final household = householdDto.toDomain();
    final isAdmin = _isSenderAdmin(household, senderId);
    final isMember = isAdmin || household.memberIds.contains(senderId);

    if (entityType == SyncEntityType.households) {
      if (action == 'delete') {
        return isAdmin;
      }
      if (isAdmin) {
        return true;
      }
      if (payload is! Map) {
        return false;
      }
      if (_allowAdminHouseholdUpsertFromPayload(
        senderId: senderId,
        payload: payload.cast<String, dynamic>(),
      )) {
        return true;
      }
      return _allowNonAdminHouseholdUpsert(
        senderId: senderId,
        existing: household,
        payload: payload.cast<String, dynamic>(),
      );
    }

    if (entityType == SyncEntityType.userProfiles) {
      if (!isMember) {
        return false;
      }
      if (isAdmin) {
        return true;
      }
      if (senderId != entityId || payload is! Map) {
        return false;
      }
      return _allowSelfProfileUpdate(
        senderId: senderId,
        payload: payload.cast<String, dynamic>(),
      );
    }

    if (!isMember) {
      return false;
    }

    if (_isAdminOnlyEntity(entityType)) {
      return isAdmin;
    }

    if (action == 'delete') {
      return _allowMemberDelete(
        entityType: entityType,
        entityId: entityId,
        senderId: senderId,
      );
    }

    if (payload is! Map) {
      return false;
    }
    return _allowMemberUpsert(
      entityType: entityType,
      senderId: senderId,
      payload: payload.cast<String, dynamic>(),
    );
  }

  bool _isAdminOnlyEntity(SyncEntityType type) {
    switch (type) {
      case SyncEntityType.items:
      case SyncEntityType.rewards:
      case SyncEntityType.boxRules:
      case SyncEntityType.inventoryItems:
      case SyncEntityType.behaviorRules:
      case SyncEntityType.completionEvents:
        return true;
      case SyncEntityType.completionRequests:
      case SyncEntityType.ledgerEntries:
      case SyncEntityType.redemptions:
      case SyncEntityType.households:
      case SyncEntityType.userProfiles:
        return false;
    }
  }

  bool _allowMemberUpsert({
    required SyncEntityType entityType,
    required String senderId,
    required Map<String, dynamic> payload,
  }) {
    switch (entityType) {
      case SyncEntityType.completionRequests:
        return _readString(payload['submittedByUserId']) == senderId;
      case SyncEntityType.redemptions:
        return _allowMemberRedemptionUpsert(senderId, payload);
      case SyncEntityType.ledgerEntries:
        return _allowMemberLedgerUpsert(senderId, payload);
      case SyncEntityType.items:
      case SyncEntityType.completionEvents:
      case SyncEntityType.rewards:
      case SyncEntityType.boxRules:
      case SyncEntityType.inventoryItems:
      case SyncEntityType.behaviorRules:
      case SyncEntityType.households:
      case SyncEntityType.userProfiles:
        return false;
    }
  }

  bool _allowMemberDelete({
    required SyncEntityType entityType,
    required String entityId,
    required String senderId,
  }) {
    switch (entityType) {
      case SyncEntityType.completionRequests:
        final dto = _completionRequestsBox.get(entityId);
        if (dto == null) {
          return false;
        }
        return dto.submittedByUserId == senderId;
      case SyncEntityType.redemptions:
        final dto = _redemptionsBox.get(entityId);
        if (dto == null) {
          return false;
        }
        return dto.userId == senderId && dto.reviewedByUserId == null;
      default:
        return false;
    }
  }

  bool _allowMemberLedgerUpsert(
    String senderId,
    Map<String, dynamic> payload,
  ) {
    final userId = _readString(payload['userId']);
    if (userId != senderId) {
      return false;
    }
    final reasonIndex = _readInt(payload['reasonIndex']);
    if (reasonIndex != LedgerReason.redemptionCost.index) {
      return false;
    }
    final redemptionId = _readString(payload['relatedRedemptionId']);
    return redemptionId.isNotEmpty;
  }

  bool _allowMemberRedemptionUpsert(
    String senderId,
    Map<String, dynamic> payload,
  ) {
    final userId = _readString(payload['userId']);
    if (userId != senderId) {
      return false;
    }
    final reviewedBy = _readString(payload['reviewedByUserId']);
    if (reviewedBy.isNotEmpty) {
      return false;
    }
    final statusIndex = _readInt(payload['statusIndex']);
    final allowed = <int>{
      RedemptionStatus.active.index,
      RedemptionStatus.pending.index,
      RedemptionStatus.used.index,
    };
    return allowed.contains(statusIndex);
  }

  bool _allowSelfProfileUpdate({
    required String senderId,
    required Map<String, dynamic> payload,
  }) {
    final incomingRole = _readString(payload['roleName']);
    if (incomingRole.isNotEmpty &&
        incomingRole != UserRole.member.name) {
      return false;
    }
    final householdId = _readString(payload['householdId']);
    return householdId == _householdId;
  }

  bool _allowHouseholdBootstrap(
    String senderId,
    Map<String, dynamic> payload,
  ) {
    final adminIds = _readStringList(payload['adminIds']);
    final memberIds = _readStringList(payload['memberIds']);
    final primaryAdminId = _readString(payload['primaryAdminId']);
    final secondaryAdminId = _readString(payload['secondaryAdminId']);
    final adminEpoch = _readInt(payload['adminEpoch']);
    if (adminIds.isNotEmpty ||
        primaryAdminId.isNotEmpty ||
        secondaryAdminId.isNotEmpty ||
        adminEpoch != 0) {
      return false;
    }
    return memberIds.contains(senderId);
  }

  bool _allowAdminHouseholdUpsertFromPayload({
    required String senderId,
    required Map<String, dynamic> payload,
  }) {
    final adminIds = _readStringList(payload['adminIds']);
    if (!adminIds.contains(senderId)) {
      return false;
    }
    final primaryAdminId = _readString(payload['primaryAdminId']);
    if (primaryAdminId.isNotEmpty && primaryAdminId != senderId) {
      return false;
    }
    final memberIds = _readStringList(payload['memberIds']);
    if (!memberIds.contains(_userId)) {
      return false;
    }
    return true;
  }

  bool _allowNonAdminHouseholdUpsert({
    required String senderId,
    required Household existing,
    required Map<String, dynamic> payload,
  }) {
    final incomingId = _readString(payload['id']);
    if (incomingId != existing.id) {
      return false;
    }
    final incomingName = _readString(payload['name']).trim();
    final incomingAdmins = _readStringList(payload['adminIds']);
    final incomingMembers = _readStringList(payload['memberIds']);
    final incomingPrimary = _readString(payload['primaryAdminId']);
    final incomingSecondary = _readString(payload['secondaryAdminId']);
    final incomingEpoch = _readInt(payload['adminEpoch']);

    if (!_sameSet(existing.adminIds, incomingAdmins)) {
      return false;
    }
    if (incomingPrimary != existing.primaryAdminId ||
        incomingSecondary != (existing.secondaryAdminId ?? '') ||
        incomingEpoch != existing.adminEpoch) {
      return false;
    }

    if (incomingName != existing.name) {
      if (!_isPlaceholderHouseholdName(existing.name) ||
          incomingName.isEmpty) {
        return false;
      }
    }

    final existingMembers = existing.memberIds;
    if (_sameSet(existingMembers, incomingMembers)) {
      return existingMembers.contains(senderId);
    }
    final expected = {...existingMembers, senderId}.toList();
    return _sameSet(expected, incomingMembers);
  }

  bool _isSenderAdmin(Household household, String senderId) {
    if (household.adminIds.isEmpty) {
      if (household.primaryAdminId == senderId) {
        return true;
      }
      if (household.secondaryAdminId == senderId) {
        return true;
      }
      return false;
    }
    return household.adminIds.contains(senderId);
  }

  bool _passesHouseholdCas({
    required Map<String, dynamic> payload,
    required String entityId,
  }) {
    if (!payload.containsKey('expectedPrimaryAdminId') &&
        !payload.containsKey('expectedAdminEpoch')) {
      return true;
    }
    final expectedPrimary =
        _readString(payload['expectedPrimaryAdminId']);
    final expectedEpoch = _readInt(payload['expectedAdminEpoch']);
    final existingDto = _householdsBox.get(entityId);
    if (existingDto == null) {
      return false;
    }
    final existing = existingDto.toDomain();
    if (expectedPrimary.isNotEmpty &&
        existing.primaryAdminId != expectedPrimary) {
      return false;
    }
    if (existing.adminEpoch != expectedEpoch) {
      return false;
    }
    return true;
  }

  bool _sameSet(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    final leftSet = left.toSet();
    if (leftSet.length != right.length) {
      return false;
    }
    for (final value in right) {
      if (!leftSet.contains(value)) {
        return false;
      }
    }
    return true;
  }

  bool _isPlaceholderHouseholdName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ||
        trimmed == 'Household' ||
        trimmed == 'Gospodarstwo';
  }

  String _readString(dynamic value) {
    if (value is String) {
      return value;
    }
    return '';
  }

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return 0;
  }

  List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((entry) => entry.toString()).toList();
    }
    return <String>[];
  }

  Future<void> _handleSyncRequest(Map<String, dynamic> message) async {
    final mode = message['mode'] as String? ?? 'delta';
    if (mode == 'full') {
      await _sendSnapshot();
      return;
    }
    final sinceMs = message['sinceMs'] as int? ?? 0;
    final events = _syncEventsBox.values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .where((event) =>
            event['householdId'] == _householdId &&
            (event['tsMs'] as int? ?? 0) > sinceMs)
        .toList()
      ..sort((a, b) => (a['tsMs'] as int? ?? 0)
          .compareTo(b['tsMs'] as int? ?? 0));
    final response = <String, dynamic>{
      'type': 'sync_response',
      'householdId': _householdId,
      'senderId': _userId,
      'events': events,
      'serverTsMs': DateTime.now().millisecondsSinceEpoch,
    };
    await _engine.broadcast(response);
  }

  Future<void> _handleSyncResponse(Map<String, dynamic> message) async {
    final events = message['events'];
    if (events is! List) {
      return;
    }
    for (final raw in events) {
      if (raw is! Map) {
        continue;
      }
      await _applyEvent(raw.cast<String, dynamic>());
    }
  }

  Future<void> _sendSyncRequest({bool full = false}) async {
    final sinceMs = full ? 0 : _readLastEventTs();
    final message = <String, dynamic>{
      'type': 'sync_request',
      'householdId': _householdId,
      'sinceMs': sinceMs,
      'senderId': _userId,
      'tsMs': DateTime.now().millisecondsSinceEpoch,
    };
    if (full) {
      message['mode'] = 'full';
    }
    _lastSyncRequestMs = DateTime.now().millisecondsSinceEpoch;
    await _engine.send(message);
  }

  Future<void> _sendSnapshot() async {
    final snapshot = <String, List<Map<String, dynamic>>>{
      SyncEntityType.items.wire: _itemsBox.values
          .where((dto) => dto.householdId == _householdId)
          .map((dto) => SyncPayloadCodec.itemToMap(dto))
          .toList(),
      SyncEntityType.completionEvents.wire: _completionEventsBox.values
          .where((dto) => dto.householdId == _householdId)
          .map((dto) => SyncPayloadCodec.completionEventToMap(dto))
          .toList(),
      SyncEntityType.completionRequests.wire: _completionRequestsBox.values
          .where((dto) => dto.householdId == _householdId)
          .map((dto) => SyncPayloadCodec.completionRequestToMap(dto))
          .toList(),
      SyncEntityType.ledgerEntries.wire: _ledgerBox.values
          .where((dto) => dto.householdId == _householdId)
          .map((dto) => SyncPayloadCodec.ledgerEntryToMap(dto))
          .toList(),
      SyncEntityType.rewards.wire: _rewardsBox.values
          .where((dto) => dto.householdId == _householdId)
          .map((dto) => SyncPayloadCodec.rewardToMap(dto))
          .toList(),
      SyncEntityType.boxRules.wire: _boxRulesBox.values
          .where((dto) => dto.householdId == _householdId)
          .map((dto) => SyncPayloadCodec.boxRuleToMap(dto))
          .toList(),
      SyncEntityType.redemptions.wire: _redemptionsBox.values
          .where((dto) => dto.householdId == _householdId)
          .map((dto) => SyncPayloadCodec.redemptionToMap(dto))
          .toList(),
      SyncEntityType.inventoryItems.wire: _inventoryBox.values
          .where((dto) => dto.householdId == _householdId)
          .map((dto) => SyncPayloadCodec.inventoryItemToMap(dto))
          .toList(),
      SyncEntityType.behaviorRules.wire: _behaviorRulesBox.values
          .where((dto) =>
              dto.householdId == _householdId ||
              dto.householdId.trim().isEmpty)
          .map((dto) => SyncPayloadCodec.behaviorRuleToMap(dto))
          .toList(),
      SyncEntityType.households.wire: _householdsBox.values
          .where((dto) => dto.id == _householdId)
          .map((dto) => SyncPayloadCodec.householdToMap(dto))
          .toList(),
      SyncEntityType.userProfiles.wire: _userProfilesBox.values
          .where((dto) => dto.householdId == _householdId)
          .map((dto) => SyncPayloadCodec.userProfileToMap(dto))
          .toList(),
    };
    final response = <String, dynamic>{
      'type': 'sync_snapshot',
      'householdId': _householdId,
      'senderId': _userId,
      'snapshot': snapshot,
      'serverTsMs': DateTime.now().millisecondsSinceEpoch,
    };
    await _engine.broadcast(response);
  }

  Future<void> _announceLocalProfile() async {
    if (_userId.isEmpty) {
      return;
    }
    final dto = _userProfilesBox.get(_userId);
    if (dto == null || dto.displayName.trim().isEmpty) {
      return;
    }
    await publishUpsert(
      SyncEntityType.userProfiles,
      SyncPayloadCodec.userProfileToMap(dto),
      entityId: _userId,
    );
  }

  Future<void> _handleSyncSnapshot(Map<String, dynamic> message) async {
    final snapshot = message['snapshot'];
    if (snapshot is! Map) {
      return;
    }
    final senderId = message['senderId'] as String? ?? '';
    var senderIsAdmin = false;
    var senderHasAdminClaim = false;
    if (kDebugMode) {
      _log('snapshot received senderId=$senderId entries=${snapshot.length}');
    }
    if (senderId.isNotEmpty) {
      final householdDto = _householdsBox.get(_householdId);
      if (householdDto != null) {
        senderIsAdmin = _isSenderAdmin(householdDto.toDomain(), senderId);
      }
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final entry in snapshot.entries) {
      final type = syncEntityTypeFromWire(entry.key.toString());
      if (type == null) {
        continue;
      }
      if (kDebugMode) {
        final count = entry.value is List ? (entry.value as List).length : -1;
        _log(
          'snapshot type=${entry.key} count=$count '
          'senderIsAdmin=$senderIsAdmin senderHasAdminClaim=$senderHasAdminClaim',
        );
      }
      if (type == SyncEntityType.households && entry.value is List) {
        for (final payload in entry.value as List) {
          if (payload is! Map) {
            continue;
          }
          final adminIds = _readStringList(payload['adminIds']);
          if (adminIds.contains(senderId)) {
            senderHasAdminClaim = true;
            break;
          }
        }
        if (kDebugMode) {
          _log(
            'snapshot household adminClaim=$senderHasAdminClaim senderId=$senderId',
          );
        }
      }
      if (!senderIsAdmin && _isAdminOnlyEntity(type)) {
        continue;
      }
      if (senderIsAdmin &&
          _isAdminOnlyEntity(type) &&
          !senderHasAdminClaim) {
        continue;
      }
      if (type == SyncEntityType.userProfiles) {
        await _replaceUserProfiles(entry.value, nowMs);
        continue;
      }
      final payloads = entry.value;
      if (payloads is! List) {
        continue;
      }
      final typed = <Map<String, dynamic>>[];
      for (final payload in payloads) {
        if (payload is Map) {
          typed.add(payload.cast<String, dynamic>());
        }
      }
      await _replaceEntities(type, typed, nowMs);
    }
    _syncMetaBox.put(_lastEventTsKey(), nowMs);
    _refreshAdminState();
  }

  Future<void> _replaceUserProfiles(dynamic payloads, int nowMs) async {
    if (payloads is! List) {
      return;
    }
    final typed = <Map<String, dynamic>>[];
    for (final payload in payloads) {
      if (payload is Map) {
        typed.add(payload.cast<String, dynamic>());
      }
    }
    final incomingIds = <String>{};
    for (final payload in typed) {
      final id = payload['id'];
      if (id is String && id.isNotEmpty) {
        incomingIds.add(id);
      }
    }
    await _deleteMissingEntities(SyncEntityType.userProfiles, incomingIds);
    for (final payload in typed) {
      final id = payload['id'];
      if (id is! String || id.isEmpty) {
        continue;
      }
      if (id == _userId) {
        continue;
      }
      await _upsertEntity(SyncEntityType.userProfiles, payload, id);
      _markEntityTimestamp(SyncEntityType.userProfiles, id, nowMs);
    }
  }

  Future<void> _replaceEntities(
    SyncEntityType type,
    List<Map<String, dynamic>> payloads,
    int nowMs,
  ) async {
    if (type == SyncEntityType.behaviorRules) {
      for (final payload in payloads) {
        final id = payload['id'];
        if (id is! String || id.isEmpty) {
          continue;
        }
        if (_shouldPreserveQueued(type, id)) {
          continue;
        }
        await _upsertEntity(type, payload, id);
        _markEntityTimestamp(type, id, nowMs);
      }
      return;
    }
    final incomingIds = <String>{};
    for (final payload in payloads) {
      final id = payload['id'];
      if (id is String && id.isNotEmpty) {
        incomingIds.add(id);
      }
    }
    await _deleteMissingEntities(type, incomingIds);
    for (final payload in payloads) {
      final id = payload['id'];
      if (id is! String || id.isEmpty) {
        continue;
      }
      if (_shouldPreserveQueued(type, id)) {
        continue;
      }
      await _upsertEntity(type, payload, id);
      _markEntityTimestamp(type, id, nowMs);
    }
  }

  Future<void> _deleteMissingEntities(
    SyncEntityType type,
    Set<String> keepIds,
  ) async {
    switch (type) {
      case SyncEntityType.items:
        for (final dto in _itemsBox.values) {
          if (dto.householdId == _householdId && !keepIds.contains(dto.id)) {
            await _itemsBox.delete(dto.id);
          }
        }
        return;
      case SyncEntityType.completionEvents:
        for (final dto in _completionEventsBox.values) {
          if (dto.householdId == _householdId && !keepIds.contains(dto.id)) {
            await _completionEventsBox.delete(dto.id);
          }
        }
        return;
      case SyncEntityType.completionRequests:
        for (final dto in _completionRequestsBox.values) {
          if (dto.householdId == _householdId && !keepIds.contains(dto.id)) {
            if (_shouldPreserveQueued(SyncEntityType.completionRequests, dto.id)) {
              continue;
            }
            await _completionRequestsBox.delete(dto.id);
          }
        }
        return;
      case SyncEntityType.ledgerEntries:
        for (final dto in _ledgerBox.values) {
          if (dto.householdId == _householdId && !keepIds.contains(dto.id)) {
            if (_shouldPreserveQueued(SyncEntityType.ledgerEntries, dto.id)) {
              continue;
            }
            await _ledgerBox.delete(dto.id);
          }
        }
        return;
      case SyncEntityType.rewards:
        for (final dto in _rewardsBox.values) {
          if (dto.householdId == _householdId && !keepIds.contains(dto.id)) {
            await _rewardsBox.delete(dto.id);
          }
        }
        return;
      case SyncEntityType.boxRules:
        for (final dto in _boxRulesBox.values) {
          if (dto.householdId == _householdId && !keepIds.contains(dto.id)) {
            await _boxRulesBox.delete(dto.id);
          }
        }
        return;
      case SyncEntityType.redemptions:
        for (final dto in _redemptionsBox.values) {
          if (dto.householdId == _householdId && !keepIds.contains(dto.id)) {
            if (_shouldPreserveQueued(SyncEntityType.redemptions, dto.id)) {
              continue;
            }
            await _redemptionsBox.delete(dto.id);
          }
        }
        return;
      case SyncEntityType.inventoryItems:
        for (final dto in _inventoryBox.values) {
          if (dto.householdId == _householdId && !keepIds.contains(dto.id)) {
            await _inventoryBox.delete(dto.id);
          }
        }
        return;
      case SyncEntityType.behaviorRules:
        return;
        return;
      case SyncEntityType.households:
        for (final dto in _householdsBox.values) {
          if (dto.id == _householdId && !keepIds.contains(dto.id)) {
            await _householdsBox.delete(dto.id);
          }
        }
        return;
      case SyncEntityType.userProfiles:
        for (final dto in _userProfilesBox.values) {
          if (dto.householdId == _householdId &&
              dto.id != _userId &&
              !keepIds.contains(dto.id)) {
            await _userProfilesBox.delete(dto.id);
          }
        }
        return;
    }
  }

  void _startPresenceTimer() {
    _presenceTimer?.cancel();
    _presenceTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _emitPresence());
  }

  void _startSyncPulseTimer() {
    _syncPulseTimer?.cancel();
    _syncPulseTimer =
        Timer.periodic(const Duration(seconds: 6), (_) => _syncPulse());
  }

  void _syncPulse() {
    if (!_started || _engine.isHost || !_isConnectedOrHosting()) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    const syncIntervalMs = 12000;
    if (now - _lastSyncRequestMs > syncIntervalMs) {
      _sendSyncRequest();
      return;
    }
    const inboundStaleMs = 20000;
    if (_lastInboundMs > 0 && now - _lastInboundMs > inboundStaleMs) {
      _sendSyncRequest();
    }
  }

  void _trackPresence(String senderId) {
    if (senderId == _userId) {
      return;
    }
    _presenceByUser[senderId] = DateTime.now().millisecondsSinceEpoch;
    _emitPresence();
  }

  void _emitPresence() {
    if (_presenceController.isClosed) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    const timeoutMs = 30000;
    _presenceByUser.removeWhere(
      (_, lastSeen) => now - lastSeen > timeoutMs,
    );
    final entries = _presenceByUser.entries
        .map((entry) => SyncPresenceEntry(
              userId: entry.key,
              lastSeenMs: entry.value,
            ))
        .toList()
      ..sort((a, b) => b.lastSeenMs.compareTo(a.lastSeenMs));
    _presenceController.add(entries);
    _maybePromoteToPrimary(now);
  }

  void _refreshAdminState() {
    final dto = _householdsBox.get(_householdId);
    if (dto == null) {
      _log('admin refresh skipped: missing household $_householdId');
      return;
    }
    final household = dto.toDomain();
    _log(
      'admin refresh householdId=${household.id} '
      'primaryAdminId=${household.primaryAdminId} '
      'secondaryAdminId=${household.secondaryAdminId} '
      'adminEpoch=${household.adminEpoch} '
      'adminIds=${household.adminIds} memberIds=${household.memberIds}',
    );
    _primaryAdminId = household.primaryAdminId;
    _adminEpoch = household.adminEpoch;
    var isAdmin =
        _role == UserRole.admin && household.adminIds.contains(_userId);
    var isPrimary = isAdmin && _primaryAdminId == _userId;
    if (_role == UserRole.admin &&
        household.adminIds.isEmpty &&
        household.primaryAdminId.isEmpty) {
      // Bootstrap: avoid presenting an admin as a member before local repair.
      isAdmin = true;
      isPrimary = true;
      _primaryAdminId = _userId;
    }
    _engine.updateAdminState(
      isAdmin: isAdmin,
      isPrimary: isPrimary,
      primaryAdminId: _primaryAdminId,
      adminEpoch: _adminEpoch,
    );
    if (_isMemberConfirmed() && _isConnectedOrHosting()) {
      _flushOutbox();
    }
  }

  void _maybePromoteToPrimary(int nowMs) {
    if (_promotionInFlight) {
      return;
    }
    if (_role != UserRole.admin) {
      return;
    }
    final dto = _householdsBox.get(_householdId);
    if (dto == null) {
      return;
    }
    final household = dto.toDomain();
    if (!household.adminIds.contains(_userId)) {
      return;
    }
    if (household.primaryAdminId == _userId) {
      return;
    }
    if (household.primaryAdminId.isEmpty) {
      if (nowMs - _syncStartedAtMs > 10000) {
        _promoteToPrimary(household);
      }
      return;
    }
    const timeoutMs = 35000;
    if (_lastPrimaryHeartbeatMs == 0) {
      if (nowMs - _syncStartedAtMs > timeoutMs) {
        _promoteToPrimary(household);
      }
      return;
    }
    if (nowMs - _lastPrimaryHeartbeatMs > timeoutMs) {
      _promoteToPrimary(household);
    }
  }

  void _promoteToPrimary(Household household) {
    _promotionInFlight = true;
    final nextEpoch = household.adminEpoch + 1;
    final previousPrimary = household.primaryAdminId;
    final nextSecondary = previousPrimary.isEmpty || previousPrimary == _userId
        ? household.secondaryAdminId
        : previousPrimary;
    final updated = household.copyWith(
      primaryAdminId: _userId,
      secondaryAdminId: nextSecondary,
      adminEpoch: nextEpoch,
    );
    final dto = HouseholdDto.fromDomain(updated);
    _householdsBox.put(updated.id, dto);
    _refreshAdminState();
    final payload = SyncPayloadCodec.householdToMap(dto)
      ..['expectedPrimaryAdminId'] = household.primaryAdminId
      ..['expectedAdminEpoch'] = household.adminEpoch
      ..['mutationReason'] = 'promote_primary';
    publishUpsert(
      SyncEntityType.households,
      payload,
      entityId: updated.id,
    ).whenComplete(() => _promotionInFlight = false);
  }

  void _queueEngine(Future<void> Function() action) {
    _engineTask = _engineTask.then((_) => action()).catchError((_) {});
  }

  void _seedProfileFromHeartbeat(
    String senderId,
    String? displayName,
    bool isAdmin,
  ) {
    if (senderId == _userId || displayName == null) {
      return;
    }
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final existing = _userProfilesBox.get(senderId);
    final existingName = existing?.displayName.trim() ?? '';
    final isPlaceholder = existingName.isEmpty ||
        existingName == senderId ||
        existingName == 'Unknown' ||
        existingName == 'unknown-user';
    if (existing != null && !isPlaceholder && existingName == trimmed) {
      return;
    }
    final role = isAdmin ? UserRole.admin : UserRole.member;
    final dto = UserProfileDto(
      id: senderId,
      householdId: _householdId,
      displayName: trimmed,
      roleName: role.name,
    );
    _userProfilesBox.put(senderId, dto);
    _markEntityTimestamp(
      SyncEntityType.userProfiles,
      senderId,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _maybeAdmitMember(String senderId) async {
    if (senderId == _userId || senderId.isEmpty) {
      return;
    }
    final lastAttempt = _autoAdmitByUser[senderId] ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastAttempt < 3000) {
      return;
    }
    _autoAdmitByUser[senderId] = now;
    final dto = _householdsBox.get(_householdId);
    if (dto == null) {
      return;
    }
    final household = dto.toDomain();
    if (household.adminIds.contains(senderId) ||
        household.memberIds.contains(senderId) ||
        household.primaryAdminId == senderId ||
        household.secondaryAdminId == senderId) {
      return;
    }
    final updatedMembers = {...household.memberIds, senderId}.toList();
    final updated = household.copyWith(memberIds: updatedMembers);
    final updatedDto = HouseholdDto.fromDomain(updated);
    _householdsBox.put(updated.id, updatedDto);
    final payload = SyncPayloadCodec.householdToMap(updatedDto);
    await publishUpsert(
      SyncEntityType.households,
      payload,
      entityId: updated.id,
    );
    if (_engine.isHost && _isConnectedOrHosting()) {
      await _sendSnapshot();
    }
  }

  bool _isConnectedOrHosting() {
    final state = _engine.currentState;
    return state == SyncConnectionState.connected ||
        state == SyncConnectionState.hosting;
  }

  bool _isMemberConfirmed() {
    if (_engine.isHost || _role == UserRole.admin) {
      return true;
    }
    final dto = _householdsBox.get(_householdId);
    if (dto == null) {
      return false;
    }
    final household = dto.toDomain();
    if (!household.memberIds.contains(_userId)) {
      return false;
    }
    return household.adminIds.isNotEmpty ||
        household.primaryAdminId.isNotEmpty;
  }

  bool _canSendWhileUnconfirmed(
    SyncEntityType type,
    String action,
    Map<String, dynamic> payload,
  ) {
    if (action != 'upsert') {
      return false;
    }
    if (type != SyncEntityType.households) {
      return false;
    }
    final memberIds = _readStringList(payload['memberIds']);
    return memberIds.contains(_userId);
  }

  bool isQueued(SyncEntityType type, String entityId) {
    return _syncOutboxBox.containsKey(syncOutboxKey(type, entityId));
  }

  bool _shouldPreserveQueued(SyncEntityType type, String entityId) {
    if (_engine.isHost) {
      return false;
    }
    switch (type) {
      case SyncEntityType.completionRequests:
      case SyncEntityType.ledgerEntries:
      case SyncEntityType.redemptions:
        return isQueued(type, entityId);
      default:
        return false;
    }
  }

  void _flushOutbox() {
    if (_syncOutboxBox.isEmpty) {
      return;
    }
    if (_engine.isHost) {
      _log('outbox clear host count=${_syncOutboxBox.length}');
      _syncOutboxBox.clear();
      return;
    }
    if (!_isMemberConfirmed()) {
      return;
    }
    if (!_isConnectedOrHosting()) {
      return;
    }
    final keys = _syncOutboxBox.keys.whereType<String>().toList();
    for (final key in keys) {
      final raw = _syncOutboxBox.get(key);
      if (raw is! Map) {
        _syncOutboxBox.delete(key);
        continue;
      }
      final message = Map<String, dynamic>.from(raw);
      if (message['householdId'] != _householdId) {
        _syncOutboxBox.delete(key);
        continue;
      }
      _sendMessage(message);
      _syncOutboxBox.delete(key);
    }
  }

  int _readTimestampMs(Map<String, dynamic> message) {
    final tsMs = message['tsMs'];
    if (tsMs is int) {
      return _clampTimestamp(tsMs);
    }
    final ts = message['ts'];
    if (ts is String) {
      final parsed = DateTime.tryParse(ts)?.millisecondsSinceEpoch ?? 0;
      return _clampTimestamp(parsed);
    }
    return 0;
  }

  int _clampTimestamp(int tsMs) {
    if (tsMs <= 0) {
      return 0;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    const maxFutureSkewMs = 30000;
    if (tsMs > now + maxFutureSkewMs) {
      return now;
    }
    return tsMs;
  }

  bool _shouldApply(SyncEntityType type, String id, int tsMs) {
    final key = _entityTsKey(type, id);
    final last = _syncMetaBox.get(key) as int?;
    if (last != null && tsMs <= last) {
      return false;
    }
    _markEntityTimestamp(type, id, tsMs);
    return true;
  }

  void _markEntityTimestamp(SyncEntityType type, String id, int tsMs) {
    _syncMetaBox.put(_entityTsKey(type, id), tsMs);
    final lastEventTs = _readLastEventTs();
    if (tsMs > lastEventTs) {
      _syncMetaBox.put(_lastEventTsKey(), tsMs);
    }
  }

  int _readLastEventTs() {
    return _syncMetaBox.get(_lastEventTsKey()) as int? ?? 0;
  }

  String _entityTsKey(SyncEntityType type, String id) {
    return 'entityTs:${type.wire}:$id';
  }

  String _lastEventTsKey() {
    return 'lastEventTs:$_householdId';
  }

  String _newEventId(int tsMs) {
    _localEventCounter += 1;
    return '$_userId-$tsMs-$_localEventCounter';
  }

  String _outboxKey(SyncEntityType type, String entityId) {
    return syncOutboxKey(type, entityId);
  }

  void _queueOutbox(
    Map<String, dynamic> message,
    SyncEntityType type,
    String entityId,
  ) {
    _syncOutboxBox.put(
      _outboxKey(type, entityId),
      Map<String, dynamic>.from(message),
    );
  }

  void _recordEvent(Map<String, dynamic> message) {
    final eventId = message['eventId'] as String? ?? _newEventId(
      _readTimestampMs(message),
    );
    final stored = Map<String, dynamic>.from(message);
    stored['eventId'] = eventId;
    _syncEventsBox.put(eventId, stored);
  }

  Future<void> _deleteEntity(SyncEntityType type, String id) async {
    switch (type) {
      case SyncEntityType.items:
        await _itemsBox.delete(id);
        return;
      case SyncEntityType.completionEvents:
        await _completionEventsBox.delete(id);
        return;
      case SyncEntityType.completionRequests:
        await _completionRequestsBox.delete(id);
        return;
      case SyncEntityType.ledgerEntries:
        await _ledgerBox.delete(id);
        return;
      case SyncEntityType.rewards:
        await _rewardsBox.delete(id);
        return;
      case SyncEntityType.boxRules:
        await _boxRulesBox.delete(id);
        return;
      case SyncEntityType.redemptions:
        await _redemptionsBox.delete(id);
        return;
      case SyncEntityType.inventoryItems:
        await _inventoryBox.delete(id);
        return;
      case SyncEntityType.behaviorRules:
        await _behaviorRulesBox.delete(id);
        return;
      case SyncEntityType.households:
        await _householdsBox.delete(id);
        return;
      case SyncEntityType.userProfiles:
        await _userProfilesBox.delete(id);
        return;
    }
  }

  Future<void> _upsertEntity(
    SyncEntityType type,
    Map<String, dynamic> payload,
    String id,
  ) async {
    switch (type) {
      case SyncEntityType.items:
        await _itemsBox.put(id, SyncPayloadCodec.itemFromMap(payload));
        return;
      case SyncEntityType.completionEvents:
        await _completionEventsBox.put(
          id,
          SyncPayloadCodec.completionEventFromMap(payload),
        );
        return;
      case SyncEntityType.completionRequests:
        await _completionRequestsBox.put(
          id,
          SyncPayloadCodec.completionRequestFromMap(payload),
        );
        return;
      case SyncEntityType.ledgerEntries:
        await _ledgerBox.put(
          id,
          SyncPayloadCodec.ledgerEntryFromMap(payload),
        );
        return;
      case SyncEntityType.rewards:
        await _rewardsBox.put(id, SyncPayloadCodec.rewardFromMap(payload));
        return;
      case SyncEntityType.boxRules:
        await _boxRulesBox.put(id, SyncPayloadCodec.boxRuleFromMap(payload));
        return;
      case SyncEntityType.redemptions:
        await _redemptionsBox.put(
          id,
          SyncPayloadCodec.redemptionFromMap(payload),
        );
        return;
      case SyncEntityType.inventoryItems:
        await _inventoryBox.put(
          id,
          SyncPayloadCodec.inventoryItemFromMap(payload),
        );
        return;
      case SyncEntityType.behaviorRules:
        final normalized = Map<String, dynamic>.from(payload);
        final householdId =
            (normalized['householdId'] as String?)?.trim() ?? '';
        if (householdId.isEmpty) {
          normalized['householdId'] = _householdId;
        }
        final incoming = SyncPayloadCodec.behaviorRuleFromMap(normalized);
        final existing = _behaviorRulesBox.get(id);
        final hasName = normalized.containsKey('name') ||
            normalized.containsKey('title') ||
            normalized.containsKey('label');
        final hasLikes = normalized.containsKey('likes') ||
            normalized.containsKey('likeCount') ||
            normalized.containsKey('thumbsUp');
        final hasDislikes = normalized.containsKey('dislikes') ||
            normalized.containsKey('dislikeCount') ||
            normalized.containsKey('thumbsDown');
        final merged = existing == null
            ? incoming
            : BehaviorRuleDto(
                id: incoming.id,
                householdId: incoming.householdId.trim().isEmpty
                    ? existing.householdId
                    : incoming.householdId,
                name: hasName && incoming.name.trim().isNotEmpty
                    ? incoming.name
                    : existing.name,
                likes: hasLikes ? incoming.likes : existing.likes,
                dislikes: hasDislikes ? incoming.dislikes : existing.dislikes,
              );
        await _behaviorRulesBox.put(id, merged);
        return;
      case SyncEntityType.households:
        final incoming = SyncPayloadCodec.householdFromMap(payload);
        final existing = _householdsBox.get(id);
        if (existing == null) {
          await _householdsBox.put(id, incoming);
          return;
        }
        final adminIds = incoming.adminIds.isEmpty &&
                existing.adminIds.isNotEmpty
            ? existing.adminIds
            : incoming.adminIds;
        final primaryAdminId =
            incoming.primaryAdminId.isEmpty &&
                    existing.primaryAdminId.isNotEmpty
                ? existing.primaryAdminId
                : incoming.primaryAdminId;
        final secondaryAdminId =
            incoming.secondaryAdminId == null &&
                    existing.secondaryAdminId != null
                ? existing.secondaryAdminId
                : incoming.secondaryAdminId;
        final adminEpoch = incoming.adminEpoch < existing.adminEpoch
            ? existing.adminEpoch
            : incoming.adminEpoch;
        await _householdsBox.put(
          id,
          HouseholdDto(
            id: incoming.id,
            name: incoming.name,
            adminIds: List<String>.from(adminIds),
            memberIds: List<String>.from(incoming.memberIds),
            primaryAdminId: primaryAdminId,
            secondaryAdminId: secondaryAdminId,
            adminEpoch: adminEpoch,
          ),
        );
        return;
      case SyncEntityType.userProfiles:
        await _userProfilesBox.put(
          id,
          SyncPayloadCodec.userProfileFromMap(payload),
        );
        return;
    }
  }
}

class SyncPresenceEntry {
  const SyncPresenceEntry({
    required this.userId,
    required this.lastSeenMs,
  });

  final String userId;
  final int lastSeenMs;
}
