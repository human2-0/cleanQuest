import 'package:hive/hive.dart';

import '../domain/ledger_entry.dart';
import '../domain/ledger_reason.dart';

class LedgerEntryDto {
  LedgerEntryDto({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.delta,
    required this.createdAt,
    required this.reasonIndex,
    this.relatedRequestId,
    this.relatedRedemptionId,
  });

  final String id;
  final String householdId;
  final String userId;
  final int delta;
  final DateTime createdAt;
  final int reasonIndex;
  final String? relatedRequestId;
  final String? relatedRedemptionId;

  LedgerEntry toDomain() {
    return LedgerEntry(
      id: id,
      householdId: householdId,
      userId: userId,
      delta: delta,
      createdAt: createdAt,
      reason: LedgerReason.values[reasonIndex],
      relatedRequestId: relatedRequestId,
      relatedRedemptionId: relatedRedemptionId,
    );
  }

  static LedgerEntryDto fromDomain(LedgerEntry entry) {
    return LedgerEntryDto(
      id: entry.id,
      householdId: entry.householdId,
      userId: entry.userId,
      delta: entry.delta,
      createdAt: entry.createdAt,
      reasonIndex: entry.reason.index,
      relatedRequestId: entry.relatedRequestId,
      relatedRedemptionId: entry.relatedRedemptionId,
    );
  }
}

class LedgerEntryDtoAdapter extends TypeAdapter<LedgerEntryDto> {
  @override
  final int typeId = 4;

  @override
  LedgerEntryDto read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return LedgerEntryDto(
      id: fields[0] as String,
      householdId: fields[1] as String,
      userId: fields[2] as String,
      delta: fields[3] as int,
      createdAt: fields[4] as DateTime,
      reasonIndex: fields[5] as int,
      relatedRequestId: fields[6] as String?,
      relatedRedemptionId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LedgerEntryDto obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.householdId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.delta)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.reasonIndex)
      ..writeByte(6)
      ..write(obj.relatedRequestId)
      ..writeByte(7)
      ..write(obj.relatedRedemptionId);
  }
}
