import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/providers/user_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../items/application/items_providers.dart';
import '../../household/application/household_providers.dart';
import '../../points/application/points_providers.dart';
import '../application/rewards_providers.dart';
import '../data/box_rules_repository.dart';
import '../data/rewards_repository.dart';
import '../domain/box_rule.dart';
import '../domain/reward.dart';
import '../domain/redemption.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rules = ref.watch(boxRulesProvider).value ?? <BoxRule>[];
    final rewards = ref.watch(rewardsProvider).value ?? <Reward>[];
    final redemptions = ref.watch(redemptionsProvider).value ?? [];
    final householdRedemptions =
        ref.watch(householdRedemptionsProvider).value ?? [];
    final household = ref.watch(activeHouseholdProvider).value;
    final profiles = ref.watch(householdProfilesProvider).value ?? [];
    final profileById = {
      for (final profile in profiles) profile.id: profile,
    };
    final adminIds = household?.adminIds.toSet() ?? <String>{};
    final memberIds = household?.memberIds.toSet() ?? <String>{};
    final adminRedemptions = householdRedemptions.where((redemption) {
      final role = profileById[redemption.userId]?.role;
      return adminIds.contains(redemption.userId) || role == UserRole.admin;
    }).toList();
    final memberRedemptions = householdRedemptions.where((redemption) {
      final role = profileById[redemption.userId]?.role;
      final isAdmin = adminIds.contains(redemption.userId) || role == UserRole.admin;
      final isMember = memberIds.contains(redemption.userId) || role == UserRole.member;
      return isMember || !isAdmin;
    }).toList();
    final balance = ref.watch(pointsBalanceProvider);
    final householdId = ref.read(activeHouseholdIdProvider);
    final userId = ref.read(currentUserIdProvider);
    final controller = ref.read(redeemControllerProvider);
    final role = ref.watch(currentUserRoleProvider);
    final rewardsRepository = ref.read(rewardsRepositoryProvider);
    final rulesRepository = ref.read(boxRulesRepositoryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rewardsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primaryContainer,
                  scheme.secondaryContainer,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: scheme.onPrimaryContainer,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.rewardsPointsBalance,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: scheme.onPrimaryContainer),
                        ),
                        Text(
                          balance.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.onPrimaryContainer.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.rewardsMysteryBoxes,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.rewardsMysteryBoxes,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (rules.isEmpty)
            Text(l10n.rewardsNoBoxes)
          else
            ...rules.map(
              (rule) {
                final statusLines =
                    _ruleStatusLines(l10n, rule, redemptions);
                return _BoxRuleCard(
                  rule: rule,
                  rewards: rewards,
                  statusLines: statusLines,
                  onViewOdds: () => _showOdds(context, rule, rewards),
                  onRedeem: () async {
                    try {
                      final redemption = await controller.redeem(
                        householdId: householdId,
                        userId: userId,
                        boxRule: rule,
                        pointsBalance: balance,
                        existingRedemptions: redemptions,
                        userLabel: userId,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      final reward = rewards.firstWhere(
                        (reward) => reward.id == redemption.outcomeRewardId,
                        orElse: () => Reward(
                          id: redemption.outcomeRewardId,
                          householdId: redemption.householdId,
                          title: l10n.commonUnknownReward,
                          weight: 0,
                          enabled: false,
                        ),
                      );
                      await showDialog<void>(
                        context: context,
                        builder: (context) => _RewardRevealDialog(
                          title: l10n.rewardsYouGot,
                          rewardTitle: reward.title,
                          ctaLabel: l10n.rewardsNice,
                        ),
                      );
                    } catch (error) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.toString())),
                      );
                    }
                  },
                );
              },
            ),
          if (role == UserRole.admin) ...[
            const SizedBox(height: 20),
            Text(
              l10n.rewardsManageRewards,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...rewards.map(
              (reward) => ListTile(
                title: Text(reward.title),
                subtitle: Text(
                  l10n.rewardsWeightStatus(
                    reward.weight,
                    reward.enabled ? l10n.rewardsEnabled : l10n.rewardsDisabled,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showRewardEditor(
                        context: context,
                        householdId: householdId,
                        repository: rewardsRepository,
                        reward: reward,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDeleteReward(
                        context: context,
                        repository: rewardsRepository,
                        rulesRepository: rulesRepository,
                        reward: reward,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _showRewardEditor(
                  context: context,
                  householdId: householdId,
                  repository: rewardsRepository,
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.rewardsAddReward),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.rewardsManageBoxRules,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...rules.map(
              (rule) => ListTile(
                title: Text(rule.title),
                subtitle: Text(
                  l10n.rewardsCostRewardsCount(
                    rule.costPoints,
                    rule.rewardIds.length,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showBoxRuleEditor(
                        context: context,
                        householdId: householdId,
                        repository: rulesRepository,
                        rewards: rewards,
                        rule: rule,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDeleteRule(
                        context: context,
                        repository: rulesRepository,
                        rule: rule,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _showBoxRuleEditor(
                  context: context,
                  householdId: householdId,
                  repository: rulesRepository,
                  rewards: rewards,
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.rewardsAddBoxRule),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.rewardsMyRewards,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: redemptions.isEmpty
                  ? null
                  : () => _showRedemptionsHistory(
                        context: context,
                        l10n: l10n,
                        title: l10n.rewardsMyRewards,
                        rewards: rewards,
                        redemptions: redemptions,
                        showUserId: false,
                      ),
              icon: const Icon(Icons.history),
              label: Text(l10n.rewardsViewAll),
            ),
          ),
          const SizedBox(height: 8),
          if (redemptions.isEmpty)
            Text(l10n.rewardsNoRedemptions)
          else
            ...redemptions.take(5).map(
                  (redemption) => _RedemptionTile(
                    title: _rewardTitleFor(l10n, rewards, redemption),
                    subtitle: formatShortDateTime(redemption.rolledAt),
                    costPoints: redemption.costPoints,
                  ),
                ),
          const SizedBox(height: 16),
          Text(
            l10n.rewardsAdminRewards,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: adminRedemptions.isEmpty
                  ? null
                  : () => _showRedemptionsHistory(
                        context: context,
                        l10n: l10n,
                        title: l10n.rewardsAdminRewards,
                        rewards: rewards,
                        redemptions: adminRedemptions,
                        showUserId: true,
                      ),
              icon: const Icon(Icons.history),
              label: Text(l10n.rewardsViewAll),
            ),
          ),
          const SizedBox(height: 8),
          if (adminRedemptions.isEmpty)
            Text(l10n.rewardsNoAdminRewards)
          else
            ...adminRedemptions.take(10).map(
                  (redemption) => _RedemptionTile(
                    title: _rewardTitleFor(l10n, rewards, redemption),
                    subtitle:
                        '${redemption.userId} • ${formatShortDateTime(redemption.rolledAt)}',
                    costPoints: redemption.costPoints,
                    highlight: true,
                  ),
                ),
          const SizedBox(height: 16),
          Text(
            l10n.rewardsMemberRewards,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: memberRedemptions.isEmpty
                  ? null
                  : () => _showRedemptionsHistory(
                        context: context,
                        l10n: l10n,
                        title: l10n.rewardsMemberRewards,
                        rewards: rewards,
                        redemptions: memberRedemptions,
                        showUserId: true,
                      ),
              icon: const Icon(Icons.history),
              label: Text(l10n.rewardsViewAll),
            ),
          ),
          const SizedBox(height: 8),
          if (memberRedemptions.isEmpty)
            Text(l10n.rewardsNoMemberRewards)
          else
            ...memberRedemptions.take(10).map(
                  (redemption) => _RedemptionTile(
                    title: _rewardTitleFor(l10n, rewards, redemption),
                    subtitle:
                        '${redemption.userId} • ${formatShortDateTime(redemption.rolledAt)}',
                    costPoints: redemption.costPoints,
                  ),
                ),
        ],
      ),
    );
  }
}

String _rewardTitleFor(
  AppLocalizations l10n,
  List<Reward> rewards,
  Redemption redemption,
) {
  return rewards
      .firstWhere(
        (reward) => reward.id == redemption.outcomeRewardId,
        orElse: () => Reward(
          id: redemption.outcomeRewardId,
          householdId: redemption.householdId,
          title: l10n.commonUnknownReward,
          weight: 0,
          enabled: false,
        ),
      )
      .title;
}

Future<void> _showRedemptionsHistory({
  required BuildContext context,
  required AppLocalizations l10n,
  required String title,
  required List<Reward> rewards,
  required List<Redemption> redemptions,
  required bool showUserId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.commonClose,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: redemptions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final redemption = redemptions[index];
                  final subtitle = showUserId
                      ? '${redemption.userId} • ${formatShortDateTime(redemption.rolledAt)}'
                      : formatShortDateTime(redemption.rolledAt);
                  return ListTile(
                    title: Text(_rewardTitleFor(l10n, rewards, redemption)),
                    subtitle: Text(subtitle),
                    trailing: Text('-${redemption.costPoints}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BoxRuleCard extends StatefulWidget {
  const _BoxRuleCard({
    required this.rule,
    required this.rewards,
    required this.statusLines,
    required this.onViewOdds,
    required this.onRedeem,
  });

  final BoxRule rule;
  final List<Reward> rewards;
  final List<String> statusLines;
  final VoidCallback onViewOdds;
  final VoidCallback onRedeem;

  @override
  State<_BoxRuleCard> createState() => _BoxRuleCardState();
}

class _BoxRuleCardState extends State<_BoxRuleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.04).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final enabledRewards = widget.rewards.where(
      (reward) => widget.rule.rewardIds.contains(reward.id),
    );
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary.withOpacity(0.12),
        scheme.secondary.withOpacity(0.18),
      ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onViewOdds,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: gradient,
            border: Border.all(color: scheme.primary.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.rule.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      icon: Icons.local_fire_department,
                      label: l10n.rewardsCostPoints(widget.rule.costPoints),
                    ),
                    _InfoChip(
                      icon: Icons.star_outline,
                      label: l10n.rewardsRewardsCount(enabledRewards.length),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onViewOdds,
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(l10n.rewardsViewOdds),
                    ),
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        final glow = 0.18 + (_pulseController.value * 0.22);
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.primary.withOpacity(glow),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: FilledButton.icon(
                        onPressed: widget.onRedeem,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(l10n.rewardsOpenBox),
                      ),
                    ),
                  ],
                ),
                if (widget.statusLines.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.statusLines
                        .map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              line,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardRevealDialog extends StatelessWidget {
  const _RewardRevealDialog({
    required this.title,
    required this.rewardTitle,
    required this.ctaLabel,
  });

  final String title;
  final String rewardTitle;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primaryContainer,
        scheme.secondaryContainer,
      ],
    );
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.85, end: 1),
        builder: (context, value, child) {
          final opacity = value.clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity as double,
            child: Transform.scale(scale: value, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -6,
                top: -6,
                child: Transform.rotate(
                  angle: math.pi / 10,
                  child: Icon(
                    Icons.auto_awesome,
                    color: scheme.primary.withOpacity(0.35),
                    size: 42,
                  ),
                ),
              ),
              Positioned(
                left: -4,
                bottom: -4,
                child: Transform.rotate(
                  angle: -math.pi / 6,
                  child: Icon(
                    Icons.star,
                    color: scheme.secondary.withOpacity(0.3),
                    size: 36,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: scheme.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rewardTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.celebration_outlined),
                    label: Text(ctaLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _RedemptionTile extends StatelessWidget {
  const _RedemptionTile({
    required this.title,
    required this.subtitle,
    required this.costPoints,
    this.highlight = false,
  });

  final String title;
  final String subtitle;
  final int costPoints;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.secondaryContainer.withOpacity(0.4)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '-$costPoints',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _ruleStatusLines(
  AppLocalizations l10n,
  BoxRule rule,
  List<Redemption> redemptions,
) {
  final lines = <String>[];
  final ruleRedemptions =
      redemptions.where((redemption) => redemption.boxRuleId == rule.id).toList();
  if (kDebugMode) {
    if (rule.cooldownSeconds > 0) {
      lines.add(l10n.rewardsCooldownDisabledDebug);
    }
    if (rule.maxPerDay > 0) {
      lines.add(l10n.rewardsDailyLimitDisabledDebug);
    }
    return lines;
  }

  if (rule.cooldownSeconds > 0) {
    final latest = ruleRedemptions
        .map((redemption) => redemption.rolledAt)
        .fold<DateTime?>(null, (latest, current) {
      if (latest == null || current.isAfter(latest)) {
        return current;
      }
      return latest;
    });
    if (latest != null) {
      final nextAllowed =
          latest.add(Duration(seconds: rule.cooldownSeconds));
      final remaining = nextAllowed.difference(DateTime.now());
      if (remaining > Duration.zero) {
        lines.add(
          l10n.rewardsCooldownRemaining(formatDurationShort(remaining)),
        );
      }
    }
  }

  if (rule.maxPerDay > 0) {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final count = ruleRedemptions
        .where((redemption) => redemption.rolledAt.isAfter(dayStart))
        .length;
    lines.add(l10n.rewardsDailyLimitStatus(count, rule.maxPerDay));
  }

  return lines;
}

Future<void> _showRewardEditor({
  required BuildContext context,
  required String householdId,
  required RewardsRepository repository,
  Reward? reward,
}) {
  final l10n = AppLocalizations.of(context)!;
  final titleController = TextEditingController(text: reward?.title ?? '');
  final descriptionController =
      TextEditingController(text: reward?.description ?? '');
  final weightController =
      TextEditingController(text: reward?.weight.toString() ?? '10');
  var enabled = reward?.enabled ?? true;

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        reward == null ? l10n.rewardsAddRewardTitle : l10n.rewardsEditRewardTitle,
      ),
      content: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: l10n.rewardsTitleLabel),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration:
                    InputDecoration(labelText: l10n.rewardsDescriptionLabel),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weightController,
                decoration: InputDecoration(labelText: l10n.rewardsWeightLabel),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: enabled,
                onChanged: (value) => setState(() => enabled = value),
                title: Text(l10n.rewardsEnabledLabel),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () async {
            final title = titleController.text.trim();
            final weight = int.tryParse(weightController.text.trim()) ?? 0;
            if (title.isEmpty || weight <= 0) {
              return;
            }
            final updated = Reward(
              id: reward?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
              householdId: householdId,
              title: title,
              description: descriptionController.text.trim().isEmpty
                  ? null
                  : descriptionController.text.trim(),
              weight: weight,
              enabled: enabled,
            );
            await repository.upsertReward(updated);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Text(l10n.commonSave),
        ),
      ],
    ),
  );
}

Future<void> _showBoxRuleEditor({
  required BuildContext context,
  required String householdId,
  required BoxRulesRepository repository,
  required List<Reward> rewards,
  BoxRule? rule,
}) {
  final l10n = AppLocalizations.of(context)!;
  final titleController = TextEditingController(text: rule?.title ?? '');
  final costController =
      TextEditingController(text: rule?.costPoints.toString() ?? '20');
  final cooldownController = TextEditingController(
    text: rule?.cooldownSeconds.toString() ?? '${60 * 60 * 12}',
  );
  final maxPerDayController =
      TextEditingController(text: rule?.maxPerDay.toString() ?? '2');
  final selected = <String>{...?(rule?.rewardIds)};

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        rule == null ? l10n.rewardsAddBoxRuleTitle : l10n.rewardsEditBoxRuleTitle,
      ),
      content: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: l10n.rewardsTitleLabel),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: costController,
                decoration:
                    InputDecoration(labelText: l10n.rewardsCostPointsLabel),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cooldownController,
                decoration: InputDecoration(
                  labelText: l10n.rewardsCooldownSecondsLabel,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: maxPerDayController,
                decoration:
                    InputDecoration(labelText: l10n.rewardsMaxPerDayLabel),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.rewardsTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 4),
              ...rewards.map(
                (reward) => CheckboxListTile(
                  value: selected.contains(reward.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked ?? false) {
                        selected.add(reward.id);
                      } else {
                        selected.remove(reward.id);
                      }
                    });
                  },
                  title: Text(reward.title),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () async {
            final title = titleController.text.trim();
            final cost = int.tryParse(costController.text.trim()) ?? 0;
            final cooldown = int.tryParse(cooldownController.text.trim()) ?? 0;
            final maxPerDay = int.tryParse(maxPerDayController.text.trim()) ?? 0;
            if (title.isEmpty || cost <= 0 || selected.isEmpty) {
              return;
            }
            final updated = BoxRule(
              id: rule?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
              householdId: householdId,
              title: title,
              costPoints: cost,
              cooldownSeconds: cooldown,
              maxPerDay: maxPerDay,
              rewardIds: selected.toList(),
            );
            await repository.upsertRule(updated);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Text(l10n.commonSave),
        ),
      ],
    ),
  );
}

