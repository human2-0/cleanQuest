class CompletionEvent {
  const CompletionEvent({
    required this.id,
    required this.householdId,
    required this.itemId,
    required this.approvedAt,
  });

  final String id;
  final String householdId;
  final String itemId;
  final DateTime approvedAt;
}
