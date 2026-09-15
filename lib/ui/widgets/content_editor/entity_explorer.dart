import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'choice_surface.dart';
import 'editor_style.dart';

/// L'explorateur du mode Modifier (spec D2) : les entites existantes,
/// groupees par proprietaire — les neutres d'abord, puis chaque classe par
/// ordre alphabetique —, et un filtre.
///
/// Une `Column` dans un `SingleChildScrollView`, pas un `ListView` : un
/// `ListView` ne construit pas ses enfants hors ecran.
class EntityExplorer extends StatefulWidget {
  const EntityExplorer({
    super.key,
    required this.idsByOwner,
    required this.selectedOwner,
    required this.selectedId,
    required this.onSelected,
    required this.colorOf,
  });

  /// Tel que le rend `entityIdsByOwner` : la cle `null` porte les neutres.
  final Map<String?, List<String>> idsByOwner;
  final String? selectedOwner;
  final String? selectedId;
  final void Function(String? owner, String id) onSelected;

  /// La couleur d'un proprietaire, `null` pour les neutres.
  final Color Function(String? owner) colorOf;

  @override
  State<EntityExplorer> createState() => _EntityExplorerState();
}

class _EntityExplorerState extends State<EntityExplorer> {
  final TextEditingController _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _filter.text.trim().toLowerCase();
    final owners = [
      null,
      ...widget.idsByOwner.keys.whereType<String>().toList()..sort(),
    ];
    final total = widget.idsByOwner.values
        .fold<int>(0, (sum, ids) => sum + ids.length);

    final groups = <Widget>[];
    for (final owner in owners) {
      final ids = [
        for (final id in widget.idsByOwner[owner] ?? const <String>[])
          if (id.toLowerCase().contains(query)) id,
      ];
      if (ids.isNotEmpty) groups.add(_group(owner, ids));
    }

    return Container(
      decoration: const BoxDecoration(
        color: EditorColors.side,
        border: Border(right: BorderSide(color: EditorColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_tree,
                      size: 16,
                      color: EditorColors.muted,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'ENTITÉS',
                        style: TextStyle(
                          color: EditorColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: EditorColors.faint,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('editeur-filtre'),
                  controller: _filter,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: editorInputDecoration(hintText: 'Filtrer…')
                      .copyWith(
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 17,
                      color: EditorColors.faint,
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 32, minHeight: 0),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: EditorColors.line),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 6, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: groups.isNotEmpty
                    ? groups
                    : const [
                        Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'Aucune entité ne correspond.',
                            style: TextStyle(
                              color: EditorColors.faint,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(String? owner, List<String> ids) {
    return KeyedSubtree(
      key: Key('editeur-groupe-${owner ?? 'neutre'}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 5),
              child: Row(
                children: [
                  Container(
                    key: const Key('editeur-groupe-pastille'),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.colorOf(owner),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: EditorColors.groupDotShadow,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      owner ?? 'Neutres',
                      style: const TextStyle(
                        color: EditorColors.soft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${ids.length}',
                    style: const TextStyle(
                      color: EditorColors.faint,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            for (final id in ids)
              _ExplorerItem(
                id: id,
                isSelected:
                    id == widget.selectedId && owner == widget.selectedOwner,
                onTap: () => widget.onSelected(owner, id),
              ),
          ],
        ),
      ),
    );
  }
}

/// Une entite de l'explorateur, selon le contrat de choix (spec D9).
class _ExplorerItem extends StatelessWidget {
  const _ExplorerItem({
    required this.id,
    required this.isSelected,
    required this.onTap,
  });

  final String id;
  final bool isSelected;
  final VoidCallback onTap;

  static final Color _selectedFill = Color.alphaBlend(
    EditorColors.accent.withValues(alpha: 0.12),
    EditorColors.side,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ChoiceSurface(
        isSelected: isSelected,
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        decoration: BoxDecoration(
          color: isSelected ? _selectedFill : EditorColors.side,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.fromLTRB(30, 5, 10, 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                id,
                overflow: TextOverflow.ellipsis,
                style: editorMono(
                  color: isSelected
                      ? AppColors.textPrimary
                      : EditorColors.explorerItemInk,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 16, color: EditorColors.accent),
          ],
        ),
      ),
    );
  }
}