Future<void> _confirmDeleteReward({
  required BuildContext context,
  required RewardsRepository repository,
  required BoxRulesRepository rulesRepository,
  required Reward reward,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.rewardsDeleteRewardTitle),
      content: Text(l10n.rewardsDeleteRewardBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.commonDelete),
        ),
      ],
    ),
  );

  if (confirmed ?? false) {
    await repository.deleteReward(reward.id);
    await rulesRepository.removeRewardFromRules(reward.id);
  }
}

Future<void> _confirmDeleteRule({
  required BuildContext context,
  required BoxRulesRepository repository,
  required BoxRule rule,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.rewardsDeleteBoxRuleTitle),
      content: Text(l10n.rewardsDeleteBoxRuleBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.commonDelete),
        ),
      ],
    ),
  );

  if (confirmed ?? false) {
    await repository.deleteRule(rule.id);
  }
}

Future<void> _showOdds(
  BuildContext context,
  BoxRule rule,
  List<Reward> rewards,
) {
  final l10n = AppLocalizations.of(context)!;
  final eligible = rewards
      .where((reward) => rule.rewardIds.contains(reward.id))
      .where((reward) => reward.enabled && reward.weight > 0)
      .toList();
  final totalWeight =
      eligible.fold<int>(0, (sum, reward) => sum + reward.weight);

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.rewardsOddsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: eligible.length,
          itemBuilder: (context, index) {
            final reward = eligible[index];
            final percent = totalWeight == 0
                ? 0
                : (reward.weight / totalWeight * 100);
            return ListTile(
              title: Text(reward.title),
              trailing: Text('${percent.toStringAsFixed(1)}%'),
            );
          },
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
      ],
    ),
  );
}
