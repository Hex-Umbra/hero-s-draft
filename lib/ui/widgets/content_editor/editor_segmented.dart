import 'package:flutter/material.dart';

import 'editor_style.dart';

/// Un segment d'[EditorSegmented].
@immutable
class EditorSegment<T> {
  const EditorSegment({
    required this.value,
    required this.label,
    this.icon,
    this.key,
  });

  final T value;
  final String label;
  final IconData? icon;

  /// Posee sur la zone touchable du segment.
  final Key? key;
}

/// Un choix exclusif entre quelques valeurs voisines : Créer / Modifier,
/// Formulaire / JSON.
///
/// Suit le contrat de choix (spec D9) : chaque segment peint un fond opaque de
/// cle `editeur-bouton-fond`, se dit choisi a l'accessibilite, et marque sa
/// selection d'un anneau en plus de la couleur.
class EditorSegmented<T> extends StatelessWidget {
  const EditorSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
    this.dense = false,
  });

  final List<EditorSegment<T>> segments;

  /// `null` : aucun segment choisi.
  final T? selected;

  /// Rappele aussi pour le segment deja choisi : a l'appelant de l'ignorer.
  final ValueChanged<T> onSelected;

  /// Le format d'un en-tete de panneau.
  final bool dense;

  static final Color _selectedFill = Color.alphaBlend(
    EditorColors.accent.withValues(alpha: 0.14),
    EditorColors.well,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dense ? 2 : 3),
      decoration: BoxDecoration(
        color: EditorColors.well,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: EditorColors.lineStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _segment(segments[i]),
          ],
        ],
      ),
    );
  }

  Widget _segment(EditorSegment<T> segment) {
    final isSelected = segment.value == selected;
    final ink = isSelected ? EditorColors.accent : EditorColors.muted;
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: InkWell(
        key: segment.key,
        onTap: () => onSelected(segment.value),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          key: const Key('editeur-bouton-fond'),
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 12,
            vertical: dense ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: isSelected ? _selectedFill : EditorColors.well,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? EditorColors.accent.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.icon != null) ...[
                Icon(segment.icon, size: dense ? 15 : 17, color: ink),
                const SizedBox(width: 6),
              ],
              Text(
                segment.label,
                style: TextStyle(
                  color: ink,
                  fontSize: dense ? 12 : 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
