import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';

import '../../../models/data/signature_evolution_data.dart';
import '../../../models/signature_instance.dart';
import 'curtains/level_up_curtain.dart';
import 'curtains/major_evolution_curtain.dart';
import 'curtains/minor_evolution_curtain.dart';

/// Le rideau de la carte : il dit ce qui attend (D79), et sa forme dit ce que
/// c'est (D80). Toucher n'importe où l'ouvre.
class LevelUpOverlay extends StatelessWidget {
  final VoidCallback onTap;
  final Color classColor;

  /// Les signatures dont l'évolution est le prochain choix. Vide, le prochain
  /// choix est un draft de niveau.
  final List<SignatureInstance> evolving;

  const LevelUpOverlay({
    super.key,
    required this.onTap,
    required this.classColor,
    this.evolving = const [],
  });

  Widget _curtain(AppLocalizations l10n) {
    if (evolving.isEmpty) {
      return LevelUpCurtain(
        classColor: classColor,
        title: l10n.levelUpCurtainTitle,
        subtitle: l10n.levelUpCurtainSubtitle,
        action: l10n.levelUpCurtainAction,
      );
    }
    final subtitle = switch (evolving) {
      [final signature] => l10n.evolutionCurtainOne(
          signature.data.getName(l10n.localeName),
        ),
      _ => l10n.evolutionCurtainBoth,
    };
    return evolving.any((s) => s.nextTier == EvolutionTier.major)
        ? MajorEvolutionCurtain(
            classColor: classColor,
            title: l10n.evolutionCurtainTitleMajor,
            subtitle: subtitle,
            action: l10n.evolutionCurtainAction,
          )
        : MinorEvolutionCurtain(
            classColor: classColor,
            title: l10n.evolutionCurtainTitleMinor,
            subtitle: subtitle,
            action: l10n.evolutionCurtainAction,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // Les flèches et les rayons débordent : ils s'arrêtent à la carte.
        child: ClipRect(child: _curtain(AppLocalizations.of(context)!)),
      ),
    );
  }
}
