import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/passive_data.dart';
import 'class_identity.dart';
import 'game_dialog.dart';

/// Le choix du passif de depart, sorti de la carte de classe.
///
/// La carte ne montre plus que l'identite de la classe : le passif se choisit
/// ici, ou chaque option dispose de sa description entiere et de sa ligne de
/// Maitrise. Comparer les trois ne demande plus de les selectionner un par un
/// pour lire ce qu'ils font.
///
/// Le panneau ne navigue pas : il rend le passif retenu, et l'ecran appelant
/// decide de la suite. `null` veut dire annule — ni le bouton Annuler, ni la
/// croix, ni un tap hors du panneau ne valident quoi que ce soit.
class PassiveChoiceDialog extends StatefulWidget {
  final HeroData playerClass;
  final List<PassiveData> passives;

  /// Le passif coche a l'ouverture, par son rang dans `passives`.
  final int initialIndex;

  const PassiveChoiceDialog({
    super.key,
    required this.playerClass,
    required this.passives,
    required this.initialIndex,
  });

  /// Ouvre le panneau et rend le passif retenu, ou `null` si le joueur a
  /// renonce.
  ///
  /// `passives` ne peut pas etre vide : une classe sans passif disponible
  /// n'a aucun choix a offrir, et l'appelant enchaine sans ouvrir le panneau.
  static Future<PassiveData?> show(
    BuildContext context, {
    required HeroData playerClass,
    required List<PassiveData> passives,
    int initialIndex = 0,
  }) {
    assert(passives.isNotEmpty, 'aucun passif a proposer');
    return showGeneralDialog<PassiveData>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PassiveChoice',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) => PassiveChoiceDialog(
        playerClass: playerClass,
        passives: passives,
        initialIndex: initialIndex,
      ),
      transitionBuilder: (context, anim1, anim2, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim1, child: child),
      ),
    );
  }

  @override
  State<PassiveChoiceDialog> createState() => _PassiveChoiceDialogState();
}

class _PassiveChoiceDialogState extends State<PassiveChoiceDialog> {
  late int _index = widget.initialIndex.clamp(0, widget.passives.length - 1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final classColor = ClassIdentity.colorOf(widget.playerClass);

    return GameDialog(
      glowColor: classColor,
      maxWidth: 520,
      title: Text(l10n.passiveChoiceTitle),
      subtitle: Text(widget.playerClass.getName(locale)),
      // `GameDialog` est un `Container` pose par `showGeneralDialog` : il n'y
      // a aucun `Material` au-dessus, et l'ondulation des lignes en exige un.
      // `transparency` n'en peint aucun : le fond reste celui du panneau.
      content: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.passives.length; i++)
              _buildOption(i, locale, l10n, classColor),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: classColor),
          onPressed: () => Navigator.of(context).pop(widget.passives[_index]),
          child: Text(l10n.passiveChoiceConfirm),
        ),
      ],
    );
  }

  Widget _buildOption(
    int i,
    String locale,
    AppLocalizations l10n,
    Color classColor,
  ) {
    final passive = widget.passives[i];
    final selected = i == _index;
    final mastery = passive.mastery;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _index = i),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          // La ligne entiere porte le geste, et jamais moins que la cible
          // tactile de Material : c'est ce que l'ancienne puce du selecteur,
          // haute d'une trentaine de pixels, ne tenait pas.
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? classColor.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            // Largeur constante, seule la couleur change : une bordure qui
            // s'epaissit a la selection remesurerait la ligne a chaque tap.
            border: Border.all(
              color: selected ? classColor : Colors.white24,
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: selected ? classColor : Colors.white38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passive.getName(locale),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      passive.getDescription(locale),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                    if (mastery != null) ...[
                      const SizedBox(height: 4),
                      // La valeur de depart de la classe accompagne l'effet :
                      // deux classes sur trois demarrent a 0 et pouvaient
                      // croire l'effet actif. Il reste ecrit parce qu'elles
                      // peuvent gagner de la Maitrise en cours de run.
                      Text(
                        l10n.passiveMasteryAtStart(
                          widget.playerClass.mastery,
                          mastery.describe(locale, 1),
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.cyanAccent.withValues(alpha: 0.8),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
