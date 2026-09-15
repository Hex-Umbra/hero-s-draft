import 'package:flutter/material.dart';

import 'editor_style.dart';

/// Des rangees separees d'un filet : les champs d'un panneau, ceux d'un
/// element de liste.
List<Widget> separatedRows(List<Widget> rows) => [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0)
          const Divider(height: 1, thickness: 1, color: EditorColors.line),
        rows[i],
      ],
    ];

/// Une section du formulaire (spec D4) : un en-tete titre, puis ses rangees.
class EditorPanel extends StatelessWidget {
  const EditorPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.caption,
    this.trailing,
  });

  final IconData icon;

  /// Affiche en capitales espacees, comme `PageHeader`.
  final String title;
  final List<Widget> children;

  /// Une precision discrete, a droite de l'en-tete.
  final String? caption;

  /// Un controle d'en-tete : la bascule JSON, le nombre de cartes.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: EditorColors.panel,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: EditorColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
            color: EditorColors.panelHead,
            child: Row(
              children: [
                Icon(icon, size: 18, color: EditorColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: EditorColors.soft,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    caption!,
                    style: const TextStyle(
                      color: EditorColors.faint,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: EditorColors.line),
          ...separatedRows(children),
        ],
      ),
    );
  }
}
