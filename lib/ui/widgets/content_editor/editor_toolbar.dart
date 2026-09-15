import 'package:flutter/material.dart';

import '../../../services/content_editor/entity_descriptor.dart';
import '../../theme/app_colors.dart';
import 'editor_style.dart';

/// La barre d'outils (spec D1) : les types en onglets, et au bout l'action.
/// Les onglets passent a la ligne quand la largeur manque.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.trailing,
  });

  final EntityCategory? selected;

  /// Rappele aussi pour l'onglet deja choisi : a l'appelant de l'ignorer.
  final ValueChanged<EntityCategory> onSelected;

  /// Le choix de l'action, une fois un type choisi.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: EditorColors.side,
        border: Border(bottom: BorderSide(color: EditorColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              children: [
                for (final descriptor in kEntityDescriptors.values)
                  _TypeTab(
                    label: descriptor.label,
                    icon: kCategoryIcons[descriptor.category]!,
                    isSelected: descriptor.category == selected,
                    onTap: () => onSelected(descriptor.category),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: trailing,
            ),
        ],
      ),
    );
  }
}

/// Un onglet de type, selon le contrat de choix (spec D9) : son soulignement
/// marque la selection autrement que par la couleur du texte.
class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          key: const Key('editeur-bouton-fond'),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: EditorColors.side,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? EditorColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? EditorColors.accent : EditorColors.faint,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? AppColors.textPrimary : EditorColors.muted,
                  fontSize: 13.5,
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
