import 'package:flutter/material.dart';

import 'color_field.dart';

/// Le fond des entites sans proprietaire : un gris moyen, du meme poids que les
/// couleurs de classe. Le gris clair d'avant les eclipsait.
const Color kNeutralOwnerColor = Color(0xFF9E9E9E);

/// Un choix de l'editeur : un niveau de l'arbre, une pastille de proprietaire,
/// un passif.
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
    this.imagePath,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// La couleur qui identifie le choix : [kNeutralOwnerColor] pour une entite
  /// neutre, `themeColor` de sa classe sinon. Elle reste le fond, choisi ou
  /// non, et un anneau marque alors la selection.
  ///
  /// `null` pour un choix sans identite — type, mode, passif : son fond suit
  /// l'etat, sombre au repos, couleur primaire du theme une fois choisi.
  final Color? identityColor;

  /// L'icone ou la carte de la classe proprietaire. La distinction ne repose
  /// ainsi pas sur la seule couleur.
  final String? imagePath;

  static const double _radius = 6;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final identity = identityColor;
    final fill = identity ?? (isSelected ? scheme.primary : scheme.surface);
    final ink = readableOn(fill);

    return Container(
      // L'anneau d'un choix d'identite, separe du bouton par le fond de
      // l'ecran : il se detache de toute couleur de classe, meme d'un bleu
      // voisin du sien. Sa place est gardee au repos, pour que choisir ne
      // decale pas la rangee.
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius + 4),
        border: Border.all(
          color: identity != null && isSelected
              ? scheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          key: const Key('editeur-bouton-fond'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(_radius),
            // Au repos, un choix sans identite a presque le fond de l'ecran :
            // seul ce lisere en dessine le bord.
            border: Border.all(
              color: identity == null && !isSelected
                  ? ink.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check, size: 16, color: ink),
                const SizedBox(width: 4),
              ],
              if (imagePath != null) ...[
                ClipOval(
                  child: Image.asset(
                    imagePath!,
                    width: 16,
                    height: 16,
                    fit: BoxFit.cover,
                    // Un placeholder absent ne doit pas faire tomber l'ecran.
                    errorBuilder: (_, _, _) => const SizedBox(width: 16),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: ink,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
