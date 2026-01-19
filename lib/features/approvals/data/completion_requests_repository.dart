import 'dart:async';

import 'package:hive/hive.dart';

import '../../../data/hive/hive_boxes.dart';
import '../domain/completion_request.dart';
import 'completion_request_dto.dart';

class CompletionRequestsRepository {
  CompletionRequestsRepository(this._box);

  final Box<CompletionRequestDto> _box;

  static CompletionRequestsRepository open() {
    return CompletionRequestsRepository(
      Hive.box<CompletionRequestDto>(completionRequestsBoxName),
    );
  }

  Stream<List<CompletionRequest>> watchRequests(String householdId) async* {
    yield _requestsForHousehold(householdId);
    await for (final _ in _box.watch()) {
      yield _requestsForHousehold(householdId);
    }
  }

  Future<void> upsertRequest(CompletionRequest request) {
    return _box.put(request.id, CompletionRequestDto.fromDomain(request));
  }

  List<CompletionRequest> _requestsForHousehold(String householdId) {
    return _box.values
        .where((dto) => dto.householdId == householdId)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
