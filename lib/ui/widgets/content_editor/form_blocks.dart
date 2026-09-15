import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'dashed_border.dart';
import 'editor_panel.dart';
import 'editor_style.dart';

/// Les deux premieres valeurs simples d'un element : `damage · 6`.
String summaryOf(Object? element) => element is Map
    ? element.values
        .where((value) => value is String || value is num || value is bool)
        .take(2)
        .join(' · ')
    : '';

/// Une suite de nombres rangee en grille (spec D5) : trois colonnes au plus,
/// une de moins par tranche de 190 points qui manque.
class NumberGrid extends StatelessWidget {
  const NumberGrid({super.key, required this.cells});

  final List<Widget> cells;

  static const double minCellWidth = 190;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.max(
          1,
          math.min(3, (constraints.maxWidth / minCellWidth).floor()),
        );
        final rows = <Widget>[
          for (var start = 0; start < cells.length; start += columns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var column = 0; column < columns; column++)
                  Expanded(
                    child: _cell(
                      column,
                      start + column < cells.length
                          ? cells[start + column]
                          : null,
                    ),
                  ),
              ],
            ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: separatedRows(rows),
        );
      },
    );
  }

  Widget _cell(int column, Widget? cell) {
    final content = cell ?? const SizedBox.shrink();
    if (column == 0) return content;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: EditorColors.line)),
      ),
      child: content,
    );
  }
}

/// Un element d'une liste d'objets, ou un objet imbrique (spec D6) : un cadre,
/// un en-tete — numero et resume, ou nom —, puis ses rangees.
class ElementCard extends StatelessWidget {
  const ElementCard({
    super.key,
    required this.children,
    this.index,
    this.title,
    this.summary = '',
    this.onRemove,
    this.removeKey,
  });

  final List<Widget> children;

  /// Le rang de l'element, a partir de 1.
  final int? index;

  /// Le nom d'un objet imbrique.
  final String? title;
  final String summary;
  final VoidCallback? onRemove;
  final Key? removeKey;

  static final Color _fill = Color.alphaBlend(
    EditorColors.well.withValues(alpha: 0.6),
    EditorColors.panel,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: EditorColors.lineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
            child: Row(
              children: [
                if (index != null)
                  Text(
                    '#$index',
                    style: editorMono(
                      size: 12,
                      color: EditorColors.soft,
                      weight: FontWeight.w700,
                    ),
                  ),
                if (title != null) Text(title!, style: editorMono()),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary,
                    overflow: TextOverflow.ellipsis,
                    style: editorMono(size: 12, color: EditorColors.faint),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    key: removeKey,
                    tooltip: 'Retirer',
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    color: EditorColors.faint,
                    hoverColor: AppColors.danger.withValues(alpha: 0.1),
                    icon: const Icon(Icons.delete),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: EditorColors.line),
          ...children,
        ],
      ),
    );
  }
}

/// Le geste « Ajouter » d'une liste, en pointilles : ce qui reste a remplir.
class AddElementButton extends StatelessWidget {
  const AddElementButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: EditorColors.lineStrong,
      radius: 9,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(9),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: EditorColors.accent),
                SizedBox(width: 6),
                Text(
                  'Ajouter',
                  style: TextStyle(
                    color: EditorColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le nombre d'elements d'une liste.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: EditorColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: EditorColors.accentInk,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// `FR` ou `EN`, devant un texte affiche au joueur.
class LangBadge extends StatelessWidget {
  const LangBadge(this.language, {super.key});

  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: EditorColors.muted,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        language,
        style: editorMono(
          size: 10.5,
          color: EditorColors.accentInk,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}
