import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/color_field.dart';

/// Le rapport de contraste WCAG entre deux couleurs opaques, de 1:1 a 21:1.
///
/// Tire de la seule luminance du framework, jamais de `readableOn` : un test
/// qui jugerait le texte choisi avec la fonction qui le choisit passerait quoi
/// qu'elle decide.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Le fond du choix qui porte [label] : le `Container` du contrat de choix.
Finder choiceFill(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byKey(const Key('editeur-bouton-fond')),
    );

/// Tout ce que le choix [label] ecrit — libelle, icone, coche — se lit a
/// 4,5:1 au moins sur son fond, qui doit etre opaque (WCAG AA).
void expectReadableChoice(WidgetTester tester, String label) {
  expect(choiceFill(label), findsOneWidget,
      reason: '« $label » n est pas un choix');
  final fill =
      (tester.widget<Container>(choiceFill(label)).decoration! as BoxDecoration)
          .color!;
  expect(fill.a, 1.0, reason: '« $label » doit peindre un fond opaque');
  final inks = tester.widgetList<RichText>(
    find.descendant(of: choiceFill(label), matching: find.byType(RichText)),
  );
  for (final ink in inks) {
    final seen = Color.alphaBlend(ink.text.style!.color!, fill);
    expect(
      contrastRatio(seen, fill),
      greaterThanOrEqualTo(4.5),
      reason: '« $label » illisible sur ${colorToHex(fill)}',
    );
  }
}
