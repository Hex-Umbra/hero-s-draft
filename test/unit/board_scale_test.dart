import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/board_scale.dart';
import 'package:roguelike_card_game/game/systems/enemy_row.dart';

/// Le palier du plateau (spec P-05, vague 2, §5.1, B90) : la hauteur du héros que
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
  test('x2 net en 1920 x 1080, la creature a la moitie', () {
    final scale = _scaleAt(1920, 1080);

    expect(scale.frame, 2);
    expect(scale.crisp, isTrue);
    expect(scale.creature, 1);
  });

  test('x2 net en 1920 x 1009 : 1,87 s arrondit (B86)', () {
    final scale = _scaleAt(1920, 1009);

    expect(scale.frame, 2);
    expect(scale.crisp, isTrue);
  });

  test('x2 physique net en 1536 x 864 a 1,25 : 1,6 logique', () {
    final scale = _scaleAt(1536, 864, ratio: 1.25);

    expect(scale.frame, closeTo(1.6, 1e-9));
    expect(scale.crisp, isTrue);
  });

  test('2,667 non net en 2560 x 1440 : 0,33 d un entier, plus de 10 %', () {
    final scale = _scaleAt(2560, 1440);

    expect(scale.frame, closeTo(8 / 3, 1e-9));
    expect(scale.crisp, isFalse);
  });

  test('x3 net en 2880 x 1626 : 3,011 s arrondit', () {
    final scale = _scaleAt(2880, 1626);

    expect(scale.frame, 3);
    expect(scale.crisp, isTrue);
  });

  test('x3 net en 2880 x 1600 : 2,963 s arrondit vers le haut', () {
    final scale = _scaleAt(2880, 1600);

    expect(scale.frame, 3);
    expect(scale.crisp, isTrue);
  });

  test('x3 physique net en 1440 x 813 a 2 : frame 1,5 logique', () {
    final scale = _scaleAt(1440, 813, ratio: 2);

    expect(scale.frame, closeTo(1.5, 1e-9));
    expect(scale.crisp, isTrue);
  });

  test('x3 net en 2880 x 1800 : la cible 3,333 est plafonnee a 3,003 par la '
      'rangee, qui tient x3', () {
    final scale = _scaleAt(2880, 1800);

    expect(scale.frame, 3);
    expect(scale.crisp, isTrue);
    expect(_scaleAt(1440, 900, ratio: 2).frame, closeTo(1.5, 1e-9));
    expect(_scaleAt(1440, 900, ratio: 2).crisp, isTrue);
  });

  test('x4 net en 3840 x 2160', () {
    final scale = _scaleAt(3840, 2160);

    expect(scale.frame, 4);
    expect(scale.crisp, isTrue);
  });

  test('1,333 non net en 1280 x 720 : la hauteur decide, sous la largeur '
      '(1,335)', () {
    final scale = _scaleAt(1280, 720);

    expect(scale.frame, closeTo(2 * 720 / 1080, 1e-9));
    expect(scale.frame, lessThan(0.95 * 1280 / referenceRowFrameWidth));
    expect(scale.crisp, isFalse);
  });

  test('1,261 non net en 1264 x 681', () {
    final scale = _scaleAt(1264, 681);

    expect(scale.frame, closeTo(2 * 681 / 1080, 1e-9));
    expect(scale.crisp, isFalse);
  });

  test('x3 ne tient pas en 2781 x 1800 : non net a la limite de la rangee', () {
    final scale = _scaleAt(2781, 1800);

    expect(scale.frame, closeTo(0.95 * 2781 / referenceRowFrameWidth, 1e-9));
    expect(scale.frame, lessThan(3));
    expect(scale.crisp, isFalse);
  });

  test('2,407 non net en 4000 x 1300 : a plus de 10 % de x2, sans plafond', () {
    final scale = _scaleAt(4000, 1300);

    expect(scale.frame, closeTo(2 * 1300 / 1080, 1e-9));
    expect(scale.crisp, isFalse);
  });

  test('la rangee de six tient a x2 en 1920, plus si une place ou un ecart '
      'grandit d un pixel', () {
    expect(referenceRowFrameWidth, 911);
    expect(_scaleAt(1920, 1080).crisp, isTrue);
    expect(_scaleAt(1920, 1080, reference: 917).crisp, isFalse);
    expect(_scaleAt(1920, 1080, reference: 916).crisp, isFalse);
  });

  test('en 4K, x4 net a 911, non net des qu une place ou un ecart grandit', () {
    expect(_scaleAt(3840, 2160).frame, 4);
    expect(_scaleAt(3840, 2160, reference: 917).crisp, isFalse);
    expect(_scaleAt(3840, 2160, reference: 917).frame,
        closeTo(0.95 * 3840 / 917, 1e-9));
    expect(_scaleAt(3840, 2160, reference: 916).crisp, isFalse);
  });

  test('un ecran trop bas pour la barre fait tomber le palier', () {
    final scale = _scaleAt(1920, 1080, rowCenterY: 150);

    expect(scale.frame, lessThan(2));
    expect(scale.crisp, isFalse);
  });

  test('un heros trop haut pour le cadre fait tomber le palier', () {
    final scale = _scaleAt(1920, 1080, rowFloorY: 227 + 151);

    expect(scale.frame, closeTo(151 / frameBelowWindowCenter, 1e-9));
    expect(scale.crisp, isFalse);
  });
}
