import 'package:hive/hive.dart';

import '../domain/completion_request.dart';
import '../domain/request_status.dart';

class CompletionRequestDto {
  CompletionRequestDto({
    required this.id,
    required this.householdId,
    required this.itemId,
    required this.submittedByUserId,
    required this.submittedAt,
    required this.statusIndex,
    this.note,
    this.reviewedByUserId,
    this.reviewedAt,
  });

  final String id;
  final String householdId;
  final String itemId;
  final String submittedByUserId;
  final DateTime submittedAt;
  final int statusIndex;
  final String? note;
  final String? reviewedByUserId;
  final DateTime? reviewedAt;

  CompletionRequest toDomain() {
    return CompletionRequest(
      id: id,
      householdId: householdId,
      itemId: itemId,
      submittedByUserId: submittedByUserId,
      submittedAt: submittedAt,
      status: RequestStatus.values[statusIndex],
      note: note,
      reviewedByUserId: reviewedByUserId,
      reviewedAt: reviewedAt,
    );
  }

  static CompletionRequestDto fromDomain(CompletionRequest request) {
    return CompletionRequestDto(
      id: request.id,
      householdId: request.householdId,
      itemId: request.itemId,
      submittedByUserId: request.submittedByUserId,
      submittedAt: request.submittedAt,
      statusIndex: request.status.index,
      note: request.note,
      reviewedByUserId: request.reviewedByUserId,
      reviewedAt: request.reviewedAt,
    );
  }
}

class CompletionRequestDtoAdapter extends TypeAdapter<CompletionRequestDto> {
  @override
  final int typeId = 3;

  @override
  CompletionRequestDto read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return CompletionRequestDto(
      id: fields[0] as String,
      householdId: fields[1] as String,
      itemId: fields[2] as String,
      submittedByUserId: fields[3] as String,
      submittedAt: fields[4] as DateTime,
      statusIndex: fields[5] as int,
      note: fields[6] as String?,
      reviewedByUserId: fields[7] as String?,
      reviewedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CompletionRequestDto obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.householdId)
      ..writeByte(2)
      ..write(obj.itemId)
      ..writeByte(3)
      ..write(obj.submittedByUserId)
      ..writeByte(4)
      ..write(obj.submittedAt)
      ..writeByte(5)
      ..write(obj.statusIndex)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.reviewedByUserId)
      ..writeByte(8)
      ..write(obj.reviewedAt);
  }
}
