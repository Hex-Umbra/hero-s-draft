import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'tabs/debug_combat_tab.dart';

/// Tiroir de debug ancre au bord gauche de l'ecran de combat.
///
/// **Ancre dans l'arbre de `GameScreen`, et non pousse comme dialogue.** Il
/// n'est donc pas une route du navigateur, ce qui le rend sur pendant qu'une
/// action met fin au combat : la sortie de combat pope alors bien l'ecran,
/// sans qu'une route de debug se soit glissee au sommet de la pile. C'est
/// exactement le defaut qui se produisait quand ces memes actions vivaient
/// dans le menu de pause.
class DebugCombatDrawer extends StatefulWidget {
  const DebugCombatDrawer({super.key});

  @override
  State<DebugCombatDrawer> createState() => _DebugCombatDrawerState();
}

class _DebugCombatDrawerState extends State<DebugCombatDrawer> {
  bool _open = false;

  static const Color _accent = Colors.deepPurpleAccent;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_open)
            Container(
              width: 330,
              height: 420,
              padding: AppSpacing.paddingSm,
              decoration: BoxDecoration(
                color: surface.withValues(alpha: 0.96),
                border: const Border(
                  top: BorderSide(color: _accent, width: 2),
                  right: BorderSide(color: _accent, width: 2),
                  bottom: BorderSide(color: _accent, width: 2),
                ),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
              ),
              child: const DebugCombatTab(),
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
          color: _DebugCombatDrawerState._accent.withValues(alpha: 0.85),
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
