import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/controllers/deck_controller.dart';
import '../../../../game/services/debug_actions.dart';
import '../../../../models/data/card_data.dart';
import '../../../../models/data/game_data_registry.dart';
import '../../notification_overlay.dart';

class DebugDeckTab extends ConsumerWidget {
  const DebugDeckTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterDeck = ref.watch(deckProvider).masterDeck;
    final catalogue = List<CardData>.of(
      GameDataRegistry.instance?.cards ?? const <CardData>[],
    )..sort(CardData.compareByDisplayOrder);

    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  DebugActions.drawCards(ref.read, 1);
                  context.showNotification(
                    '1 carte piochee',
                    type: NotificationType.success,
                  );
                },
                child: const Text('Piocher 1'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  DebugActions.discardHand(ref.read);
                  context.showNotification(
                    'Main defaussee',
                    type: NotificationType.success,
                  );
                },
                child: const Text('Defausser la main'),
              ),
            ),
          ],
        ),
        const Divider(),
        const Text('Ajouter une carte'),
        for (final card in catalogue)
          ListTile(
            dense: true,
            title: Text('${card.nameFr}  (${card.cost})'),
            trailing: const Icon(Icons.add),
            onTap: () {
              DebugActions.addCard(ref.read, card);
              context.showNotification(
                'Carte ajoutee : ${card.nameFr}',
                type: NotificationType.success,
              );
            },
          ),
        const Divider(),
        Text('Deck maitre (${masterDeck.length})'),
        for (final instance in masterDeck)
          ListTile(
            dense: true,
            title: Text(instance.data.nameFr),
            trailing: const Icon(Icons.remove),
            onTap: () {
              DebugActions.removeCard(ref.read, instance.uniqueId);
              context.showNotification(
                'Carte retiree : ${instance.data.nameFr}',
                type: NotificationType.success,
              );
            },
          ),
      ],
    );
  }
}
