import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/controllers/combat_controller.dart';
import '../../../../game/controllers/run_controller.dart';
import '../../../../game/services/debug_actions.dart';
import '../../notification_overlay.dart';
import '../debug_number_field.dart';

/// Seul onglet affiche pendant un combat : il doit donc etre autosuffisant.
///
/// Il porte les statistiques du heros qui bougent au fil des tours — PV, mana,
/// armure — la ou l'onglet Heros garde celles qui relevent de la progression :
/// maxima, attaque, chance, niveau.
class DebugCombatTab extends ConsumerWidget {
  const DebugCombatTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enemies = ref.watch(combatProvider).enemies;
    final stats = ref.watch(runProvider).heroStats;

    return ListView(
      children: [
        const Text('Statistiques du heros'),
        DebugNumberField(
          label: 'PV  (max ${stats.maxPv})',
          value: stats.currentPv,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(currentPv: v),
          ),
        ),
        DebugNumberField(
          label: 'Mana  (max ${stats.maxMana})',
          value: stats.currentMana,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(currentMana: v),
          ),
        ),
        DebugNumberField(
          label: 'Armure',
          value: stats.armure,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(armure: v),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => DebugActions.updateHeroStats(
                  ref.read,
                  (s) => s.copyWith(currentPv: s.maxPv),
                ),
                child: const Text('Soin complet'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => DebugActions.updateHeroStats(
                  ref.read,
                  (s) => s.copyWith(currentMana: s.maxMana),
                ),
                child: const Text('Mana plein'),
              ),
            ),
          ],
        ),
        const Divider(),
        Text('Ennemis (${enemies.length})'),
        for (var i = 0; i < enemies.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: DebugNumberField(
                    // Le rang distingue deux ennemis du meme type.
                    label:
                        '${i + 1}. ${enemies[i].data.nameFr}'
                        '  (${enemies[i].stats.currentPv}'
                        '/${enemies[i].stats.maxPv})',
                    value: enemies[i].stats.currentPv,
                    onSubmitted: (v) =>
                        DebugActions.setEnemyHp(ref.read, enemies[i].id, v),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      DebugActions.setEnemyHp(ref.read, enemies[i].id, 0),
                  child: const Text('0 PV'),
                ),
              ],
            ),
          ),
        const Divider(),
        TextButton(
          onPressed: () {
            DebugActions.killAllEnemies(ref.read);
            context.showNotification(
              'Vague videe',
              type: NotificationType.success,
            );
          },
          child: const Text('Tous les ennemis a 0 PV'),
        ),
        // Aucun `Navigator.pop()` ici : ce panneau est ancre dans l'ecran de
        // combat, pas pousse comme route. C'est le jeu qui navigue — la
        // victoire mene aux recompenses, la mort a `DeathOverlay`.
        TextButton(
          onPressed: () => DebugActions.winCombat(ref.read),
          child: const Text('Gagner le combat'),
        ),
        TextButton(
          onPressed: () => DebugActions.loseCombat(ref.read),
          child: const Text('Perdre le combat'),
        ),
        TextButton(
          onPressed: () {
            DebugActions.skipEnemyPhase(ref.read);
            context.showNotification(
              'Phase joueur forcee',
              type: NotificationType.success,
            );
          },
          child: const Text('Sauter la phase ennemie'),
        ),
      ],
    );
  }
}
