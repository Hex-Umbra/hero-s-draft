import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'tabs/debug_combat_tab.dart';
import 'tabs/debug_deck_tab.dart';
import 'tabs/debug_hero_tab.dart';
import 'tabs/debug_relics_tab.dart';
import 'tabs/debug_run_tab.dart';

/// Tiroir de debug ancre au bord gauche de l'ecran, sur la carte comme en
/// combat.
///
/// **Ancre dans l'arbre de l'ecran, jamais pousse comme dialogue.** Il n'est
/// donc pas une route du navigateur, ce qui le rend sur pendant qu'une action
/// change d'ecran : terminer un combat depuis lui pope bien l'ecran de combat,
/// la ou un dialogue empile au-dessus se faisait fermer a sa place.
///
/// Un seul composant pour les deux ecrans : les onglets sont les memes, seul
/// l'onglet Combat s'ajoute quand il y a un combat.
class DebugDrawer extends StatefulWidget {
  /// Ajoute l'onglet Combat, et retire de l'onglet Run l'action d'acte
  /// suivant — elle regenere la carte et effacerait la position.
  final bool inCombat;

  const DebugDrawer({super.key, required this.inCombat});

  @override
  State<DebugDrawer> createState() => _DebugDrawerState();
}

class _DebugDrawerState extends State<DebugDrawer> {
  bool _open = false;

  static const Color accent = Colors.deepPurpleAccent;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    final tabs = <(String, Widget)>[
      ('Heros', const DebugHeroTab()),
      ('Run', DebugRunTab(canRegenerateMap: !widget.inCombat)),
      ('Deck', const DebugDeckTab()),
      ('Reliques', const DebugRelicsTab()),
      if (widget.inCombat) ('Combat', const DebugCombatTab()),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_open)
            Container(
              width: 360,
              height: 460,
              padding: AppSpacing.paddingSm,
              decoration: BoxDecoration(
                color: surface.withValues(alpha: 0.97),
                border: const Border(
                  top: BorderSide(color: accent, width: 2),
                  right: BorderSide(color: accent, width: 2),
                  bottom: BorderSide(color: accent, width: 2),
                ),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
              ),
              child: DefaultTabController(
                length: tabs.length,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelPadding: AppSpacing.paddingHSm,
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
          _DrawerHandle(
            open: _open,
            onTap: () => setState(() => _open = !_open),
          ),
        ],
      ),
    );
  }
}

/// La poignee, toujours visible : c'est elle qui signale que l'on joue une
/// run debug, meme tiroir ferme.
class _DrawerHandle extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;

  const _DrawerHandle({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 132,
        decoration: BoxDecoration(
          color: _DebugDrawerState.accent.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(8),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              open ? Icons.chevron_left : Icons.chevron_right,
              color: Colors.white,
              size: 18,
            ),
            AppSpacing.heightXs,
            const RotatedBox(
              quarterTurns: 3,
              child: Text(
                'DEBUG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
