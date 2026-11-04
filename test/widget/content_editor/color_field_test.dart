import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/color_field.dart';

void main() {
  test('la conversion vers le JSON est en majuscules et sur six chiffres', () {
    expect(colorToHex(const Color(0xFFB71C1C)), '#B71C1C');
    expect(colorToHex(const Color(0xFF000000)), '#000000');
    // L'alpha est ignore : le JSON ne porte que RRGGBB, et `HeroData` rend
    // toujours une couleur opaque.
    expect(colorToHex(const Color(0x40B71C1C)), '#B71C1C');
  });

  test('la conversion depuis le JSON refuse ce qui n est pas #RRGGBB', () {
    expect(hexToColor('#B71C1C'), const Color(0xFFB71C1C));
    for (final bad in const ['B71C1C', '#XYZ', '#B71C1', '']) {
      expect(hexToColor(bad), isNull, reason: 'valeur refusée : "$bad"');
    }
  });
}
