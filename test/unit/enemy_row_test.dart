import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/enemy_row.dart';

import 'tier_frame_fixture.dart';

/// La rangée des ennemis (spec P-05, vague 2, §5.6) : 1080p à x2, soit un
/// écran de 1920 pixels logiques et un pixel de cadre de 2.
void main() {
  const ordinary = RowSlot(width: 146, gap: 7);
  const tight = RowSlot(width: 146, gap: 2);

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

  test('slotOf rend 146 aux cinq tiers, a l ecart minimal 7', () {
    for (final frame in testTierFrames) {
      final slot = slotOf(frame);

      expect(slot.width, 146, reason: 'tier ${frame.tier}');
      expect(slot.gap, 7);
    }
  });

  test('six places en 1080p a x2 : 306 et 1822', () {
    final centers = row(List.filled(6, ordinary));

    expect(gaps(centers), everyElement(306));
    expect(centers.last - centers.first + 292, 1822);
  });

  test('cinq places en 1080p a x2 : 306 et 1516', () {
    final centers = row(List.filled(5, ordinary));

    expect(gaps(centers), everyElement(306));
    expect(centers.last - centers.first + 292, 1516);
  });

  test('quatre places en 1080p a x2 : 326 et 1270', () {
    final centers = row(List.filled(4, ordinary));

    expect(centers, [471, 797, 1123, 1449]);
    expect(centers.last - centers.first + 292, 1270);
  });

  test('deux places en 1080p a x2 : 536 et 828', () {
    final centers = row(List.filled(2, ordinary));

    expect(gaps(centers), [536]);
    expect(centers.last - centers.first + 292, 828);
  });

  test('une place seule au centre', () {
    expect(row([ordinary]), [960]);
  });

  test('la rangee est centree', () {
    final centers = row(const [
      RowSlot(width: 146, gap: 7),
      RowSlot(width: 200, gap: 7),
    ]);

    final left = centers.first - 73 * 2;
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
      expect(gap, greaterThanOrEqualTo(153 * unit - 1e-9));
    }
  });

  test('deux places a ecart serre sont plus proches que deux ordinaires', () {
    final close = row(List.filled(2, tight), width: 600);
    final usual = row(List.filled(2, ordinary), width: 600);

    expect(gaps(close), [296]);
    expect(gaps(usual), [306]);
  });

  test('une place serree a cote d une ordinaire garde l ecart ordinaire', () {
    final centers = row(const [tight, ordinary], width: 600);

    expect(gaps(centers), [306]);
  });

  test('une meute de trois places serrees entre deux ordinaires', () {
    final centers = row(const [ordinary, tight, tight, tight, ordinary]);

    expect(gaps(centers), [306, 296, 296, 306]);
    final left = centers.first - 73 * 2;
    final right = 1920 - (centers.last + 73 * 2);
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
}
