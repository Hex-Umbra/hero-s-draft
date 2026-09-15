import 'package:flutter/material.dart';

import 'color_field.dart';
import 'editor_style.dart';

/// Le fond des entites sans proprietaire : un gris moyen, du meme poids que les
/// couleurs de classe. Le gris clair d'avant les eclipsait.
const Color kNeutralOwnerColor = Color(0xFF9E9E9E);

/// Un choix de l'editeur : une pastille de proprietaire, une option de
/// formulaire. Suit le contrat de choix (spec D9) : fond opaque
/// derriere `Key('editeur-bouton-fond')`, texte et coche a 4,5:1, coche sur le
/// seul choix actif.
///
/// **Le texte tire sa couleur de son fond**, jamais du theme : voir
/// [readableOn]. Le defaut d'origine etait la — un bouton peint en gris clair
/// heritait du blanc a 70 % prevu pour le fond sombre de l'ecran, a 1,22:1.
///
/// **La selection ne repose pas sur la seule couleur** : le choix actif porte
/// une coche et un libelle gras.
class ChoiceButton extends StatelessWidget {
  const ChoiceButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.identityColor,
    this.tint,
    this.isPlaceholder = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// La couleur qui identifie le choix : [kNeutralOwnerColor] pour une entite
  /// neutre, `themeColor` de sa classe sinon. Elle reste le fond, choisi ou
  /// non, et un anneau marque alors la selection.
  final Color? identityColor;

  /// Une teinte d'option — la couleur d'une rarete. Au repos, elle colore le
  /// libelle et le bord sur le fond sombre d'une puce ; choisie, elle devient
  /// le fond.
  final Color? tint;

  /// « aucun » : l'absence de valeur, en italique tant qu'elle n'est pas
  /// choisie.
  final bool isPlaceholder;

  static const double _radius = 6;

  @override
  Widget build(BuildContext context) {
    final identity = identityColor;
    final tint = this.tint;

    // Le texte tire sa couleur de son fond, jamais du theme (voir la note de
    // tete) : au repos teinte, il est eclairci vers le blanc pour garder
    // 4,5:1 sur le fond sombre, meme pour le violet d'une rarete epique.
    final Color fill;
    final Color ink;
    final Color edge;
    if (identity != null) {
      fill = identity;
      ink = readableOn(fill);
      edge = Colors.transparent;
    } else if (isSelected) {
      fill = tint ?? EditorColors.accent;
      ink = readableOn(fill);
      edge = Colors.transparent;
    } else if (tint != null) {
      fill = Color.alphaBlend(tint.withValues(alpha: 0.07), EditorColors.chip);
      ink = Color.lerp(tint, Colors.white, 0.4)!;
      edge = tint.withValues(alpha: 0.45);
    } else {
      fill = EditorColors.chip;
      ink = isPlaceholder ? EditorColors.muted : EditorColors.soft;
      edge = EditorColors.chipBorder;
    }
    final labelStyle = isPlaceholder && !isSelected
        ? TextStyle(color: ink, fontSize: 12.5, fontStyle: FontStyle.italic)
        : editorMono(
            color: ink,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );

    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: Container(
        // L'anneau d'un choix d'identite, separe du bouton par le fond de
        // l'ecran : il se detache de toute couleur de classe. Sa place est
        // gardee au repos, pour que choisir ne decale pas la rangee.
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius + 4),
          border: Border.all(
            color: identity != null && isSelected
                ? EditorColors.accent
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            key: const Key('editeur-bouton-fond'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: edge),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check, size: 15, color: ink),
                  const SizedBox(width: 5),
                ],
                Text(label, style: labelStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
