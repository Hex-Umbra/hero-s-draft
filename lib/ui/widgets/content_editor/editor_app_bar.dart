import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'editor_style.dart';

/// Les deux derniers dossiers d'un chemin : assez pour reconnaitre le depot.
String shortRoot(String root) {
  final parts = root.split('/').where((part) => part.isNotEmpty).toList();
  return parts.length <= 2
      ? root
      : '…/${parts.sublist(parts.length - 2).join('/')}';
}

/// La barre de titre de l'editeur : retour, titre, badge DEBUG, et le depot
/// ou il ecrit.
class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EditorAppBar({super.key, required this.rootPath});

  /// `null` hors arborescence source : l'ecran refuse alors de s'ouvrir.
  final String? rootPath;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    final root = rootPath;
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: EditorColors.bar,
        border: Border(bottom: BorderSide(color: EditorColors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'ÉDITEUR DE CONTENU',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: EditorColors.titleShadow,
                  offset: Offset(1, 1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: EditorColors.debug,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'DEBUG',
              style: TextStyle(
                color: EditorColors.debugInk,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          if (root != null)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.folder_open,
                    size: 16,
                    color: EditorColors.faint,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      shortRoot(root),
                      overflow: TextOverflow.ellipsis,
                      style: editorMono(size: 12, color: EditorColors.faint),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
