import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/enemy_row.dart';

import 'tier_frame_fixture.dart';

/// La rangée des ennemis (spec P-05, vague 2, §5.6, B91) : 1080p à x2, soit un
/// écran de 1920 pixels logiques et un pixel de cadre de 2. Une place vaut le
/// gabarit et une languette, 117 pixels de cadre, 234 à x2.
void main() {
  const ordinary = RowSlot(width: 117, gap: 7);
  const tight = RowSlot(width: 117, gap: 2);

  List<double> row(List<RowSlot> slots,
          {double unit = 2, double width = 1920, double ratio = 1}) =>
      placeRow(
        slots: slots,
        unit: unit,
        screenWidth: width,
        devicePixelRatio: ratio,
      );

  List<double> gaps(List<double> centers) => [
        for (var i = 1; i < centers.length; i++) centers[i] - centers[i - 1],
      ];

  test('slotOf rend 117 du tier 1 au tier 4, le cadre de 120 au tier 5, a l '
      'ecart minimal 7', () {
    for (final frame in testTierFrames) {
      final slot = slotOf(frame);

      expect(slot.width, frame.tier == 5 ? 120 : 117,
          reason: 'tier ${frame.tier}');
      expect(slot.gap, 7);
    }
  });

  test('six places en 1080p a x2 : 248 et 1474', () {
    final centers = row(List.filled(6, ordinary));

    expect(gaps(centers), everyElement(248));
    expect(centers.last - centers.first + 234, 1474);
  });

  test('deux voisines a l ecart minimal : leurs languettes au repos se '
      'superposent', () {
    final centers = row(List.filled(6, ordinary));
    // Du centre de la fenêtre au bout de la languette au repos : la moitié du
    // gabarit et la languette, 44 + 29, à x2.
    final rightTabEnd = centers[0] + 73 * 2;
    final leftTabStart = centers[1] - 73 * 2;

    expect(rightTabEnd - leftTabStart, 44);
  });

  test('cinq places en 1080p a x2 : 272 et 1322', () {
    final centers = row(List.filled(5, ordinary));

    expect(gaps(centers), everyElement(272));
    expect(centers.last - centers.first + 234, 1322);
  });

  test('quatre places en 1080p a x2 : 326 et 1212', () {
    final centers = row(List.filled(4, ordinary));

    expect(centers, [471, 797, 1123, 1449]);
    expect(centers.last - centers.first + 234, 1212);
  });

  test('le pas se calle sur le pixel physique le plus proche, pas en dessous',
      () {
    // 0,85 x 1910 / 5 / 2 x 2 = 324,7 : le pas vaut 325, pas 324.
    final centers = row(List.filled(4, ordinary), width: 1910);

    expect(gaps(centers), everyElement(325));
  });

  test('deux places en 1080p a x2 : 478 et 712', () {
    final centers = row(List.filled(2, ordinary));

    expect(gaps(centers), [478]);
    expect(centers.last - centers.first + 234, 712);
  });

  test('une place seule au centre', () {
    expect(row([ordinary]), [960]);
  });

  test('la rangee est centree', () {
    final centers = row(const [
      RowSlot(width: 117, gap: 7),
      RowSlot(width: 200, gap: 7),
    ]);

    final left = centers.first - 58.5 * 2;
    final right = 1920 - (centers.last + 100 * 2);
    expect((left - right).abs(), lessThanOrEqualTo(1));
  });

  test('deux places voisines ne sont jamais plus proches que leur distance '
      'minimale', () {
    const unit = 1.3348;
    final centers = row(
      List.filled(6, ordinary),
      unit: unit,
      width: 1264,
      ratio: 1.25,
    );

    for (final gap in gaps(centers)) {
      expect(gap, greaterThanOrEqualTo(124 * unit - 1e-9));
    }
  });

  test('deux places a ecart serre sont plus proches que deux ordinaires', () {
    final close = row(List.filled(2, tight), width: 600);
    final usual = row(List.filled(2, ordinary), width: 600);

    expect(gaps(close), [238]);
    expect(gaps(usual), [248]);
  });

  test('une place serree a cote d une ordinaire garde l ecart ordinaire', () {
    final centers = row(const [tight, ordinary], width: 600);

    expect(gaps(centers), [248]);
  });

  test('une meute de trois places serrees entre deux ordinaires', () {
    final centers = row(const [ordinary, tight, tight, tight, ordinary]);

    expect(gaps(centers), [277, 267, 267, 277]);
    final left = centers.first - 58.5 * 2;
    final right = 1920 - (centers.last + 58.5 * 2);
    expect((left - right).abs(), lessThanOrEqualTo(1));
  });

  test('les centres et l ordonnee sont cales sur le pixel physique', () {
    final centers = row(
      List.filled(6, ordinary),
      unit: 1.6,
      width: 1536,
      ratio: 1.25,
    );

    for (final x in centers) {
      expect(x * 1.25, closeTo((x * 1.25).roundToDouble(), 1e-9));
    }
    expect(rowCenterYFor(1080), 227);
    expect(rowCenterYFor(864, devicePixelRatio: 1.25) * 1.25, closeTo(227, 1e-9));
  });

  group('inspectionShift (B89)', () {
    test('nul quand la carte tient, aux deux bords exacts compris', () {
      expect(inspectionShift(left: 100, right: 400, screenWidth: 1920), 0);
      expect(inspectionShift(left: 0, right: 400, screenWidth: 1920), 0);
      expect(inspectionShift(left: 1500, right: 1920, screenWidth: 1920), 0);
    });

    // La carte ouverte, au double : sa zone au repos, le gabarit et ses deux
    // languettes, 73 de chaque côté du centre, × 2 × l'échelle.
    test('cinq places en 1080p : la carte ouverte du bord tient, bord droit a '
        '1796', () {
      final xs = placeRow(
        slots: List.filled(5, slotOf(testFrameOf(1))),
        unit: 2,
        screenWidth: 1920,
      );
      final right = xs.last + 73 * 4;
      expect(right, 1796);
      expect(inspectionShift(left: right - 584, right: right, screenWidth: 1920), 0);
    });

    test('six places en 1080p : la carte ouverte du bord droit tient, bord '
        'droit a 1872 (B91)', () {
      final xs = placeRow(
        slots: List.filled(6, slotOf(testFrameOf(1))),
        unit: 2,
        screenWidth: 1920,
      );
      final right = xs.last + 73 * 4;
      expect(right, 1872);
      expect(inspectionShift(left: right - 584, right: right, screenWidth: 1920), 0);
    });

    test('la carte du bord droit d une rangee de six en 1280 x 720 se decale '
        'de 30 vers la gauche', () {
      const unit = 2.2 * 720 / 1080;
      final xs = placeRow(
        slots: List.filled(6, slotOf(testFrameOf(1))),
        unit: unit,
        screenWidth: 1280,
      );
      final right = xs.last + 73 * 2 * unit;
      expect(xs.last, 1095);
      expect(right, closeTo(1309.13, 1e-2));
      final shift = inspectionShift(
        left: right - 146 * 2 * unit,
        right: right,
        screenWidth: 1280,
      );
      expect(shift, -30);
      expect(right + shift, lessThanOrEqualTo(1280));
    });

    test('la carte du bord gauche, symetrique : +97', () {
      expect(inspectionShift(left: -97, right: 487, screenWidth: 1920), 97);
    });

    test('une carte plus large que l ecran se centre', () {
      final shift = inspectionShift(left: 100, right: 2100, screenWidth: 1920);
      expect(100 + shift, -40);
      expect(2100 + shift, 1960);
    });

    test('a 1,25, la grandeur s arrondit au pixel physique superieur', () {
      final right = inspectionShift(
        left: 1300,
        right: 1536.3,
        screenWidth: 1536,
        devicePixelRatio: 1.25,
      );
      expect(right, -0.8);
      expect(1536.3 + right, lessThanOrEqualTo(1536));
      final left = inspectionShift(
        left: -0.3,
        right: 200,
        screenWidth: 1536,
        devicePixelRatio: 1.25,
      );
      expect(left, 0.8);
      expect(-0.3 + left, greaterThanOrEqualTo(0));
    });
  });
}
