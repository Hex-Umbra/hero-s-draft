import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/entity_hover.dart';

/// L'arbitre du survol : une seule carte à la fois (spec P-05, §4.5).
void main() {
  final first = Rect.fromLTWH(0, 0, 100, 140);
  final second = Rect.fromLTWH(200, 0, 100, 140);

  test('le pointeur dans une carte la designe', () {
    final picked = pickHoveredEntity(
      zones: [
        [first],
        [second],
      ],
      current: null,
      pointer: const Offset(250, 70),
    );

    expect(picked, 1);
  });

  test('dans les languettes deroulees de la courante, hors de sa carte : la '
      'courante', () {
    final unfolded = Rect.fromLTWH(100, 20, 60, 60);

    final picked = pickHoveredEntity(
      zones: [
        [first, unfolded],
        [second],
      ],
      current: 0,
      pointer: const Offset(130, 40),
    );

    expect(picked, 0);
  });

  test('ailleurs : aucune', () {
    final picked = pickHoveredEntity(
      zones: [
        [first],
        [second],
      ],
      current: 0,
      pointer: const Offset(150, 300),
    );

    expect(picked, isNull);
  });

  test('deux zones qui se recouvrent : la courante l emporte', () {
    final overlapping = Rect.fromLTWH(50, 0, 100, 140);
    const pointer = Offset(75, 70);
    final zones = [
      [first],
      [overlapping],
    ];

    expect(pickHoveredEntity(zones: zones, current: 1, pointer: pointer), 1);
    expect(pickHoveredEntity(zones: zones, current: null, pointer: pointer), 0);
  });

  test('une languette au repos designe sa carte', () {
    final tab = Rect.fromLTWH(-20, 20, 20, 30);

    final picked = pickHoveredEntity(
      zones: [
        [first, tab],
      ],
      current: null,
      pointer: const Offset(-10, 30),
    );

    expect(picked, 0);
  });

  test('la bande entre la barre et la carte appartient a l ennemi', () {
    final body = enemyBodyRect(100, 140);

    expect(body.contains(const Offset(50, -2)), isTrue);
    expect(body.contains(const Offset(50, 139)), isTrue);
    expect(body.contains(const Offset(50, -18)), isFalse);
  });
}
