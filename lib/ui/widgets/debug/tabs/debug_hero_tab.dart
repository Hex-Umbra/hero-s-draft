import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../game/controllers/run_controller.dart';
import '../../../../game/services/debug_actions.dart';
import '../../../../models/entity_stats.dart';
import '../../../../models/might_target.dart';
import '../../../theme/app_spacing.dart';
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
    final run = ref.watch(runProvider);
    final stats = run.heroStats;

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
          label: 'Puissance',
          value: stats.might,
          onSubmitted: (v) => DebugActions.updateHeroStats(
            ref.read,
            (s) => s.copyWith(might: v),
          ),
        ),
        // Ce que la Puissance renforce. Une puce par valeur de `MightTarget`,
        // **generee** : une liste ecrite a la main divergerait de
        // l'enumeration au premier ajout (ADR-090).
        //
        // `Wrap`, pas `Row` : sous la police de substitution de `flutter
        // test` (chaque glyphe a la largeur d'un em, le double de Roboto),
        // trois FilterChip Material 3 a cote du libelle debordent de 88px
        // dans les 342px de contenu du tiroir (`debug_drawer.dart:61`) — pas
        // un fait de l'appli reelle, ou la police de bureau tient. Le `Wrap`
        // laisse les puces refluer sur une seconde ligne au lieu de deborder,
        // sans rien changer aux cibles affichees ni a la bascule. Le libelle
        // garde un `Flexible` (pas un `Text` nu) pour qu'il puisse retrecir
        // et passer a la ligne plutot que de reclamer sa largeur intrinseque
        // et affamer le `Wrap`.
        Padding(
          padding: AppSpacing.paddingVSm,
          child: Row(
            children: [
              const Flexible(child: Text('Puissance : cibles')),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final target in MightTarget.values)
                      FilterChip(
                        label: Text(target.name),
                        selected: stats.mightTargets.contains(target),
                        onSelected: (_) => _toggleTarget(ref, stats, target),
                      ),
                  ],
                ),
              ),
            ],
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
        // L'identite de la classe telle que la run la porte. En lecture
        // seule : ces trois-la viennent du `class.json` et du choix de
        // passif, et les ecraser ici produirait une run qu'aucune sauvegarde
        // ne saurait relire (`RunState.statRules` n'est pas serialise, il est
        // relu de la classe).
        Padding(
          padding: AppSpacing.paddingVSm,
          child: Text('Classe : ${run.heroClassId}'),
        ),
        Padding(
          padding: AppSpacing.paddingVSm,
          child: Text(
            run.statRules.isEmpty
                ? 'Regles de stat : aucune'
                : 'Regles de stat :',
          ),
        ),
        for (final rule in run.statRules)
          Padding(
            padding: AppSpacing.paddingVSm,
            // `StatRule.toString()` : le vocabulaire du fichier, pas la
            // phrase du joueur.
            child: Text('$rule'),
          ),
        Padding(
          padding: AppSpacing.paddingVSm,
          child: Text('Passif actif : ${run.activePassive?.id ?? 'aucun'}'),
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

  /// Ajoute ou retire [target], **sans jamais vider l'ensemble**.
  ///
  /// `HeroData.fromJson` refuse une liste vide comme une faute de donnee
  /// (`might_target.dart:20-25`) : un outil de debug ne doit pas produire un
  /// etat que la couche de donnees refuse de relire. Pour une run dont la
  /// Puissance ne renforce rien, le reglage prevu est le champ « Puissance »
  /// a 0.
  void _toggleTarget(WidgetRef ref, EntityStats stats, MightTarget target) {
    final next = {...stats.mightTargets};
    if (next.contains(target)) {
      if (next.length == 1) return;
      next.remove(target);
    } else {
      next.add(target);
    }
    DebugActions.updateHeroStats(
      ref.read,
      (s) => s.copyWith(mightTargets: next),
    );
  }
}
