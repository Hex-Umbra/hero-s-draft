import 'package:flutter/material.dart';

import 'color_field.dart';
import 'editor_style.dart';

/// Les valeurs deja utilisees dans la categorie (spec D8), en etiquettes : un
/// aide-memoire pour nommer comme le reste du contenu.
class ReferencePanel extends StatelessWidget {
  const ReferencePanel({
    super.key,
    required this.values,
    required this.entityCount,
  });

  /// Tel que le rend `knownValues` : cle -> valeurs relevees.
  final Map<String, List<String>> values;

  /// Le nombre d'entites relues pour les relever.
  final int entityCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EditorColors.side,
        border: Border(left: BorderSide(color: EditorColors.line)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.library_books, size: 16, color: EditorColors.muted),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'VALEURS DÉJÀ UTILISÉES',
                    style: TextStyle(
                      color: EditorColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entityCount == 1
                  ? 'Relevées dans 1 entité'
                  : 'Relevées dans $entityCount entités',
              style: const TextStyle(color: EditorColors.faint, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (values.isEmpty)
              const Text(
                'Aucune valeur relevée.',
                style: TextStyle(color: EditorColors.faint, fontSize: 12.5),
              ),
            for (final entry in values.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: editorMono(
                              size: 12,
                              color: EditorColors.muted,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value.length}',
                          style: const TextStyle(
                            color: EditorColors.faint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        for (final value in entry.value) _ValueTag(value),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Une valeur relevee. Une couleur montre sa teinte ; un chemin se reduit au
/// nom de son fichier, le chemin entier restant en infobulle.
class _ValueTag extends StatelessWidget {
  const _ValueTag(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(value);
    final slash = value.lastIndexOf('/');
    final shown = slash < 0 ? value : value.substring(slash + 1);

    final tag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: EditorColors.tagFill,
        border: Border.all(color: EditorColors.tagBorder),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null) ...[
            Container(
              key: const Key('editeur-reference-teinte'),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(shown, style: editorMono(size: 11.5, color: EditorColors.soft)),
        ],
      ),
    );
    return slash < 0 ? tag : Tooltip(message: value, child: tag);
  }
}
