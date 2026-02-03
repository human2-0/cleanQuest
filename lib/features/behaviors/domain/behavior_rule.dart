class BehaviorRule {
  const BehaviorRule({
    required this.id,
    required this.householdId,
    required this.name,
    required this.likes,
    required this.dislikes,
  });

  final String id;
  final String householdId;
  final String name;
  final int likes;
  final int dislikes;

  int get score => likes - dislikes;

  BehaviorRule copyWith({
    String? id,
    String? householdId,
    String? name,
    int? likes,
    int? dislikes,
  }) {
    return BehaviorRule(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
    );
  }
}
