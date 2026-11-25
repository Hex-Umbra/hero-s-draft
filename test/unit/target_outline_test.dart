import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/entities/target_outline.dart';

void main() {
  const window = Rect.fromLTWH(20, 20, 64, 96);

  test('au repos, rien', () {
    final outline = TargetOutline(window: window);
    expect(outline.strokeRect, isNull);
    outline.setStroke(Colors.amber, 4);
    outline.setStroke(null, 0);
    expect(outline.strokeRect, isNull);
  });

  test('le trait se pose a l exterieur de la fenetre', () {
    final outline = TargetOutline(window: window)
      ..setStroke(Colors.amber, 4);
    expect(outline.strokeRect, window.inflate(2));
    // Le bord intérieur du trait tombe sur le bord de la fenêtre.
    expect(outline.strokeRect!.deflate(2), window);

    outline.setStroke(Colors.cyanAccent, 3);
    expect(outline.strokeRect, window.inflate(1.5));
    expect(outline.color, Colors.cyanAccent);
  });
}
