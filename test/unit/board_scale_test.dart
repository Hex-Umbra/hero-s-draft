import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/board_scale.dart';
import 'package:roguelike_card_game/game/systems/enemy_row.dart';

/// Le palier du plateau (spec P-05, vague 2, §5.1, B90, B91) : la hauteur du héros que
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
  test('x2 net en 1920 x 1080 : la cible 2,2 s arrondit, seuil compris, la '
      'creature a la moitie', () {
    // En double, 2,2 - 2 depasse 0,10 x 2 : sans la tolerance de calcul,
    // le 1080p se lisserait a 2,2.
    expect(2.2 * 1080 / 1080 - 2, greaterThan(0.10 * 2));
    final scale = _scaleAt(1920, 1080);

    expect(scale.frame, 2);
    expect(scale.crisp, isTrue);
    expect(scale.creature, 1);
  });

  test('x2 net en 1920 x 1009 : 2,055 s arrondit (B86)', () {
    final scale = _scaleAt(1920, 1009);

    expect(scale.frame, 2);
    expect(scale.crisp, isTrue);
  });

  test('x2 physique net en 1536 x 864 a 1,25 : 1,6 logique', () {
    final scale = _scaleAt(1536, 864, ratio: 1.25);

    expect(scale.frame, closeTo(1.6, 1e-9));
    expect(scale.crisp, isTrue);
  });

  test('x3 net en 2560 x 1440 : 2,933 s arrondit vers le haut', () {
    final scale = _scaleAt(2560, 1440);

    expect(scale.frame, 3);
    expect(scale.crisp, isTrue);
  });

  test('3,312 non net en 2880 x 1626 : a 0,312 de x3, plus de 10 %', () {
    final scale = _scaleAt(2880, 1626);

    expect(scale.frame, closeTo(2.2 * 1626 / 1080, 1e-9));
    expect(scale.crisp, isFalse);
  });

  test('x3 net en 2880 x 1600 : 3,259 s arrondit vers le bas', () {
    final scale = _scaleAt(2880, 1600);

    expect(scale.frame, 3);
    expect(scale.crisp, isTrue);
  });

  test('3,306 physique non net en 1440 x 813 a 2 : le meme ecran dans '
      'Chrome, la carte entre la barre du haut et le heros (B93)', () {
    final scale = _scaleAt(1440, 813, ratio: 2);

    expect(scale.frame, closeTo((_floorOf(813) - 56) / 153, 1e-9));
    expect(scale.frame * 2, closeTo(3.306, 1e-3));
    expect(scale.crisp, isFalse);
  });

  test('3,667 non net en 2880 x 1800 : x4, a 10 % pres, ne tient pas sous la '
      'rangee (3,712), qui ne plafonne pas la cible', () {
    final scale = _scaleAt(2880, 1800);

    expect(scale.frame, closeTo(2.2 * 1800 / 1080, 1e-9));
    expect(scale.frame, lessThan(0.95 * 2880 / referenceRowFrameWidth));
    expect(scale.crisp, isFalse);
    expect(_scaleAt(1440, 900, ratio: 2).frame,
        closeTo(2.2 * 1800 / 1080 / 2, 1e-9));
    expect(_scaleAt(1440, 900, ratio: 2).crisp, isFalse);
  });

  test('x4 net en 3840 x 2160 : la cible 4,4 s arrondit, seuil compris', () {
    final scale = _scaleAt(3840, 2160);

    expect(scale.frame, 4);
    expect(scale.crisp, isTrue);
  });

  test('1,422 non net en 1280 x 720 : la carte entre la barre du haut et le '
      'heros, sous la cible (1,467) et la largeur (1,650) (B93)', () {
    final scale = _scaleAt(1280, 720);

    expect(scale.frame, closeTo((_floorOf(720) - 56) / 153, 1e-9));
    expect(scale.frame, closeTo(1.422, 1e-3));
    expect(scale.frame, lessThan(2.2 * 720 / 1080));
    expect(scale.crisp, isFalse);
  });

  test('1,326 non net en 1264 x 681 (B93)', () {
    final scale = _scaleAt(1264, 681);

    expect(scale.frame, closeTo((_floorOf(681) - 56) / 153, 1e-9));
    expect(scale.crisp, isFalse);
  });

  test('x4 ne tient pas en 2781 x 1800 : non net a la limite de la rangee', () {
    final scale = _scaleAt(2781, 1800);

    expect(scale.frame, closeTo(0.95 * 2781 / referenceRowFrameWidth, 1e-9));
    expect(scale.frame, lessThan(2.2 * 1800 / 1080));
    expect(scale.frame, closeTo(3.585, 1e-3));
    expect(scale.crisp, isFalse);
  });

  test('2,648 non net en 4000 x 1300 : a plus de 10 % de x3, la cible sous son '
      'plafond (2,908)', () {
    final scale = _scaleAt(4000, 1300);

    expect(scale.frame, closeTo(2.2 * 1300 / 1080, 1e-9));
    expect(scale.crisp, isFalse);
  });

  test('la place compte le gabarit et une languette (B91) : 117, la rangee de '
      'six 737', () {
    expect(enemySlotWidth, 117);
    expect(referenceRowFrameWidth, 737);
  });

  test('a 911, deux languettes par place, la rangee ramenait 2880 x 1800 a x3',
      () {
    expect(_scaleAt(2880, 1800, reference: 911).frame, 3);
    expect(_scaleAt(2880, 1800, reference: 911).crisp, isTrue);
    expect(_scaleAt(2880, 1800).frame, closeTo(11 / 3, 1e-9));
  });

  test('en 4K, x4 net tant que la rangee tient sous 912, non net au-dela', () {
    expect(_scaleAt(3840, 2160, reference: 912).frame, 4);
    expect(_scaleAt(3840, 2160, reference: 912).crisp, isTrue);
    expect(_scaleAt(3840, 2160, reference: 913).crisp, isFalse);
    expect(_scaleAt(3840, 2160, reference: 913).frame,
        closeTo(0.95 * 3840 / 913, 1e-9));
  });

  test('un heros trop haut sous la barre du haut fait tomber le palier, ou '
      'que soit la rangee (B93)', () {
    // 56 + 153 x 2 = 362 : un plancher plus haut ne laisse plus x2.
    final scale = _scaleAt(1920, 1080, rowCenterY: 150, rowFloorY: 361);

    expect(scale.frame, closeTo((361 - 56) / 153, 1e-9));
    expect(scale.crisp, isFalse);
  });

  group('enemyRowCenterYFor (B93)', () {
    test('garde la part de l ecran quand la barre passe sous la barre du '
        'haut : 1080p, 1009', () {
      const crisp2 = BoardScale(frame: 2, crisp: true);
      expect(enemyRowCenterYFor(1080, scale: crisp2), 227);
      expect(enemyRowCenterYFor(1009, scale: crisp2), rowCenterYFor(1009));
    });

    test('descend la rangee en 1280 x 720 : le haut des barres a 56, la carte '
        'au-dessus du heros', () {
      final scale = _scaleAt(1280, 720);
      final y = enemyRowCenterYFor(720, scale: scale);

      expect(y, greaterThan(rowCenterYFor(720)));
      expect(y - barTopAboveWindowCenter * scale.frame, greaterThanOrEqualTo(56));
      expect(y - barTopAboveWindowCenter * scale.frame, lessThan(57));
      expect(y + frameBelowWindowCenter * scale.frame,
          lessThanOrEqualTo(_floorOf(720) + 1));
    });

    test('se cale sur le pixel physique, vers le bas', () {
      final scale = _scaleAt(1440, 813, ratio: 2);
      final y = enemyRowCenterYFor(813, scale: scale, devicePixelRatio: 2);

      expect(y * 2, closeTo((y * 2).roundToDouble(), 1e-9));
      expect(y - barTopAboveWindowCenter * scale.frame, greaterThanOrEqualTo(56));
    });
  });

  test('un heros trop haut pour le cadre fait tomber le palier', () {
    final scale = _scaleAt(1920, 1080, rowFloorY: 227 + 151);

    expect(scale.frame, closeTo(151 / frameBelowWindowCenter, 1e-9));
    expect(scale.crisp, isFalse);
  });
}
