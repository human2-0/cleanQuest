import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_models.dart';
import '../../../core/sync/sync_payloads.dart';
import '../domain/completion_request.dart';
import 'completion_request_dto.dart';

class CompletionRequestsRepository {
  CompletionRequestsRepository(this._box, {SyncCoordinator? sync})
      : _sync = sync;

  final Box<CompletionRequestDto> _box;
  final SyncCoordinator? _sync;

  static CompletionRequestsRepository open({SyncCoordinator? sync}) {
    return CompletionRequestsRepository(
      Hive.box<CompletionRequestDto>(completionRequestsBoxName),
      sync: sync,
    );
  }

  Stream<List<CompletionRequest>> watchRequests(String householdId) async* {
    yield _requestsForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _requestsForHousehold(householdId);
    }
  }

  Future<void> upsertRequest(CompletionRequest request) async {
    final dto = CompletionRequestDto.fromDomain(request);
    await _box.put(request.id, dto);
    await _sync?.publishUpsert(
      SyncEntityType.completionRequests,
      SyncPayloadCodec.completionRequestToMap(dto),
      entityId: request.id,
    );
  }

  Future<void> ensureConnected() async {
    await _sync?.ensureConnected();
  }

  List<CompletionRequest> _requestsForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
