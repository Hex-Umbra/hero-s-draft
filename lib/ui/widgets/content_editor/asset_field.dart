import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../services/content_editor/entity_descriptor.dart';
import '../../theme/app_colors.dart';
import 'choice_button.dart';
import 'dashed_border.dart';
import 'editor_button.dart';
import 'editor_style.dart';
import 'property_row.dart';

/// Le champ d'une ressource : un son choisi parmi `audio.json`, ou une image
/// au nom impose (spec §5.2, §5.3).
///
/// **Purement presentationnel** : l'ecran lit le disque et fournit les octets
/// de l'image — un widget qui importerait `dart:io` casserait le build web.
class AssetField extends StatelessWidget {
  const AssetField({
    super.key,
    required this.fieldKey,
    required this.slot,
    this.value,
    this.soundIds = const [],
    this.imageBytes,
    this.pendingLabel,
    this.errorText,
    this.onSelectSound,
    this.onClear,
    this.onImport,
  });

  final String fieldKey;
  final AssetSlot slot;

  /// L'identifiant du son choisi, ou le chemin de l'image.
  final String? value;
  final List<String> soundIds;

  /// L'image actuelle, ou celle en attente d'import. `null` si aucune.
  final Uint8List? imageBytes;

  /// « à importer : … », tant que l'import attend « Écrire ».
  final String? pendingLabel;

  /// La faute qui vise cette ressource, affichee sous elle.
  final String? errorText;

  final ValueChanged<String>? onSelectSound;

  /// « aucun » pour un son, « aucune » pour une image optionnelle.
  final VoidCallback? onClear;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final isImage = slot.kind == AssetKind.image;
    return PropertyRow(
      label: fieldKey,
      isRequired: isImage && slot.isRequired,
      note: isImage && !slot.isRequired ? 'optionnel' : null,
      errorText: errorText,
      alignTop: true,
      child: isImage ? _image() : _sounds(),
    );
  }

  Widget _pending() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 15, color: AppColors.warning),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              pendingLabel!,
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  Widget _importButton(IconData icon) => EditorButton(
        key: Key('editeur-importer-$fieldKey'),
        label: 'Importer…',
        icon: icon,
        dense: true,
        onPressed: onImport,
      );

  Widget _sounds() {
    final current = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          key: Key('editeur-champ-$fieldKey'),
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceButton(
              label: 'aucun',
              isPlaceholder: true,
              isSelected: current == null,
              onTap: () => onClear?.call(),
            ),
            // Un son en attente d'import n'est pas encore dans `audio.json` :
            // il reste affiche, et choisi.
            for (final id in {...soundIds, ?current})
              ChoiceButton(
                label: id,
                isSelected: current == id,
                onTap: () => onSelectSound?.call(id),
              ),
          ],
        ),
        if (pendingLabel != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: _pending()),
        if (onImport != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _importButton(Icons.music_note),
          ),
      ],
    );
  }

  Widget _image() {
    final clearable = !slot.isRequired && onClear != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Thumbnail(bytes: imageBytes, portrait: slot.isRequired),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value ?? '(aucune)',
                style: editorMono(
                  size: 12,
                  color: value == null ? EditorColors.faint : EditorColors.soft,
                ),
              ),
              if (pendingLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _pending(),
                ),
              if (onImport != null || clearable)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onImport != null) _importButton(Icons.upload_file),
                      if (clearable)
                        EditorButton(
                          label: 'aucune',
                          icon: Icons.close,
                          tone: EditorButtonTone.quiet,
                          dense: true,
                          onPressed: onClear,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// L'apercu d'une image, sur un damier : une zone transparente s'y voit.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.bytes, required this.portrait});

  final Uint8List? bytes;

  /// Une image obligatoire est une carte ou un sprite, en hauteur ; une icone
  /// est carree.
  final bool portrait;

  @override
  Widget build(BuildContext context) {
    final bytes = this.bytes;
    final frame = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: portrait ? 72 : 56,
        height: portrait ? 96 : 56,
        child: CustomPaint(
          painter: const _CheckerPainter(),
          child: bytes == null
              ? const Center(
                  child: Icon(Icons.image, size: 22, color: EditorColors.faint),
                )
              : Image.memory(
                  bytes,
                  // Un apercu de 72 points : decoder une carte de classe de
                  // 6,5 Mo a pleine taille serait un cout pur.
                  cacheWidth: 144,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) =>
                      const Center(child: Text('?')),
                ),
        ),
      ),
    );
    if (bytes == null) {
      return DashedBorder(
        color: EditorColors.lineStrong,
        radius: 8,
        child: frame,
      );
    }
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EditorColors.lineStrong),
      ),
      child: frame,
    );
  }
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter();

  static const double _cell = 6;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = EditorColors.checkerDark,
    );
    final light = Paint()..color = EditorColors.checkerLight;
    for (var row = 0; row * _cell < size.height; row++) {
      for (var column = row.isEven ? 1 : 0;
          column * _cell < size.width;
          column += 2) {
        canvas.drawRect(
          Rect.fromLTWH(column * _cell, row * _cell, _cell, _cell),
          light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter oldDelegate) => false;
}
