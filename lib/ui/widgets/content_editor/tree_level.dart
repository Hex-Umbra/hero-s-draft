import 'package:flutter/material.dart';

/// Un choix d'un niveau de l'arbre.
@immutable
class TreeChoice {
  const TreeChoice({
    required this.value,
    required this.label,
    this.background,
    this.imagePath,
  });

  final Object value;
  final String label;

  /// Le fond du bouton. Porte le proprietaire d'une carte : gris pour les
  /// neutres, `themeColor` de la classe sinon.
  final Color? background;

  /// L'icone ou la carte de la classe proprietaire. La distinction ne repose
  /// ainsi pas sur la seule couleur.
  final String? imagePath;
}

/// Une rangee de boutons, dont un peut etre selectionne.
///
/// [depth] est la tabulation : chaque descente decale d'un cran, et rien ne se
/// replie vers le haut.
class TreeLevel extends StatelessWidget {
  const TreeLevel({
    super.key,
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.depth = 0,
  });

  static const double indent = 24;

  final List<TreeChoice> choices;
  final Object? selected;
  final ValueChanged<Object> onSelected;
  final int depth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * indent, top: 8, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final choice in choices)
            _button(context, choice, choice.value == selected),
        ],
      ),
    );
  }

  Widget _button(BuildContext context, TreeChoice choice, bool isSelected) {
    final background = choice.background ?? Colors.grey.shade300;
    return InkWell(
      onTap: () => onSelected(choice.value),
      child: Container(
        key: const Key('editeur-bouton-fond'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (choice.imagePath != null) ...[
              ClipOval(
                child: Image.asset(
                  choice.imagePath!,
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
              choice.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
