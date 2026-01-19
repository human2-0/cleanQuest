import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_format.dart';
import '../../../l10n/app_localizations.dart';
import '../application/notification_log_providers.dart';

class NotificationsLogScreen extends ConsumerWidget {
  const NotificationsLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final logs = ref.watch(notificationLogProvider).value ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
      ),
      body: logs.isEmpty
          ? Center(child: Text(l10n.notificationsEmpty))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  elevation: 0.6,
                  child: ListTile(
                    title: Text(log.title),
                    subtitle: Text('${log.body}\n${formatShortDateTime(log.createdAt)}'),
                  ),
                );
              },
            ),
    );
  }
}
