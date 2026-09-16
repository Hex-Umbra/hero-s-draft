import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/controllers/run_controller.dart';
import '../../../../game/services/debug_actions.dart';
import '../../notification_overlay.dart';
import '../debug_number_field.dart';

/// Statistiques de **progression** du heros.
///
/// PV, mana et armure n'y sont pas : ils bougent au fil des tours et vivent
/// dans l'onglet Combat, seul onglet affiche pendant un combat.
class DebugHeroTab extends ConsumerWidget {
  const DebugHeroTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(runProvider).heroStats;

    return ListView(
      children: [
        DebugNumberField(
          label: 'PV max',
          value: stats.maxPv,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(maxPv: v),
          ),
        ),
        DebugNumberField(
          label: 'Mana max',
          value: stats.maxMana,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(maxMana: v),
          ),
        ),
        DebugNumberField(
          label: 'Attaque',
          value: stats.attackPower,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(attackPower: v),
          ),
        ),
        DebugNumberField(
          label: 'Chance',
          value: stats.luck,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(luck: v),
          ),
        ),
        DebugNumberField(
          label: 'Chance de critique (%)',
          value: stats.critChance,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(critChance: v),
          ),
        ),
        const Divider(),
        DebugNumberField(
          label: 'Niveau (stat brute)',
          value: stats.level,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(level: v),
          ),
        ),
        DebugNumberField(
          label: 'XP  (seuil ${stats.xpToNextLevel})',
          value: stats.xp,
          onSubmitted: (v) =>
              DebugActions.updateHeroStats(ref.read, (s) => s.copyWith(xp: v)),
        ),
        // Le champ ci-dessus n'ecrase qu'une statistique. Ce bouton emprunte le
        // vrai chemin : seuil d'XP recalcule et draft de recompense ouvert.
        TextButton(
          onPressed: () {
            DebugActions.gainLevel(ref.read);
            context.showNotification(
              'Niveau ${ref.read(runProvider).heroStats.level} — '
              'draft en attente sur la carte',
              type: NotificationType.success,
            );
          },
          child: const Text('Gagner un niveau (ouvre le draft)'),
        ),
      ],
    );
  }
}
