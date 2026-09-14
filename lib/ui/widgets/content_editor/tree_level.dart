import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'choice_button.dart';

/// Un choix d'un niveau de l'arbre.
@immutable
class TreeChoice {
  const TreeChoice({
    required this.value,
    required this.label,
    this.identityColor,
    this.imagePath,
  });

  final Object value;
  final String label;

  /// Le proprietaire d'une entite, qui reste son fond : voir
  /// [ChoiceButton.identityColor]. `null` pour un type ou un mode.
  final Color? identityColor;

  /// L'icone ou la carte de la classe proprietaire. La distinction ne repose
  /// ainsi pas sur la seule couleur.
  final String? imagePath;
}

/// Une rangee de boutons sous sa legende, dont un peut etre selectionne.
///
/// [depth] est la tabulation : chaque descente decale d'un cran, et rien ne se
/// replie vers le haut.
class TreeLevel extends StatelessWidget {
  const TreeLevel({
    super.key,
    required this.caption,
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.depth = 0,
  });

  static const double indent = 24;

  /// Ce que le niveau propose : « Type », « Action », « Entité ».
  final String caption;
  final List<TreeChoice> choices;
  final Object? selected;
  final ValueChanged<Object> onSelected;
  final int depth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * indent, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            // Chaque bouton garde deja la place de son anneau de selection :
            // l'ecart entre deux fonds reste d'une douzaine de points.
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final choice in choices)
                ChoiceButton(
                  label: choice.label,
                  isSelected: choice.value == selected,
                  onTap: () => onSelected(choice.value),
                  identityColor: choice.identityColor,
                  imagePath: choice.imagePath,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
