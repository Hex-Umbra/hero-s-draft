import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/window_background.dart';

/// Le tirage du fond de fenêtre (spec P-05, vague 2, B87).
void main() {
  test('un indice dans [0, count)', () {
    final random = Random(1);

    for (var i = 0; i < 100; i++) {
      final index = pickWindowBackground(count: 3, random: random);

      expect(index, inInclusiveRange(0, 2));
    }
  });

  test('un alea a graine rejoue le meme', () {
    final first = Random(7);
    final second = Random(7);

    for (var i = 0; i < 20; i++) {
      expect(
        pickWindowBackground(count: 3, random: first),
        pickWindowBackground(count: 3, random: second),
      );
    }
  });

  test('sur 300 tirages, chacun des trois sort', () {
    final random = Random(3);
    final seen = {
      for (var i = 0; i < 300; i++)
        pickWindowBackground(count: 3, random: random),
    };

    expect(seen, {0, 1, 2});
  });
}
