import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../services/content_editor/entity_descriptor.dart';
import '../../theme/app_colors.dart';
import 'choice_button.dart';

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

  final ValueChanged<String>? onSelectSound;

  /// « aucun » pour un son, « aucune » pour une image optionnelle.
  final VoidCallback? onClear;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fieldKey, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (slot.kind == AssetKind.sound) _sounds() else _image(),
          if (pendingLabel != null)
            Text(pendingLabel!, style: const TextStyle(color: AppColors.warning)),
          if (onImport != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton(
                key: Key('editeur-importer-$fieldKey'),
                onPressed: onImport,
                child: const Text('Importer…'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sounds() {
    final current = value;
    return Wrap(
      key: Key('editeur-champ-$fieldKey'),
      spacing: 4,
      runSpacing: 4,
      children: [
        ChoiceButton(
          label: 'aucun',
          isSelected: current == null,
          onTap: () => onClear?.call(),
        ),
        // Un son en attente d'import n'est pas encore dans `audio.json` : il
        // reste affiche, et choisi.
        for (final id in {...soundIds, ?current})
          ChoiceButton(
            label: id,
            isSelected: current == id,
            onTap: () => onSelectSound?.call(id),
          ),
      ],
    );
  }

  Widget _image() {
    final bytes = imageBytes;
    return Row(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: bytes == null
              ? const Center(child: Text('—'))
              : Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) =>
                      const Center(child: Text('?')),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value ?? '(aucune)',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        if (!slot.isRequired && onClear != null)
          TextButton(onPressed: onClear, child: const Text('aucune')),
      ],
    );
  }
}
