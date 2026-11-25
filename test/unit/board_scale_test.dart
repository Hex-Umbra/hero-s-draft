import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/board_scale.dart';
import 'package:roguelike_card_game/game/systems/enemy_row.dart';

/// Le palier du plateau (spec P-05, vague 2, §5.1) : la hauteur du héros que
/// `HerosDraftGame` passe, `s.y × 0,51 − 80 × clamp(s.y / 800, 0,85 ; 2,5) × 1,3`.
double _floorOf(double height) =>
    height * 0.51 - 80 * (height / 800).clamp(0.85, 2.5) * 1.3;

BoardScale _scaleAt(
  double width,
  double height, {
  double ratio = 1,
  double? rowCenterY,
  double? rowFloorY,
  double reference = referenceRowFrameWidth,
}) =>
    boardScaleFor(
      screen: Size(width, height),
      devicePixelRatio: ratio,
      rowCenterY: rowCenterY ??
          rowCenterYFor(height, devicePixelRatio: ratio),
      rowFloorY: rowFloorY ?? _floorOf(height),
      referenceRowWidth: reference,
    );

void main() {
  test('x2 en 1920 x 1080, net, la creature a la moitie', () {
    final scale = _scaleAt(1920, 1080);

    expect(scale.frame, 2);
    expect(scale.crisp, isTrue);
    expect(scale.creature, 1);
  });

  test('x2 en 1920 x 1009', () {
    final scale = _scaleAt(1920, 1009);

    expect(scale.frame, 2);
    expect(scale.crisp, isTrue);
  });

  test('1,6 logique en 1536 x 864 a 1,25', () {
    final scale = _scaleAt(1536, 864, ratio: 1.25);

    expect(scale.frame, closeTo(1.6, 1e-9));
    expect(scale.crisp, isTrue);
  });

  test('la rangee de six tient a x2 en 1920, plus si une place ou un ecart '
      'grandit d un pixel', () {
    expect(referenceRowFrameWidth, 911);
    expect(_scaleAt(1920, 1080).crisp, isTrue);
    expect(_scaleAt(1920, 1080, reference: 917).crisp, isFalse);
    expect(_scaleAt(1920, 1080, reference: 916).crisp, isFalse);
  });

  test('un ecran trop bas pour la barre fait tomber le palier', () {
    final scale = _scaleAt(1920, 1080, rowCenterY: 150);

    expect(scale.frame, lessThan(2));
    expect(scale.crisp, isFalse);
  });

  test('un heros trop haut pour le cadre fait tomber le palier', () {
    final scale = _scaleAt(1920, 1080, rowFloorY: 227 + 151);

    expect(scale.crisp, isFalse);
  });

  test('x2 en 2560 x 1440 (B83)', () {
    final scale = _scaleAt(2560, 1440);

    expect(scale.frame, 2);
    expect(scale.crisp, isTrue);
  });

  test('x4 en 3840 x 2160 a 4 pixels pres, x2 si une place ou un ecart '
      'grandit', () {
    expect(_scaleAt(3840, 2160).frame, 4);
    expect(_scaleAt(3840, 2160, reference: 917).frame, 2);
    expect(_scaleAt(3840, 2160, reference: 916).frame, 2);
  });

  test('1,335 lisse en 1280 x 720 (B85)', () {
    final scale = _scaleAt(1280, 720);

    expect(scale.frame, closeTo(1.3348, 1e-4));
    expect(scale.crisp, isFalse);
  });

  test('1,318 lisse en 1264 x 681', () {
    final scale = _scaleAt(1264, 681);

    expect(scale.frame, closeTo(1.3181, 1e-4));
    expect(scale.crisp, isFalse);
  });
}
