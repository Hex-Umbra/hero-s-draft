import 'package:flutter/material.dart';

import '../game_dialog.dart';
import 'tabs/debug_combat_tab.dart';
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
    final tabs = <(String, Widget)>[
      ('Heros', const DebugHeroTab()),
      ('Run', DebugRunTab(canRegenerateMap: !inCombat)),
      ('Deck', const DebugDeckTab()),
      ('Reliques', const DebugRelicsTab()),
      if (inCombat) ('Combat', const DebugCombatTab()),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: GameDialog(
        title: const Text('Menu de debug', textAlign: TextAlign.center),
        content: SizedBox(
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
    );
  }
}
