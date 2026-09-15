import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/controllers/inventory_controller.dart';
import '../../../../game/services/debug_actions.dart';
import '../../../../models/data/game_data_registry.dart';
import '../../../../models/data/relic_data.dart';
import '../../notification_overlay.dart';

class DebugRelicsTab extends ConsumerWidget {
  const DebugRelicsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref.watch(inventoryProvider).relics;
    final catalogue = GameDataRegistry.instance?.relics ?? const <RelicData>[];

    return ListView(
      children: [
        const Text('Ajouter une relique'),
        for (final relic in catalogue)
          ListTile(
            dense: true,
            leading: Text(relic.emoji),
            title: Text(relic.nameFr),
            trailing: const Icon(Icons.add),
            onTap: () {
              DebugActions.addRelic(ref.read, relic);
              context.showNotification(
                'Relique ajoutee : ${relic.nameFr}',
                type: NotificationType.success,
              );
            },
          ),
        const Divider(),
        Text('Reliques possedees (${owned.length})'),
        for (final relic in owned)
          ListTile(
            dense: true,
            leading: Text(relic.emoji),
            title: Text(relic.nameFr),
            trailing: const Icon(Icons.remove),
            onTap: () {
              DebugActions.removeRelic(ref.read, relic.id);
              context.showNotification(
                'Relique retiree : ${relic.nameFr}',
                type: NotificationType.success,
              );
            },
          ),
      ],
    );
  }
}
