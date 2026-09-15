import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../theme/app_colors.dart';
import 'editor_style.dart';

/// `Color` -> `#RRGGBB`. L'alpha est ignore : le JSON n'en porte pas, et une
/// couleur de classe est toujours opaque.
String colorToHex(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// `#RRGGBB` -> `Color` opaque. `null` pour tout le reste — c'est au champ de
/// choisir son repli, pas a la conversion de deviner.
Color? hexToColor(String hex) {
  final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex);
  if (match == null) return null;
  return Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
}

/// Le texte le plus lisible sur [background] : noir ou blanc, celui des deux
/// qui contraste le plus.
///
/// Les deux contrastes s'egalent quand `(L + 0,05)² = 1,05 × 0,05`, `L` etant
/// la luminance du fond : c'est le seuil WCAG, et a ce point exact, le pire,
/// le texte est encore a 4,58:1. Une couleur de classe tiree a la roue reste
/// donc lisible, quelle qu'elle soit.
///
/// Pas `ThemeData.estimateBrightnessForColor` : son seuil, 0,15, penche
/// deliberement vers le blanc, et y laisse le bleu du paladin a 3,1:1.
Color readableOn(Color background) {
  final shifted = background.computeLuminance() + 0.05;
  return shifted * shifted > 1.05 * 0.05 ? Colors.black : Colors.white;
}

/// Une pastille de la couleur courante, qui ouvre la roue complete.
///
/// Une palette fermee aurait suffi a l'usage, mais le spectre entier est un
/// choix explicite : voir D11 de la spec.
class ColorField extends StatelessWidget {
  const ColorField({super.key, required this.value, required this.onChanged});

  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Ouvrir la roue des couleurs',
          child: InkWell(
            key: const Key('editeur-couleur-pastille'),
            onTap: () => _open(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: value,
                borderRadius: BorderRadius.circular(8),
                // Le lisere doit se voir sur le fond de l'ecran, meme autour
                // d'une couleur sombre.
                border: Border.all(
                  color: EditorColors.soft.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: value.withValues(alpha: 0.45),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: EditorColors.well,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: EditorColors.lineStrong),
          ),
          child: Text(
            colorToHex(value),
            style: editorMono(size: 13, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Text(
            'Clic sur la pastille : roue complète',
            style: TextStyle(color: EditorColors.faint, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    var picked = value;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: value,
            onColorChanged: (color) => picked = color,
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onChanged(picked);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Valider la couleur'),
          ),
        ],
      ),
    );
  }
}
