import 'package:flutter/material.dart';
// `colorToHex` du paquet entre en collision avec celui de `color_field.dart`
// (voir plus bas) : seul `ColorPicker`, le type pilote par ce test, est
// necessaire ici.
import 'package:flutter_colorpicker/flutter_colorpicker.dart' hide colorToHex;
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/color_field.dart';

import 'contrast.dart';

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

  test('le texte choisi se lit sur tout fond, a 4,5:1 au moins', () {
    // 4,5:1 est le seuil WCAG AA du texte courant. Une couleur de classe se
    // tire a la roue : aucune palette ne peut etre supposee, d'ou le balayage.
    // C'est lui qui refuse `ThemeData.estimateBrightnessForColor`, dont le
    // seuil penche vers le blanc et le laisse a 3,1:1 sur un bleu comme
    // #0096FF.
    for (var r = 0; r <= 255; r += 15) {
      for (var g = 0; g <= 255; g += 15) {
        for (var b = 0; b <= 255; b += 15) {
          final background = Color.fromARGB(255, r, g, b);
          expect(
            contrastRatio(readableOn(background), background),
            greaterThanOrEqualTo(4.5),
            reason: 'texte illisible sur ${colorToHex(background)}',
          );
        }
      }
    }
  });

  testWidgets('le champ montre la couleur courante et signale le changement',
      (tester) async {
    Color? seen;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ColorField(
          value: const Color(0xFFB71C1C),
          onChanged: (c) => seen = c,
        ),
      ),
    ));

    expect(find.byKey(const Key('editeur-couleur-pastille')), findsOneWidget);

    await tester.tap(find.byKey(const Key('editeur-couleur-pastille')));
    await tester.pumpAndSettle();
    // La roue est ouverte : le bouton de confirmation en est la preuve.
    expect(find.text('Valider la couleur'), findsOneWidget);

    // La roue rapporte une couleur : on la lui fait rapporter sans dependre
    // d'une coordonnee, qui rendrait le test tributaire de la geometrie du
    // widget et pourrait retomber sur la couleur de depart.
    final picker = tester.widget<ColorPicker>(find.byType(ColorPicker));
    picker.onColorChanged(const Color(0xFF00FF00));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Valider la couleur'));
    await tester.pumpAndSettle();

    // L'assertion qui compte : c'est la couleur **choisie** qui remonte, pas
    // celle de depart. Sans elle, un `onChanged(value)` a la place de
    // `onChanged(picked)` passerait ce test.
    expect(seen, const Color(0xFF00FF00));
  });
}
