import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';

/// La courbe d'XP (spec P-43 E3, §3.2, §8 ; D24, D58, D67).
void main() {
  const d67 = [
    115, 200, 310, 480, 590, 775, 955, 1100, //
    1040, 1185, 1370, 1370, 1300, 1375, 1015,
  ];

  Matcher refused() => throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('xpPerLevelByAct'),
        ),
      );

  test('lit la table par acte : 115 a l acte 1, 1015 a l acte 15', () {
    final curve = XpCurveData.fromJson({'xpPerLevelByAct': d67});

    expect(curve.xpPerLevelByAct, d67);
    expect(curve.thresholdFor(1), 115);
    expect(curve.thresholdFor(15), 1015);
  });

  test('au-dela de la table, la derniere valeur ; en dessous de l acte 1, '
      'la premiere', () {
    final curve = XpCurveData.fromJson({'xpPerLevelByAct': d67});

    expect(curve.thresholdFor(16), 1015);
    expect(curve.thresholdFor(40), 1015);
    expect(curve.thresholdFor(0), 115);
  });

  test('refuse une table absente ou vide', () {
    expect(() => XpCurveData.fromJson(const {}), refused());
    expect(
      () => XpCurveData.fromJson(const {'xpPerLevelByAct': []}),
      refused(),
    );
  });

  test('refuse un palier nul ou negatif : gainXp bouclerait sans fin', () {
    for (final bad in [0, -5]) {
      expect(
        () => XpCurveData.fromJson({
          'xpPerLevelByAct': [115, bad],
        }),
        refused(),
        reason: '$bad',
      );
    }
  });

  test('refuse un palier non entier', () {
    for (final bad in <Object?>[115.5, '115', null]) {
      expect(
        () => XpCurveData.fromJson({
          'xpPerLevelByAct': [bad],
        }),
        refused(),
        reason: '$bad',
      );
    }
  });
}
