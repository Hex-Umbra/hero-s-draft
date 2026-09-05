import 'package:flutter/material.dart';

import '../game_dialog.dart';
import 'tabs/debug_deck_tab.dart';
import 'tabs/debug_hero_tab.dart';
import 'tabs/debug_relics_tab.dart';
import 'tabs/debug_run_tab.dart';

/// Menu de manipulation d'etat, reserve au developpement.
///
/// Il n'est jamais construit dans un build release : son unique point d'appel,
/// dans `PauseDialog`, est garde par `kDebugMode`.
class DebugMenuDialog extends StatelessWidget {
  /// Faux hors combat : l'onglet Combat n'a alors rien a montrer, et l'action
  /// d'acte suivant redevient disponible.
  final bool inCombat;

  const DebugMenuDialog({super.key, required this.inCombat});

  static Future<void> show(BuildContext context, {required bool inCombat}) {
    return showDialog(
      context: context,
      builder: (_) => DebugMenuDialog(inCombat: inCombat),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pas d'onglet Combat : il vit dans `DebugCombatDrawer`, ancre a meme
    // l'ecran de combat. Une seule place par chose — et surtout, un panneau
    // ancre n'est pas une route, donc terminer un combat depuis lui ne
    // derange pas la pile de navigation.
    final tabs = <(String, Widget)>[
      ('Heros', const DebugHeroTab()),
      ('Run', DebugRunTab(canRegenerateMap: !inCombat)),
      ('Deck', const DebugDeckTab()),
      ('Reliques', const DebugRelicsTab()),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: GameDialog(
        title: const Text('Menu de debug', textAlign: TextAlign.center),
        // `GameDialog` est un conteneur stylé maison : il n'y a pas de
        // `Material` dans son arbre. Or `TextField` et `ListTile` en exigent
        // un et refusent de se construire sans. `transparency` le fournit
        // sans rien peindre, pour ne pas recouvrir le fond du dialogue.
        //
        // Aucune couleur n'est fixée ici : les deux thèmes du jeu — sombre et
        // parchemin — définissent déjà les leurs, et les coder en dur rendrait
        // le menu illisible sur l'un des deux.
        content: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            height: 380,
            width: 460,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: [for (final (label, _) in tabs) Tab(text: label)],
                ),
                Expanded(
                  child: TabBarView(
                    children: [for (final (_, view) in tabs) view],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
