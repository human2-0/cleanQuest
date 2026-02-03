import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_config/app_config_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../application/behavior_rules_providers.dart';
import '../domain/behavior_rule.dart';

class BehaviorRulesScreen extends ConsumerWidget {
  const BehaviorRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(behaviorRulesProvider).value ?? <BehaviorRule>[];
    final controller = ref.read(behaviorRulesControllerProvider);
    final householdId = ref.watch(appConfigProvider).householdId ?? '';
    final isAdmin = ref.watch(currentUserRoleProvider) == UserRole.admin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Good Habits'),
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () => _showAddRuleDialog(context, controller, householdId),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add habit',
            ),
        ],
      ),
      body: rules.isEmpty
          ? const Center(child: Text('No habits yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rule = rules[index];
                final total = rule.likes + rule.dislikes;
                final ratio = total == 0 ? 0.0 : rule.likes / total;
                return Card(
                  elevation: 0.6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rule.name.trim().isEmpty
                                    ? 'Unnamed habit'
                                    : rule.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            _ScoreBadge(rule: rule),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _RatioBar(ratio: ratio),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('👍 ${rule.likes}'),
                            const SizedBox(width: 12),
                            Text('👎 ${rule.dislikes}'),
                            const Spacer(),
                            if (isAdmin) ...[
                              IconButton(
                                onPressed: () => controller.addFeedback(rule, 1),
                                icon: const Icon(Icons.thumb_up_alt_outlined),
                                tooltip: 'Like',
                              ),
                              IconButton(
                                onPressed: () => controller.addFeedback(rule, -1),
                                icon: const Icon(Icons.thumb_down_alt_outlined),
                                tooltip: 'Dislike',
                              ),
                              IconButton(
                                onPressed: () => _showEditRuleDialog(
                                  context,
                                  controller,
                                  rule,
                                ),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                onPressed: () => _confirmDeleteRule(
                                  context,
                                  controller,
                                  rule,
                                ),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

enum _RuleMenuAction {
  edit,
  delete,
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.rule});

  final BehaviorRule rule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = rule.score;
    final isPositive = score >= 0;
    final color = isPositive
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.errorContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          score >= 0 ? '+$score' : score.toString(),
          style: theme.textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: LinearProgressIndicator(
          value: ratio,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}

Future<void> _showAddRuleDialog(
  BuildContext context,
  BehaviorRulesController controller,
  String householdId,
) async {
  final rule = await showDialog<String>(
    context: context,
    builder: (context) => const _AddHabitDialog(),
  );
  if (rule == null) {
    return;
  }
  await controller.addRule(householdId: householdId, name: rule);
}

Future<void> _showEditRuleDialog(
  BuildContext context,
  BehaviorRulesController controller,
  BehaviorRule rule,
) async {
  final updated = await showDialog<String>(
    context: context,
    builder: (context) => _EditHabitDialog(initialValue: rule.name),
  );
  if (updated == null) {
    return;
  }
  await controller.renameRule(rule, updated);
}

Future<void> _confirmDeleteRule(
  BuildContext context,
  BehaviorRulesController controller,
  BehaviorRule rule,
) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete habit'),
      content: Text('Delete "${rule.name}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (shouldDelete == true) {
    await controller.deleteRule(rule);
  }
}

class _AddHabitDialog extends StatefulWidget {
  const _AddHabitDialog();

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _EditHabitDialog extends StatefulWidget {
  const _EditHabitDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends State<_EditHabitDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit habit'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'e.g. Put dishes away'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add habit'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'e.g. Put dishes away'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
