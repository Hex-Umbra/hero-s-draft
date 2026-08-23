import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/tutorial/tutorial_screen.dart';

void main() {
  group('parseBoldSegments', () {
    const style = TextStyle(fontSize: 12, color: Color(0xFFCCCCCC));

    test('une chaîne sans marqueur rend un unique segment normal', () {
      final spans = parseBoldSegments('Simple texte sans emphase.', style);

      expect(spans, hasLength(1));
      expect(spans.single.text, 'Simple texte sans emphase.');
      expect(spans.single.style, style);
      expect(spans.single.style?.fontWeight, isNot(FontWeight.bold));
    });

    test(
      'un segment emphasé devient gras ; sauts de ligne et puces préservés',
      () {
        final spans = parseBoldSegments(
          'Règle :\n'
          '• Ceci est **important** à retenir.',
          style,
        );

        expect(spans, hasLength(3));

        expect(spans[0].text, 'Règle :\n• Ceci est ');
        expect(spans[0].style?.fontWeight, isNot(FontWeight.bold));

        expect(spans[1].text, 'important');
        // Seul le fontWeight change sur le segment emphasé : le reste du
        // style de base (taille, couleur...) doit rester identique.
        expect(spans[1].style, style.copyWith(fontWeight: FontWeight.bold));

        expect(spans[2].text, ' à retenir.');
        expect(spans[2].style?.fontWeight, isNot(FontWeight.bold));

        // Rien n'est perdu : la concaténation des segments reconstruit le
        // texte d'origine, délimiteurs `**` mis à part.
        expect(
          spans.map((s) => s.text).join(),
          'Règle :\n• Ceci est important à retenir.',
        );
      },
    );

    test(
      'un nombre impair de délimiteurs affiche le dernier segment '
      'normalement, sans rien perdre',
      () {
        final spans = parseBoldSegments('abc **gras** def **oubli', style);

        expect(spans, hasLength(4));

        expect(spans[0].text, 'abc ');
        expect(spans[0].style?.fontWeight, isNot(FontWeight.bold));

        expect(spans[1].text, 'gras');
        expect(spans[1].style?.fontWeight, FontWeight.bold);

        expect(spans[2].text, ' def ');
        expect(spans[2].style?.fontWeight, isNot(FontWeight.bold));

        // Le délimiteur final n'a jamais été refermé : le segment qui le
        // suit reste normal plutôt que de passer en gras ou de disparaître.
        expect(spans[3].text, 'oubli');
        expect(spans[3].style?.fontWeight, isNot(FontWeight.bold));

        expect(spans.map((s) => s.text).join(), 'abc gras def oubli');
      },
    );
  });
}
