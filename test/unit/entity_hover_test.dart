import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/entity_hover.dart';
import 'package:roguelike_card_game/game/systems/status_readout.dart';

import 'tier_frame_fixture.dart';

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
    final zone = enemyZoneRect(testFrameOf(1));

    expect(zone.contains(const Offset(50, -2)), isTrue);
    expect(zone.contains(const Offset(50, 119)), isTrue);
    expect(zone.contains(const Offset(50, -18)), isFalse);
  });

  group('unfoldsInward', () {
    test('la languette droite de l ennemi du bord droit se deroule vers l '
        'interieur', () {
      expect(
        unfoldsInward(
          side: StatusSide.right,
          attachEdge: 1184,
          unfoldedWidth: 172,
          screenWidth: 1280,
        ),
        isTrue,
      );
    });

    test('la languette gauche de l ennemi du bord gauche aussi', () {
      expect(
        unfoldsInward(
          side: StatusSide.left,
          attachEdge: 96,
          unfoldedWidth: 172,
          screenWidth: 1280,
        ),
        isTrue,
      );
    });

    test('le heros au centre ne se retourne jamais', () {
      expect(
        unfoldsInward(
          side: StatusSide.left,
          attachEdge: 562,
          unfoldedWidth: 156,
          screenWidth: 1280,
        ),
        isFalse,
      );
      expect(
        unfoldsInward(
          side: StatusSide.right,
          attachEdge: 718,
          unfoldedWidth: 156,
          screenWidth: 1280,
        ),
        isFalse,
      );
    });
  });

  group('la zone d un ennemi', () {
    test('sur les cinq tiers : du haut de la barre au bas du canevas', () {
      const tops = [-17.0, -13.0, -9.0, -5.0, -1.0];

      for (final frame in testTierFrames) {
        final zone = enemyZoneRect(frame);

        expect(zone.top, tops[frame.tier - 1], reason: 'tier ${frame.tier}');
        expect(zone.left, 0);
        expect(zone.right, frame.width);
        expect(zone.bottom, frame.height);
      }
    });

    test('les coins au-dessus du canevas, de part et d autre de la barre, '
        'sont dans la zone', () {
      expect(enemyZoneRect(testFrameOf(2)).contains(const Offset(2, -10)),
          isTrue);
      expect(enemyZoneRect(testFrameOf(2)).contains(const Offset(94, -10)),
          isTrue);
      expect(enemyZoneRect(testFrameOf(3)).contains(const Offset(4, -5)),
          isTrue);
      expect(enemyZoneRect(testFrameOf(3)).contains(const Offset(100, -5)),
          isTrue);
      expect(enemyZoneRect(testFrameOf(4)).contains(const Offset(6, -3)),
          isTrue);
      expect(enemyZoneRect(testFrameOf(5)).contains(const Offset(8, -0.5)),
          isTrue);
    });

    test('le gabarit est le meme autour de la fenetre sur les cinq cadres',
        () {
      for (final frame in testTierFrames) {
        final window = enemyWindowRect(frame);
        final template = enemyTemplateRect(frame);

        expect(window.size, const Size(64, 96));
        expect(template.size, const Size(88, 120));
        expect(template.left, window.left - 12);
        expect(template.top, window.top - 12);
      }
    });
  });
}
