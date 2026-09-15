import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/controllers/inventory_controller.dart';
import '../../../../game/controllers/run_controller.dart';
import '../../../../game/services/debug_actions.dart';
import '../../notification_overlay.dart';
import '../debug_number_field.dart';

/// Onglet de progression de la run, affiche sur la carte uniquement.
///
/// C'est ce qui rend « acte suivant » sur : l'action regenere la carte et
/// efface la position, ce qui laisserait une run en combat sans noeud courant.
class DebugRunTab extends ConsumerWidget {
  const DebugRunTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(runProvider);
    final gold = ref.watch(inventoryProvider).gold;

    return ListView(
      children: [
        DebugNumberField(
          label: 'Or',
          value: gold,
          onSubmitted: (v) => DebugActions.setGold(ref.read, v),
        ),
        DebugNumberField(
          label: 'Acte (sans regenerer la carte)',
          value: run.act,
          onSubmitted: (v) =>
              DebugActions.updateRun(ref.read, (s) => s.copyWith(act: v)),
        ),
        DebugNumberField(
          label: 'Niveau de run',
          value: run.currentLevel,
          onSubmitted: (v) => DebugActions.updateRun(
            ref.read,
            (s) => s.copyWith(currentLevel: v),
          ),
        ),
        DebugNumberField(
          label: 'Drafts en attente',
          value: run.pendingDrafts,
          onSubmitted: (v) => DebugActions.updateRun(
            ref.read,
            (s) => s.copyWith(pendingDrafts: v),
          ),
        ),
        DebugNumberField(
          label: 'Cartes par tour',
          value: run.cardsPerTurn,
          onSubmitted: (v) => DebugActions.updateRun(
            ref.read,
            (s) => s.copyWith(cardsPerTurn: v),
          ),
        ),
        DebugNumberField(
          label: 'Slots de forge bonus',
          value: run.bonusForgeSlots,
          onSubmitted: (v) => DebugActions.updateRun(
            ref.read,
            (s) => s.copyWith(bonusForgeSlots: v),
          ),
        ),
        TextButton(
          onPressed: () {
            DebugActions.advanceToNextAct(ref.read);
            context.showNotification(
              'Acte ${ref.read(runProvider).act} — carte regeneree',
              type: NotificationType.success,
            );
          },
          child: const Text('Acte suivant (regenere la carte)'),
        ),
      ],
    );
  }
}
