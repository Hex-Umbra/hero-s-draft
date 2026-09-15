import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'editor_style.dart';

/// La cle d'une propriete : son nom JSON, un point si elle est obligatoire,
/// une mention discrete (« optionnel »), rouge quand une faute la vise.
///
/// Contient un `Flexible` : a poser dans une largeur bornee.
class PropertyLabel extends StatelessWidget {
  const PropertyLabel({
    super.key,
    required this.label,
    this.isRequired = false,
    this.note,
    this.hasError = false,
  });

  final String label;
  final bool isRequired;
  final String? note;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRequired) ...[
          Semantics(
            label: 'obligatoire',
            child: Container(
              key: const Key('editeur-obligatoire'),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: EditorColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: editorMono(
              color: hasError ? AppColors.danger : EditorColors.keyText,
            ),
          ),
        ),
        if (note != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              border: Border.all(color: EditorColors.lineStrong),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              note!,
              style: const TextStyle(color: EditorColors.faint, fontSize: 10.5),
            ),
          ),
        ],
      ],
    );
  }
}

/// Le message d'une faute, sous le champ qu'elle vise.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error, size: 15, color: AppColors.danger),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Une rangee de l'inspecteur (spec D5) : la cle a gauche, le controle a
/// droite, et le message d'une faute sous le controle. La cle passe au-dessus
/// quand le controle n'a plus sa place a cote.
class PropertyRow extends StatelessWidget {
  const PropertyRow({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.note,
    this.errorText,
    this.alignTop = false,
    this.labelWidth = 170,
  });

  /// Sous cette largeur, un controle ne se lit plus a cote de sa cle.
  static const double minControlWidth = 240;

  final String label;
  final Widget child;
  final bool isRequired;
  final String? note;
  final String? errorText;

  /// Pour un controle plus haut qu'une ligne : une rangee de puces, une
  /// vignette. La cle s'aligne alors sur sa premiere ligne.
  final bool alignTop;

  /// 170 au premier niveau, 110 dans un element de liste.
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final error = errorText;
    final top = alignTop || error != null;
    final key = PropertyLabel(
      label: label,
      isRequired: isRequired,
      note: note,
      hasError: error != null,
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: FieldError(error),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < labelWidth + 14 + minControlWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [key, const SizedBox(height: 6), body],
            );
          }
          return Row(
            crossAxisAlignment:
                top ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: labelWidth,
                child: Padding(
                  padding: EdgeInsets.only(top: top ? 9 : 0),
                  child: key,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }
}
