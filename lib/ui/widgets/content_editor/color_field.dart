import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
        InkWell(
          key: const Key('editeur-couleur-pastille'),
          onTap: () => _open(context),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(colorToHex(value)),
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
