import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/localized_labels.dart';
import '../../../core/utils/date_format.dart';
import '../../../l10n/app_localizations.dart';
import '../application/items_providers.dart';
import '../domain/area_category.dart';
import '../domain/completion_event.dart';
import '../domain/item.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, this.itemId, this.readOnly = false});

  final String? itemId;
  final bool readOnly;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  final _roomController = TextEditingController();
  final _intervalDaysController = TextEditingController();
  final _pointsController = TextEditingController();
  AreaCategory _category = AreaCategory.home;
  bool _isPaused = false;
  bool _didInit = false;
  ProviderSubscription<AsyncValue<List<Item>>>? _itemsSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.itemId == null) {
      _pointsController.text = '10';
      _didInit = true;
      return;
    }
    _itemsSubscription =
        ref.listenManual<AsyncValue<List<Item>>>(itemsListProvider,
            (previous, next) {
      if (_didInit) {
        return;
      }
      final items = next.value;
      if (items == null) {
        return;
      }
      final item = _currentItem(items);
      if (item != null) {
        _applyItem(item);
      }
      _didInit = true;
    });
  }

  @override
  void dispose() {
    _itemsSubscription?.close();
    _nameController.dispose();
    _iconController.dispose();
    _roomController.dispose();
    _intervalDaysController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(itemsListProvider).value ?? <Item>[];
    final item = _currentItem(items);
    final isEditing = item != null;
    final readOnly = widget.readOnly;
    final events = ref.watch(completionEventsProvider).value ?? <CompletionEvent>[];
    final lastApprovedAt = _latestApprovalFor(item?.id, events);
    if (!_didInit && item != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _applyItem(item);
        _didInit = true;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          readOnly
              ? l10n.choreDetailsTitle
              : (isEditing ? l10n.choreEditTitle : l10n.choreNewTitle),
        ),
        actions: [
          if (isEditing && !readOnly)
            IconButton(
              onPressed: () => _confirmDelete(context, item!.id),
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.choreDeleteTooltip,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0.6,
            child: ListTile(
              title: Text(l10n.choreLastCleanedTitle),
              subtitle: Text(
                lastApprovedAt == null
                    ? l10n.choreNoApprovedCompletions
                    : formatShortDate(lastApprovedAt),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.choreNameLabel),
            textInputAction: TextInputAction.next,
            enabled: !readOnly,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _iconController,
            decoration: InputDecoration(labelText: l10n.choreIconLabel),
            textInputAction: TextInputAction.next,
            enabled: !readOnly,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AreaCategory>(
            value: _category,
            decoration: InputDecoration(labelText: l10n.choreCategoryLabel),
            items: AreaCategory.values
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(localizedAreaCategory(l10n, category)),
                  ),
                )
                .toList(),
            onChanged: readOnly
                ? null
                : (value) {
              if (value == null) {
                return;
              }
              setState(() => _category = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _roomController,
            decoration: InputDecoration(labelText: l10n.choreRoomLabel),
            textInputAction: TextInputAction.next,
            enabled: !readOnly,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _intervalDaysController,
            decoration: InputDecoration(labelText: l10n.choreIntervalLabel),
            keyboardType: TextInputType.number,
            enabled: !readOnly,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pointsController,
            decoration: InputDecoration(labelText: l10n.chorePointsLabel),
            keyboardType: TextInputType.number,
            enabled: !readOnly,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _isPaused,
            onChanged: readOnly
                ? null
                : (value) => setState(() => _isPaused = value),
            title: Text(l10n.chorePausedLabel),
          ),
          const SizedBox(height: 16),
          if (!readOnly)
            FilledButton(
              onPressed: () => _save(context, item),
              child: Text(l10n.choreSave),
            ),
        ],
      ),
    );
  }

  Item? _currentItem(List<Item> items) {
    final itemId = widget.itemId;
    if (itemId == null) {
      return null;
    }
    for (final item in items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  void _save(BuildContext context, Item? existing) {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage(context, l10n.choreNameRequired);
      return;
    }
    final intervalDays = int.tryParse(_intervalDaysController.text.trim());
    if (intervalDays == null || intervalDays <= 0) {
      _showMessage(context, l10n.choreIntervalPositive);
      return;
    }
    final points = int.tryParse(_pointsController.text.trim());
    if (points == null || points <= 0) {
      _showMessage(context, l10n.chorePointsPositive);
      return;
    }
    final icon = _iconController.text.trim().isEmpty
        ? '🧽'
        : _iconController.text.trim();
    final room = _roomController.text.trim().isEmpty
        ? null
        : _roomController.text.trim();
    final householdId = ref.read(activeHouseholdIdProvider);
    final item = Item(
      id: existing?.id ?? _newId(),
      householdId: householdId,
      name: name,
      category: _category,
      icon: icon,
      intervalSeconds: intervalDays * Duration.secondsPerDay,
      points: points,
      roomOrZone: room,
      isPaused: _isPaused,
      snoozedUntil: existing?.snoozedUntil,
    );

    final controller = ref.read(itemsControllerProvider);
    final operation = existing == null
        ? controller.addItem(item)
        : controller.updateItem(item);
    operation.then((_) {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _applyItem(Item item) {
    _nameController.text = item.name;
    _iconController.text = item.icon;
    _roomController.text = item.roomOrZone ?? '';
    _intervalDaysController.text =
        (item.intervalSeconds / Duration.secondsPerDay).round().toString();
    _pointsController.text = item.points.toString();
    setState(() {
      _category = item.category;
      _isPaused = item.isPaused;
    });
  }

  DateTime? _latestApprovalFor(String? itemId, List<CompletionEvent> events) {
    if (itemId == null) {
      return null;
    }
    DateTime? latest;
    for (final event in events) {
      if (event.itemId != itemId) {
        continue;
      }
      if (latest == null || event.approvedAt.isAfter(latest)) {
        latest = event.approvedAt;
      }
    }
    return latest;
  }

  Future<void> _confirmDelete(BuildContext context, String itemId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.choreDeleteTitle),
        content: Text(l10n.choreDeleteBody),
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
      ref.read(itemsControllerProvider).deleteItem(itemId).then((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
