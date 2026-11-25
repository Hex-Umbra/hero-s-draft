import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/creature_fit.dart';

/// Le recadrage d'une créature (spec P-05, vague 2, §5.4, B75).
void main() {
  test('un sprite neuf de 128 x 192 se dessine entier et net', () {
    final fit = creatureFitOf(128, 192);

    expect(fit.source, const Rect.fromLTWH(0, 0, 128, 192));
    expect(fit.smooth, isFalse);
  });

  test('une peinture de 1696 ou 1694 x 2528 se recadre sur B75 et se lisse',
      () {
    for (final width in [1696, 1694]) {
      final fit = creatureFitOf(width, 2528);

      expect(fit.source, oldSpriteRect);
      expect(fit.source.width * 3, fit.source.height * 2);
      final image = Rect.fromLTWH(0, 0, width.toDouble(), 2528);
      expect(image.intersect(fit.source), fit.source);
      expect(fit.smooth, isTrue);
    }
  });

  test('l image de remplacement de 64 x 64 se dessine entiere', () {
    final fit = creatureFitOf(64, 64);

    expect(fit.source, const Rect.fromLTWH(0, 0, 64, 64));
    expect(fit.smooth, isFalse);
  });
}
